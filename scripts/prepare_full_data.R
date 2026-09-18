suppressPackageStartupMessages(library(data.table))
dir.create("outputs/full",showWarnings=FALSE,recursive=TRUE)
dir.create("data/processed/full",showWarnings=FALSE,recursive=TRUE)
base<-readRDS("data/processed/adults_selected.rds")
extra<-list(); incomes<-list(); mergechecks<-list()
for(y in 2019:2025){
 path<-sprintf("data/processed/extracted/adult%s.csv",substr(y,3,4))
 # Original filenames differ in capitalization; resolve from the retained ZIP.
 z<-sprintf("data/raw/%s/adult%scsv.zip",y,substr(y,3,4)); member<-unzip(z,list=TRUE)$Name
 path<-file.path("data/processed/extracted",member[grepl("[.]csv$",member,ignore.case=TRUE)])
 edu<-if(y<2021) "EDUC_A" else "EDUCP_A"
 cols<-c("HHX",edu,"NOTCOV_A","PRIVATE_A","MEDICARE_A","MEDICAID_A","CHIP_A","OTHPUB_A","OTHGOV_A","MILITARY_A","PHSTAT_A","DIBEV_A","HYPEV_A","CHDEV_A","SMKCIGST_A")
 d<-fread(path,select=cols);setnames(d,edu,"education_raw");d[,year:=y];extra[[as.character(y)]]<-d
 z<-sprintf("data/raw/%s/adultinc%scsv.zip",y,substr(y,3,4));member<-unzip(z,list=TRUE)$Name
 member<-member[grepl("[.]csv$",member,ignore.case=TRUE)];stopifnot(length(member)==1L,basename(member)==member)
 path<-file.path("data/processed/extracted",member);if(!file.exists(path))unzip(z,files=member,exdir="data/processed/extracted")
 inc<-fread(path);if("IMPNUM" %in% names(inc))setnames(inc,"IMPNUM","IMPNUM_A");inc[,year:=y]
 inc<-inc[,.(year,HHX,IMPNUM_A,IMPINCFLG_A,POVRATTC_A,RATCAT_A)]
 stopifnot(!anyDuplicated(inc[,.(HHX,IMPNUM_A)]),setequal(unique(inc$IMPNUM_A),1:10),all(is.finite(inc$POVRATTC_A)),all(inc$POVRATTC_A>=0),all(inc$RATCAT_A %in% 1:14))
 for(m in 1:10){stopifnot(setequal(base[year==y,HHX],inc[IMPNUM_A==m,HHX]))}
 mergechecks[[as.character(y)]]<-data.table(year=y,adult_rows=nrow(d),income_rows=nrow(inc),imputations=uniqueN(inc$IMPNUM_A),matched_all=TRUE)
 incomes[[as.character(y)]]<-inc
}
extras<-rbindlist(extra)
stopifnot(!anyDuplicated(extras[,.(year,HHX)]))
base<-merge(base,extras,by=c("year","HHX"),sort=FALSE,all.x=TRUE)
base[,education:=factor(fcase(education_raw %in% 0:2,"Less than high school",education_raw %in% 3:4,"High school or GED",education_raw %in% 5:7,"Some college or associate",education_raw %in% 8:11,"Bachelor or higher",default=NA_character_),levels=c("Bachelor or higher","Some college or associate","High school or GED","Less than high school"))]
# Mutually exclusive hierarchy. Code 1 or 2 means insurance present; 3 means absent.
# NOTCOV is authoritative for uninsured; ambiguous covered type stays unknown.
base[,insurance:=fcase(NOTCOV_A==1,"Uninsured",NOTCOV_A==2 & PRIVATE_A %in% 1:2,"Private",
 NOTCOV_A==2 & PRIVATE_A==3 & (MEDICARE_A %in% 1:2 | MEDICAID_A %in% 1:2 | CHIP_A %in% 1:2 | OTHPUB_A %in% 1:2 | OTHGOV_A %in% 1:2),"Public without private",
 NOTCOV_A==2 & PRIVATE_A==3 & MEDICARE_A==3 & MEDICAID_A==3 & CHIP_A==3 & OTHPUB_A==3 & OTHGOV_A==3 & MILITARY_A %in% 1:2,"Military only",default=NA_character_)]
base[,insurance:=factor(insurance,levels=c("Private","Public without private","Military only","Uninsured"))]
yn<-function(x) factor(fifelse(x==1,"Yes",fifelse(x==2,"No",NA_character_)),levels=c("No","Yes"))
base[,`:=`(hypertension=yn(HYPEV_A),diabetes=yn(DIBEV_A),coronary=yn(CHDEV_A),
 fairpoor=factor(fifelse(PHSTAT_A %in% 4:5,"Fair or poor",fifelse(PHSTAT_A %in% 1:3,"Good or better",NA_character_)),levels=c("Good or better","Fair or poor")),
 smoking=factor(fcase(SMKCIGST_A %in% 1:2,"Current",SMKCIGST_A==3,"Former",SMKCIGST_A==4,"Never",default=NA_character_),levels=c("Never","Former","Current")),
 disability=factor(disability,levels=c("Without disability","With disability")),
 young=factor(age_group,levels=c("65+","18-64")),yearf=factor(year,levels=2019:2025))]
partial<-fread("data/processed/extracted/adultpart20.csv")
base[,pooled_weight:=WTFA_A];base[year==2020,pooled_weight:=partial$WTSA_P[match(HHX,partial$HHX_2020)]]
base<-base[!is.na(pooled_weight) & pooled_weight>0];base[,pooled_weight:=pooled_weight/7]
inc<-rbindlist(incomes)
nonincome<-c("any_barrier","age","sex","race","region","education","insurance","hypertension","diabetes","coronary","fairpoor","smoking","disability")
base[,complete:=complete.cases(.SD),.SDcols=nonincome]
ms<-rbindlist(lapply(nonincome,function(v)base[stroke==TRUE,.(variable=v,n=.N,missing=sum(is.na(get(v))),pct_missing=100*mean(is.na(get(v))))]))
fwrite(ms,"outputs/full/covariate_missingness.csv");fwrite(rbindlist(mergechecks),"outputs/full/income_merge_checks.csv")
saveRDS(base,"data/processed/full/base.rds");saveRDS(inc,"data/processed/full/income.rds")
fwrite(base[stroke==TRUE],"data/processed/full/stroke_covariates.csv")
print(ms)
print(base[stroke==TRUE,.(n=.N,complete=sum(complete),events=sum(any_barrier==1,na.rm=TRUE),model_events=sum(any_barrier==1 & complete,na.rm=TRUE))])
print(base[stroke==TRUE,.(n=.N,events=sum(any_barrier==1,na.rm=TRUE)),by=insurance])
