# MEPS 2019-2024: build the pooled analytic file for the registered replication.
# Outcome firewall: exposures and covariates go to data/processed/meps/meps_analytic.rds; every outcome
# (cost-barrier items, the dental-barrier negative control, drug-class fills, out-of-pocket spending)
# goes to data/processed/meps/meps_outcomes_SEALED.rds, which only meps_analysis.R in "real" mode reads,
# and only after the registration tag has been pushed. This script prints no outcome values.
# Run from the project root after scripts/acquire_meps_brfss.py.
suppressPackageStartupMessages({library(data.table);library(haven)})
RAW<-"data/raw_meps/extracted";PROC<-"data/processed/meps";OUT<-"outputs/meps"
dir.create(PROC,recursive=TRUE,showWarnings=FALSE);dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
FYC<-c("2019"="h216","2020"="h224","2021"="h233","2022"="h243","2023"="h251","2024"="h256")
PMED<-c("2019"="h213a","2020"="h220a","2021"="h229a","2022"="h239a","2023"="h248a","2024"="h254a")
MON<-c("JA","FE","MA","AP","MY","JU","JL","AU","SE","OC","NO","DE")
NYEARS<-length(FYC)
num<-function(x)as.numeric(zap_labels(x))

# ---------------------------------------------------------------- drug classes (generic names; Multum codes cross-checked below)
CLASS<-list(
 ldl="ATORVASTATIN|ROSUVASTATIN|SIMVASTATIN|PRAVASTATIN|LOVASTATIN|FLUVASTATIN|PITAVASTATIN|EZETIMIBE|EVOLOCUMAB|ALIROCUMAB|INCLISIRAN|BEMPEDOIC",
 statin="ATORVASTATIN|ROSUVASTATIN|SIMVASTATIN|PRAVASTATIN|LOVASTATIN|FLUVASTATIN|PITAVASTATIN",
 anticoag="WARFARIN|APIXABAN|RIVAROXABAN|DABIGATRAN|EDOXABAN",
 antiplatelet="CLOPIDOGREL|PRASUGREL|TICAGRELOR|DIPYRIDAMOLE|CILOSTAZOL|TICLOPIDINE",
 antihtn=paste0("PRIL\\b|PRIL;|SARTAN|AMLODIPINE|NIFEDIPINE|FELODIPINE|ISRADIPINE|NICARDIPINE|NISOLDIPINE|DILTIAZEM|VERAPAMIL|",
   "HYDROCHLOROTHIAZIDE|CHLORTHALIDONE|CHLOROTHIAZIDE|INDAPAMIDE|METOLAZONE|OLOL\\b|OLOL;|CARVEDILOL|LABETALOL|NEBIVOLOL|",
   "SPIRONOLACTONE|EPLERENONE|HYDRALAZINE|CLONIDINE|MINOXIDIL|DOXAZOSIN|TERAZOSIN|PRAZOSIN|METHYLDOPA|ALISKIREN|SACUBITRIL|GUANFACINE"))
classify<-function(name){n<-toupper(name);setDT(lapply(CLASS,function(p)as.integer(grepl(p,n))))}

# ---------------------------------------------------------------- prescribed medicines: class validation (whole file) and person-level fills (sealed)
fills<-list();valid<-list()
for(y in names(PMED)){
 yy<-substr(y,3,4)
 p<-as.data.table(read_dta(file.path(RAW,paste0(PMED[[y]],".dta")),col_select=c("DUPERSID","RXDRGNAM","TC1","TC1S1","TC1S1_1","TC2","TC2S1","TC2S1_1","TC3","TC3S1","TC3S1_1",paste0("RXSF",yy,"X"),paste0("RXXP",yy,"X"),"RXDAYSUP")))
 setnames(p,c(paste0("RXSF",yy,"X"),paste0("RXXP",yy,"X")),c("rxsf","rxxp"))
 p[,(names(CLASS)):=classify(RXDRGNAM)]
 codes<-p[,.(TC1S1_1=num(TC1S1_1),TC2S1_1=num(TC2S1_1),TC3S1_1=num(TC3S1_1),TC1S1=num(TC1S1),TC2S1=num(TC2S1),TC3S1=num(TC3S1),TC1=num(TC1),TC2=num(TC2),TC3=num(TC3))]
 # Multum cross-check: statins 173; ezetimibe 316; PCSK9 484; warfarin-type 262; factor Xa 285; platelet aggregation inhibitors 211.
 has<-function(v)Reduce(`|`,lapply(codes,function(col)col %in% v))
 p[,`:=`(code_ldl=as.integer(has(c(173,316,484))),code_anticoag=as.integer(has(c(262,285))),code_antiplatelet=as.integer(has(211)),
   code_antihtn=as.integer(has(c(42,44,47,48,49,55,56,340,482))))]
 valid[[y]]<-rbindlist(lapply(c("ldl","anticoag","antiplatelet","antihtn"),function(k)
   data.table(year=as.integer(y),class=k,records=nrow(p),by_name=sum(p[[k]]),by_code=sum(p[[paste0("code_",k)]]),both=sum(p[[k]]==1 & p[[paste0("code_",k)]]==1))))
 p[,rxsf:=fifelse(num(rxsf)<0,NA_real_,num(rxsf))];p[,days:=fifelse(num(RXDAYSUP)<0,NA_real_,num(RXDAYSUP))]
 fills[[y]]<-p[,.(n_ldl=sum(ldl),n_statin=sum(statin),n_anticoag=sum(anticoag),n_antiplatelet=sum(antiplatelet),n_antihtn=sum(antihtn),
   oop_ldl=sum(rxsf*ldl,na.rm=TRUE),oop_anticoag=sum(rxsf*anticoag,na.rm=TRUE),oop_antiplatelet=sum(rxsf*antiplatelet,na.rm=TRUE),oop_antihtn=sum(rxsf*antihtn,na.rm=TRUE),
   days_ldl=sum(days*ldl,na.rm=TRUE),days_ldl_missing=sum(ldl==1 & is.na(days))),by=DUPERSID][,year:=as.integer(y)]
 cat("PMED",y,nrow(p),"records\n");rm(p);gc(verbose=FALSE)
}
valid<-rbindlist(valid);valid[,`:=`(agreement_of_name_matches=both/by_name,code_matches_found_by_name=both/by_code)]
fwrite(valid,file.path(OUT,"drug_class_validation.csv"))
fills<-rbindlist(fills)

# ---------------------------------------------------------------- full-year consolidated files
yn<-function(x){x<-num(x);fifelse(x==1,1,fifelse(x==2,0,NA_real_))}
persons<-list();outcomes<-list();presence<-list()
for(y in names(FYC)){
 yy<-substr(y,3,4);f<-file.path(RAW,paste0(FYC[[y]],".dta"))
 have<-names(read_dta(f,n_max=0))
 cov<-c(t(outer(c("PRI","MCR","MCD","GVA","GVB","GVC","VAP","IHS"),MON,function(a,m)paste0(a,m,yy))),paste0("TRI",MON,yy,"X"))
 base<-c("DUPERSID","DUID","PANEL","FAMIDYR","VARSTR","VARPSU",paste0("PERWT",yy,"F"),"AGE42X",paste0("AGE",yy,"X"),"SEX","RACETHX",paste0("REGION",yy),"HIDEG",
  paste0("POVCAT",yy),paste0("POVLEV",yy),paste0("FAMINC",yy),"HIBPDX","DIABDX_M18","CHDDX","MIDX","ANGIDX","STRKDX","CHOLDX","RTHLTH42","RTHLTH31","OFTSMK53",
  "ACTLIM31","WLKLIM31","COGLIM31","ADLHLP31","IADLHP31","ACTLIM53","WLKLIM53","COGLIM53","ADLHLP53","IADLHP53","ACCELI42","MCRPHO31","MCRPHO42",paste0("MCRPHO",yy),paste0("INSCOV",yy))
 sealed<-c("DLAYCA42","AFRDCA42","DLAYPM42","AFRDPM42","AFRDDN42",paste0("TOTSLF",yy),paste0("RXSLF",yy))
 need<-c(base,cov,sealed)
 presence[[y]]<-data.table(year=as.integer(y),variable=need,present=need %in% have)
 d<-as.data.table(read_dta(f,col_select=all_of(intersect(need,have))))
 for(v in setdiff(names(d),c("DUPERSID","DUID","FAMIDYR")))set(d,j=v,value=num(d[[v]]))
 setnames(d,paste0("MCRPHO",yy),"MCRPHO_R53")
 setnames(d,c(paste0("PERWT",yy,"F"),paste0("AGE",yy,"X"),paste0("REGION",yy),paste0("POVCAT",yy),paste0("POVLEV",yy),paste0("FAMINC",yy),paste0("INSCOV",yy)),
  c("perwt","age_eoy","region","povcat","povlev","faminc","inscov"))
 d[,year:=as.integer(y)]
 # Disability: round 3/1 items, falling back to round 5/3 where round 3/1 was not asked (mainly 2020).
 for(v in c("ACTLIM","WLKLIM","COGLIM","ADLHLP","IADLHP")){
  r31<-if(paste0(v,"31") %in% names(d)) d[[paste0(v,"31")]] else rep(NA_real_,nrow(d))
  r53<-if(paste0(v,"53") %in% names(d)) d[[paste0(v,"53")]] else rep(NA_real_,nrow(d))
  set(d,j=paste0(v,"_X"),value=fifelse(r31 %in% 1:2,r31,fifelse(r53 %in% 1:2,r53,NA_real_)))
 }
 # Monthly coverage category (NCHS-style hierarchies); MA status from the round covering the month (R3/1 Jan-Apr, R4/2 May-Aug,
 # and MCRPHOyy = R5/3 through Dec 31 for Sep-Dec; approximate).
 age_mid<-fifelse(d$AGE42X>=0,d$AGE42X,d$age_eoy)
 catm<-function(m){
  g<-function(a)d[[paste0(a,m,yy)]]==1
  tri<-d[[paste0("TRI",m,yy,"X")]]==1
  inscope<-d[[paste0("PRI",m,yy)]] %in% c(1,2)
  pri<-g("PRI");mcr<-g("MCR");mcd<-g("MCD");gv<-g("GVA")|g("GVB")|g("GVC");mil<-tri|g("VAP")
  ma<-switch(as.character(ceiling(match(m,MON)/4)),"1"=d$MCRPHO31,"2"=d$MCRPHO42,"3"=d$MCRPHO_R53)==1
  u65<-fcase(!inscope,NA_character_,pri,"Private",mcd|gv,"Medicaid and other public",mcr|mil,"Other coverage",default="Uninsured")
  o65<-fcase(!inscope,NA_character_,pri,"Private",mcr & mcd,"Dual eligible",mcr & !(gv|mil) & ma,"Medicare Advantage",mcr & !(gv|mil),"Medicare only excluding Medicare Advantage",
             mcd|gv|mil|mcr,"Other coverage",default="Uninsured")
  fifelse(age_mid<65,u65,o65)
 }
 months<-sapply(MON,catm)
 d[,coverage:=months[,"JU"]]
 d[,coverage_stable:=fifelse(apply(months,1,function(r)all(!is.na(r)) && length(unique(r))==1),months[,"JU"],NA_character_)]
 d[,coverage_any_medicaid_type:=as.integer(apply(months,1,function(r)any(r %in% c("Medicaid and other public","Dual eligible"))))]
 d[,`:=`(age=fifelse(age_mid>=0,age_mid,NA_real_))]
 d[,age_group:=factor(fifelse(age<65,"18-64","65+"),levels=c("18-64","65+"))]
 d[,`:=`(adult=!is.na(age) & age>=18,stroke=STRKDX==1,high_chol=CHOLDX==1,eligible=ACCELI42==1,
  sex=factor(fifelse(SEX %in% 1:2,SEX,NA_real_),labels=c("Male","Female")),
  race=factor(fcase(RACETHX==1,"Hispanic",RACETHX==2,"NH White",RACETHX==3,"NH Black",RACETHX==4,"NH Asian",RACETHX==5,"NH Other or multiple"),levels=c("NH White","Hispanic","NH Black","NH Asian","NH Other or multiple")),
  region=factor(fifelse(region %in% 1:4,region,NA_real_),labels=c("Northeast","Midwest","South","West")),
  education=factor(fcase(HIDEG==1,"Less than high school",HIDEG %in% 2:3,"High school or GED",HIDEG==7,"Other degree",HIDEG %in% 4:6,"Bachelor or higher"),levels=c("Bachelor or higher","Other degree","High school or GED","Less than high school")),
  income=factor(fcase(povcat==1,"Poor (<100% FPL)",povcat==2,"Near poor (100-124%)",povcat==3,"Low (125-199%)",povcat==4,"Middle (200-399%)",povcat==5,"High (>=400%)"),
                levels=c("High (>=400%)","Middle (200-399%)","Low (125-199%)","Near poor (100-124%)","Poor (<100% FPL)")),
  hypertension=yn(HIBPDX),diabetes=yn(DIABDX_M18),coronary=fifelse(CHDDX==1|MIDX==1|ANGIDX==1,1,fifelse(CHDDX==2 & MIDX==2 & ANGIDX==2,0,NA_real_)),
  smoking=fifelse(OFTSMK53 %in% 1:2,1,fifelse(OFTSMK53 %in% c(3,-1),0,NA_real_)),
  fairpoor=fifelse(fifelse(RTHLTH42>0,RTHLTH42,RTHLTH31) %in% 4:5,1,fifelse(fifelse(RTHLTH42>0,RTHLTH42,RTHLTH31) %in% 1:3,0,NA_real_)),
  disability=fifelse(ACTLIM_X %in% 1|WLKLIM_X %in% 1|COGLIM_X %in% 1|ADLHLP_X %in% 1|IADLHP_X %in% 1,1,
             fifelse(ACTLIM_X %in% 2 & WLKLIM_X %in% 2 & COGLIM_X %in% 2 & ADLHLP_X %in% 2 & IADLHP_X %in% 2,0,NA_real_)))]
 d[,medicaid_type:=fcase(coverage %in% c("Medicaid and other public","Dual eligible"),1,coverage=="Private",0,default=NA_real_)]
 d[,`:=`(wt=perwt/NYEARS,stratum=paste(year,VARSTR,sep="_"),psu=paste(year,VARSTR,VARPSU,sep="_"))]
 keep<-c("DUPERSID","DUID","FAMIDYR","PANEL","year","wt","perwt","stratum","psu","age","age_group","adult","stroke","high_chol","eligible","sex","race","region","education","income","povlev","faminc",
         "hypertension","diabetes","coronary","smoking","fairpoor","disability","coverage","coverage_stable","coverage_any_medicaid_type","medicaid_type","inscov")
 persons[[y]]<-d[,..keep]
 o<-d[,c("DUPERSID","year","DUID","FAMIDYR",intersect(sealed,names(d))),with=FALSE]
 setnames(o,c(paste0("TOTSLF",yy),paste0("RXSLF",yy)),c("totslf","rxslf"),skip_absent=TRUE)
 outcomes[[y]]<-o
 cat("FYC",y,nrow(d),"persons\n")
}
presence<-rbindlist(presence);fwrite(presence,file.path(OUT,"variable_presence.csv"))
missing_vars<-presence[present==FALSE]
persons<-rbindlist(persons,fill=TRUE)
nonout<-c("age","sex","race","region","education","income","hypertension","diabetes","coronary","smoking","fairpoor","disability")
persons[,complete:=complete.cases(.SD),.SDcols=nonout]
persons<-persons[wt>0]

# ---------------------------------------------------------------- sealed outcome file (not summarized here)
o<-rbindlist(outcomes,fill=TRUE)
o[,`:=`(dlayca=yn(DLAYCA42),afrdca=yn(AFRDCA42),dlaypm=yn(DLAYPM42),afrdpm=yn(AFRDPM42),dental_barrier=yn(AFRDDN42))]
o[,any_barrier:=fifelse(dlayca %in% 1 | afrdca %in% 1 | dlaypm %in% 1 | afrdpm %in% 1,1,fifelse(dlayca %in% 0 & afrdca %in% 0 & dlaypm %in% 0 & afrdpm %in% 0,0,NA_real_))]
o[,care_barrier:=fifelse(dlayca %in% 1 | afrdca %in% 1,1,fifelse(dlayca %in% 0 & afrdca %in% 0,0,NA_real_))]
o[,rx_barrier:=fifelse(dlaypm %in% 1 | afrdpm %in% 1,1,fifelse(dlaypm %in% 0 & afrdpm %in% 0,0,NA_real_))]
o<-merge(o,fills,by=c("DUPERSID","year"),all.x=TRUE)
for(v in setdiff(names(fills),c("DUPERSID","year")))set(o,i=which(is.na(o[[v]])),j=v,value=0)
o[,`:=`(no_ldl_fill=as.integer(n_ldl==0),any_anticoag=as.integer(n_anticoag>0),any_antiplatelet=as.integer(n_antiplatelet>0),any_antihtn=as.integer(n_antihtn>0))]
# Family out-of-pocket burden (exploratory): sum of members' self/family payments relative to family income.
o[,totslf:=fifelse(totslf<0,NA_real_,totslf)]
fam<-o[,.(family_oop=sum(totslf,na.rm=TRUE)),by=.(year,DUID,FAMIDYR)]
o<-merge(o,fam,by=c("year","DUID","FAMIDYR"),all.x=TRUE)
o<-merge(o,persons[,.(DUPERSID,year,faminc)],by=c("DUPERSID","year"),all.x=TRUE)
o[,`:=`(oop_burden10=fifelse(faminc>0,as.integer(family_oop>0.10*faminc),fifelse(faminc<=0 & family_oop>0,1L,NA_integer_)),
        oop_burden20=fifelse(faminc>0,as.integer(family_oop>0.20*faminc),fifelse(faminc<=0 & family_oop>0,1L,NA_integer_)))]
o[,faminc:=NULL]
saveRDS(o[,.(DUPERSID,year,any_barrier,care_barrier,rx_barrier,dental_barrier,no_ldl_fill,n_ldl,n_statin,any_anticoag,any_antiplatelet,any_antihtn,n_anticoag,n_antiplatelet,n_antihtn,
             oop_ldl,oop_anticoag,oop_antiplatelet,oop_antihtn,days_ldl,days_ldl_missing,totslf,rxslf,family_oop,oop_burden10,oop_burden20)],
        file.path(PROC,"meps_outcomes_SEALED.rds"))
saveRDS(persons,file.path(PROC,"meps_analytic.rds"))

# ---------------------------------------------------------------- outcome-blind counts (exposures and sample only)
s<-persons[adult & stroke & eligible]
counts<-rbind(
 s[,.(n=.N,complete=sum(complete)),by=.(year)][,group:="year"][,level:=as.character(year)][,.(group,level,n,complete)],
 s[,.(n=.N,complete=sum(complete)),by=.(age_group,coverage)][,.(group=paste("coverage",age_group),level=coverage,n,complete)],
 s[,.(n=.N,complete=sum(complete)),by=.(medicaid_type,age_group)][,.(group=paste("H1 exposure",age_group),level=as.character(medicaid_type),n,complete)],
 s[high_chol==TRUE,.(n=.N,complete=sum(complete)),by=.(age_group)][,.(group="H2 domain (high cholesterol)",level=as.character(age_group),n,complete)])
fwrite(counts,file.path(OUT,"sample_counts.csv"))
reps<-s[,.N,by=DUPERSID][,.N,by=.(appearances=N)][order(appearances)]
fwrite(reps,file.path(OUT,"repeat_appearances.csv"))
cat("\nStroke survivors (adult, access-eligible, positive weight): person-years",nrow(s)," unique persons",uniqueN(s$DUPERSID),"\n")
print(counts);print(reps);if(nrow(missing_vars)) print(missing_vars[,.N,by=.(year)])
print(valid)
