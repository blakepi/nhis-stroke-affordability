# Descriptive characteristics of the MEPS and BRFSS study populations for the cross-survey Table 1 (covariates only;
# no outcome is used). NHIS characteristics come from outputs/full/table1_characteristics.csv.
# MEPS: adult, access-eligible stroke survivors 2019-2024, survey-weighted percentages (pooled design).
# BRFSS: the difference-in-differences primary sample (low-income survivors aged 18-64 in the 46 study states, 2011-2019,
# complete covariates), unweighted counts and percentages (the primary estimator is unweighted) and weighted percentages.
# Output: outputs/v3/characteristics_meps.csv, outputs/v3/characteristics_brfss.csv
suppressPackageStartupMessages({library(data.table);library(survey)})
options(survey.lonely.psu="adjust")
dir.create("outputs/v3",showWarnings=FALSE)
p<-readRDS("data/processed/meps/meps_analytic.rds")
des<-svydesign(ids=~psu,strata=~stratum,weights=~wt,data=p,nest=TRUE)
dm<-subset(des,adult & stroke & eligible)
mv<-list(age_group="Age group",sex="Sex",race="Race and ethnicity",education="Education",income="Family income",coverage="Coverage (June)",
         hypertension="Hypertension",diabetes="Diabetes",coronary="Coronary heart disease",smoking="Current smoking",fairpoor="Fair or poor health",disability="Any disability")
meps<-rbindlist(lapply(names(mv),function(v){
 x<-dm$variables[[v]];if(is.logical(x)||is.numeric(x)){dm$variables$.f<-factor(as.integer(x),levels=0:1,labels=c("No","Yes"))} else dm$variables$.f<-factor(x)
 dd<-subset(dm,!is.na(.f));m<-svymean(~.f,dd);n<-table(dd$variables$.f)
 data.table(variable=mv[[v]],level=sub("^\\.f","",names(coef(m))),n=as.integer(n[sub("^\\.f","",names(coef(m)))]),weighted_pct=100*as.numeric(coef(m)))
}))
meps<-meps[!(level=="No" & variable %in% unlist(mv[c("hypertension","diabetes","coronary","smoking","fairpoor","disability")]))]
meps<-rbind(data.table(variable="Total",level="Person-years",n=nrow(dm$variables),weighted_pct=100),
            data.table(variable="Total",level="Persons",n=uniqueN(dm$variables$DUPERSID),weighted_pct=NA_real_),meps)
meps[,age_mean:=NA_real_];meps[variable=="Total" & level=="Person-years",age_mean:=as.numeric(coef(svymean(~age,dm)))]
fwrite(meps,"outputs/v3/characteristics_meps.csv")
a<-readRDS("data/processed/brfss/brfss_analytic.rds")
b<-a[status!="excluded" & wt>0 & !is.na(age) & !is.na(sex) & !is.na(race) & !is.na(educ) & stroke==1 & age %between% c(18,64) & low_income_138==1 & year<=2019]
b<-b[!(state_abbr %in% c("VA","ME") & year==2019)]
b[,`:=`(cohort=fcase(first_treat_year==2014,"Expanded 2014",first_treat_year %in% 2015:2016,"Expanded 2015-2016",default="Not expanded by 2019"),
        age_band=fcase(age<45,"18-44",age<55,"45-54",default="55-64"),sexf=fifelse(sex==2,"Female","Male"),
        racef=c("White, non-Hispanic","Black, non-Hispanic","Hispanic","Other or multiple, non-Hispanic")[race],period=fifelse(year<=2013,"2011-2013","2014-2019"))]
bv<-list(cohort="Expansion cohort",period="Period",age_band="Age group",sexf="Sex",racef="Race and ethnicity",educ="Education",adults_imputed="Household adults imputed")
brfss<-rbindlist(lapply(names(bv),function(v){x<-as.character(b[[v]])
 rbindlist(lapply(sort(unique(x)),function(l)data.table(variable=bv[[v]],level=l,n=sum(x==l),pct=100*mean(x==l),weighted_pct=100*sum(b$wt[x==l])/sum(b$wt))))}))
brfss<-rbind(data.table(variable="Total",level="Respondents",n=nrow(b),pct=100,weighted_pct=100),
             data.table(variable="Total",level="States",n=uniqueN(b$state),pct=NA_real_,weighted_pct=NA_real_),brfss)
brfss[,age_mean:=NA_real_];brfss[variable=="Total" & level=="Respondents",age_mean:=mean(b$age)]
fwrite(brfss,"outputs/v3/characteristics_brfss.csv")
print(meps);print(brfss)
