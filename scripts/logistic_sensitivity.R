suppressPackageStartupMessages({library(data.table);library(survey);library(mitools)})
options(survey.lonely.psu="fail")
base<-readRDS("data/processed/full/base.rds");income<-readRDS("data/processed/full/income.rds")
rhs<-"yearf + splines::ns(age, df=3) + sex + race + region + education + income_group + insurance + hypertension + diabetes + coronary + smoking + fairpoor + disability"
results<-list();diagnostics<-list()
margin<-function(fit,v){
 d<-fit$survey.design;data<-d$variables;w<-as.numeric(weights(d));w<-w/sum(w);infl<-attr(fit,"influence")
 lv<-levels(data[[v]]);p<-numeric(length(lv));u<-matrix(0,nrow(data),length(lv))
 for(j in seq_along(lv)){
  nd<-data;nd[[v]]<-factor(lv[j],levels=lv)
  x<-model.matrix(delete.response(terms(fit)),nd,contrasts.arg=fit$contrasts,xlev=fit$xlevels)
  mu<-plogis(as.vector(x%*%coef(fit)));p[j]<-sum(w*mu)
  g<-colSums(x*(w*mu*(1-mu)));u[,j]<-as.vector(infl%*%g)+w*(mu-p[j])
 }
 cov<-survey::svyrecvar(u,d$cluster,d$strata,d$fpc,d$postStrata)
 lapply(2:length(lv),function(j){a<-rep(0,length(lv));a[j]<-1/p[j];a[1]<- -1/p[1]
  list(variable=v,level=lv[j],reference=lv[1],coef=log(p[j]/p[1]),variance=as.numeric(t(a)%*%cov%*%a),df=fit$df.residual,p_reference=p[1],p_level=p[j])})
}
for(m in 1:10){
 d<-copy(base);inc<-income[IMPNUM_A==m];rc<-inc$RATCAT_A[match(paste(d$year,d$HHX),paste(inc$year,inc$HHX))]
 d[,income_group:=factor(fcase(rc%in%1:3,"<100%",rc%in%4:7,"100-199%",rc%in%8:11,"200-399%",rc%in%12:14,"400%+"),levels=c("400%+","200-399%","100-199%","<100%"))]
 des<-svydesign(ids=~PPSU,strata=~PSTRAT,weights=~pooled_weight,data=d,nest=TRUE);cc<-subset(des,stroke & complete)
 for(kind in c("spline","age_group")){
  r<-if(kind=="spline")rhs else sub("splines::ns(age, df=3)","young",rhs,fixed=TRUE)
  fit<-svyglm(as.formula(paste("any_barrier ~",r)),cc,family=quasibinomial(),influence=TRUE)
  stopifnot(fit$converged)
  for(v in if(kind=="spline")c("income_group","insurance","disability") else "young"){
   a<-rbindlist(margin(fit,v));a[,imputation:=m];results[[length(results)+1L]]<-a
  }
  diagnostics[[length(diagnostics)+1L]]<-data.table(imputation=m,model=kind,n=nrow(cc$variables),converged=fit$converged,min_fitted=min(fitted(fit)),max_fitted=max(fitted(fit)))
 }
 cat("Bounded sensitivity imputation",m,"\n");flush.console()
}
all<-rbindlist(results);fwrite(all,"outputs/full/logistic_sensitivity_imputations.csv")
pooled<-all[,{
 q<-MIcombine(results=as.list(coef),variances=lapply(variance,function(x)matrix(x,1,1)),df.complete=min(df));se<-sqrt(q$variance[1,1]);ci<-qt(.975,q$df)*se
 .(PR=exp(q$coefficients),lower=exp(q$coefficients-ci),upper=exp(q$coefficients+ci),p_reference=mean(p_reference),p_level=mean(p_level))
},by=.(variable,level,reference)]
fwrite(pooled,"outputs/full/logistic_sensitivity.csv");fwrite(rbindlist(diagnostics),"outputs/full/logistic_diagnostics.csv");print(pooled)
