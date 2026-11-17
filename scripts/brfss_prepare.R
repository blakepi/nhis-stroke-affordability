# BRFSS 2011-2025: build compact analysis files for the registered difference-in-differences and
# regression discontinuity analyses. Each annual file is extracted alone, read for the needed columns,
# and deleted, so disk use stays near one extracted file (about 1.3 GB).
# Outcome firewall: insurance, cost-barrier, checkup, personal-clinician and primary-insurance items go to
# data/processed/brfss/brfss_outcomes_SEALED.rds and are not summarized here.
# Run from the project root after scripts/acquire_meps_brfss.py.
suppressPackageStartupMessages({library(data.table);library(haven)})
RAW<-"data/raw_brfss";TMP<-file.path(RAW,"tmp");PROC<-"data/processed/brfss";OUT<-"outputs/brfss"
dir.create(PROC,recursive=TRUE,showWarnings=FALSE);dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
num<-function(x)as.numeric(zap_labels(x))
pov<-fread(file.path(OUT,"hhs_poverty_guidelines.csv"))
exp_dates<-fread(file.path(OUT,"expansion_dates.csv"))
CAND<-list(design=c("_STATE","_STSTR","_PSU","_LLCPWT","IYEAR"),
 stroke="CVDSTRK3",age=c("_AGE80","AGE","_AGEG5YR","_AGE65YR"),sex=c("SEX","SEX1","SEXVAR","_SEX"),race=c("_IMPRACE","_RACEGR3","_RACEGR4","_RACE"),
 educ="EDUCA",income=c("INCOME2","INCOME3"),hh=c("NUMADULT","HHADULT","CHILDREN"),other=c("EMPLOY1","MARITAL"),
 sealed=c("HLTHPLN1","_HLTHPLN","_HLTHPL1","_HLTHPL2","PRIMINSR","PRIMINS1","PRIMINS2","MEDCOST","MEDCOST1","CHECKUP1","PERSDOC2","PERSDOC3","_HCVU651","_HCVU652","_HCVU653","_HCVU654"))
MID2<-c(5000,12500,17500,22500,30000,42500,62500,100000)                       # INCOME2 1-8 (8 = $75,000 or more)
MID3<-c(5000,12500,17500,22500,30000,42500,62500,87500,125000,175000,250000)   # INCOME3 1-11
LO2<-c(0,10000,15000,20000,25000,35000,50000,75000);HI2<-c(10000,15000,20000,25000,35000,50000,75000,Inf)
LO3<-c(LO2[1:7],75000,100000,150000,200000);HI3<-c(HI2[1:7],100000,150000,200000,Inf)
analytic<-list();sealed<-list();presence<-list()
for(y in 2011:2025){
 z<-file.path(RAW,sprintf("LLCP%dXPT.zip",y));dir.create(TMP,showWarnings=FALSE)
 member<-unzip(z,list=TRUE)$Name;member<-member[grepl("xpt",member,ignore.case=TRUE)][1]
 unzip(z,files=member,exdir=TMP);f<-file.path(TMP,member)
 have<-names(read_xpt(f,n_max=0))
 want<-unlist(CAND);use<-intersect(want,have)
 presence[[as.character(y)]]<-data.table(year=y,variable=want,present=want %in% have)
 d<-as.data.table(read_xpt(f,col_select=all_of(use)))
 unlink(f);unlink(TMP,recursive=TRUE)
 for(v in names(d))set(d,j=v,value=num(d[[v]]))
 g<-function(v)if(v %in% names(d)) d[[v]] else rep(NA_real_,nrow(d))
 first<-function(vs){for(v in vs)if(v %in% names(d))return(d[[v]]);rep(NA_real_,nrow(d))}
 a<-data.table(row_id=paste0(y,"_",seq_len(nrow(d))),year=y,state=g("_STATE"),ststr=g("_STSTR"),psu=g("_PSU"),wt=g("_LLCPWT"))
 age80<-g("_AGE80");age_raw<-g("AGE")
 a[,age:=fifelse(!is.na(age80),age80,fifelse(age_raw %in% 18:99,pmin(age_raw,80),NA_real_))]
 ag5<-g("_AGEG5YR");a[,age5:=fifelse(ag5 %in% 1:13,ag5,NA_real_)]
 sx<-first(c("SEXVAR","SEX1","SEX","_SEX"));a[,sex:=fifelse(sx %in% 1:2,sx,NA_real_)]
 # Race and Hispanic origin, 4 groups: _IMPRACE (imputed; all years except 2015-16), else _RACEGR3 / _RACEGR4.
 ir<-g("_IMPRACE");rg<-first(c("_RACEGR3","_RACEGR4"))
 a[,race:=fcase(ir==1,1,ir==2,2,ir==5,3,ir %in% c(3,4,6),4,is.na(ir) & rg==1,1,is.na(ir) & rg==2,2,is.na(ir) & rg==5,3,is.na(ir) & rg %in% 3:4,4,default=NA_real_)]
 a[,race_source:=fifelse(!is.na(ir),"_IMPRACE",fifelse(!is.na(rg),"_RACEGR3/4",NA_character_))]
 ed<-g("EDUCA");a[,educ:=fcase(ed %in% 1:3,"Less than high school",ed==4,"High school",ed==5,"Some college",ed==6,"College graduate",default=NA_character_)]
 a[,stroke:=fcase(g("CVDSTRK3")==1,1,g("CVDSTRK3")==2,0,default=NA_real_)]
 inc<-first(c("INCOME3","INCOME2"));ninc<-if("INCOME3" %in% names(d)) 11 else 8
 a[,inc_cat:=fifelse(inc %in% seq_len(ninc),inc,NA_real_)]
 adults<-fifelse(g("NUMADULT") %in% 1:76,g("NUMADULT"),fifelse(g("HHADULT") %in% 1:76,g("HHADULT"),NA_real_))
 kids<-fifelse(g("CHILDREN")==88,0,fifelse(g("CHILDREN") %in% 0:87,g("CHILDREN"),NA_real_))
 # Household adults are missing for many cell-phone respondents in 2011-2013 and 2017; impute from marital status
 # (married or unmarried couple = 2 adults, otherwise 1) so the low-income definition does not change at 2014.
 mar<-g("MARITAL");adults_imp<-fifelse(!is.na(adults),adults,fifelse(mar %in% c(1,6),2,fifelse(mar %in% 2:5,1,NA_real_)))
 a[,`:=`(adults=adults,adults_imputed=as.integer(is.na(adults) & !is.na(adults_imp)),children=kids,marital=mar,
         hhsize=fifelse(is.na(adults_imp),NA_real_,adults_imp+fifelse(is.na(kids),0,kids)),
         hhsize_observed=fifelse(is.na(adults),NA_real_,adults+fifelse(is.na(kids),0,kids)))]
 # Poverty line for household size: area-specific HHS guideline (AK = 2, HI = 15).
 area<-fcase(a$state==2,"ak",a$state==15,"hi",default="us")
 pg<-pov[year==y];base<-pg$first_person[match(area,pg$area)];inc_add<-pg$each_additional[match(area,pg$area)]
 a[,poverty_line:=base+inc_add*pmax(hhsize-1,0)]
 mid<-if(ninc==11)MID3 else MID2;lo<-if(ninc==11)LO3 else LO2;hi<-if(ninc==11)HI3 else HI2
 a[,fpl_ratio:=mid[inc_cat]/poverty_line]
 a[,low_income_138:=as.integer(fpl_ratio<=1.38)]
 a[,low_income_138_observed_hh:=as.integer(mid[inc_cat]/(base+inc_add*pmax(hhsize_observed-1,0))<=1.38)]
 # Partial-membership sensitivity: share of the income interval at or below 138% of poverty (uniform within category).
 cut<-1.38*a$poverty_line
 a[,low_income_share:=fifelse(is.na(inc_cat)|is.na(cut),NA_real_,pmin(1,pmax(0,(cut-lo[inc_cat])/pmax(1,pmin(hi[inc_cat],lo[inc_cat]+100000)-lo[inc_cat]))))]
 a[,under25k:=as.integer(inc_cat<=4)]
 a[,high_income_400:=as.integer(fpl_ratio>4)]
 s<-data.table(row_id=a$row_id,year=y)
 for(v in CAND$sealed)set(s,j=v,value=g(v))
 analytic[[as.character(y)]]<-a;sealed[[as.character(y)]]<-s
 cat(y,nrow(a),"respondents; variables used:",length(use),"\n");flush.console()
}
a<-rbindlist(analytic);s<-rbindlist(sealed)
a<-merge(a,exp_dates[,.(state=state_fips,state_abbr=state,first_treat_year,status)],by="state",all.x=TRUE)
a<-a[!is.na(state_abbr)]   # drops territories (Guam, Puerto Rico, Virgin Islands)
presence<-rbindlist(presence);fwrite(presence[,.(present=any(present)),by=.(variable,year)][,dcast(.SD,variable~year,value.var="present")],file.path(OUT,"variable_presence.csv"))
saveRDS(a,file.path(PROC,"brfss_analytic.rds"));saveRDS(s,file.path(PROC,"brfss_outcomes_SEALED.rds"))
# Outcome-blind counts: sample sizes only.
did<-a[stroke==1 & age %between% c(18,64) & status!="excluded"]
cnt<-rbind(
 did[,.(n=.N),by=year][,.(sample="stroke 18-64, all incomes",year,n)],
 did[low_income_138==1,.(n=.N),by=year][,.(sample="stroke 18-64, <=138% FPL",year,n)],
 a[stroke==1 & age %between% c(55,75),.(n=.N),by=year][,.(sample="stroke 55-75 (RD)",year,n)])
fwrite(cnt[order(sample,year)],file.path(OUT,"sample_counts.csv"))
cat("\nLow-income stroke 18-64 by first-treatment cohort, 2011-2019:\n")
print(did[low_income_138==1 & year<=2019,.(n=.N,states=uniqueN(state)),by=first_treat_year][order(first_treat_year)])
cat("Missing income or household size among stroke 18-64:",did[,mean(is.na(fpl_ratio))],"\n")
print(dcast(cnt,year~sample,value.var="n"))
