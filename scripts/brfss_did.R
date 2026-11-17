# BRFSS Medicaid-expansion staggered difference-in-differences (H3, H4) and pre-specified checks.
# Usage: Rscript scripts/brfss_did.R <mode> [replicates]
#   synthetic : outcomes simulated with a planted ATT of -5 percentage points (H3 and H4)
#   null      : outcomes simulated with no effect
#   covariates: event studies on covariates and stroke prevalence (outcome-blind composition checks)
#   smoke     : one planted-effect replicate written to its own folder (checks the full pipeline)
#   real      : sealed outcomes; refused unless the registration tag is on the public remote
# Specification: REGISTERED_ANALYSIS_PLAN.md. Output: outputs/brfss/did_<mode>/.
suppressPackageStartupMessages({library(data.table);library(did);library(HonestDiD);library(fixest)})
args<-commandArgs(trailingOnly=TRUE);mode<-if(length(args))args[1] else "synthetic";R<-if(length(args)>1)as.integer(args[2]) else 1L
stopifnot(mode %in% c("synthetic","null","covariates","real","smoke"))
TAG<-"prereg-2026-11";PROC<-"data/processed/brfss";OUT<-file.path("outputs/brfss",paste0("did_",mode))
if(mode=="real"){
 remote<-suppressWarnings(system2("git",c("ls-remote","--tags","origin",TAG),stdout=TRUE))
 if(!length(remote) || !any(grepl(TAG,remote))) stop("Real outcomes are sealed until tag ",TAG," is pushed to the public remote.")
}
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
a<-readRDS(file.path(PROC,"brfss_analytic.rds"))
a<-a[status!="excluded" & wt>0 & !is.na(age) & !is.na(sex) & !is.na(race) & !is.na(educ)]
a[,`:=`(female=as.integer(sex==2),college=as.integer(educ=="College graduate"),nonwhite=as.integer(race!=1),hs_or_less=as.integer(educ %in% c("Less than high school","High school")))]
# Treatment timing within the primary 2011-2019 window: 2014-16 cohorts treated; later expanders are
# not yet treated (coded 0); VA and ME 2019 observations are dropped so they serve only as controls.
window<-function(d,last=2019){
 d<-d[year<=last]
 if(last==2019){d<-d[!(state_abbr %in% c("VA","ME") & year==2019)];d[,g:=fifelse(first_treat_year %in% 2014:2016,first_treat_year,0)]}
 else d[,g:=first_treat_year]
 d[,id:=.I];d
}
outcomes_real<-function(d){
 s<-readRDS(file.path(PROC,"brfss_outcomes_SEALED.rds"));d<-merge(d,s,by=c("row_id","year"),all.x=TRUE)
 d[,uninsured:=fcase(HLTHPLN1==2,1,HLTHPLN1==1,0,`_HLTHPLN`==2,1,`_HLTHPLN`==1,0,`_HLTHPL1`==2,1,`_HLTHPL1`==1,0,`_HLTHPL2`==2,1,`_HLTHPL2`==1,0,default=NA_real_)]
 d[,cost_barrier:=fcase(MEDCOST==1,1,MEDCOST==2,0,MEDCOST1==1,1,MEDCOST1==2,0,default=NA_real_)]
 d[,no_checkup:=fcase(CHECKUP1 %in% c(2,3,4,8),1,CHECKUP1==1,0,default=NA_real_)]
 d[,no_clinician:=fcase(PERSDOC2==3,1,PERSDOC2 %in% 1:2,0,PERSDOC3==3,1,PERSDOC3 %in% 1:2,0,default=NA_real_)]
 d
}
simulate<-function(d,att,seed){
 set.seed(seed);n<-nrow(d)
 se<-d[,.(u=rnorm(1,0,0.04)),by=state];ye<-data.table(year=2011:2025,v=seq(0,-0.06,length.out=15))
 d<-merge(merge(d,se,by="state"),ye,by="year");treated<-d$g>0 & d$year>=d$g
 for(o in c("uninsured","cost_barrier","no_checkup","no_clinician")){
  base<-switch(o,uninsured=0.30,cost_barrier=0.35,no_checkup=0.25,no_clinician=0.25)
  set(d,j=o,value=rbinom(n,1,pmin(0.95,pmax(0.01,base+d$u+d$v+0.03*(d$female)+att*treated))))
 }
 d[,c("u","v"):=NULL];d
}
# Primary: unweighted outcome-regression Callaway-Sant'Anna with binary covariates (registered after an
# outcome-blind comparison on simulated outcomes: BRFSS weights have a Kish design effect near 4, which doubled
# the standard error; Solon, Haider and Wooldridge 2015). Survey-weighted and equal-state-weight versions are
# registered sensitivity analyses.
est<-function(d,y,xf=~age+female+nonwhite+hs_or_less,cg="notyettreated",bs=TRUE,biters=999,weights=c("none","survey","state"),method="reg"){
 weights<-match.arg(weights);d<-d[!is.na(get(y))]
 d[,w_use:=switch(weights,none=1,survey=wt/mean(wt),state={x<-1/table(state)[as.character(state)];as.numeric(x/mean(x))})]
 m<-att_gt(yname=y,tname="year",idname="id",gname="g",xformla=xf,data=as.data.frame(d),panel=FALSE,control_group=cg,
   weightsname="w_use",clustervars="state",est_method=method,base_period="universal",bstrap=bs,biters=biters,cband=FALSE,print_details=FALSE)
 list(m=m,simple=aggte(m,type="simple",na.rm=TRUE,bstrap=bs,biters=biters,clustervars="state"),
      es=aggte(m,type="dynamic",min_e=-3,max_e=5,na.rm=TRUE,bstrap=bs,biters=biters,clustervars="state"),n=nrow(d),states=uniqueN(d$state))
}
tidy_simple<-function(r,label){s<-r$simple;crit<-qnorm(.975)
 data.table(analysis=label,ATT=s$overall.att,se=s$overall.se,lower=s$overall.att-crit*s$overall.se,upper=s$overall.att+crit*s$overall.se,
            p=2*pnorm(-abs(s$overall.att/s$overall.se)),n=r$n,states=r$states)}
# Sun-Abraham interaction-weighted estimator (fixest), unweighted, state and year fixed effects, clustered by state.
sunab_att<-function(d,y,label){
 d<-d[!is.na(get(y))];d[,cohort:=fifelse(g>0,g,10000L)]
 m<-feols(as.formula(paste(y,"~ sunab(cohort, year) + age + female + nonwhite + hs_or_less | state + year")),data=d,cluster=~state)
 a<-aggregate(m,agg="att");b<-a[1,1];se<-a[1,2]
 data.table(analysis=label,ATT=b,se=se,lower=b-1.96*se,upper=b+1.96*se,p=2*pnorm(-abs(b/se)),n=nobs(m),states=uniqueN(d$state))}
tidy_es<-function(r,label)data.table(analysis=label,event_time=r$es$egt,ATT=r$es$att.egt,se=r$es$se.egt)
# Event-study covariance clustered by state: influence functions summed within state before the outer product.
cl_vcov<-function(r){inf<-r$es$inf.function$dynamic.inf.func.e;cl<-r$m$DIDparams$cluster_vector
 stopifnot(length(cl)==nrow(inf));S<-rowsum(inf,cl);crossprod(S)/nrow(inf)^2}
honest<-function(r,label){
 es<-r$es;e<-es$egt;keep<-e>=-3 & e<=5 & e!=-1
 V<-cl_vcov(r)
 b<-es$att.egt[keep];V<-V[keep,keep];npre<-sum(e[keep]<0);npost<-sum(e[keep]>=0)
 l<-rep(1/npost,npost)   # average of post-period effects
 orig<-HonestDiD::constructOriginalCS(betahat=b,sigma=V,numPrePeriods=npre,numPostPeriods=npost,l_vec=l)
 rm<-HonestDiD::createSensitivityResults_relativeMagnitudes(betahat=b,sigma=V,numPrePeriods=npre,numPostPeriods=npost,Mbarvec=c(0.5,1,2),l_vec=l)
 o<-as.data.table(orig);x<-as.data.table(rm)
 rbind(data.table(analysis=label,Mbar=0,lb=o[["lb"]],ub=o[["ub"]]),data.table(analysis=label,Mbar=x[["Mbar"]],lb=x[["lb"]],ub=x[["ub"]]))
}
# Wald test of the pre-period event-study coefficients (event times -3 and -2), state-clustered covariance.
pretest<-function(r,label){es<-r$es;e<-es$egt;k<-e %in% c(-3,-2)
 V<-cl_vcov(r);b<-es$att.egt[k];W<-as.numeric(t(b)%*%solve(V[k,k],b))
 data.table(analysis=label,pre_wald=W,df=sum(k),p=pchisq(W,sum(k),lower.tail=FALSE))}

samples<-function(d){list(
 primary=window(d[stroke==1 & age %between% c(18,64) & low_income_138==1]),
 older=window(d[stroke==1 & age>=65 & low_income_138==1]),
 higher_income=window(d[stroke==1 & age %between% c(18,64) & high_income_400==1]))}

if(mode=="covariates"){
 # Composition checks: covariates and stroke prevalence as outcomes; no study outcome is read.
 base<-window(a[age %between% c(18,64) & low_income_138==1]);base[,stroke_prev:=stroke]
 cs<-window(a[stroke==1 & age %between% c(18,64) & low_income_138==1])
 res<-list();es<-list()
 for(spec in list(list(d=base,y="stroke_prev",lab="Stroke prevalence, low-income 18-64",xf=~age+female+nonwhite+hs_or_less),
                  list(d=cs,y="female",lab="Female, low-income survivors 18-64",xf=~age),list(d=cs,y="college",lab="College graduate, low-income survivors 18-64",xf=~age),
                  list(d=cs,y="age",lab="Age, low-income survivors 18-64",xf=~female))){
  r<-est(spec$d,spec$y,xf=spec$xf);res[[spec$lab]]<-tidy_simple(r,spec$lab);es[[spec$lab]]<-tidy_es(r,spec$lab)
 }
 fwrite(rbindlist(res),file.path(OUT,"covariate_att.csv"));fwrite(rbindlist(es),file.path(OUT,"covariate_event_study.csv"))
 print(rbindlist(res));quit(save="no")
}

run<-function(rep){
 d<-copy(a)
 if(mode=="real") d<-outcomes_real(d) else {d<-window(d,2025);d[,g:=first_treat_year];d<-simulate(d,if(mode %in% c("synthetic","smoke"))-0.05 else 0,20261116L+rep)}
 S<-samples(d);out<-list()
 # Primary-sample outcomes of replicate 1 are saved for the independent Python check (git-ignored data folder).
 if(rep==1L) fwrite(S$primary[,.(row_id,year,state,g,wt,uninsured,cost_barrier)],file.path(PROC,paste0("validation_did_",mode,".csv")))
 r3<-est(S$primary,"uninsured",biters=if(rep==1L)999 else 199);out$H3<-tidy_simple(r3,"H3 uninsured")
 r4<-est(S$primary,"cost_barrier",biters=if(rep==1L)999 else 199);out$H4<-tidy_simple(r4,"H4 cost barrier")
 o<-rbindlist(out)[,replicate:=rep]
 o[,decision:=c(fifelse(p[1]<0.05,"H3 rejected","H3 not rejected"),fifelse(p[1]<0.05,fifelse(p[2]<0.05,"H4 rejected","H4 not rejected"),"H4 not tested (gate)"))]
 if(rep==1L){
  ex<-list();es<-list();hd<-list();pt<-list()
  for(nm in c("H3 uninsured","H4 cost barrier")){r<-if(nm=="H3 uninsured")r3 else r4;es[[nm]]<-tidy_es(r,nm);hd[[nm]]<-honest(r,nm);pt[[nm]]<-pretest(r,nm)}
  for(y in c("uninsured","cost_barrier")){
   ex[[paste("older",y)]]<-tidy_simple(est(S$older,y),paste("Falsification: survivors 65+,",y))
   ex[[paste("hi",y)]]<-tidy_simple(est(S$higher_income,y),paste("Falsification: survivors >400% FPL,",y))
   ex[[paste("nwi",y)]]<-tidy_simple(est(S$primary[state_abbr!="WI"],y),paste("Sensitivity: drop Wisconsin,",y))
   ex[[paste("nev",y)]]<-tidy_simple(est(S$primary,y,cg="nevertreated"),paste("Sensitivity: never-treated controls,",y))
   ex[[paste("sw",y)]]<-tidy_simple(est(S$primary,y,weights="survey"),paste("Sensitivity: survey weights,",y))
   ex[[paste("eq",y)]]<-tidy_simple(est(S$primary,y,weights="state"),paste("Sensitivity: equal weight per state,",y))
   ex[[paste("dr",y)]]<-tidy_simple(est(S$primary,y,method="dr"),paste("Sensitivity: doubly robust estimator,",y))
   ex[[paste("sa",y)]]<-sunab_att(S$primary,y,paste("Sensitivity: Sun-Abraham estimator,",y))
   ex[[paste("u25",y)]]<-tidy_simple(est(window(d[stroke==1 & age %between% c(18,64) & under25k==1]),y),paste("Sensitivity: income < $25,000,",y))
   ex[[paste("hs",y)]]<-tidy_simple(est(window(d[stroke==1 & age %between% c(18,64) & educ %in% c("Less than high school","High school")]),y,xf=~age+female+nonwhite),paste("Sensitivity: high school or less,",y))
   ex[[paste("obshh",y)]]<-tidy_simple(est(window(d[stroke==1 & age %between% c(18,64) & low_income_138_observed_hh %in% 1]),y),paste("Sensitivity: observed household size only,",y))
  }
  for(y in c("no_checkup","no_clinician"))ex[[y]]<-tidy_simple(est(S$primary,y),paste("Exploratory:",y))
  # Triple difference (exploratory): survivors' ATT minus the ATT among low-income adults 18-64 without stroke.
  nost<-window(d[stroke==0 & age %between% c(18,64) & low_income_138==1])
  for(y in c("uninsured","cost_barrier")){
   rs<-if(y=="uninsured")out$H3 else out$H4;rn<-tidy_simple(est(nost,y,biters=199),paste("Exploratory: adults without stroke,",y))
   dd<-rs$ATT-rn$ATT;sd<-sqrt(rs$se^2+rn$se^2)
   ex[[paste("nost",y)]]<-rn
   ex[[paste("ddd",y)]]<-data.table(analysis=paste("Exploratory: triple difference (survivors minus no stroke),",y),ATT=dd,se=sd,lower=dd-1.96*sd,upper=dd+1.96*sd,p=2*pnorm(-abs(dd/sd)),n=rs$n+rn$n,states=rs$states)
  }
  full<-d[stroke==1 & age %between% c(18,64) & low_income_138==1];full[,g:=first_treat_year];full[,id:=.I]
  for(y in c("uninsured","cost_barrier"))ex[[paste("full",y)]]<-tidy_simple(est(full,y),paste("Exploratory: 2011-2025, all cohorts,",y))
  fwrite(rbindlist(ex),file.path(OUT,"secondary.csv"));fwrite(rbindlist(es),file.path(OUT,"event_study.csv"))
  fwrite(rbindlist(hd),file.path(OUT,"honestdid.csv"));fwrite(rbindlist(pt),file.path(OUT,"pretrend_tests.csv"))
 }
 o
}
runs<-rbindlist(lapply(seq_len(R),function(r){x<-run(r);cat("replicate",r,format(Sys.time(),"%H:%M:%S"),"\n");flush.console();x}))
fwrite(runs,file.path(OUT,"confirmatory_runs.csv"))
if(mode %in% c("synthetic","null","smoke")){
 truth<-if(mode %in% c("synthetic","smoke"))-0.05 else 0
 sm<-runs[,.(replicates=.N,mean_ATT=mean(ATT),coverage_95=mean(lower<=truth & upper>=truth),rejection_rate=mean(p<0.05)),by=analysis][,true_ATT:=truth]
 fwrite(sm,file.path(OUT,"simulation_summary.csv"));print(sm)
} else print(runs)
writeLines(capture.output(sessionInfo()),file.path(OUT,"R_session_info.txt"))
