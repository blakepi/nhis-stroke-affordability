# MEPS 2019-2024 registered replication: H1, H2 and pre-specified exploratory analyses.
# Usage: Rscript scripts/meps_analysis.R <mode> [replicates]
#   synthetic : outcomes simulated with planted effects (H1 PR 0.6; H2 PR 1.3), repeated <replicates> times
#   null      : outcomes simulated with no effect (PR 1), repeated <replicates> times
#   real      : the sealed outcome file; refused unless the registration tag is on the public remote
# Specification: REGISTERED_ANALYSIS_PLAN.md. Output: outputs/meps/<mode>/.
suppressPackageStartupMessages({library(data.table);library(survey)})
options(survey.lonely.psu="adjust")
args<-commandArgs(trailingOnly=TRUE);mode<-if(length(args))args[1] else "synthetic";R<-if(length(args)>1)as.integer(args[2]) else 1L
stopifnot(mode %in% c("synthetic","null","real"))
TAG<-"prereg-2026-11";PROC<-"data/processed/meps";OUT<-file.path("outputs/meps",mode)
if(mode=="real"){
 remote<-suppressWarnings(system2("git",c("ls-remote","--tags","origin",TAG),stdout=TRUE))
 if(!length(remote) || !any(grepl(TAG,remote))) stop("Real outcomes are sealed until tag ",TAG," is pushed to the public remote.")
}
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
p<-readRDS(file.path(PROC,"meps_analytic.rds"))
p[,`:=`(yearf=factor(year),coverage_c=factor(fcase(age_group=="65+" & coverage %in% c("Uninsured","Other coverage"),"65+: Other or uninsured",
  !is.na(coverage),paste0(age_group,": ",coverage),default=NA_character_)))]
p[,coverage_c:=relevel(coverage_c,ref="18-64: Private")]
p[,cov_u65:=factor(fifelse(age_group=="18-64",coverage,NA_character_),levels=c("Private","Medicaid and other public","Other coverage","Uninsured"))]
p[,cov_65:=factor(fifelse(age_group=="65+" & coverage!="Uninsured",coverage,NA_character_),levels=c("Private","Dual eligible","Medicare Advantage","Medicare only excluding Medicare Advantage","Other coverage"))]
core<-p[adult & stroke & eligible & complete]
COV<-"age_group + splines::ns(age, df=3) + sex + race + region + education + income + yearf + hypertension + diabetes + coronary + smoking + fairpoor + disability"
# H2 models adjust for age-group-specific coverage, which already encodes age group.
COV2<-sub("age_group + ","",COV,fixed=TRUE)
OUTCOMES<-c("any_barrier","care_barrier","rx_barrier","dental_barrier","no_ldl_fill","any_anticoag","any_antiplatelet","any_antihtn","n_statin","totslf","rxslf","oop_ldl","oop_burden10","oop_burden20","days_ldl")

simulate<-function(d,planted,seed){
 set.seed(seed);n<-nrow(d)
 base<-fifelse(d$age_group=="18-64",0.20,0.08)*exp(0.25*d$fairpoor)
 eff<-if(planted)0.6 else 1
 mt<-fifelse(is.na(d$medicaid_type),0,d$medicaid_type)
 d[,any_barrier:=rbinom(n,1,pmin(0.95,base*eff^mt))]
 d[,care_barrier:=as.integer(any_barrier==1 & runif(n)<0.6)];d[,rx_barrier:=as.integer(any_barrier==1 & (care_barrier==0 | runif(n)<0.5))]
 d[,dental_barrier:=rbinom(n,1,0.15)]
 d[,no_ldl_fill:=rbinom(n,1,pmin(0.95,0.30*(if(planted)1.3 else 1)^any_barrier))]
 for(v in c("any_anticoag","any_antiplatelet","any_antihtn","oop_burden10","oop_burden20"))set(d,j=v,value=rbinom(n,1,0.2))
 for(v in c("n_statin","totslf","rxslf","oop_ldl","days_ldl"))set(d,j=v,value=rexp(n,1/100))
 d
}
attach_outcomes<-function(d,rep){
 if(mode=="real"){o<-readRDS(file.path(PROC,"meps_outcomes_SEALED.rds"));return(merge(d,o,by=c("DUPERSID","year"),all.x=TRUE))}
 simulate(copy(d),mode=="synthetic",20261116L+rep)
}
fit_pr<-function(des,formula,term){
 f<-svyglm(as.formula(formula),design=des,family=quasipoisson(link="log"));stopifnot(f$converged)
 b<-coef(f)[term];se<-sqrt(vcov(f)[term,term]);df<-f$df.residual;crit<-qt(.975,df)
 data.table(term=term,PR=exp(b),lower=exp(b-crit*se),upper=exp(b+crit*se),p=2*pt(-abs(b/se),df),log_PR=b,se=se,n=nrow(f$survey.design$variables),max_fitted=max(fitted(f)))
}
# Marginal (standardized) prevalence ratio from a bounded logistic model; point estimate only
# (interval for the registered sensitivity analysis is computed with the influence-function method
# used in scripts/extended_analysis.R when real outcomes are analyzed).
marg_pr<-function(des,formula,var){
 f<-svyglm(as.formula(formula),design=des,family=quasibinomial());stopifnot(f$converged)
 X<-model.matrix(f);w<-f$prior.weights;stopifnot(nrow(X)==length(w),var %in% colnames(X),!anyNA(coef(f)))
 b<-coef(f);if(ncol(X)!=length(b))stop(sprintf('marg_pr: %d columns vs %d coefficients; extra: %s / %s',ncol(X),length(b),paste(setdiff(colnames(X),names(b)),collapse=','),paste(setdiff(names(b),colnames(X)),collapse=',')))
 pr<-function(val){X[,var]<-val;sum(w*plogis(drop(X%*%b)))/sum(w)}
 p1<-pr(1);p0<-pr(0)
 data.table(term=var,marginal_PR=p1/p0,p_exposed=p1,p_unexposed=p0)
}
one_run<-function(rep){
 d<-attach_outcomes(p,rep)
 # Outcomes used in replicate 1 are saved for the independent Python reproduction (git-ignored data folder).
 if(rep==1L) fwrite(d[,.(DUPERSID,year,any_barrier,no_ldl_fill,dental_barrier)],file.path(PROC,paste0("validation_outcomes_",mode,".csv")))
 des<-svydesign(ids=~psu,strata=~stratum,weights=~wt,data=d,nest=TRUE)
 dom<-function(expr)subset(des,eval(expr))
 res<-list()
 h1d<-subset(des,adult & stroke & eligible & complete & !is.na(medicaid_type) & !is.na(any_barrier))
 res$H1<-fit_pr(h1d,paste("any_barrier ~ medicaid_type +",COV),"medicaid_type")[,hypothesis:="H1"]
 h2d<-subset(des,adult & stroke & eligible & complete & high_chol & !is.na(any_barrier) & !is.na(coverage_c))
 res$H2<-fit_pr(h2d,paste("no_ldl_fill ~ any_barrier + coverage_c +",COV2),"any_barrier")[,hypothesis:="H2"]
 res$NC<-fit_pr(subset(h2d,!is.na(dental_barrier)),paste("no_ldl_fill ~ dental_barrier + coverage_c +",COV2),"dental_barrier")[,hypothesis:="Negative control (dental barrier)"]
 out<-rbindlist(res,fill=TRUE)
 pr<-out[hypothesis %in% c("H1","H2")];out[hypothesis %in% c("H1","H2"),p_holm:=p.adjust(pr$p,"holm")]
 out[,replicate:=rep]
 if(rep==1L){
  ex<-list()
  # Age-specific H1 estimates.
  for(g in c("18-64","65+"))ex[[length(ex)+1L]]<-fit_pr(subset(h1d,age_group==g),paste("any_barrier ~ medicaid_type +",sub("age_group + ","",COV,fixed=TRUE)),"medicaid_type")[,analysis:=paste("H1 age-specific",g)]
  # Full coverage models within age group (as NHIS Table 3).
  for(spec in list(list(v="cov_u65",g="18-64",lv=c("Medicaid and other public","Other coverage","Uninsured")),list(v="cov_65",g="65+",lv=c("Dual eligible","Medicare Advantage","Medicare only excluding Medicare Advantage","Other coverage")))){
   dd<-subset(des,adult & stroke & eligible & complete & age_group==spec$g & !is.na(get(spec$v)) & !is.na(any_barrier))
   f<-svyglm(as.formula(paste("any_barrier ~",spec$v,"+",sub("age_group + ","",COV,fixed=TRUE))),design=dd,family=quasipoisson(link="log"))
   for(l in spec$lv){t<-paste0(spec$v,l);b<-coef(f)[t];se<-sqrt(vcov(f)[t,t]);crit<-qt(.975,f$df.residual)
    ex[[length(ex)+1L]]<-data.table(analysis=paste("Coverage",spec$g),term=l,PR=exp(b),lower=exp(b-crit*se),upper=exp(b+crit*se),p=2*pt(-abs(b/se),f$df.residual),n=nrow(f$survey.design$variables))}
  }
  # Domains of the barrier and sensitivity analyses for H1/H2.
  for(o in c("care_barrier","rx_barrier"))ex[[length(ex)+1L]]<-fit_pr(subset(h1d,!is.na(get(o))),paste(o,"~ medicaid_type +",COV),"medicaid_type")[,analysis:=paste("H1 domain",o)]
  ex[[length(ex)+1L]]<-fit_pr(subset(h1d,year!=2020),paste("any_barrier ~ medicaid_type +",sub("yearf + ","",COV,fixed=TRUE),"+ yearf"),"medicaid_type")[,analysis:="H1 excluding 2020"]
  ex[[length(ex)+1L]]<-fit_pr(subset(h2d,year!=2020),paste("no_ldl_fill ~ any_barrier + coverage_c +",COV2),"any_barrier")[,analysis:="H2 excluding 2020"]
  st<-subset(des,adult & stroke & eligible & complete & !is.na(any_barrier) & coverage_stable %in% c("Private","Medicaid and other public","Dual eligible"))
  st$variables$mt_stable<-as.integer(st$variables$coverage_stable!="Private")
  ex[[length(ex)+1L]]<-fit_pr(st,paste("any_barrier ~ mt_stable +",COV),"mt_stable")[,analysis:="H1 same coverage all year"]
  ex[[length(ex)+1L]]<-fit_pr(h2d,paste("no_ldl_fill ~ care_barrier + rx_barrier + coverage_c +",COV2),"care_barrier")[,analysis:="H2 joint: care barrier"]
  ex[[length(ex)+1L]]<-fit_pr(h2d,paste("no_ldl_fill ~ care_barrier + rx_barrier + coverage_c +",COV2),"rx_barrier")[,analysis:="H2 joint: medication barrier"]
  ex[[length(ex)+1L]]<-marg_pr(h1d,paste("any_barrier ~ medicaid_type +",COV),"medicaid_type")[,analysis:="H1 bounded logistic marginal PR"]
  ex[[length(ex)+1L]]<-marg_pr(h2d,paste("no_ldl_fill ~ any_barrier + coverage_c +",COV2),"any_barrier")[,analysis:="H2 bounded logistic marginal PR"]
  fwrite(rbindlist(ex,fill=TRUE),file.path(OUT,"exploratory_and_sensitivity.csv"))
  # Descriptive: fills and out-of-pocket spending by coverage among survivors (exploratory).
  ds<-subset(des,adult & stroke & eligible & !is.na(coverage_c))
  desc<-rbindlist(lapply(c("any_barrier","care_barrier","rx_barrier","no_ldl_fill","any_anticoag","any_antiplatelet","any_antihtn","oop_burden10","oop_burden20","totslf","rxslf","oop_ldl"),function(o){
   m<-svyby(as.formula(paste0("~",o)),~coverage_c,subset(ds,!is.na(get(o))),svymean,na.rm=TRUE)
   data.table(outcome=o,coverage=as.character(m$coverage_c),estimate=coef(m),se=SE(m))}))
  fwrite(desc,file.path(OUT,"descriptive_by_coverage.csv"))
 }
 out
}
runs<-rbindlist(lapply(seq_len(R),function(r){x<-one_run(r);if(r%%10==0)cat("replicate",r,"\n");flush.console();x}),fill=TRUE)
fwrite(runs,file.path(OUT,"confirmatory_runs.csv"))
if(mode!="real"){
 truth<-c(H1=if(mode=="synthetic")0.6 else 1,H2=if(mode=="synthetic")1.3 else 1,`Negative control (dental barrier)`=1)
 sm<-runs[,.(replicates=.N,mean_PR=exp(mean(log_PR)),coverage_95=mean(lower<=truth[hypothesis] & upper>=truth[hypothesis]),
   rejection_rate=mean(p<0.05),rejection_rate_holm=mean(p_holm<0.05,na.rm=TRUE)),by=hypothesis]
 sm[,true_PR:=truth[hypothesis]]
 fwrite(sm,file.path(OUT,"simulation_summary.csv"));print(sm)
} else print(runs)
writeLines(capture.output(sessionInfo()),file.path(OUT,"R_session_info.txt"))
