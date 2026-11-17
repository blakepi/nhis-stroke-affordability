# BRFSS regression discontinuity at age 65 among stroke survivors (H5, H6) and pre-specified checks.
# Usage: Rscript scripts/brfss_rd.R <mode> [replicates]
#   synthetic : outcomes simulated with a planted change of -3 percentage points at 65
#   null      : outcomes simulated with no change
#   covariates: continuity of covariates at 65 (outcome-blind)
#   real      : sealed outcomes; refused unless the registration tag is on the public remote
# EXPLORATORY (moved from confirmatory before registration): outcome-blind checks showed honest intervals of
# roughly +/-7-10 points even at the interval-minimizing bandwidth, and weighted covariates shift at 65,
# consistent with BRFSS raking by age bands. Reported: RDHonest local linear, triangular kernel, bandwidth
# chosen to minimize the honest CI (FLCI), M by rule of thumb, unweighted (main) and survey-weighted.
suppressPackageStartupMessages({library(data.table);library(RDHonest);library(fixest)})
args<-commandArgs(trailingOnly=TRUE);mode<-if(length(args))args[1] else "synthetic";R<-if(length(args)>1)as.integer(args[2]) else 1L
stopifnot(mode %in% c("synthetic","null","covariates","real"))
TAG<-"prereg-2026-11";PROC<-"data/processed/brfss";OUT<-file.path("outputs/brfss",paste0("rd_",mode))
if(mode=="real"){
 remote<-suppressWarnings(system2("git",c("ls-remote","--tags","origin",TAG),stdout=TRUE))
 if(!length(remote) || !any(grepl(TAG,remote))) stop("Real outcomes are sealed until tag ",TAG," is pushed to the public remote.")
}
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
a<-readRDS(file.path(PROC,"brfss_analytic.rds"))
d0<-a[stroke==1 & year>=2013 & age %between% c(55,75) & wt>0];d0[,x:=age-65]
d0[,`:=`(female=as.integer(sex==2),college=as.integer(educ %in% "College graduate"),black=as.integer(race==2),low_income=low_income_138)]
outcomes_real<-function(d){
 s<-readRDS(file.path(PROC,"brfss_outcomes_SEALED.rds"));d<-merge(d,s,by=c("row_id","year"),all.x=TRUE)
 d[,uninsured:=fcase(HLTHPLN1==2,1,HLTHPLN1==1,0,`_HLTHPLN`==2,1,`_HLTHPLN`==1,0,`_HLTHPL1`==2,1,`_HLTHPL1`==1,0,`_HLTHPL2`==2,1,`_HLTHPL2`==1,0,default=NA_real_)]
 d[,cost_barrier:=fcase(MEDCOST==1,1,MEDCOST==2,0,MEDCOST1==1,1,MEDCOST1==2,0,default=NA_real_)]
 # First stage uses PRIMINSR (2021-2022), whose codes are documented (3 Medicare, 4 Medigap); PRIMINS1/PRIMINS2 (2023+) are
 # added only if their codebooks confirm the same coding (recorded in DEVIATIONS.md if so).
 d[,medicare_primary:=fcase(PRIMINSR %in% c(3,4),1,PRIMINSR %in% c(1,2,5:10,88),0,default=NA_real_)]
 d
}
simulate<-function(d,jump,seed){
 set.seed(seed);n<-nrow(d);post<-as.numeric(d$x>=0)
 d[,uninsured:=rbinom(n,1,pmin(.95,pmax(.01,0.10-0.002*x+jump*post)))]
 d[,cost_barrier:=rbinom(n,1,pmin(.95,pmax(.01,0.20-0.004*x+jump*post)))]
 d[,medicare_primary:=fifelse(year %in% 2021:2022,rbinom(n,1,pmin(.95,pmax(.01,0.15+0.6*post))),NA_integer_)]
 d
}
rd<-function(d,y,h=NULL,M=NULL,label,weighted=FALSE){
 d<-d[!is.na(get(y))];if(!is.null(h))d<-d[abs(x)<=h]
 d[,w_use:=if(weighted) wt/mean(wt) else 1]
 f<-as.formula(paste(y,"~ x"));argl<-list(formula=f,data=d,weights=d$w_use,cutoff=0,kern="triangular")
 if(is.null(h))argl$opt.criterion<-"FLCI" else argl$h<-h
 if(!is.null(M))argl$M<-M
 r<-do.call(RDHonest,argl)
 co<-r$coefficients
 data.table(analysis=label,outcome=y,weighted=weighted,h=co$bandwidth,estimate=co$estimate,se=co$std.error,max_bias=co$maximum.bias,lower=co$conf.low,upper=co$conf.high,
            M=if(!is.null(co$M)) co$M else NA_real_,n=nrow(d),p_naive=2*pnorm(-abs(co$estimate/co$std.error)),excludes_zero=co$conf.low>0 | co$conf.high<0)
}
fe<-function(d,y,h=10,label){
 d<-d[!is.na(get(y)) & abs(x)<=h];d[,`:=`(post=as.numeric(x>=0),kw=wt*pmax(0,1-abs(x)/(h+1)))]
 m<-feols(as.formula(paste(y,"~ post + x + x:post | state + year")),data=d,weights=~kw,cluster=~state)
 b<-coef(m)["post"];se<-se(m)["post"]
 data.table(analysis=label,outcome=y,h=h,estimate=b,se=se,lower=b-1.96*se,upper=b+1.96*se,n=nobs(m))
}
if(mode=="covariates"){
 res<-rbindlist(lapply(c("female","college","black","low_income"),function(v)rd(d0,v,label=paste("Covariate continuity:",v))))
 fwrite(res,file.path(OUT,"covariate_continuity.csv"));print(res)
 cnt<-d0[,.N,by=age][order(age)];fwrite(cnt,file.path(OUT,"counts_by_age.csv"));print(cnt);quit(save="no")
}
run<-function(rep){
 d<-copy(d0);d<-if(mode=="real") outcomes_real(d) else simulate(d,if(mode=="synthetic")-0.03 else 0,20261116L+rep)
 h5<-rd(d,"uninsured",label="Exploratory RD: uninsured")
 h6<-rd(d,"cost_barrier",label="Exploratory RD: cost barrier")
 o<-rbind(h5,h6,fill=TRUE)[,replicate:=rep]
 if(rep==1L){
  ex<-list()
  for(y in c("uninsured","cost_barrier")){
   ex[[paste(y,"w")]]<-rd(d,y,weighted=TRUE,label="Survey-weighted")
   for(h in c(5,10))ex[[paste(y,h)]]<-rd(d,y,h=h,label="Fixed bandwidth")
   ex[[paste(y,"donut")]]<-rd(d[x!=0],y,label="Donut: age 65 excluded")
   ex[[paste(y,"M2")]]<-rd(d,y,M=2*h5$M,label="Smoothness bound doubled")
   ex[[paste(y,"p60")]]<-rd(copy(d[age<65])[,x:=age-60],y,label="Placebo cutoff 60 (ages 55-64)")
   ex[[paste(y,"p70")]]<-rd(copy(d[age>=65])[,x:=age-70],y,label="Placebo cutoff 70 (ages 65-75)")
   ex[[paste(y,"fe")]]<-fe(d,y,label="Fixed effects (state, year), clustered by state")
  }
  ex$fs<-rd(d[year %in% 2021:2022],"medicare_primary",label="First stage: Medicare as primary coverage (2021-2022)")
  fwrite(rbindlist(ex,fill=TRUE),file.path(OUT,"secondary.csv"))
 }
 o
}
runs<-rbindlist(lapply(seq_len(R),function(r){x<-run(r);if(r%%10==0)cat("replicate",r,"\n");x}),fill=TRUE)
fwrite(runs,file.path(OUT,"confirmatory_runs.csv"))
if(mode %in% c("synthetic","null")){
 truth<-if(mode=="synthetic")-0.03 else 0
 sm<-runs[,.(replicates=.N,mean_estimate=mean(estimate),coverage_95=mean(lower<=truth & upper>=truth),rejection_rate=mean(excludes_zero)),by=outcome][,true_change:=truth]
 fwrite(sm,file.path(OUT,"simulation_summary.csv"));print(sm)
} else print(runs)
writeLines(capture.output(sessionInfo()),file.path(OUT,"R_session_info.txt"))
