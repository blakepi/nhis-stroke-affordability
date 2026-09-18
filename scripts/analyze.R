# Reproducible first-pass NHIS survey analysis. Run from the project root.
suppressPackageStartupMessages({library(data.table); library(survey); library(ggplot2)})
options(survey.lonely.psu="fail")
dir.create("outputs", showWarnings=FALSE)
dir.create("data/processed", recursive=TRUE, showWarnings=FALSE)
dir.create("data/processed/extracted", recursive=TRUE, showWarnings=FALSE)

read_zip <- function(path, columns=NULL) {
  member <- unzip(path, list=TRUE)$Name
  member <- member[grepl("[.]csv$", member, ignore.case=TRUE)]
  stopifnot(length(member)==1L, basename(member)==member)
  file <- file.path("data/processed/extracted", member)
  if (!file.exists(file)) unzip(path, files=member, exdir="data/processed/extracted")
  fread(file, select=columns, na.strings=c("", "NA"), showProgress=FALSE)
}
yesno <- function(x) fifelse(x==1, 1, fifelse(x==2, 0, NA_real_))
any_known <- function(m) {
  # A positive settles an OR; a negative needs every component observed.
  yes <- rowSums(m==1, na.rm=TRUE)>0
  no <- rowSums(!is.na(m))==ncol(m) & rowSums(m==0,na.rm=TRUE)==ncol(m)
  fifelse(yes, 1, fifelse(no, 0, NA_real_))
}
derive <- function(d) {
  alladult <- as.matrix(d[, lapply(.SD, yesno), .SDcols=c("MEDDL12M_A","MEDNG12M_A","RXDG12M_A")])
  prescription <- as.matrix(d[, lapply(.SD, yesno), .SDcols=c("RXSK12M_A","RXLS12M_A","RXDL12M_A")])
  base <- any_known(alladult)
  rx <- any_known(prescription)
  # Keep all original blanks and explicitly evaluate the applicability branch.
  d[, universal_barrier := base]
  d[, rx_underuse := fifelse(RX12M_A==1, rx, NA_real_)]
  positive <- base==1 | (d$RX12M_A==1 & rx==1)
  negative <- base==0 & (d$RX12M_A==2 | (d$RX12M_A==1 & rx==0))
  d[, any_barrier := fifelse(!is.na(positive) & positive,1,
                            fifelse(!is.na(negative) & negative,0,NA_real_))]
  d[, delayed_care := yesno(MEDDL12M_A)]
  d[, forgone_care := yesno(MEDNG12M_A)]
  d[, forgone_rx := yesno(RXDG12M_A)]
  d[, age := fifelse(AGEP_A %between% c(18,85), as.numeric(AGEP_A), NA_real_)]
  d[, stroke := STREV_A %in% 1 & !is.na(age) & WTFA_A>0]
  d[, age_group := fifelse(age<65,"18-64",fifelse(!is.na(age),"65+",NA_character_))]
  d[, disability := fifelse(DISAB3_A==1,"With disability",fifelse(DISAB3_A==2,"Without disability",NA_character_))]
  d[, sex := factor(fifelse(SEX_A %in% 1:2, SEX_A, NA_real_))]
  d[, race := factor(fifelse(HISPALLP_A %in% 1:7,HISPALLP_A,NA_real_))]
  d[, region := factor(fifelse(REGION %in% 1:4,REGION,NA_real_))]
  d[]
}

# Edge cases that materially affect denominators, independent of survey fitting.
stopifnot(identical(any_known(rbind(c(0,NA),c(1,NA),c(0,0),c(NA,NA))),c(NA_real_,1,0,NA_real_)))

columns <- c("HHX","SRVY_YR","RECTYPE","WTFA_A","PSTRAT","PPSU","STREV_A","AGEP_A",
 "SEX_A","HISPALLP_A","REGION","MEDDL12M_A","MEDNG12M_A","RX12M_A","RXSK12M_A",
 "RXLS12M_A","RXDL12M_A","RXDG12M_A","DISAB3_A","COVER_A","COVER65_A")
records <- list(); flow <- list(); missingness <- list(); freq <- list()
for (y in 2019:2025) {
  d <- read_zip(sprintf("data/raw/%s/adult%scsv.zip",y,substr(y,3,4)), columns)
  stopifnot(!anyDuplicated(d$HHX), all(d$SRVY_YR==y), all(d$RECTYPE==10),
            all(!is.na(d$PSTRAT)), all(!is.na(d$PPSU)), all(d$WTFA_A>0))
  rawvars <- c("STREV_A","MEDDL12M_A","MEDNG12M_A","RX12M_A","RXSK12M_A","RXLS12M_A","RXDL12M_A","RXDG12M_A")
  for (v in rawvars) {
    stopifnot(all(is.na(d[[v]]) | d[[v]] %in% c(1,2,7,8,9)))
    f <- d[, .N, by=c(v)]; setnames(f,v,"raw_code")
    f[, `:=`(year=y, variable=v)]; freq[[length(freq)+1L]] <- f
  }
  for (v in c("RXSK12M_A","RXLS12M_A","RXDL12M_A")) {
    stopifnot(!any(d[[v]] %in% c(1,2) & !(d$RX12M_A %in% 1)))
  }
  d <- derive(d); d[, year:=y]
  s <- d[stroke==TRUE]
  flow[[as.character(y)]] <- data.table(year=y, adults=nrow(d), raw_stroke=sum(d$STREV_A==1,na.rm=TRUE),
     stroke_unknown_age=sum(d$STREV_A==1 & is.na(d$age),na.rm=TRUE), stroke_eligible=nrow(s),
     primary_observed=sum(!is.na(s$any_barrier)), primary_events=sum(s$any_barrier==1,na.rm=TRUE),
     primary_unknown=sum(is.na(s$any_barrier)), prescription_users=sum(s$RX12M_A==1,na.rm=TRUE))
  for (v in c(rawvars,"any_barrier","universal_barrier","rx_underuse","sex","race","region","disability")) {
    x <- s[[v]]
    missingness[[length(missingness)+1L]] <- data.table(year=y, variable=v, denominator=nrow(s),
        blank=sum(is.na(x)), special_codes=if(v %in% rawvars) sum(x %in% c(7,8,9)) else 0L)
  }
  records[[as.character(y)]] <- d
  cat("Built",y,"stroke domain:",nrow(s),"\n")
}
all <- rbindlist(records)
fwrite(rbindlist(flow), "outputs/cohort_flow.csv")
fwrite(rbindlist(missingness), "outputs/missingness.csv")
fwrite(rbindlist(freq), "outputs/raw_response_counts.csv")
saveRDS(all,"data/processed/adults_selected.rds")
fwrite(all[stroke==TRUE],"data/processed/stroke_records.csv")

outcomes <- c("any_barrier","universal_barrier","delayed_care","forgone_care","forgone_rx","rx_underuse")
estimate <- function(design, outcome, domain, year, group, basis) {
  keep <- domain & !is.na(design$variables[[outcome]])
  keep[is.na(keep)] <- FALSE
  dd <- design[keep,]
  n <- nrow(dd$variables); events <- sum(dd$variables[[outcome]])
  if (n<2 || events==0 || events==n) {
    return(data.table(year,group,basis,outcome,n,events,estimate=NA_real_,se=NA_real_,lower=NA_real_,upper=NA_real_,
                      design_df=degf(dd),effective_n=NA_real_,precision_flag="boundary_or_insufficient"))
  }
  fit <- svyciprop(reformulate(outcome),dd,method="logit",df=degf(dd))
  p <- as.numeric(coef(fit)); se <- as.numeric(SE(fit)); ci <- as.numeric(confint(fit))
  direct <- weighted.mean(dd$variables[[outcome]],weights(dd))
  stopifnot(abs(p-direct)<1e-7,ci[1]>=0,ci[2]<=1,ci[1]<=p,ci[2]>=p)
  neff <- p*(1-p)/se^2
  flag <- if(n<30 || neff<30 || se/p>0.30 || degf(dd)<8) "limited_precision" else "passes_initial_screen"
  data.table(year,group,basis,outcome,n,events,estimate=p,se,lower=ci[1],upper=ci[2],design_df=degf(dd),effective_n=neff,precision_flag=flag)
}
annual <- list()
for (y in 2019:2025) {
  d <- records[[as.character(y)]]
  design <- svydesign(ids=~PPSU,strata=~PSTRAT,weights=~WTFA_A,data=d,nest=TRUE)
  for (o in outcomes) {
    annual[[length(annual)+1L]] <- estimate(design,o,d$stroke,y,"All survivors","annual_full_weight")
  }
  for (g in c("18-64","65+")) {
    annual[[length(annual)+1L]] <- estimate(design,"any_barrier",d$stroke & d$age_group==g,y,g,"annual_full_weight")
  }
}
annual <- rbindlist(annual)
fwrite(annual,"outputs/annual_prevalence.csv")

# Per NCHS 2020 Scenario 1: partial weights remove the repeat interviews.
partial <- read_zip("data/raw/2020/adultpart20csv.zip")
stopifnot(!anyDuplicated(partial$HHX_2020), all(partial$HHX_2020 %in% records[['2020']]$HHX))
all[, pooled_weight:=WTFA_A]
all[year==2020, pooled_weight:=partial$WTSA_P[match(HHX,partial$HHX_2020)]]
pooled <- all[!is.na(pooled_weight) & pooled_weight>0]
pooled[, pooled_weight:=pooled_weight/7]
pooled_design <- svydesign(ids=~PPSU,strata=~PSTRAT,weights=~pooled_weight,data=pooled,nest=TRUE)
pooled_results <- list()
for(o in outcomes) pooled_results[[length(pooled_results)+1L]] <- estimate(pooled_design,o,pooled$stroke,0,"All survivors","pooled_2020_partial")
for(g in c("18-64","65+")) pooled_results[[length(pooled_results)+1L]] <- estimate(pooled_design,"any_barrier",pooled$stroke & pooled$age_group==g,0,g,"pooled_2020_partial")
for(g in c("With disability","Without disability")) pooled_results[[length(pooled_results)+1L]] <- estimate(pooled_design,"any_barrier",pooled$stroke & pooled$disability==g,0,g,"pooled_2020_partial")
fwrite(rbindlist(pooled_results),"outputs/pooled_prevalence.csv")
fwrite(pooled[,.(adults=.N,stroke=sum(stroke),primary_observed=sum(stroke & !is.na(any_barrier)),
                primary_events=sum(stroke & any_barrier==1,na.rm=TRUE)),by=year],"outputs/pooled_cohort_flow.csv")

# A first demographic-adjusted model, explicitly not a fully adjusted model.
model_domain <- subset(pooled_design,stroke & !is.na(any_barrier) & !is.na(sex) & !is.na(race) & !is.na(region))
model <- svyglm(any_barrier ~ factor(year)+splines::ns(age,df=3)+sex+race+region,
                design=model_domain,family=quasipoisson(link="log"))
stopifnot(model$converged,all(is.finite(coef(model))))
ci <- confint(model)
coef_table <- data.table(term=names(coef(model)),log_PR=coef(model),SE=sqrt(diag(vcov(model))),
                         prevalence_ratio=exp(coef(model)),lower=exp(ci[,1]),upper=exp(ci[,2]))
fwrite(coef_table,"outputs/demographic_model.csv")
diagnostics <- data.table(model="demographic_quasi_poisson",n=nrow(model_domain$variables),
   events=sum(model_domain$variables$any_barrier),converged=model$converged,
   fitted_min=min(fitted(model)),fitted_max=max(fitted(model)),fitted_above_one=sum(fitted(model)>1),
   residual_df=model$df.residual,model_rank=model$rank)
fwrite(diagnostics,"outputs/model_diagnostics.csv")
saveRDS(model,"data/processed/demographic_model.rds")

p <- ggplot(annual[outcome=="any_barrier" & group=="All survivors"],aes(year,estimate*100))+
  geom_line(linewidth=.8,color="#176B87")+geom_errorbar(aes(ymin=lower*100,ymax=upper*100),width=.12,color="#176B87")+
  geom_point(size=3,color="#176B87")+scale_x_continuous(breaks=2019:2025)+
  scale_y_continuous(limits=c(0,NA),expand=expansion(mult=c(0,.08)))+
  labs(title="Cost-related barriers among U.S. stroke survivors",
       subtitle="NHIS 2019-2025 | unadjusted survey-weighted prevalence and 95% confidence intervals",
       x=NULL,y="Any affordability barrier (%)",
       caption="Six-item composite with prescription-use applicability rules. Annual full-sample weights.\nPreliminary analysis; annual differences are not a formal trend test.")+
  theme_minimal(base_size=12)+theme(panel.grid.minor=element_blank(),plot.title=element_text(face="bold"),plot.caption=element_text(hjust=0))
ggsave("outputs/annual_prevalence.png",p,width=10,height=6,dpi=170)
writeLines(capture.output(sessionInfo()),"outputs/R_session_info.txt")
cat("\nAnnual primary estimates:\n")
print(annual[outcome=="any_barrier" & group=="All survivors",.(year,n,events,estimate,lower,upper)])
cat("\nPooled primary and subgroup estimates:\n")
print(rbindlist(pooled_results)[outcome=="any_barrier"])
print(diagnostics)
