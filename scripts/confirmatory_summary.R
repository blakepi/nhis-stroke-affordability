# Collects the four registered confirmatory tests (REGISTERED_ANALYSIS_PLAN.md, Section 2) into one table with the
# registered decision rules, and adds the registered sensitivity analysis "Holm adjustment across all four".
# Added after registration to implement that sensitivity analysis (DEVIATIONS.md, item 3); reads only result files.
# Output: outputs/confirmatory_summary.csv
suppressPackageStartupMessages(library(data.table))
m<-fread("outputs/meps/real/confirmatory_runs.csv")[hypothesis %in% c("H1","H2")]
b<-fread("outputs/brfss/did_real/confirmatory_runs.csv")
s<-rbind(
 m[,.(hypothesis,data=c(H1="MEPS 2019-2024",H2="MEPS 2019-2024")[hypothesis],estimand="Adjusted prevalence ratio",estimate=PR,lower,upper,p,p_family=p_holm,n)],
 b[,.(hypothesis=c("H3","H4"),data="BRFSS 2011-2019",estimand="ATT, percentage points",estimate=100*ATT,lower=100*lower,upper=100*upper,p,p_family=p,n)])
# Family rules: MEPS Holm across H1-H2 (direction PR<1 for H1, PR>1 for H2); BRFSS fixed sequence H3 -> H4 (ATT<0).
s[,direction_ok:=c(estimate[1]<1,estimate[2]>1,estimate[3]<0,estimate[4]<0)]
s[,supported:=p_family<0.05 & direction_ok]
s[hypothesis=="H4",supported:=supported & s[hypothesis=="H3",supported]]
s[,decision:=fcase(supported,"Supported",hypothesis=="H4" & !s[hypothesis=="H3",supported],"Not tested (gate)",default="Not supported")]
# Registered no-effect rule for a null H4: inconclusive unless the 95% CI excludes +/-3 points; H1/H2 equivalence bounds in Section 6.
s[,null_interpretation:=fcase(supported,NA_character_,
  hypothesis=="H4" & lower>-3 & upper<3,"No effect larger than 3 points",hypothesis=="H4","Inconclusive (95% CI includes effects of 3 points)",
  hypothesis=="H1" & lower>0.80 & upper<1.25,"No meaningful association",hypothesis=="H2" & lower>0.87 & upper<1.15,"No meaningful association",default="Inconclusive")]
s[,p_holm_all4:=p.adjust(p,"holm")]
fwrite(s,"outputs/confirmatory_summary.csv");print(s)
