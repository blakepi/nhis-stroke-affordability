# Extended (exploratory) analyses: add coverage, medication, utilization, hardship,
# employment and urbanicity fields to the pooled and annual analysis files.
# See EXTENDED_ANALYSIS_PLAN.md. Run from the project root after prepare_full_data.R.
suppressPackageStartupMessages(library(data.table))
dir.create("data/processed/extended",showWarnings=FALSE,recursive=TRUE)
dir.create("outputs/extended",showWarnings=FALSE,recursive=TRUE)
base<-readRDS("data/processed/full/base.rds")
annual<-readRDS("data/processed/adults_selected.rds")
want<-c("PRDEDUC1_A","PRHDHP1_A","HYPMED_A","CHLEV_A","CHLMED_A","EMERG12MTC_A","HOSPONGT_A",
        "PAYBLL12M_A","PAYNOBLLNW_A","PAYWORRY_A","PRIVATE_A","HYPEV_A")
extra<-list();codes<-list()
for(y in 2019:2025){
 z<-sprintf("data/raw/%s/adult%scsv.zip",y,substr(y,3,4));member<-unzip(z,list=TRUE)$Name
 path<-file.path("data/processed/extracted",member[grepl("[.]csv$",member,ignore.case=TRUE)])
 hdr<-names(fread(path,nrows=0))
 emp<-if(y<2021)"EMPWRKLSWK_A" else "EMPWRKLSW1_A"; urb<-if(y<2024)"URBRRL" else "URBRRL23"
 stopifnot(all(c("HHX",want,emp,urb) %in% hdr))
 d<-fread(path,select=c("HHX",want,emp,urb));setnames(d,c(emp,urb),c("worked_raw","urban_raw"));d[,year:=y]
 # Guard against silent recoding between years.
 stopifnot(all(is.na(d$PRDEDUC1_A) | d$PRDEDUC1_A %in% c(1,2,7,8,9)),all(is.na(d$PRHDHP1_A) | d$PRHDHP1_A %in% c(1,2,7,8,9)),
  all(is.na(d$HYPMED_A) | d$HYPMED_A %in% c(1,2,7,8,9)),all(is.na(d$CHLMED_A) | d$CHLMED_A %in% c(1,2,7,8,9)),
  all(is.na(d$CHLEV_A) | d$CHLEV_A %in% c(1,2,7,8,9)),all(is.na(d$HOSPONGT_A) | d$HOSPONGT_A %in% c(1,2,7,8,9)),
  all(is.na(d$EMERG12MTC_A) | d$EMERG12MTC_A %in% c(0:4,7,8,9)),all(is.na(d$PAYBLL12M_A) | d$PAYBLL12M_A %in% c(1,2,7,8,9)),
  all(is.na(d$PAYNOBLLNW_A) | d$PAYNOBLLNW_A %in% c(1,2,7,8,9)),all(is.na(d$PAYWORRY_A) | d$PAYWORRY_A %in% c(1,2,3,7,8,9)),
  all(is.na(d$worked_raw) | d$worked_raw %in% c(1,2,7,8,9)),all(d$urban_raw %in% 1:4),!anyDuplicated(d$HHX))
 for(v in c(want,"worked_raw","urban_raw")){f<-d[,.N,by=c(v)];setnames(f,v,"raw_code");f[,`:=`(year=y,variable=v)];codes[[length(codes)+1L]]<-f}
 extra[[as.character(y)]]<-d
}
extra<-rbindlist(extra);fwrite(rbindlist(codes),"outputs/extended/raw_response_counts_extended.csv")
yn<-function(x) fifelse(x==1,1,fifelse(x==2,0,NA_real_))
derive<-function(d){
 # PRIVATE_A and HYPEV_A are already in the pooled file; add them only where absent (annual file).
 add<-c("year","HHX",setdiff(names(extra),names(d)))
 n0<-nrow(d);d<-merge(d,extra[,..add],by=c("year","HHX"),sort=FALSE,all.x=TRUE);stopifnot(nrow(d)==n0,!anyNA(d$urban_raw))
 # Domain composites: a positive settles the OR; a negative needs every applicable item known.
 d[,care_barrier:=fifelse(delayed_care %in% 1 | forgone_care %in% 1,1,fifelse(delayed_care %in% 0 & forgone_care %in% 0,0,NA_real_))]
 d[,rx_barrier:=fifelse(forgone_rx %in% 1 | rx_underuse %in% 1,1,
     fifelse(forgone_rx %in% 0 & (RX12M_A %in% 2 | rx_underuse %in% 0),0,NA_real_))]
 d[,cover_u65:=factor(fcase(age<65 & COVER_A==1,"Private",age<65 & COVER_A==2,"Medicaid and other public",
     age<65 & COVER_A==3,"Other coverage",age<65 & COVER_A==4,"Uninsured",default=NA_character_),
     levels=c("Private","Medicaid and other public","Other coverage","Uninsured"))]
 d[,cover_65all:=factor(fcase(age>=65 & COVER65_A==1,"Private",age>=65 & COVER65_A==2,"Dual eligible",
     age>=65 & COVER65_A==3,"Medicare Advantage",age>=65 & COVER65_A==4,"Medicare only excluding Medicare Advantage",
     age>=65 & COVER65_A==5,"Other coverage",age>=65 & COVER65_A==6,"Uninsured",default=NA_character_),
     levels=c("Private","Dual eligible","Medicare Advantage","Medicare only excluding Medicare Advantage","Other coverage","Uninsured"))]
 d[,cover_65:=factor(fifelse(cover_65all=="Uninsured",NA_character_,as.character(cover_65all)),levels=levels(cover_65all)[1:5])]
 d[,hdhp:=factor(fcase(PRIVATE_A %in% 1:2 & PRDEDUC1_A==2,"No deductible",PRIVATE_A %in% 1:2 & PRHDHP1_A==1,"Deductible below HDHP threshold",
     PRIVATE_A %in% 1:2 & PRHDHP1_A==2,"High deductible",default=NA_character_),levels=c("No deductible","Deductible below HDHP threshold","High deductible"))]
 d[,bp_nonuse:=fifelse(HYPEV_A==1,1-yn(HYPMED_A),NA_real_)]
 d[,chol_nonuse:=fifelse(CHLEV_A==1,1-yn(CHLMED_A),NA_real_)]
 d[,ed_any:=fifelse(EMERG12MTC_A %in% 1:4,1,fifelse(EMERG12MTC_A %in% 0,0,NA_real_))]
 d[,ed_2plus:=fifelse(EMERG12MTC_A %in% 2:4,1,fifelse(EMERG12MTC_A %in% 0:1,0,NA_real_))]
 d[,hosp:=yn(HOSPONGT_A)]
 d[,bills:=yn(PAYBLL12M_A)]
 d[,worry_any:=fifelse(PAYWORRY_A %in% 1:2,1,fifelse(PAYWORRY_A %in% 3,0,NA_real_))]
 d[,worry_very:=fifelse(PAYWORRY_A %in% 1,1,fifelse(PAYWORRY_A %in% 2:3,0,NA_real_))]
 d[,barrier_or_bills:=fifelse(any_barrier %in% 1 | bills %in% 1,1,fifelse(any_barrier %in% 0 & bills %in% 0,0,NA_real_))]
 d[,urban4:=factor(urban_raw,levels=1:4,labels=c("Large central metro","Large fringe metro","Medium and small metro","Nonmetropolitan"))]
 d[,worked:=factor(fifelse(worked_raw==1,"Worked last week",fifelse(worked_raw==2,"Did not work",NA_character_)),levels=c("Did not work","Worked last week"))]
 d[,known_stroke:=STREV_A %in% 1:2 & !is.na(age)]
 d[,strokef:=factor(fifelse(known_stroke,fifelse(STREV_A==1,"Stroke","No stroke"),NA_character_),levels=c("No stroke","Stroke"))]
 d[,age_band:=cut(age,c(17,44,54,64,74,85),labels=c("18-44","45-54","55-64","65-74","75-85"))]
 d[,race_w:=relevel(race,ref="2")]
 d[]
}
base<-derive(base);annual<-derive(annual)
stopifnot(all(base[stroke==TRUE & !is.na(any_barrier) & any_barrier==0,care_barrier==0 & rx_barrier==0]),
          all(base[stroke==TRUE & (care_barrier %in% 1 | rx_barrier %in% 1),any_barrier==1]))
saveRDS(base,"data/processed/extended/base_ext.rds");saveRDS(annual,"data/processed/extended/annual_ext.rds")
s<-base[stroke==TRUE]
cat("Pooled stroke records:",nrow(s),"\n")
print(s[,.(any=sum(any_barrier==1,na.rm=TRUE),care=sum(care_barrier==1,na.rm=TRUE),rx=sum(rx_barrier==1,na.rm=TRUE),
  care_obs=sum(!is.na(care_barrier)),rx_obs=sum(!is.na(rx_barrier)),bp_obs=sum(!is.na(bp_nonuse)),chol_obs=sum(!is.na(chol_nonuse)),
  ed_obs=sum(!is.na(ed_any)),hosp_obs=sum(!is.na(hosp)),bills_obs=sum(!is.na(bills)),worked_obs=sum(!is.na(worked)))])
print(s[,.N,by=cover_u65][order(cover_u65)]);print(s[,.N,by=cover_65all][order(cover_65all)])
print(s[age<65 & cover_u65=="Private",.N,by=hdhp][order(hdhp)])
print(s[,.N,by=.(year,urban4)][,dcast(.SD,year~urban4,value.var="N")])
