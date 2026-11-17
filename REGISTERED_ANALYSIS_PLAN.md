# Registered analysis plan: MEPS and BRFSS confirmatory analyses

**Study:** Health coverage and cost-related barriers to care among US stroke survivors.
**Authors:** G. Blake Pierpoint; Alberto E. Musto.
**Registration:** frozen in the commit tagged `prereg-2026-11` in https://github.com/blakepi/nhis-stroke-affordability before any MEPS or BRFSS outcome was examined. Because commit dates can be set by an author, the registration time is the date the tag first appeared on the public remote, together with the timestamp of a GitHub release of the tag archived by Zenodo, if one is created.
**Status of the authors' knowledge at registration:** see "Prior knowledge" below.

## 1. Prior knowledge (declared)

The hypotheses below were generated from exploratory analyses of the National Health Interview Survey (NHIS) 2019–2025, which the authors have seen in full (`outputs/extended/`, `outputs/extended/EXTENDED_RESULTS.md`). Key NHIS estimates among stroke survivors:
- Medicaid or other public coverage vs private coverage, ages 18–64: adjusted PR 0.60 (95% CI 0.48–0.75).
- Dual Medicare-Medicaid vs private coverage, ages 65 and older: PR 0.53 (0.37–0.76).
- Cost barrier and not taking prescribed cholesterol medication: PR 1.27 (1.01–1.60); FDR q = 0.14 across 99 exploratory contrasts.
- The NHIS change at age 65 among survivors was imprecise (−4.0 points, 95% CI −11.2 to 3.2).

The authors have NOT examined any MEPS or BRFSS outcome. Before registration they examined only:
- variable names, labels and whole-file codebook frequencies;
- counts of stroke survivors by year, age group, coverage category, state and treatment cohort;
- validation of the drug-class mapping on the entire MEPS prescribed-medicines file, not linked to any person's barrier status;
- covariate distributions and event studies or discontinuity estimates in which covariates (not outcomes) are the dependent variables;
- results of the analysis code run on simulated outcomes.

MEPS and BRFSS outcomes are stored in separate "sealed" files (`data/processed/meps/meps_outcomes_SEALED.rds`, `data/processed/brfss/brfss_outcomes_SEALED.rds`). The analysis scripts refuse to read them until this tag is on the public remote.

## 2. Confirmatory hypotheses

Each data source is a separate family with familywise α = 0.05 (two-sided). Holm adjustment across all four is reported as a sensitivity analysis.

| # | Data | Hypothesis | Estimand and decision rule |
|---|---|---|---|
| H1 | MEPS 2019–2024 | Medicaid-type coverage is associated with fewer cost barriers than private coverage among stroke survivors | Adjusted prevalence ratio for Medicaid-type (Medicaid/other public at 18–64; dual Medicare-Medicaid at 65+) vs private (private at 18–64; private, usually with Medicare, at 65+). Supported if the Holm-adjusted P < 0.05 (H1 with H2) and PR < 1 |
| H2 | MEPS 2019–2024 | Among survivors with diagnosed high cholesterol, any cost barrier is associated with having no LDL-lowering fill | Adjusted PR for any barrier. Supported if the Holm-adjusted P < 0.05 and PR > 1 |
| H3 | BRFSS 2011–2019 | Medicaid expansion reduced uninsurance among low-income stroke survivors aged 18–64 | Callaway–Sant'Anna overall ATT (simple aggregation), 2014–2016 cohorts; unweighted outcome-regression estimator (Section 4). Supported if P < 0.05 and ATT < 0 |
| H4 | BRFSS 2011–2019 | Medicaid expansion reduced the cost barrier to seeing a doctor in the same population | Same estimator. Tested only if H3 is supported (fixed sequence); supported if P < 0.05 and ATT < 0 |

**Removed before registration.** The draft plan also listed two regression-discontinuity hypotheses at age 65 (H5: uninsurance drops; H6: the cost barrier drops). Outcome-blind checks led us to report these as exploratory instead:
- With survey weights, honest confidence intervals for binary covariates had half-widths of about 7–10 percentage points, and the weighted share of women shifted at 65, consistent with BRFSS raking to age bands that break at 65.
- Unweighted, covariates were continuous at 65 (all intervals included 0), but honest half-widths were still about 2.5–4 points for covariates and about 3.5 points for simulated outcomes.
- Those widths are too large to detect the 3–5 point changes that are plausible among stroke survivors, many of whom already have disability-based Medicare or Medicaid before 65.

The analysis is still run and reported (Section 5).

A null result for any hypothesis will be reported as a null result. "No difference" will not be claimed unless the confidence interval excludes the minimum effects of interest stated in Section 6.

## 3. MEPS design (H1, H2)

Code: `scripts/meps_prepare.R`, `scripts/meps_analysis.R` (run as `Rscript scripts/meps_analysis.R real`).

- **Data.** MEPS Household Component full-year consolidated files 2019–2024 (HC-216, 224, 233, 243, 251, 256) and prescribed-medicines files (HC-213A, 220A, 229A, 239A, 248A, 254A); hashes in `outputs/meps/source_manifest_meps.json`.
- **Design.** Pooled across years using each year's VARSTR and VARPSU, made unique by year, with PSUs nested in strata. Weight PERWTyyF/6. Domain estimation is over the full pooled file, with lonely PSUs handled by `survey.lonely.psu = "adjust"`. Persons appearing in several annual files remain separate person-years; their correlation is absorbed by the design-based variance.
- **Population.** Adults (age ≥18 at round 4/2) with STRKDX = 1 ("ever told had a stroke", which in MEPS includes TIA), eligible for the access supplement (ACCELI42 = 1), with a positive person weight and complete covariates.
- **Outcome (H1): any cost barrier.** "Yes" to any of DLAYCA42 (delayed medical care because of worry about cost), AFRDCA42 (could not afford medical care), DLAYPM42 (delayed prescription medicines because of cost) or AFRDPM42 (could not afford prescription medicines). "No" requires all four answered "no"; refused or don't know is missing.
- **Exposure (H1).** Coverage in June of the survey year, from monthly indicators, mapped to the NCHS hierarchies.
  - Under 65: private (PRIJU) > Medicaid/other public (MCDJU, GVAJU–GVCJU) > other (Medicare, TRICARE, VA) > uninsured.
  - 65 and older: private > dual (Medicare and Medicaid) > Medicare Advantage (MCRPHO for the round covering June) > Medicare only > other > uninsured.
  - Medicaid-type = Medicaid/other public (<65) or dual (65+); comparison = private (either age group). Other categories are excluded from H1.
- **H2 population and outcome.** Survivors as above with CHOLDX = 1. Outcome = no LDL-lowering prescription fill during the year (no PMED record whose Multum drug name contains atorvastatin, rosuvastatin, simvastatin, pravastatin, lovastatin, fluvastatin, pitavastatin, ezetimibe, evolocumab, alirocumab, inclisiran or bempedoic acid). Exposure = any cost barrier (H1 outcome definition).
- **Covariates (both models).** Age group (H1 only), natural spline of age (3 df), sex, race and ethnicity (5 groups), census region, education (4 groups), family income category (POVCAT, 5 groups), survey year, hypertension, diabetes, coronary heart disease (CHD, MI or angina), current smoking, fair or poor health, and disability (any activity, walking, cognitive, ADL or IADL limitation; round 3/1, or round 5/3 where 3/1 was not asked). H2 also adjusts for coverage category within age group; it omits the age-group term, which that variable already encodes.
- **Model.** Survey-weighted modified Poisson regression (`svyglm`, quasi-Poisson, log link) with design-based linearized variance; Wald test with the design degrees of freedom.
- **Negative control (reported with H2, not tested).** Same H2 model with "could not afford dental care" (AFRDDN42) as the exposure. A PR close to the H2 PR would suggest that H2 reflects general financial hardship rather than medication-specific barriers.
- **Registered sensitivity analyses.**
  - Bounded logistic marginal PRs.
  - Excluding 2020.
  - Coverage that is the same in every month of the year.
  - Care and medication barrier domains separately.
  - Age-specific H1 estimates.

## 4. BRFSS difference-in-differences design (H3, H4)

Code: `scripts/brfss_prepare.R`, `scripts/brfss_did.R` (run as `Rscript scripts/brfss_did.R real`).

**Data.** BRFSS annual files 2011–2025 (hashes in `outputs/brfss/source_manifest_brfss.json`). The primary window is 2011–2019, which avoids:
- the 2021 rewording of the coverage, cost-barrier and personal-clinician items;
- 2020 data collection;
- pandemic-era Medicaid continuous enrollment;
- the 2021 marketplace subsidy increases.

**Population.** Respondents aged 18–64 with CVDSTRK3 = 1 ("ever told you had a stroke") and family income at or below 138% of the HHS poverty guideline.
- Income is the midpoint of the reported category (INCOME2; INCOME3 codes 1–7 are identical) divided by the guideline for the survey year, household size and area. Alaska and Hawaii have their own guidelines (`outputs/brfss/hhs_poverty_guidelines.csv`, from the ASPE poverty-guidelines API).
- Household size = adults (NUMADULT, else HHADULT) + children (CHILDREN, 88 = 0). Adults are missing for 14–28% of survivors in 2011–2013 and 15% in 2017, almost entirely cell-phone respondents. For them, adults are imputed from marital status: married or unmarried couple = 2, otherwise 1. Imputed records are flagged.
- Respondents with refused or unknown income are excluded.

**States and timing.**
- Exclusions: DE, DC, MA, NY and VT, which had comparable coverage before 2014. Territories are excluded.
- Treatment year: the implementation year if expansion took effect by July 1, otherwise the next year (`outputs/brfss/expansion_dates.csv`, KFF dates).
- Treated cohorts: 2014 (21 states, including MI), 2015 (NH, PA, IN) and 2016 (AK, MT, LA).
- Controls: states not treated by 2019. VA and ME 2019 observations are dropped so those states serve only as controls. Wisconsin is never treated.
- That leaves 46 state clusters: 27 treated, 19 control.

**Outcomes.**
- H3: uninsured (HLTHPLN1 = 2).
- H4: cost barrier, "was there a time in the past 12 months when you needed to see a doctor but could not because of cost?" (MEDCOST = 1).
- Refused or don't know is missing.

**Estimator.**
- Callaway–Sant'Anna group-time ATTs (`did` 2.5.1, `att_gt`) for repeated cross-sections (panel = FALSE).
- Outcome-regression estimator with covariates age, female, non-White race or Hispanic origin, and high school education or less. Binary covariates avoid sparse cells; a small cohort-year cell was singular with full categorical covariates.
- Not-yet-treated controls; universal base period (2013 for the 2014 cohort).
- Clustered multiplier bootstrap by state (999 iterations).
- **Unweighted.** On simulated outcomes the survey weights (_LLCPWT; Kish design effect about 4.0) roughly doubled the standard error of the overall ATT (about 1.7 vs 3.5 percentage points). The estimand is the effect among low-income survivors in the study states; weighting is not needed for internal validity, so the survey-weighted estimate is a registered sensitivity analysis.
- Confirmatory estimand: the simple overall ATT (`aggte(type = "simple")`).

**Registered diagnostics (reported, not part of the decision rule).**
- Event study for event times −3 to +5, with a Wald test of the two testable pre-period coefficients using a state-clustered covariance (influence functions summed within state).
- HonestDiD relative-magnitude bounds for the average post-period effect at M̄ = 0, 0.5, 1 and 2.
- Falsification groups (expected near 0 for uninsurance): low-income survivors aged 65+, and survivors aged 18–64 above 400% of poverty.
- **Composition checks completed before registration** (covariates as the outcome, same estimator; `outputs/brfss/did_covariates/covariate_att.csv`). Expansion was not associated with changes in:
  - stroke prevalence among low-income adults aged 18–64 (ATT −0.30 points, 95% CI −0.76 to 0.15);
  - the share of women among low-income survivors (0.4 points, −4.1 to 4.9);
  - the share with a college degree (1.7 points, −0.5 to 3.8);
  - mean age (0.08 years, −0.65 to 0.80).
- Sensitivity analyses:
  - survey-weighted (_LLCPWT);
  - doubly robust estimator;
  - Sun–Abraham interaction-weighted estimator (`fixest`), using all pre-periods;
  - drop Wisconsin;
  - never-treated controls only;
  - equal weight per state;
  - income under $25,000 (no household size needed);
  - high school education or less (no income criterion);
  - household size from observed adults only.

## 5. BRFSS regression discontinuity at age 65 (exploratory)

Code: `scripts/brfss_rd.R` (run as `Rscript scripts/brfss_rd.R real`).

- **Population.** BRFSS 2013–2025 respondents with CVDSTRK3 = 1, aged 55–75 by _AGE80 (whole years). Running variable x = age − 65; age 65 is on the treated side.
- **Outcomes.**
  - Uninsured: HLTHPLN1 (2013–2020), or _HLTHPLN, _HLTHPL1 or _HLTHPL2 (2021–2025).
  - Cost barrier to seeing a doctor: MEDCOST or MEDCOST1.
- **Estimator.** `RDHonest` 1.0.3 local linear, triangular kernel. Bandwidth chosen to minimize the honest confidence interval (FLCI criterion); smoothness bound M by the Armstrong–Kolesár rule of thumb; honest 95% confidence intervals. The main estimate is unweighted, because survey weights are raked to age bands that change at 65; a survey-weighted version is also reported.
- **Also reported:**
  - fixed bandwidths of 5 and 10;
  - a donut excluding age 65;
  - doubled M;
  - placebo cutoffs at 60 and 70;
  - WLS with state and year fixed effects;
  - covariate continuity;
  - the first stage (Medicare as primary coverage, PRIMINSR, 2021–2022).
- **Covariate continuity checked before registration** (unweighted; `outputs/brfss/rd_covariates/covariate_continuity.csv`). Female, college, Black and low-income shares showed no discontinuity at 65; all honest intervals included 0.
- **Interpretation.** Estimates and confidence intervals only; no hypothesis test.

## 6. Sample sizes, power and minimum effects of interest

Counts come from `outputs/meps/sample_counts.csv` and `outputs/brfss/sample_counts.csv`. Power comes from simulations that run the registered code on the real design, covariates and exposures with simulated outcomes (`outputs/meps/{synthetic,null}/simulation_summary.csv`, `outputs/brfss/did_{synthetic,null}/simulation_summary.csv`).

**MEPS (2019–2024).** 5,336 person-years of adult, access-eligible stroke survivors from 2,820 people. 1,373 people appear in two annual files, 288 in three and 189 in four.
- **H1** uses 2,959 person-years with complete covariates: 1,334 with Medicaid-type coverage (811 aged 18–64, 523 dual) and 1,625 private (662 aged 18–64, 963 aged 65+).
- **H2** uses 3,607 person-years with diagnosed high cholesterol.
- **Simulation assumptions.**
  - H1 baseline prevalence among the privately insured: 20% (18–64) and 8% (65+).
  - H2: 30% with no LDL-lowering fill.
- **Results with planted effects.**
  - H1, PR 0.6: power 87%, mean estimate 0.58, 95% CI coverage 95%.
  - H2, PR 1.3: power 86%, mean 1.30, coverage 96%.
- **Results with no effect.** Holm-adjusted false-positive rates were 6% (H1) and 4% (H2) across 100 replicates. The dental negative control was null in both scenarios.
- **Minimum effects of interest.** PR 0.80 for H1 and PR 1.15 for H2; smaller effects are not considered clinically meaningful at the population level. A "no association" conclusion requires the 95% CI to lie entirely between 0.80 and 1.25 (H1) or between 0.87 and 1.15 (H2).

**BRFSS difference-in-differences (2011–2019).** About 23,000 low-income survivors aged 18–64 with complete covariates in 46 states (27 treated, 19 control).
- By cohort before the covariate filter: 2014, 9,286; 2015, 1,413; 2016, 1,202; never-expanding states, 6,971; states expanding in 2019 or later (controls within the window), about 4,400.
- **Results with a planted ATT of −5 points** (50 replicates): mean estimate −5.25 points; empirical SD 1.9; mean bootstrap SE 1.7–1.8; 95% CI coverage 92–94%; power 78% for H3 and 60% for H4 under the fixed sequence.
- **Results with no effect:** H3 false-positive rate 4%; H4 was tested twice and never rejected.
- **Detectable effect** at 80% power: about 5.3 points. Published expansion effects on uninsurance among low-income adults are larger than this; an effect on the cost barrier could be smaller, and in that case H4 may be underpowered.
- **No-effect claims:** the design cannot rule out effects smaller than about 3.5 points, so a null H4 will be reported as inconclusive unless its 95% CI excludes ±3 points.

**BRFSS regression discontinuity (exploratory).** About 127,800 stroke survivors aged 55–75 in 2013–2025, with 3,900–8,000 per year of age.

## 7. Exploratory analyses (not confirmatory)

These are reported with point estimates and 95% confidence intervals only. No claim of statistical significance will be made for them.

- **MEPS:**
  - full coverage-category models within each age group (Medicare Advantage vs traditional Medicare vs private at 65+; uninsured and other coverage at 18–64);
  - care-barrier and medication-barrier domains;
  - H2 with care and medication barriers entered jointly;
  - prescription anticoagulant, antiplatelet and antihypertensive fills by coverage;
  - out-of-pocket spending (total, prescription, LDL-lowering drugs) by coverage;
  - family out-of-pocket spending above 10% and 20% of family income.
- **BRFSS difference-in-differences:**
  - no routine checkup in the past year and no personal clinician as outcomes;
  - the full 2011–2025 window with all expansion cohorts, including late expanders (outcome wording changed in 2021);
  - a triple difference against low-income adults without stroke.
- **BRFSS regression discontinuity at 65:** the whole analysis (Section 5).

## 8. Changes from the authors' project plan made before registration

The project plan written on 16 November 2026, before any data were obtained, was changed as follows. Every change was based on outcome-blind information:
1. **Regression discontinuity hypotheses moved to exploratory** (H5/H6 removed), because of power and weighting artifacts (Section 2).
2. **Primary difference-in-differences estimator.** Unweighted outcome regression with binary covariates, instead of the survey-weighted doubly robust estimator with categorical covariates. Simulation showed the weighted standard error was about twice as large; a categorical covariate cell was singular. Both alternatives are registered sensitivity analyses.
3. **Household size** imputed from marital status when the adult count is missing (2011–2013 and 2017). This prevents the low-income definition from changing in 2014.
4. **Race and Hispanic origin** harmonized from _IMPRACE, with _RACEGR3/_RACEGR4 where _IMPRACE is absent (2015–2016).
5. **Robustness analyses dropped.** The wild-cluster bootstrap and randomization inference are not implemented (the `fwildclusterboot` package is no longer on CRAN); clustered inference uses the `did` multiplier bootstrap by state. The stacked-design estimator is also dropped; Sun–Abraham is retained.
6. **MEPS:**
   - Coverage uses June indicators.
   - Medicare Advantage status comes from the round covering the month.
   - Smoking uses OFTSMK53, because ADSMOK42 is absent in 2020, 2022 and 2024.
   - Disability falls back to round 5/3 items when round 3/1 items are missing (mainly 2020).
   - The ICD-code sensitivity analysis (I60–I64, I69) is not done, because it requires the medical-conditions files.
7. **Pipeline null check.** Uses outcomes simulated with no effect instead of permuted real outcomes, so that real outcomes are never read before registration.

## 9. Deviations after registration

Any departure from this plan will be recorded in `DEVIATIONS.md` with its date and reason, and reported in the paper.
