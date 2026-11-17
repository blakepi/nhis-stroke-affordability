# Benjamini-Hochberg false-discovery-rate adjustment across the exploratory NHIS contrasts
# reported from the extended analyses (outputs/extended/E1-E10). Run from the project root.
#
# Family definition (fixed before computing q-values): every hypothesis test of an exploratory
# contrast reported in the revised manuscript or supplement. Included:
#   E1  stroke vs no stroke, any barrier and medical bills, 3 age groups x 3 adjustment sets
#   E3  coverage-type terms (both age groups) and deductible type
#   E4/E5  barrier terms for medication nonuse and acute care (single-barrier and joint models)
#   E7  standardized 2025-2019 differences, linear trends, period contrasts, categorical-year tests
#   E9  discontinuity at 65, primary 10-year bandwidth only (5 and 7 years are sensitivity analyses)
#   E10 race and Hispanic origin, urbanization, employment
# Excluded: income and other covariate terms (adjustment variables, not hypotheses), the
# bounded logistic estimates (E11; sensitivity versions of the same contrasts), and the
# within-survivor analyses of the initial protocol.
suppressPackageStartupMessages(library(data.table))
X<-"outputs/extended"
r<-function(f)fread(file.path(X,f))
fam<-rbindlist(list(
 r("E1_E6_stroke_vs_no_stroke_PR.csv")[,.(source="E1",contrast=paste0("Stroke vs no stroke: ",outcome,", ",group,", ",covariates),estimate=PR,lower,upper,p)],
 r("E3_coverage_PR.csv")[grepl("^cover|^hdhp",term),.(source="E3",contrast=paste0(age_group,": ",term),estimate=PR,lower,upper,p)],
 r("E4_E5_barrier_PR.csv")[,.(source="E4/E5",contrast=paste0(outcome,": ",term," (",model,")"),estimate=PR,lower,upper,p)],
 r("E7_standardized_difference_2025_2019.csv")[,.(source="E7",contrast=paste0("2025-2019 standardized difference: ",outcome,", ",group),estimate=difference_2025_minus_2019,lower,upper,p)],
 r("E7_linear_trend_PR_per_year.csv")[,.(source="E7",contrast=paste0("Linear trend: ",outcome,", ",group),estimate=PR,lower,upper,p)],
 r("E7_period_contrasts.csv")[,.(source="E7",contrast=paste0("Period: ",contrast,", ",outcome,", ",group),estimate=PR,lower,upper,p)],
 r("E7_categorical_year_tests.csv")[,.(source="E7",contrast=paste0("Categorical year: ",outcome,", ",group),estimate=NA_real_,lower=NA_real_,upper=NA_real_,p)],
 r("E9_discontinuity_at_65.csv")[bandwidth_years==10,.(source="E9",contrast=paste0("Change at 65: ",outcome,", ",stroke),estimate=jump_at_65,lower,upper,p)],
 r("E10_equity_PR.csv")[,.(source="E10",contrast=paste0(model,": ",term),estimate=PR,lower,upper,p)]
))
stopifnot(!anyNA(fam$p),all(fam$p>=0 & fam$p<=1),!anyDuplicated(fam$contrast))
fam[,q_bh:=p.adjust(p,"BH")]
fam[,holm:=p.adjust(p,"holm")]
fam[,`:=`(nominal_005=p<0.05,fdr_005=q_bh<0.05,fdr_010=q_bh<0.10)]
setorder(fam,p)
fwrite(fam,file.path(X,"E12_fdr_family.csv"))
cat("Contrasts in family:",nrow(fam)," nominal p<0.05:",sum(fam$nominal_005)," q<0.05:",sum(fam$fdr_005)," q<0.10:",sum(fam$fdr_010),"\n")
key<-c("18-64: cover_u65Medicaid and other public","65+: cover_65Dual eligible","18-64: cover_u65Uninsured",
 "chol_nonuse: any_barrier (Full + any barrier)","chol_nonuse: care_barrier (Full + care and medication barriers)",
 "ed_2plus: any_barrier (Full + any barrier)","ed_2plus: rx_barrier (Full + care and medication barriers)",
 "2025-2019 standardized difference: care_barrier, All ages","2025-2019 standardized difference: care_barrier, 65+",
 "Stroke vs no stroke: any_barrier, All ages, Dem","Stroke vs no stroke: bills, All ages, Full","18-64 private: hdhpHigh deductible")
print(fam[contrast %in% key,.(contrast,estimate=round(estimate,3),p=signif(p,3),q_bh=signif(q_bh,3),fdr_005)])
