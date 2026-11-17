# Confidence intervals for the registered bounded-logistic sensitivity analysis of H1 and H2
# (REGISTERED_ANALYSIS_PLAN.md, Section 3). scripts/meps_analysis.R reports these marginal prevalence ratios as point
# estimates; its comment specifies that the interval is computed with the influence-function method of
# scripts/extended_analysis.R once real outcomes are analyzed. Added after registration (DEVIATIONS.md, item 1); it does
# not change any registered estimate, and the point estimates must equal those in exploratory_and_sensitivity.csv.
# Usage: Rscript scripts/meps_marginal_ci.R <mode>   (reads the outcomes meps_analysis.R saved for that mode)
suppressPackageStartupMessages({library(data.table);library(survey)})
options(survey.lonely.psu="adjust")
args<-commandArgs(trailingOnly=TRUE);mode<-if(length(args))args[1] else "real"
stopifnot(mode %in% c("synthetic","null","real"))
PROC<-"data/processed/meps";OUT<-file.path("outputs/meps",mode)
p<-readRDS(file.path(PROC,"meps_analytic.rds"))
p[,`:=`(yearf=factor(year),coverage_c=factor(fcase(age_group=="65+" & coverage %in% c("Uninsured","Other coverage"),"65+: Other or uninsured",
  !is.na(coverage),paste0(age_group,": ",coverage),default=NA_character_)))]
p[,coverage_c:=relevel(coverage_c,ref="18-64: Private")]
COV<-"age_group + splines::ns(age, df=3) + sex + race + region + education + income + yearf + hypertension + diabetes + coronary + smoking + fairpoor + disability"
COV2<-sub("age_group + ","",COV,fixed=TRUE)
o<-fread(file.path(PROC,paste0("validation_outcomes_",mode,".csv")),colClasses=list(character="DUPERSID"))
d<-merge(p,o,by=c("DUPERSID","year"),all.x=TRUE)
d[,`:=`(mt_f=factor(medicaid_type,levels=0:1,labels=c("Private","Medicaid-type")),bar_f=factor(any_barrier,levels=0:1,labels=c("No","Yes")))]
des<-svydesign(ids=~psu,strata=~stratum,weights=~wt,data=d,nest=TRUE)
survey_var<-function(infl,design)survey::svyrecvar(infl,design$cluster,design$strata,design$fpc,design$postStrata)
marg<-function(fit,v){
 dd<-fit$survey.design;data<-dd$variables;w<-as.numeric(weights(dd));w<-w/sum(w);infl<-attr(fit,"influence")
 stopifnot(max(abs(survey_var(infl,dd)-vcov(fit)))<1e-8)
 lv<-levels(data[[v]]);pp<-numeric(2);u<-matrix(0,nrow(data),2)
 for(j in 1:2){
  nd<-data;nd[[v]]<-factor(lv[j],levels=lv)
  x<-model.matrix(delete.response(terms(fit)),nd,contrasts.arg=fit$contrasts,xlev=fit$xlevels)
  mu<-plogis(as.vector(x%*%coef(fit)));pp[j]<-sum(w*mu);g<-colSums(x*(w*mu*(1-mu)));u[,j]<-as.vector(infl%*%g)+w*(mu-pp[j])
 }
 cv<-survey_var(u,dd);a<-c(-1/pp[1],1/pp[2]);b<-log(pp[2]/pp[1]);se<-sqrt(as.numeric(t(a)%*%cv%*%a));crit<-qt(.975,fit$df.residual)
 data.table(term=paste0(v,lv[2]),marginal_PR=exp(b),lower=exp(b-crit*se),upper=exp(b+crit*se),p=2*pt(-abs(b/se),fit$df.residual),
            p_exposed=pp[2],p_unexposed=pp[1],n=nrow(data))
}
h1d<-subset(des,adult & stroke & eligible & complete & !is.na(medicaid_type) & !is.na(any_barrier))
h2d<-subset(des,adult & stroke & eligible & complete & high_chol & !is.na(any_barrier) & !is.na(coverage_c))
f1<-svyglm(as.formula(paste("any_barrier ~ mt_f +",COV)),design=h1d,family=quasibinomial(),influence=TRUE)
f2<-svyglm(as.formula(paste("no_ldl_fill ~ bar_f + coverage_c +",COV2)),design=h2d,family=quasibinomial(),influence=TRUE)
res<-rbind(marg(f1,"mt_f")[,hypothesis:="H1"],marg(f2,"bar_f")[,hypothesis:="H2"])
prev<-fread(file.path(OUT,"exploratory_and_sensitivity.csv"))[grepl("bounded logistic",analysis)]
res[,point_estimate_in_meps_analysis:=prev$marginal_PR[match(paste(hypothesis,"bounded logistic marginal PR"),prev$analysis)]]
stopifnot(max(abs(res$marginal_PR-res$point_estimate_in_meps_analysis))<1e-8)
fwrite(res,file.path(OUT,"bounded_logistic_marginal_PR.csv"));print(res)
