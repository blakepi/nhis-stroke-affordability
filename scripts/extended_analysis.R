# Extended (exploratory) analyses E1-E11. Specifications: EXTENDED_ANALYSIS_PLAN.md.
# Run from the project root after prepare_extended_data.R.
# Optional arguments select sections, e.g. `Rscript scripts/extended_analysis.R E3 E4`.
suppressPackageStartupMessages({library(data.table);library(survey);library(mitools);library(ggplot2)})
options(survey.lonely.psu="fail")
args<-commandArgs(trailingOnly=TRUE);run<-function(s)length(args)==0L || s %in% args
OUT<-"outputs/extended";dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
base<-readRDS("data/processed/extended/base_ext.rds");income<-readRDS("data/processed/full/income.rds")
M<-10L
dem_noyear<-"splines::ns(age, df=3) + sex + race + region"
dem<-paste("yearf +",dem_noyear)
soc<-paste(dem,"+ education + income_group + insurance")
clin<-"hypertension + diabetes + coronary + smoking + fairpoor + disability"
full<-paste(soc,"+",clin)
base[,`:=`(yearc=year-2019,uninsured=fifelse(NOTCOV_A==1,1,fifelse(NOTCOV_A==2,0,NA_real_)),
 periodf=factor(fcase(year==2019,"2019",year %in% 2020:2023,"2020-2023",year>=2024,"2024-2025"),levels=c("2019","2020-2023","2024-2025")),
 y2025=as.numeric(year==2025),
 race4=factor(fcase(race=="1","Hispanic",race=="2","NH White",race=="3","NH Black",!is.na(race),"Other"),levels=c("NH White","Hispanic","NH Black","Other")))]
race_labels<-c("1"="Hispanic","2"="Non-Hispanic White only","3"="Non-Hispanic Black only","4"="Non-Hispanic Asian only",
 "5"="Non-Hispanic AIAN only","6"="Non-Hispanic AIAN and another group","7"="Other single and multiple races")
region_labels<-c("1"="Northeast","2"="Midwest","3"="South","4"="West")

with_income<-function(m){
 d<-copy(base);inc<-income[IMPNUM_A==m];idx<-match(paste(d$year,d$HHX),paste(inc$year,inc$HHX));stopifnot(!anyNA(idx));rc<-inc$RATCAT_A[idx]
 d[,income_group:=factor(fcase(rc %in% 1:3,"<100%",rc %in% 4:7,"100-199%",rc %in% 8:11,"200-399%",rc %in% 12:14,"400%+"),levels=c("400%+","200-399%","100-199%","<100%"))]
 d
}
mkdes<-function(d,w="pooled_weight")svydesign(ids=~PPSU,strata=~PSTRAT,weights=as.formula(paste0("~",w)),data=d,nest=TRUE)
pfit<-function(rhs,outcome,design,family=quasipoisson(link="log"),influence=FALSE){
 f<-svyglm(as.formula(paste(outcome,"~",rhs)),design=design,family=family,influence=influence)
 stopifnot(f$converged,all(is.finite(coef(f))));f
}
tidy1<-function(f,label){
 b<-coef(f);se<-sqrt(diag(vcov(f)));df<-f$df.residual;crit<-qt(.975,df)
 data.table(model=label,term=names(b),log_PR=b,se=se,PR=exp(b),lower=exp(b-crit*se),upper=exp(b+crit*se),p=2*pt(-abs(b/se),df),df=df,
  n=nrow(f$survey.design$variables),events=sum(f$y),imputations=1L,max_fitted=max(fitted(f)))
}
pool<-function(fits,label){
 q<-MIcombine(results=lapply(fits,coef),variances=lapply(fits,vcov),df.complete=min(sapply(fits,function(x)x$df.residual)))
 b<-q$coefficients;se<-sqrt(diag(q$variance));crit<-qt(.975,q$df)
 data.table(model=label,term=names(b),log_PR=b,se=se,PR=exp(b),lower=exp(b-crit*se),upper=exp(b+crit*se),p=2*pt(-abs(b/se),q$df),df=q$df,
  n=nrow(fits[[1]]$survey.design$variables),events=sum(fits[[1]]$y),imputations=length(fits),max_fitted=max(sapply(fits,function(f)max(fitted(f)))))
}
precision<-function(n,p,se,lower,upper,df){
 neff<-p*(1-p)/se^2;width<-upper-lower
 if(n<30 || (!is.na(neff)&&neff<30) || width>.30 || (width>.05 && width<=.30 && width/min(p,1-p)>1.30))return("limited")
 if(df<8)return("review_df")
 "adequate"
}
# Same design-adjusted beta interval as the primary analysis (full_analysis.R).
desc_est<-function(design,variable,domain=rep(TRUE,nrow(design$variables))){
 domain<-domain & !is.na(design$variables[[variable]]);domain[is.na(domain)]<-FALSE
 d<-design[domain,];n<-nrow(d$variables);events<-sum(d$variables[[variable]])
 if(n<2L)return(data.table(n=n,events=events,estimate=NA_real_,se=NA_real_,lower=NA_real_,upper=NA_real_,df=NA_real_,effective_n=NA_real_,reliability="limited"))
 fit<-svymean(reformulate(variable),d);p<-as.numeric(coef(fit));se<-as.numeric(SE(fit));df<-degf(d)
 neff<-if(se>0)min(n,p*(1-p)/se^2) else n
 neff_df<-neff*(qnorm(.975)/qt(.975,df))^2
 lower<-if(events==0)0 else qbeta(.025,neff_df*p,neff_df*(1-p)+1)
 upper<-if(events==n)1 else qbeta(.975,neff_df*p+1,neff_df*(1-p))
 data.table(n=n,events=events,estimate=p,se=se,lower=lower,upper=upper,df=df,effective_n=neff_df,
    reliability=precision(n,p,se,lower,upper,df))
}
est_ind<-function(design,ind,domain){design$variables$.ind<-as.numeric(ind);desc_est(design,".ind",domain)}
nz<-function(x){x[is.na(x)]<-FALSE;x}
keep_terms<-function(tab,pattern)tab[grepl(pattern,term)]
survey_var<-function(infl,design)survey::svyrecvar(infl,design$cluster,design$strata,design$fpc,design$postStrata)
# Annual prevalence standardized to the domain's pooled covariate distribution (as in full_analysis.R).
std_years<-function(fit){
 d<-fit$survey.design;data<-d$variables;w<-as.numeric(weights(d));w<-w/sum(w);infl<-attr(fit,"influence")
 stopifnot(max(abs(survey_var(infl,d)-vcov(fit)))<1e-8)
 vals<-numeric(7);u<-matrix(0,nrow(data),7)
 for(i in 1:7){
  nd<-data;nd$yearf<-factor(2018+i,levels=2019:2025)
  x<-model.matrix(delete.response(terms(fit)),nd,contrasts.arg=fit$contrasts,xlev=fit$xlevels)
  mu<-plogis(as.vector(x%*%coef(fit)));p<-sum(w*mu);grad<-colSums(x*(w*mu*(1-mu)))
  u[,i]<-as.vector(infl%*%grad)+w*(mu-p);vals[i]<-p
 }
 v<-survey_var(u,d);se_logit<-sqrt(diag(v))/(vals*(1-vals));crit<-qt(.975,fit$df.residual)
 cvec<-c(-1,0,0,0,0,0,1);dse<-sqrt(as.numeric(t(cvec)%*%v%*%cvec));dd<-sum(cvec*vals)
 list(table=data.table(year=2019:2025,estimate=vals,lower=plogis(qlogis(vals)-crit*se_logit),upper=plogis(qlogis(vals)+crit*se_logit)),
  diff=data.table(difference_2025_minus_2019=dd,lower=dd-crit*dse,upper=dd+crit*dse,p=2*pt(-abs(dd/dse),fit$df.residual)))
}

# ---------------------------------------------------------------- E1 + E6: comparator
if(run("E1")){
 des<-mkdes(base);rows<-list()
 add<-function(o,dom,...){r<-desc_est(des,o,nz(dom));r[,outcome:=o];rows[[length(rows)+1L]]<<-cbind(data.table(...),r)}
 for(s in c("Stroke","No stroke")){
  for(o in c("any_barrier","care_barrier","rx_barrier","bills","worry_any","worry_very")){
   add(o,base$strokef==s,stroke=s,group="All ages")
   for(g in c("18-64","65+"))add(o,base$strokef==s & base$age_group==g,stroke=s,group=g)
  }
  for(g in levels(base$age_band))add("any_barrier",base$strokef==s & base$age_band==g,stroke=s,group=g)
 }
 for(g in c("All ages","18-64","65+"))add("barrier_or_bills",base$stroke & (g=="All ages" | base$age_group==g),stroke="Stroke",group=g)
 fwrite(rbindlist(rows),file.path(OUT,"E1_E6_comparator_prevalence.csv"))
 dom<-function(d,g,o="any_barrier")subset(d,known_stroke & complete & !is.na(get(o)) & (g=="All ages" | age_group==g))
 res<-list()
 for(g in c("All ages","18-64","65+"))for(o in c("any_barrier","bills")){
  t0<-Sys.time();f<-pfit(paste("strokef +",dem),o,dom(des,g,o))
  res[[length(res)+1L]]<-cbind(outcome=o,group=g,covariates="Dem",keep_terms(tidy1(f,"stroke vs no stroke"),"^strokef"))
  cat("E1 Dem",o,g,round(as.numeric(difftime(Sys.time(),t0,units="secs")),1),"s\n");flush.console()
 }
 specs<-CJ(o=c("any_barrier","bills"),g=c("All ages","18-64","65+"),cov=c("Soc","Full"),sorted=FALSE)
 fits<-vector("list",nrow(specs));for(i in seq_along(fits))fits[[i]]<-vector("list",M)
 for(m in 1:M){
  dm<-mkdes(with_income(m))
  for(i in seq_len(nrow(specs)))fits[[i]][[m]]<-pfit(paste("strokef +",if(specs$cov[i]=="Soc")soc else full),specs$o[i],dom(dm,specs$g[i],specs$o[i]))
  cat("E1 imputation",m,"done",format(Sys.time(),"%H:%M:%S"),"\n");flush.console()
 }
 for(i in seq_len(nrow(specs)))res[[length(res)+1L]]<-cbind(outcome=specs$o[i],group=specs$g[i],covariates=specs$cov[i],keep_terms(pool(fits[[i]],"stroke vs no stroke"),"^strokef"))
 fwrite(rbindlist(res),file.path(OUT,"E1_E6_stroke_vs_no_stroke_PR.csv"));rm(fits);gc()
}

# ---------------------------------------------------------------- E2: national burden
if(run("E2")){
 b<-copy(base);u<-b$age_group %in% "18-64";o<-b$age_group %in% "65+"
 b[,`:=`(n_stroke=as.numeric(stroke),n_stroke_u65=as.numeric(stroke & u),n_stroke_65=as.numeric(stroke & o),
  n_observed=as.numeric(stroke & !is.na(any_barrier)),
  n_barrier=as.numeric(stroke & any_barrier %in% 1),n_barrier_u65=as.numeric(stroke & u & any_barrier %in% 1),n_barrier_65=as.numeric(stroke & o & any_barrier %in% 1),
  n_care=as.numeric(stroke & care_barrier %in% 1),n_rx=as.numeric(stroke & rx_barrier %in% 1),n_bills=as.numeric(stroke & bills %in% 1),
  n_uninsured_u65=as.numeric(stroke & u & uninsured %in% 1))]
 des<-mkdes(b);v<-grep("^n_",names(b),value=TRUE);tt<-svytotal(reformulate(v),des);crit<-qt(.975,degf(des))
 fwrite(data.table(quantity=v,average_annual_persons=as.numeric(coef(tt)),se=as.numeric(SE(tt)),lower=as.numeric(coef(tt)-crit*SE(tt)),upper=as.numeric(coef(tt)+crit*SE(tt)),
  unweighted_n=sapply(v,function(z)sum(b[[z]]))),file.path(OUT,"E2_national_burden.csv"))
}

# ---------------------------------------------------------------- E3: age-specific coverage
if(run("E3")){
 des<-mkdes(base);rows<-list()
 for(spec in list(list(v="cover_u65",g="18-64"),list(v="cover_65all",g="65+"))){
  known<-base$stroke & base$age_group==spec$g & !is.na(base[[spec$v]])
  for(lv in levels(base[[spec$v]])){
   sh<-est_ind(des,base[[spec$v]] %in% lv,known)
   for(o in c("any_barrier","care_barrier","rx_barrier")){
    r<-desc_est(des,o,nz(known & base[[spec$v]]==lv))
    rows[[length(rows)+1L]]<-cbind(data.table(age_group=spec$g,coverage=lv,share_of_group=sh$estimate,share_lower=sh$lower,share_upper=sh$upper,outcome=o),r)
   }
  }
 }
 fwrite(rbindlist(rows),file.path(OUT,"E3_coverage_prevalence.csv"))
 oc<-base$stroke & base$cover_u65 %in% "Other coverage"
 comp<-rbind(cbind(component="Medicare",est_ind(des,base$MEDICARE_A %in% 1:2,oc)),cbind(component="Military",est_ind(des,base$MILITARY_A %in% 1:2,oc)),
  cbind(component="Other government program",est_ind(des,base$OTHGOV_A %in% 1:2,oc)))
 fwrite(comp,file.path(OUT,"E3_other_coverage_composition_under65.csv"))
 priv<-base$stroke & base$cover_u65 %in% "Private"
 hd<-rbindlist(lapply(levels(base$hdhp),function(lv)cbind(hdhp=lv,share=est_ind(des,base$hdhp %in% lv,priv & !is.na(base$hdhp))$estimate,desc_est(des,"any_barrier",nz(priv & base$hdhp==lv)))))
 fwrite(hd,file.path(OUT,"E3_hdhp_prevalence_private_under65.csv"))
 rhs_cov<-function(v,r="race")paste("yearf + splines::ns(age, df=3) + sex +",r,"+ region + education + income_group +",v,"+",clin)
 f1<-f2<-f3<-vector("list",M)
 for(m in 1:M){
  dm<-mkdes(with_income(m))
  f1[[m]]<-pfit(rhs_cov("cover_u65"),"any_barrier",subset(dm,stroke & complete & age<65 & !is.na(cover_u65)))
  f2[[m]]<-pfit(rhs_cov("cover_65"),"any_barrier",subset(dm,stroke & complete & age>=65 & !is.na(cover_65)))
  f3[[m]]<-pfit(rhs_cov("hdhp","race4"),"any_barrier",subset(dm,stroke & complete & age<65 & cover_u65=="Private" & !is.na(hdhp)))
 }
 fwrite(rbind(cbind(age_group="18-64",keep_terms(pool(f1,"Full, coverage hierarchy"),"^cover|^income")),
  cbind(age_group="65+",keep_terms(pool(f2,"Full, coverage hierarchy"),"^cover|^income")),
  cbind(age_group="18-64 private",keep_terms(pool(f3,"Full, deductible type"),"^hdhp"))),file.path(OUT,"E3_coverage_PR.csv"))
}

# ---------------------------------------------------------------- E4 + E5: medication use and acute care
if(run("E4")){
 des<-mkdes(base);rows<-list();outs<-c("bp_nonuse","chol_nonuse","ed_any","ed_2plus","hosp")
 for(o in outs)for(g in c("All ages","18-64","65+"))for(ex in c("any_barrier","care_barrier","rx_barrier"))for(b in 0:1){
  r<-desc_est(des,o,nz(base$stroke & (g=="All ages" | base$age_group==g) & base[[ex]]==b))
  rows[[length(rows)+1L]]<-cbind(data.table(outcome=o,group=g,exposure=ex,exposed=b),r)
 }
 fwrite(rbindlist(rows),file.path(OUT,"E4_E5_outcomes_by_barrier.csv"))
 rhs_for<-function(o,ex)paste(ex,"+",if(o=="bp_nonuse")sub("hypertension + ","",full,fixed=TRUE) else full)
 fa<-fb<-setNames(vector("list",length(outs)),outs);for(o in outs){fa[[o]]<-vector("list",M);fb[[o]]<-vector("list",M)}
 for(m in 1:M){
  dm<-mkdes(with_income(m))
  for(o in outs){
   fa[[o]][[m]]<-pfit(rhs_for(o,"any_barrier"),o,subset(dm,stroke & complete & !is.na(get(o))))
   fb[[o]][[m]]<-pfit(rhs_for(o,"care_barrier + rx_barrier"),o,subset(dm,stroke & complete & !is.na(get(o)) & !is.na(care_barrier) & !is.na(rx_barrier)))
  }
 }
 fwrite(rbindlist(c(lapply(outs,function(o)cbind(outcome=o,keep_terms(pool(fa[[o]],"Full + any barrier"),"barrier"))),
  lapply(outs,function(o)cbind(outcome=o,keep_terms(pool(fb[[o]],"Full + care and medication barriers"),"barrier"))))),file.path(OUT,"E4_E5_barrier_PR.csv"))
}

# ---------------------------------------------------------------- E7: trends by age and domain
if(run("E7")){
 annual<-readRDS("data/processed/extended/annual_ext.rds");rows<-list()
 for(y in 2019:2025){
  d<-annual[year==y];dy<-mkdes(d,"WTFA_A")
  for(g in c("All ages","18-64","65+"))for(o in c("any_barrier","care_barrier","rx_barrier")){
   keep<-nz(d$stroke & (g=="All ages" | d$age_group==g) & !is.na(d[[o]]));dd<-dy[keep,]
   ci<-svyciprop(reformulate(o),dd,method="logit",df=degf(dd))
   rows[[length(rows)+1L]]<-data.table(year=y,group=g,outcome=o,n=nrow(dd$variables),events=sum(dd$variables[[o]]),estimate=as.numeric(coef(ci)),
    se=as.numeric(SE(ci)),lower=confint(ci)[1],upper=confint(ci)[2])
  }
 }
 fwrite(rbindlist(rows),file.path(OUT,"E7_annual_observed_by_age_domain.csv"))
 des<-mkdes(base);std<-list();dif<-list();tr<-list();jt<-list()
 for(g in c("All ages","18-64","65+"))for(o in c("any_barrier","care_barrier","rx_barrier")){
  dd<-subset(des,stroke & !is.na(get(o)) & (g=="All ages" | age_group==g))
  s<-std_years(pfit(dem,o,dd,family=quasibinomial(link="logit"),influence=TRUE))
  std[[length(std)+1L]]<-cbind(group=g,outcome=o,s$table);dif[[length(dif)+1L]]<-cbind(group=g,outcome=o,s$diff)
  tr[[length(tr)+1L]]<-cbind(group=g,outcome=o,keep_terms(tidy1(pfit(paste("yearc +",dem_noyear),o,dd),"Dem, linear year"),"^yearc$"))
  w<-regTermTest(pfit(dem,o,dd),~yearf)
  jt[[length(jt)+1L]]<-data.table(group=g,outcome=o,test="categorical year (6 df), Dem-adjusted",F=as.numeric(w$Ftest),df1=w$df,df2=w$ddf,p=as.numeric(w$p))
 }
 tr<-rbindlist(tr);tr[group!="All ages",p_holm:=p.adjust(p,"holm")]
 fwrite(rbindlist(std),file.path(OUT,"E7_annual_standardized_demographic.csv"));fwrite(rbindlist(dif),file.path(OUT,"E7_standardized_difference_2025_2019.csv"))
 fwrite(tr,file.path(OUT,"E7_linear_trend_PR_per_year.csv"));fwrite(rbindlist(jt),file.path(OUT,"E7_categorical_year_tests.csv"))
 per<-list()
 for(g in c("All ages","18-64","65+")){
  f<-pfit(paste("periodf +",dem_noyear),"any_barrier",subset(des,stroke & !is.na(any_barrier) & (g=="All ages" | age_group==g)))
  b<-coef(f);v<-vcov(f);df<-f$df.residual;crit<-qt(.975,df);i2<-"periodf2020-2023";i3<-"periodf2024-2025"
  con<-list("2020-2023 vs 2019"=c(b[i2],v[i2,i2]),"2024-2025 vs 2019"=c(b[i3],v[i3,i3]),"2024-2025 vs 2020-2023"=c(b[i3]-b[i2],v[i3,i3]+v[i2,i2]-2*v[i2,i3]))
  for(nm in names(con)){e<-con[[nm]][1];s<-sqrt(con[[nm]][2]);per[[length(per)+1L]]<-data.table(group=g,outcome="any_barrier",contrast=nm,PR=exp(e),lower=exp(e-crit*s),upper=exp(e+crit*s),p=2*pt(-abs(e/s),df),n=nrow(f$survey.design$variables))}
 }
 f<-pfit(paste("y2025 +",dem_noyear),"rx_barrier",subset(des,stroke & !is.na(rx_barrier) & age_group=="65+"))
 e<-coef(f)["y2025"];s<-sqrt(vcov(f)["y2025","y2025"]);crit<-qt(.975,f$df.residual)
 per[[length(per)+1L]]<-data.table(group="65+",outcome="rx_barrier",contrast="2025 vs 2019-2024",PR=exp(e),lower=exp(e-crit*s),upper=exp(e+crit*s),p=2*pt(-abs(e/s),f$df.residual),n=nrow(f$survey.design$variables))
 fwrite(rbindlist(per),file.path(OUT,"E7_period_contrasts.csv"))
}

# ---------------------------------------------------------------- E8: age profile
if(run("E8")){
 des<-mkdes(base);prof<-list()
 for(s in c("Stroke","No stroke")){
  f<-pfit("splines::ns(age, knots=c(45,60,72), Boundary.knots=c(25,85))","any_barrier",subset(des,strokef==s & !is.na(any_barrier)),family=quasibinomial(link="logit"))
  grid<-data.frame(age=if(s=="Stroke")30:85 else 18:85)
  x<-cbind(1,splines::ns(grid$age,knots=c(45,60,72),Boundary.knots=c(25,85)));eta<-as.vector(x%*%coef(f));se<-sqrt(rowSums((x%*%vcov(f))*x));crit<-qt(.975,f$df.residual)
  prof[[s]]<-data.table(stroke=s,age=grid$age,estimate=plogis(eta),lower=plogis(eta-crit*se),upper=plogis(eta+crit*se))
 }
 prof<-rbindlist(prof);fwrite(prof,file.path(OUT,"E8_age_profile.csv"))
 p<-ggplot(prof,aes(age,estimate*100,color=stroke,fill=stroke))+geom_vline(xintercept=65,linetype="dashed",color="grey55")+
  geom_ribbon(aes(ymin=lower*100,ymax=upper*100),alpha=.18,color=NA)+geom_line(linewidth=.9)+
  scale_color_manual(values=c("Stroke"="#1F5AA6","No stroke"="#E8672B"))+scale_fill_manual(values=c("Stroke"="#1F5AA6","No stroke"="#E8672B"))+
  scale_x_continuous(breaks=seq(20,85,5))+scale_y_continuous(limits=c(0,NA),expand=expansion(mult=c(0,.05)))+
  labs(x="Age, years (85 = 85 or older)",y="Any cost-related barrier, % (95% CI)",color=NULL,fill=NULL)+
  theme_minimal(base_size=12)+theme(panel.grid.minor=element_blank(),legend.position="top")
 ggsave(file.path(OUT,"age_profile.png"),p,width=7,height=4.6,dpi=300)
}

# ---------------------------------------------------------------- E9: discontinuity at 65 (secondary)
if(run("E9")){
 rd<-list()
 for(h in c(5,10,7)){
  b<-copy(base);b[,x:=age-65];b[,inwin:=!is.na(x) & abs(x)<=h & x!=0]
  b[,`:=`(post=as.numeric(x>0),rdw=pooled_weight*fifelse(inwin,1-abs(x)/(h+1),1))]
  dh<-mkdes(b,"rdw")
  for(s in c("Stroke","No stroke"))for(o in c("any_barrier","care_barrier","rx_barrier","bills","uninsured")){
   f<-svyglm(as.formula(paste(o,"~ post + x + x:post")),design=subset(dh,strokef==s & inwin & !is.na(get(o))),family=gaussian())
   e<-coef(f)["post"];se<-sqrt(vcov(f)["post","post"]);crit<-qt(.975,f$df.residual)
   rd[[length(rd)+1L]]<-data.table(stroke=s,outcome=o,bandwidth_years=h,n=nrow(f$survey.design$variables),level_below_65=coef(f)[1],
    jump_at_65=e,se=se,lower=e-crit*se,upper=e+crit*se,p=2*pt(-abs(e/se),f$df.residual))
  }
 }
 fwrite(rbindlist(rd)[order(stroke,outcome,bandwidth_years)],file.path(OUT,"E9_discontinuity_at_65.csv"))
}

# ---------------------------------------------------------------- E10: equity descriptives (secondary)
if(run("E10")){
 des<-mkdes(base);rows<-list()
 grp<-function(variable,lv,label,dom=TRUE){r<-desc_est(des,"any_barrier",nz(base$stroke & dom & base[[variable]]==lv));rows[[length(rows)+1L]]<<-cbind(data.table(variable=variable,level=label),r)}
 for(lv in names(race_labels))grp("race",lv,race_labels[[lv]])
 for(lv in levels(base$sex))grp("sex",lv,c("1"="Male","2"="Female")[[lv]])
 for(lv in names(region_labels))grp("region",lv,region_labels[[lv]])
 for(lv in levels(base$urban4))grp("urban4",lv,lv)
 for(lv in levels(base$worked))grp("worked",lv,paste(lv,"(18-64)"),base$age_group %in% "18-64")
 sh<-est_ind(des,base$worked %in% "Worked last week",base$stroke & base$age_group %in% "18-64" & !is.na(base$worked))
 rows[[length(rows)+1L]]<-cbind(data.table(variable="share_worked_last_week",level="Stroke survivors 18-64 (share, not barrier prevalence)"),sh)
 fwrite(rbindlist(rows),file.path(OUT,"E10_equity_prevalence.csv"))
 f1<-f2<-f3<-vector("list",M)
 for(m in 1:M){
  dm<-mkdes(with_income(m));cc<-subset(dm,stroke & complete)
  f1[[m]]<-pfit(sub("+ race +","+ race_w +",full,fixed=TRUE),"any_barrier",cc)
  f2[[m]]<-pfit(paste(full,"+ urban4"),"any_barrier",cc)
  f3[[m]]<-pfit(paste(full,"+ worked"),"any_barrier",subset(cc,age<65 & !is.na(worked)))
 }
 t1<-keep_terms(pool(f1,"Full, reference non-Hispanic White"),"^race_w");t1[,term:=paste(race_labels[sub("race_w","",term)],"vs Non-Hispanic White only")]
 fwrite(rbind(t1,keep_terms(pool(f2,"Full + urban4 (reference large central metro)"),"^urban4"),keep_terms(pool(f3,"Full + worked, ages 18-64 (reference did not work)"),"^worked")),
  file.path(OUT,"E10_equity_PR.csv"))
}
# ---------------------------------------------------------------- E11: bounded logistic sensitivity for the new ratios
if(run("E11")){
 base[,`:=`(barrierf=factor(any_barrier,levels=0:1,labels=c("No","Yes")),care_f=factor(care_barrier,levels=0:1,labels=c("No","Yes")),
  rx_f=factor(rx_barrier,levels=0:1,labels=c("No","Yes")))]
 # Standardized (marginal) prevalence ratio for each level of factor v versus its first level, as in logistic_sensitivity.R.
 marg<-function(fit,v){
  d<-fit$survey.design;data<-d$variables;w<-as.numeric(weights(d));w<-w/sum(w);infl<-attr(fit,"influence")
  stopifnot(max(fitted(fit))<=1,min(fitted(fit))>=0)
  lv<-levels(data[[v]]);p<-numeric(length(lv));u<-matrix(0,nrow(data),length(lv))
  for(j in seq_along(lv)){
   nd<-data;nd[[v]]<-factor(lv[j],levels=lv)
   x<-model.matrix(delete.response(terms(fit)),nd,contrasts.arg=fit$contrasts,xlev=fit$xlevels)
   mu<-plogis(as.vector(x%*%coef(fit)));p[j]<-sum(w*mu);g<-colSums(x*(w*mu*(1-mu)));u[,j]<-as.vector(infl%*%g)+w*(mu-p[j])
  }
  cv<-survey_var(u,d)
  rbindlist(lapply(2:length(lv),function(j){a<-rep(0,length(lv));a[j]<-1/p[j];a[1]<- -1/p[1]
   data.table(variable=v,level=lv[j],reference=lv[1],coef=log(p[j]/p[1]),variance=as.numeric(t(a)%*%cv%*%a),df=fit$df.residual,
    p_reference=p[1],p_level=p[j],n=nrow(data),events=sum(fit$y))}))
 }
 lfit<-function(rhs,o,design)pfit(rhs,o,design,family=quasibinomial(link="logit"),influence=TRUE)
 res<-list();keep<-function(tab,...)res[[length(res)+1L]]<<-cbind(data.table(...),tab)
 des<-mkdes(base)
 adom<-function(d,g,o)subset(d,known_stroke & complete & !is.na(get(o)) & (g=="All ages" | age_group==g))
 for(o in c("any_barrier","bills"))for(g in c("All ages","18-64","65+"))
  keep(marg(lfit(paste("strokef +",dem),o,adom(des,g,o)),"strokef"),analysis="Stroke vs no stroke",outcome=o,group=g,covariates="Dem",imputation=0L)
 rhs_cov<-function(v)paste("yearf + splines::ns(age, df=3) + sex + race + region + education + income_group +",v,"+",clin)
 outs<-c("bp_nonuse","chol_nonuse","ed_any","ed_2plus","hosp")
 rhs_for<-function(o,ex)paste(ex,"+",if(o=="bp_nonuse")sub("hypertension + ","",full,fixed=TRUE) else full)
 for(m in 1:M){
  dm<-mkdes(with_income(m))
  for(o in c("any_barrier","bills"))for(g in c("All ages","18-64","65+"))for(cv in c("Soc","Full"))
   keep(marg(lfit(paste("strokef +",if(cv=="Soc")soc else full),o,adom(dm,g,o)),"strokef"),analysis="Stroke vs no stroke",outcome=o,group=g,covariates=cv,imputation=m)
  keep(marg(lfit(rhs_cov("cover_u65"),"any_barrier",subset(dm,stroke & complete & age<65 & !is.na(cover_u65))),"cover_u65"),analysis="Coverage type",outcome="any_barrier",group="18-64",covariates="Full, coverage hierarchy",imputation=m)
  keep(marg(lfit(rhs_cov("cover_65"),"any_barrier",subset(dm,stroke & complete & age>=65 & !is.na(cover_65))),"cover_65"),analysis="Coverage type",outcome="any_barrier",group="65+",covariates="Full, coverage hierarchy",imputation=m)
  for(o in outs){
   keep(marg(lfit(rhs_for(o,"barrierf"),o,subset(dm,stroke & complete & !is.na(get(o)))),"barrierf"),analysis="Barrier and outcome",outcome=o,group="All ages",covariates="Full + any barrier",imputation=m)
   f<-lfit(rhs_for(o,"care_f + rx_f"),o,subset(dm,stroke & complete & !is.na(get(o)) & !is.na(care_f) & !is.na(rx_f)))
   keep(rbind(marg(f,"care_f"),marg(f,"rx_f")),analysis="Barrier and outcome",outcome=o,group="All ages",covariates="Full + care and medication barriers",imputation=m)
  }
  cat("E11 imputation",m,"done",format(Sys.time(),"%H:%M:%S"),"
");flush.console()
 }
 all<-rbindlist(res);fwrite(all,file.path(OUT,"E11_bounded_logistic_imputations.csv"))
 pooled<-all[,{
  if(.N==1L){se<-sqrt(variance);crit<-qt(.975,df);.(PR=exp(coef),lower=exp(coef-crit*se),upper=exp(coef+crit*se),p_reference=p_reference,p_level=p_level,n=n,events=events,imputations=1L)}
  else{q<-MIcombine(results=as.list(coef),variances=lapply(variance,function(x)matrix(x,1,1)),df.complete=min(df));se<-sqrt(q$variance[1,1]);crit<-qt(.975,q$df)
   .(PR=exp(q$coefficients),lower=exp(q$coefficients-crit*se),upper=exp(q$coefficients+crit*se),p_reference=mean(p_reference),p_level=mean(p_level),n=n[1],events=events[1],imputations=.N)}
 },by=.(analysis,outcome,group,covariates,variable,level,reference)]
 fwrite(pooled,file.path(OUT,"E11_bounded_logistic.csv"))
}
writeLines(capture.output(sessionInfo()),file.path(OUT,"R_session_info_extended.txt"))
cat("Extended sections complete:",if(length(args))paste(args,collapse=" ") else "all","\n")
