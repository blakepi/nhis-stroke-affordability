suppressPackageStartupMessages({library(data.table);library(survey);library(mitools);library(ggplot2)})
options(survey.lonely.psu="fail")
OUT<-"outputs/full"; dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
base<-readRDS("data/processed/full/base.rds");income<-readRDS("data/processed/full/income.rds")
M<-10L
dem<-"yearf + splines::ns(age, df=3) + sex + race + region"
soc<-paste(dem,"+ education + income_group + insurance")
full<-paste(soc,"+ hypertension + diabetes + coronary + smoking + fairpoor + disability")
formula_for<-function(rhs,outcome="any_barrier")as.formula(paste(outcome,"~",rhs))
age_dem<-"yearf + young + sex + race + region"
age_soc<-paste(age_dem,"+ education + income_group + insurance")
age_full<-paste(age_soc,"+ hypertension + diabetes + coronary + smoking + fairpoor + disability")

combine<-function(estimates,variances,dfcomplete){
 MIcombine(results=estimates,variances=variances,df.complete=dfcomplete)
}
pool_fits<-function(fits,label){
 q<-combine(lapply(fits,coef),lapply(fits,vcov),min(sapply(fits,function(x)x$df.residual)))
 se<-sqrt(diag(q$variance));crit<-qt(.975,q$df)
 list(pool=q,table=data.table(model=label,term=names(q$coefficients),log_PR=q$coefficients,se=se,
    PR=exp(q$coefficients),lower=exp(q$coefficients-crit*se),upper=exp(q$coefficients+crit*se),
    p=2*pt(-abs(q$coefficients/se),df=q$df),df=q$df,missing_information=q$missinfo))
}
# Approximate pooled multivariate Wald F with the minimum scalar Rubin df.
# Explicitly an approximation, not the specialized D1/D2 MI test.
joint_test<-function(pooled,terms,label){
 idx<-which(terms);b<-pooled$coefficients[idx];v<-pooled$variance[idx,idx,drop=FALSE]
 stat<-as.numeric(crossprod(b,solve(v,b)))/length(idx);df2<-min(pooled$df[idx])
 data.table(test=label,F=stat,df1=length(idx),df2=df2,p=pf(stat,length(idx),df2,lower.tail=FALSE),method="Rubin pooled Wald F; minimum scalar df")
}
survey_var<-function(infl,design){
 survey::svyrecvar(infl,design$cluster,design$strata,design$fpc,design$postStrata)
}
margin_bundle<-function(fit){
 d<-fit$survey.design;data<-d$variables;w<-as.numeric(weights(d));w<-w/sum(w)
 infl<-attr(fit,"influence")
 # Verify influence scaling before using it in joint standardization.
 stopifnot(max(abs(survey_var(infl,d)-vcov(fit)))<1e-8)
 vals<-numeric(7);u<-matrix(0,nrow(data),7);names(vals)<-as.character(2019:2025)
 for(i in seq_along(vals)){
  nd<-data;nd$yearf<-factor(2018+i,levels=2019:2025)
  x<-model.matrix(delete.response(terms(fit)),nd,contrasts.arg=fit$contrasts,xlev=fit$xlevels)
  mu<-plogis(as.vector(x%*%coef(fit)));p<-sum(w*mu)
  grad<-colSums(x*(w*mu*(1-mu)))
  # Includes uncertainty in the weighted reference covariate distribution.
  u[,i]<-as.vector(infl%*%grad)+w*(mu-p)
  vals[i]<-p
 }
 cov<-survey_var(u,d);dimnames(cov)<-list(names(vals),names(vals))
 list(est=vals,var=cov,df=fit$df.residual)
}
pool_margins<-function(bundles,label){
 estimates<-lapply(bundles,function(z)qlogis(z$est))
 variances<-lapply(bundles,function(z){D<-diag(1/(z$est*(1-z$est)));v<-D%*%z$var%*%D;dimnames(v)<-dimnames(z$var);v})
 q<-combine(estimates,variances,min(sapply(bundles,`[[`,"df")))
 se<-sqrt(diag(q$variance));crit<-qt(.975,q$df)
 data.table(model=label,year=2019:2025,estimate=plogis(q$coefficients),lower=plogis(q$coefficients-crit*se),upper=plogis(q$coefficients+crit*se),logit_se=se,df=q$df)
}
precision<-function(n,p,se,lower,upper,df){
 neff<-p*(1-p)/se^2;width<-upper-lower
 if(n<30 || (!is.na(neff)&&neff<30) || width>.30 || (width>.05 && width<=.30 && width/min(p,1-p)>1.30))return("limited")
 if(df<8)return("review_df")
 "adequate"
}
desc_est<-function(design,variable,domain=rep(TRUE,nrow(design$variables))){
 domain<-domain & !is.na(design$variables[[variable]]);domain[is.na(domain)]<-FALSE
 d<-design[domain,];n<-nrow(d$variables);events<-sum(d$variables[[variable]])
 fit<-svymean(reformulate(variable),d);p<-as.numeric(coef(fit));se<-as.numeric(SE(fit));df<-degf(d)
 # Korn-Graubard beta interval, using effective n adjusted by t quantiles.
 neff<-if(se>0)min(n,p*(1-p)/se^2) else n
 neff_df<-neff*(qnorm(.975)/qt(.975,df))^2
 lower<-if(events==0)0 else qbeta(.025,neff_df*p,neff_df*(1-p)+1)
 upper<-if(events==n)1 else qbeta(.975,neff_df*p+1,neff_df*(1-p))
 data.table(n=n,events=events,estimate=p,se=se,lower=lower,upper=upper,df=df,effective_n=neff_df,
    reliability=precision(n,p,se,lower,upper,df))
}

fits<-list(M1=list(),M2=list(),M3=list(),Age_M1=list(),Age_M2=list(),Age_M3=list(),AgeInteraction=list(),
 No2020=list(),WorkingAge=list(),NoDisability=list(),Universal=list(),Delayed=list(),ForgoneCare=list(),ForgoneRx=list(),RxUnderuse=list(),MissingCategory=list())
margins<-list();diagnostics<-list();table1<-list();subgroups<-list();income_summary<-list();marginal_contrasts<-list()
tablevars<-c("young","sex","race","region","education","income_group","insurance","hypertension","diabetes","coronary","smoking","fairpoor","disability")

for(m in 1:M){
 d<-copy(base)
 inc<-income[IMPNUM_A==m]
 key<-paste(d$year,d$HHX);ik<-paste(inc$year,inc$HHX);idx<-match(key,ik)
 stopifnot(!anyNA(idx));rc<-inc$RATCAT_A[idx]
 # NCHS income technical document Appendix D.2 uses these RATCAT cut points.
 d[,income_group:=factor(fcase(rc %in% 1:3,"<100%",rc %in% 4:7,"100-199%",rc %in% 8:11,"200-399%",rc %in% 12:14,"400%+"),levels=c("400%+","200-399%","100-199%","<100%"))]
 d[,income_imputed:=inc$IMPINCFLG_A[idx]!=0]
 des<-svydesign(ids=~PPSU,strata=~PSTRAT,weights=~pooled_weight,data=d,nest=TRUE)
 cc<-subset(des,stroke & complete)
 fit_one<-function(rhs=full,outcome="any_barrier",domain=cc,family=quasipoisson(link="log"),influence=FALSE){
   fit<-svyglm(formula_for(rhs,outcome),design=domain,family=family,influence=influence)
   stopifnot(fit$converged,all(is.finite(coef(fit))))
   fit
 }
 for(n in c("M1","M2","M3","Age_M1","Age_M2","Age_M3")){
  rhs<-switch(n,M1=dem,M2=soc,M3=full,Age_M1=age_dem,Age_M2=age_soc,Age_M3=age_full)
  fits[[n]][[m]]<-fit_one(rhs)
 }
 fits$AgeInteraction[[m]]<-fit_one(paste(age_full,"+ yearf:young"))
 fits$No2020[[m]]<-fit_one(domain=subset(cc,year!=2020))
 fits$WorkingAge[[m]]<-fit_one(domain=subset(cc,young=="18-64"))
 fits$NoDisability[[m]]<-fit_one(rhs=sub(" + disability","",full,fixed=TRUE),domain=subset(cc,disability=="Without disability"))
 for(n in c("Universal","Delayed","ForgoneCare","ForgoneRx","RxUnderuse")){
  o<-switch(n,Universal="universal_barrier",Delayed="delayed_care",ForgoneCare="forgone_care",ForgoneRx="forgone_rx",RxUnderuse="rx_underuse")
  dd<-cc[!is.na(cc$variables[[o]]),]
  fits[[n]][[m]]<-fit_one(outcome=o,domain=dd)
 }
 # Explicit missing-category diagnostic retains observed outcomes; not imputation.
 missvars<-c("education","insurance","hypertension","diabetes","coronary","smoking","fairpoor")
 for(v in missvars){lv<-levels(d[[v]]);val<-as.character(d[[v]]);val[is.na(val)]<-"Unknown";set(d,j=v,value=factor(val,levels=c(lv,"Unknown")))}
 mdes<-svydesign(ids=~PPSU,strata=~PSTRAT,weights=~pooled_weight,data=d,nest=TRUE)
 mdes<-subset(mdes,stroke & !is.na(any_barrier))
 fits$MissingCategory[[m]]<-fit_one(domain=mdes)
 logfit<-fit_one(family=quasibinomial(link="logit"),influence=TRUE)
 margins[[m]]<-margin_bundle(logfit)
 # 2025 minus 2019 standardized absolute difference, on the probability scale.
 cvec<-c(-1,0,0,0,0,0,1)
 marginal_contrasts[[m]]<-list(est=c(diff2025_2019=sum(cvec*margins[[m]]$est)),var=matrix(as.numeric(t(cvec)%*%margins[[m]]$var%*%cvec),1,1),df=logfit$df.residual)
 for(n in names(fits)){
  f<-fits[[n]][[m]];diagnostics[[length(diagnostics)+1L]]<-data.table(imputation=m,model=n,n=nrow(f$survey.design$variables),events=sum(f$y),rank=f$rank,converged=f$converged,max_fitted=max(fitted(f)),above_one=sum(fitted(f)>1))
 }
 # Descriptive Table 1: unweighted counts and weighted percentages by outcome.
 desc<-subset(des,stroke & !is.na(any_barrier))
 for(g in c("Overall","No barrier","Any barrier")){
  dd<-if(g=="Overall")desc else desc[desc$variables$any_barrier==if(g=="Any barrier")1 else 0,]
  for(v in tablevars){
   levels_v<-c(levels(dd$variables[[v]]),"Missing")
   for(lv in levels_v){
    val<-if(lv=="Missing")is.na(dd$variables[[v]]) else !is.na(dd$variables[[v]]) & dd$variables[[v]]==lv
    # Binary category indicator is complete: unknowns reported as their own row.
    val<-as.numeric(val);fit<-svymean(~val,dd)
    table1[[length(table1)+1L]]<-data.table(imputation=m,group=g,variable=v,level=lv,n=sum(val),denominator=length(val),estimate=as.numeric(coef(fit)),variance=as.numeric(vcov(fit)))
   }
  }
 }
 for(v in c("young","income_group","insurance","disability")){
  for(lv in levels(desc$variables[[v]])){
   res<-desc_est(desc,"any_barrier",desc$variables[[v]]==lv)
   res[,`:=`(imputation=m,variable=v,level=lv)]
   subgroups[[length(subgroups)+1L]]<-res
  }
 }
 income_summary[[m]]<-data.table(imputation=m,n=sum(d$stroke),income_imputed=sum(d$income_imputed & d$stroke),weighted_pct=100*weighted.mean(d$income_imputed[d$stroke],d$pooled_weight[d$stroke]))
 # Compact per-imputation exports support independent model verification.
 f<-fits$M3[[m]]
 if(m==1){
  x<-as.data.table(model.matrix(f));x[,`:=`(y=f$y,weight=as.numeric(weights(f$survey.design)),PSTRAT=f$survey.design$variables$PSTRAT,PPSU=f$survey.design$variables$PPSU)]
  fwrite(x,"data/processed/full/model_matrix_m1.csv")
 }
 cat("Completed imputation",m,"of",M,"\n");flush.console()
}

pooled<-lapply(names(fits),function(n)pool_fits(fits[[n]],n));names(pooled)<-names(fits)
fwrite(rbindlist(lapply(pooled,`[[`,"table")),file.path(OUT,"model_coefficients.csv"))
tests<-rbindlist(list(joint_test(pooled$M3$pool,grepl("^yearf",names(pooled$M3$pool$coefficients)),"Overall categorical year, full model"),
 joint_test(pooled$AgeInteraction$pool,grepl(":",names(pooled$AgeInteraction$pool$coefficients)),"Year by age group interaction, full model")))
fwrite(tests,file.path(OUT,"joint_tests.csv"))
fwrite(rbindlist(diagnostics),file.path(OUT,"model_diagnostics.csv"))
fwrite(pool_margins(margins,"Fully adjusted logistic"),file.path(OUT,"adjusted_annual_prevalence.csv"))
q<-combine(lapply(marginal_contrasts,`[[`,"est"),lapply(marginal_contrasts,`[[`,"var"),min(sapply(marginal_contrasts,`[[`,"df")))
se<-sqrt(diag(q$variance));fwrite(data.table(contrast="2025 minus 2019",difference=q$coefficients,lower=q$coefficients-qt(.975,q$df)*se,upper=q$coefficients+qt(.975,q$df)*se,p=2*pt(-abs(q$coefficients/se),q$df)),file.path(OUT,"adjusted_year_difference.csv"))
t1<-rbindlist(table1);fwrite(t1,file.path(OUT,"table1_imputations.csv"))
t1pool<-t1[,.(n_mean=mean(n),n_min=min(n),n_max=max(n),denominator=unique(denominator),weighted_pct=100*mean(estimate)),by=.(group,variable,level)]
fwrite(t1pool,file.path(OUT,"table1_characteristics.csv"))
sg<-rbindlist(subgroups);fwrite(sg,file.path(OUT,"subgroup_imputations.csv"))
sgpool<-sg[,{
  z<-combine(as.list(qlogis(estimate)),lapply(seq_len(.N),function(i)matrix(se[i]^2/(estimate[i]^2*(1-estimate[i])^2),1,1)),min(df))
  s<-sqrt(z$variance[1,1]);crit<-qt(.975,z$df)
  .(n_mean=mean(n),n_min=min(n),n_max=max(n),events_mean=mean(events),estimate=plogis(z$coefficients),lower=plogis(z$coefficients-crit*s),upper=plogis(z$coefficients+crit*s),reliability=if(all(reliability=="adequate"))"adequate" else "limited")
},by=.(variable,level)]
fwrite(sgpool,file.path(OUT,"subgroup_prevalence.csv"))
fwrite(rbindlist(income_summary),file.path(OUT,"income_imputation_summary.csv"))

# Main descriptive component table and complete-case versus excluded comparison.
des0<-svydesign(ids=~PPSU,strata=~PSTRAT,weights=~pooled_weight,data=base,nest=TRUE)
ds<-subset(des0,stroke)
components<-rbindlist(lapply(c("any_barrier","universal_barrier","delayed_care","forgone_care","forgone_rx","rx_underuse"),function(o){r<-desc_est(ds,o);r[,outcome:=o];r}))
fwrite(components,file.path(OUT,"component_prevalence.csv"))
selection<-rbindlist(lapply(c(TRUE,FALSE),function(z){r<-desc_est(ds,"any_barrier",ds$variables$complete==z);r[,complete_case:=z];r}))
fwrite(selection,file.path(OUT,"complete_case_comparison.csv"))
saveRDS(list(pools=lapply(pooled,`[[`,"pool"),margins=margins,tests=tests),"data/processed/full/pooled_models.rds")
saveRDS(lapply(fits,function(fs)lapply(fs,function(f)list(coef=coef(f),vcov=vcov(f),df=f$df.residual))),"data/processed/full/imputation_model_summaries.rds")
# JSON covariances enable validation without R object deserialization.
jsonlite::write_json(lapply(fits,function(fs)lapply(fs,function(f)list(terms=names(coef(f)),coef=unname(coef(f)),vcov=unname(vcov(f)),df=f$df.residual))),file.path(OUT,"model_imputation_summaries.json"),digits=16,auto_unbox=TRUE)
writeLines(capture.output(sessionInfo()),file.path(OUT,"R_session_info.txt"))
cat("Full models complete.\n");print(tests);print(components);print(sgpool)
