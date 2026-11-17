# Figure input for the exploratory age-65 discontinuity (REGISTERED_ANALYSIS_PLAN.md, Section 5): unweighted means by
# single year of age (55-75) among BRFSS 2013-2025 stroke survivors, and the local linear fits on each side of 65 at
# the bandwidth chosen in scripts/brfss_rd.R. Descriptive; added after registration (DEVIATIONS.md, item 2). The fitted
# jump must equal the RDHonest estimate in outputs/brfss/rd_<mode>/confirmatory_runs.csv.
# Usage: Rscript scripts/brfss_rd_bins.R real
suppressPackageStartupMessages(library(data.table))
args<-commandArgs(trailingOnly=TRUE);mode<-if(length(args))args[1] else "real";stopifnot(mode=="real")
TAG<-"prereg-2026-11";PROC<-"data/processed/brfss";OUT<-"outputs/brfss/rd_real"
remote<-suppressWarnings(system2("git",c("ls-remote","--tags","origin",TAG),stdout=TRUE))
if(!length(remote) || !any(grepl(TAG,remote))) stop("Real outcomes are sealed until tag ",TAG," is pushed to the public remote.")
a<-readRDS(file.path(PROC,"brfss_analytic.rds"))
d<-a[stroke==1 & year>=2013 & age %between% c(55,75) & wt>0];d[,x:=age-65]
s<-readRDS(file.path(PROC,"brfss_outcomes_SEALED.rds"));d<-merge(d,s,by=c("row_id","year"),all.x=TRUE)
d[,uninsured:=fcase(HLTHPLN1==2,1,HLTHPLN1==1,0,`_HLTHPLN`==2,1,`_HLTHPLN`==1,0,`_HLTHPL1`==2,1,`_HLTHPL1`==1,0,`_HLTHPL2`==2,1,`_HLTHPL2`==1,0,default=NA_real_)]
d[,cost_barrier:=fcase(MEDCOST==1,1,MEDCOST==2,0,MEDCOST1==1,1,MEDCOST1==2,0,default=NA_real_)]
runs<-fread(file.path(OUT,"confirmatory_runs.csv"))
bins<-list();fits<-list()
for(y in c("uninsured","cost_barrier")){
 dy<-d[!is.na(get(y))]
 bins[[y]]<-dy[,.(outcome=y,n=.N,mean=mean(get(y))),by=age][,se:=sqrt(mean*(1-mean)/n)][order(age)]
 r<-runs[outcome==y];h<-r$h
 side<-function(sd){z<-dy[if(sd=="below") x<0 else x>=0][abs(x)<h];z[,k:=pmax(0,1-abs(x)/h)];z<-z[k>0]
  m<-lm(as.formula(paste(y,"~ x")),data=z,weights=k);ages<-sort(unique(z$age))
  list(fit=data.table(outcome=y,side=sd,age=ages,fitted=predict(m,newdata=data.frame(x=ages-65))),intercept=unname(coef(m)[1]))}
 lo<-side("below");hi<-side("above");jump<-hi$intercept-lo$intercept
 stopifnot(abs(jump-r$estimate)<1e-6)
 fits[[y]]<-rbind(lo$fit,hi$fit)[,`:=`(bandwidth=h,jump=jump)]
}
fwrite(rbindlist(bins),file.path(OUT,"binned_means.csv"));fwrite(rbindlist(fits),file.path(OUT,"local_linear_fits.csv"))
print(rbindlist(bins));print(unique(rbindlist(fits)[,.(outcome,bandwidth,jump)]))
