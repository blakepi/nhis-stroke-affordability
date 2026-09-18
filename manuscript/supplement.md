# Supplementary Material for Healthcare Affordability Barriers Among US Stroke Survivors

Working supplement prepared 18 September 2026. This document accompanies the 2019–2025 NHIS manuscript. Tables contain analysis results, not illustrative values. References use the numbering in the main manuscript.

## Supplementary Methods

### Sources and harmonization

Seven annual Sample Adult ZIP files, seven annual income ZIP files, and the special 2020 partial Sample Adult file supplied the microdata. The source manifest also includes seven annual adult codebooks, seven survey descriptions, and seven income technical documents. It records the download URL, size, and SHA-256 for each of the 36 files. Source files were downloaded on 18 September 2026. The original planning report informed project selection; its embedded citation tokens and implementation suggestions were checked against primary sources rather than treated as governing instructions.

The questionnaire crosswalk contains the exact questions, universes, and PDF pages for core variables in each year. A separate covariate crosswalk documents education, coverage, clinical variables, smoking, and disability. Questionnaire text was compared after normalizing capitalization for the 2019 prescription-use question. A reported stroke was a prior clinician diagnosis; neither subtype nor recency was inferred.

Annual estimates retain the full 2020 adult file, including followback observations, and use WTFA_A. Pooled estimates instead retain only records linked to adultpart20 and use WTSA_P for 2020. Household identifiers are matched within year, and the partial-file HHX_2020 field is matched to the annual HHX field. All other annual weights are WTFA_A. Dividing pooled weights by seven yields an average annual target population. No population total is presented as a count of unique survivors across the seven years.

Survey designs are defined before restricting to the stroke domain. The same published PSTRAT/PPSU identifiers are used across years, following the 2025 Survey Description. Domain variance calculations retain the parent design rather than treat the selected stroke sample as a simple random sample. No finite population correction beyond the survey package defaults was supplied. A singleton PSU in the underlying design would cause the analysis to fail rather than be silently assigned an arbitrary adjustment.

### Outcome classification

### Outcome definitions

| Measure | NHIS variables | Universe |
| --- | --- | --- |
| Stroke history | STREV_A | All sample adults |
| Delayed medical care | MEDDL12M_A | All sample adults |
| Forgone medical care | MEDNG12M_A | All sample adults |
| Forgone needed prescriptions | RXDG12M_A | All sample adults |
| Prescription use | RX12M_A | All sample adults |
| Dose skipping, dose reduction, delayed filling | RXSK12M_A; RXLS12M_A; RXDL12M_A | RX12M_A=1 |
| Any affordability barrier | Any applicable positive among six items | Known applicability and response rules described below |





Responses coded 1 and 2 indicate yes and no. Refusal, not ascertained, don't know, and missing values do not become no. Any applicable yes identifies a positive composite, even if a different component is unknown. An all-negative composite requires every applicable response to be known. For the primary composite, RX12M_A=2 is an explicit nonuse branch; the conditional questions themselves remain structurally blank. If prescription use is unknown and all universal questions are negative, the primary outcome is unknown. The prescription-underuse denominator includes only respondents with RX12M_A=1 and a classifiable underuse outcome. This distinction is essential when reproducing the analysis.

### Covariate definitions

| Domain | Variables | Analysis categories |
| --- | --- | --- |
| Age | AGEP_A | 18–85; 85 is top-coded; natural spline or 18–64/65+ |
| Sex | SEX_A | Male; female |
| Race/Hispanic origin | HISPALLP_A | Seven published categories |
| Region | REGION | Northeast; Midwest; South; West |
| Education | EDUC_A; EDUCP_A | Four harmonized attainment groups |
| Income | RATCAT_A; IMPNUM or IMPNUM_A | <100%; 100–199%; 200–399%; ≥400% FPL |
| Insurance | NOTCOV_A and seven coverage indicators | Private; public without private; military only; uninsured |
| Clinical history | HYPEV_A; DIBEV_A; CHDEV_A | Yes/no hypertension, diabetes, coronary disease |
| Smoking | SMKCIGST_A | Never; former; current; indeterminate missing |
| Self-rated health | PHSTAT_A | Fair/poor vs good/very good/excellent |
| Disability | DISAB3_A | Published Washington Group disability recode |





Insurance presence codes 1 and 2 both mean coverage is present; they differ in the availability of additional information. Code 3 means absence for the individual coverage indicators. The uninsured variable NOTCOV_A uses a different coding convention: 1 means not covered and 2 means covered. The hierarchy assigns private coverage first among covered respondents, then public without private coverage, then military only when all other listed coverage indicators are explicitly absent. Ambiguous coverage is missing. Private coverage may coexist with public or military coverage, and public without private coverage may coexist with military coverage. Military-only status is therefore deliberately narrower than any military coverage.

Income uses RATCAT_A instead of rounded income-to-poverty ratios. Categories 1–3 correspond to below 100% FPL, 4–7 to 100%–199%, 8–11 to 200%–399%, and 12–14 to at least 400%. The imputation index is named IMPNUM in 2019–2020 and IMPNUM_A thereafter. All ten annual imputations were linked by year, household, and index, with duplicate-key and complete-match assertions. The point estimate in a descriptive income row is the mean of the ten completed-data weighted percentages. Fractional unweighted income counts are averages over imputations, not fractional respondents.

### Estimands and models

The primary descriptive estimand is the weighted prevalence of any affordability barrier among noninstitutionalized adults reporting prior stroke and a classifiable outcome. Adjusted PRs condition on the stated covariate set. They are not causal effects, incidence ratios, or recurrence estimates. Model 1 adjusts for categorical year, age spline, sex, race/Hispanic origin, and region. Model 2 adds education, income, and insurance. Model 3 adds hypertension, diabetes, coronary heart disease, smoking, self-rated health, and disability. All three models use the same 6,777 records. The age-group sequence substitutes an age-group indicator for the age spline.

For each model, the coefficient vector is averaged over the ten imputations. Total covariance equals average within-imputation survey covariance plus 1.1 times the between-imputation coefficient covariance. Confidence intervals use the finite-sample degrees of freedom returned by mitools::MIcombine, supplied with the minimum complete-data residual design degrees of freedom across the fits. Poisson coefficients are exponentiated to obtain PRs. This procedure propagates income-imputation uncertainty but does not impute missing outcomes or other covariates.

For annual standardized prevalence, the fitted logistic model assigns each person to each survey year in turn while keeping their other covariates fixed. The predicted probabilities are averaged using the pooled complete-case weights. The linearized contribution includes the regression-coefficient influence multiplied by the prediction gradient and the weighted deviation of each predicted probability from its standardized mean. Their joint covariance therefore includes uncertainty in the reference population distribution and its covariance with model estimation. Before standardization, the exported regression influences were checked against the model covariance. Imputation-specific margins and their covariance were pooled on the logit scale. The 2025-minus-2019 absolute contrast was pooled directly on the probability scale.

The bounded logistic sensitivity applies the same standardization to income, insurance, disability, and the separate age-group model. Each comparison assigns the full reference sample to the comparison and reference categories and forms their prevalence ratio. These marginal estimands differ from conditional modified Poisson PRs and can involve extrapolation to covariate combinations with limited support; agreement is a model-sensitivity observation, not proof of correct specification or positivity.

The categorical-year and year-by-age-group tests use a pooled Wald F statistic based on the selected coefficients and their Rubin total covariance. The denominator degrees of freedom are the minimum scalar pooled degrees of freedom for those coefficients. This is an approximate multivariate test, not a specialized D1 or D2 multiple-imputation test. With the observed small income-related missing-information fractions for year terms, it supplies a practical exploratory summary; the tables and intervals remain the primary description of annual variation.

### Confidence intervals and precision screen

Annual observed confidence intervals are design-based logit intervals. For pooled component estimates, an effective sample size is calculated from prevalence and its Taylor variance, capped by the observed sample size and adjusted by the squared ratio of the 0.975 normal quantile to the corresponding design-t quantile. Beta quantiles based on that effective sample size provide bounded intervals. This is a documented design-adjusted beta implementation rather than a claim of exact certification against every NCHS production rule. Subgroup intervals use logit pooling across imputations; nonincome subgroup point estimates are unchanged across those imputations.

The screening rule flags a proportion when its unweighted or variance-based effective sample size is below 30, its confidence-interval width exceeds 0.30, or its width exceeds 0.05 and is more than 130% of the smaller of the estimate and its complement. Design degrees of freedom below eight prompt review. These checks are informed by NCHS guidance.[12] The unknown-insurance subgroup is flagged and its unstable prevalence is omitted from the formatted subgroup table. Main annual, component, and reported pooled subgroup estimates pass the implemented screen. This screen does not establish reliability for every regression coefficient or small race/insurance subgroup contrast.

### Sensitivity analyses and implementation checks

The component models use the primary-model complete-covariate population restricted to observed values of the component, preserving a comparable adjustment sample. Their denominators therefore differ from the broader component prevalence denominators. The no-disability model omits the disability term. The working-age model retains a continuous-age spline within ages 18–64. The no-2020 model removes 2020 records and its year level; keeping the common factor of one-seventh in weights does not affect model coefficients or their linearized variance. The missing-category diagnostic retains the 7,104 observed primary outcomes and includes explicit unknown levels for incomplete nonincome factors.

All 160 modified Poisson fits converged. The full model had 14–16 fitted values above one per imputation, with maximum values approximately 1.9. The bounded logistic sensitivity used 20 additional fits, all converged. These diagnostic findings are disclosed rather than treating log-link fitted values as valid individual probabilities. The main standardized-year fits also converged.

Independent Python verification reconstructed 12 annual or pooled primary estimates and Taylor standard errors directly from the downloaded ZIPs. A separate NumPy Newton algorithm reproduced the first-imputation full modified Poisson model using the exported design matrix; maximum absolute coefficient discrepancy was below 3×10^-13 and maximum covariance discrepancy below 3×10^-9. Rubin coefficient means and total standard errors were independently checked for all 16 model specifications. This verifies numerical implementation within the stated scope; it is not an independent recreation of all clinical recodes or a validation of the study's causal interpretation.

### Analysis development and reporting boundaries

The project was initiated from a planning report and initial descriptive results were reviewed before completing the full covariate specification. The analysis is consequently not described as preregistered or outcome-blinded. The report's five-imputation suggestion was corrected to ten using the actual CDC files. Employment was omitted because it overlaps strongly with age/disability and required additional harmonization choices outside the final adjustment set. A year-by-insurance interaction was not fit because the military-only group had 109 observed records and 17 events across all years. No data-driven significance rule selected the final model. Alternative handling of the ten unknown-age records and detailed disability-domain models were not undertaken and are not necessary to reproduce the presented estimates.

## Supplementary tables

### Table S1 Annual and pooled cohort counts

| Year | Annual stroke | Annual outcome observed | Pooled stroke | Pooled outcome observed | Pooled events |
| --- | --- | --- | --- | --- | --- |
| 2019 | 1201 | 1191 | 1201 | 1191 | 231 |
| 2020 | 1059 | 1051 | 685 | 679 | 105 |
| 2021 | 1010 | 1001 | 1010 | 1001 | 179 |
| 2022 | 1008 | 999 | 1008 | 999 | 147 |
| 2023 | 1131 | 1116 | 1131 | 1116 | 169 |
| 2024 | 1244 | 1229 | 1244 | 1229 | 215 |
| 2025 | 902 | 889 | 902 | 889 | 138 |

Annual stroke records total 7,555; pooled stroke records total 7,181. The difference comes from excluding 2020 followback records in pooled analyses. These are unweighted counts.

### Table S2 Missing nonincome variables in the pooled stroke sample

| Variable | Missing n | Missing % |
| --- | --- | --- |
| any_barrier | 77 | 1.07 |
| age | 0 | 0.00 |
| sex | 0 | 0.00 |
| race | 0 | 0.00 |
| region | 0 | 0.00 |
| education | 35 | 0.49 |
| insurance | 34 | 0.47 |
| hypertension | 9 | 0.13 |
| diabetes | 10 | 0.14 |
| coronary | 68 | 0.95 |
| fairpoor | 11 | 0.15 |
| smoking | 253 | 3.52 |
| disability | 0 | 0.00 |

Denominator is 7,181 stroke records. Missingness overlaps across variables; the counts must not be summed to derive complete cases. Among records with observed primary outcomes, 327 had at least one missing adjustment variable.

### Table S3 Full characteristics of the pooled outcome observed sample

| Characteristic | Overall N=7,104 | No barrier N=5,920 | Any barrier N=1,184 |
| --- | --- | --- | --- |
| Age 65 years or older | 4,763 (59.0) | 4,237 (64.0) | 526 (35.9) |
| Age 18–64 years | 2,341 (41.0) | 1,683 (36.0) | 658 (64.1) |
| Male | 3,269 (48.5) | 2,777 (49.7) | 492 (43.3) |
| Female | 3,835 (51.5) | 3,143 (50.3) | 692 (56.7) |
| Hispanic, any race | 599 (11.5) | 478 (11.2) | 121 (12.8) |
| Non-Hispanic White only | 5,052 (66.6) | 4,279 (67.6) | 773 (61.7) |
| Non-Hispanic Black only | 1,068 (15.8) | 852 (14.9) | 216 (19.7) |
| Non-Hispanic Asian only | 171 (3.3) | 146 (3.5) | 25 (2.4) |
| Non-Hispanic AIAN only | 77 (0.9) | 66 (0.9) | 11 (0.8) |
| Non-Hispanic AIAN with another race | 91 (1.3) | 63 (1.1) | 28 (1.8) |
| Other single or multiple races | 46 (0.7) | 36 (0.6) | 10 (0.8) |
| Northeast | 1,032 (15.6) | 901 (16.4) | 131 (11.8) |
| Midwest | 1,681 (22.0) | 1,405 (22.3) | 276 (20.6) |
| South | 2,942 (43.1) | 2,362 (41.0) | 580 (52.7) |
| West | 1,449 (19.4) | 1,252 (20.3) | 197 (15.0) |
| Bachelor's degree or higher | 1,670 (20.1) | 1,437 (20.6) | 233 (17.4) |
| Some college or associate | 2,149 (28.7) | 1,743 (28.2) | 406 (30.9) |
| High school or GED | 2,202 (32.3) | 1,848 (32.6) | 354 (30.8) |
| Less than high school | 1,050 (18.3) | 866 (18.0) | 184 (19.7) |
| Education unknown | 33 (0.6) | 26 (0.5) | 7 (1.2) |
| Income ≥400% FPL | 1,681.2 (24.2) | 1,559.9 (27.0) | 121.3 (11.0) |
| Income 200–399% FPL | 2,133.3 (31.0) | 1,786.9 (31.0) | 346.4 (31.2) |
| Income 100–199% FPL | 1,986.9 (27.5) | 1,549.6 (25.6) | 437.3 (36.0) |
| Income <100% FPL | 1,302.6 (17.4) | 1,023.6 (16.4) | 279.0 (21.8) |
| Private, with or without public coverage | 2,888 (40.3) | 2,465 (40.9) | 423 (37.2) |
| Public without private | 3,871 (53.6) | 3,263 (54.9) | 608 (47.4) |
| Military only | 109 (1.6) | 92 (1.6) | 17 (1.7) |
| Uninsured | 207 (4.0) | 80 (2.0) | 127 (13.2) |
| Insurance unknown | 29 (0.5) | 20 (0.5) | 9 (0.6) |
| No hypertension | 1,747 (25.7) | 1,455 (25.3) | 292 (27.8) |
| Hypertension | 5,349 (74.2) | 4,458 (74.6) | 891 (72.1) |
| Hypertension unknown | 8 (0.1) | 7 (0.1) | 1 (0.1) |
| No diabetes | 5,136 (71.3) | 4,330 (72.3) | 806 (66.9) |
| Diabetes | 1,960 (28.6) | 1,583 (27.6) | 377 (33.0) |
| Diabetes unknown | 8 (0.1) | 7 (0.1) | 1 (0.0) |
| No coronary heart disease | 5,212 (74.0) | 4,369 (74.8) | 843 (70.8) |
| Coronary heart disease | 1,828 (25.2) | 1,500 (24.5) | 328 (28.4) |
| Coronary heart disease unknown | 64 (0.7) | 51 (0.7) | 13 (0.8) |
| Never smoked | 3,196 (46.0) | 2,710 (46.6) | 486 (43.5) |
| Former smoker | 2,592 (34.0) | 2,240 (35.5) | 352 (27.2) |
| Current smoker | 1,132 (16.8) | 821 (14.7) | 311 (26.3) |
| Smoking unknown | 184 (3.2) | 149 (3.2) | 35 (3.0) |
| Good or better self-rated health | 3,607 (48.0) | 3,201 (51.6) | 406 (31.7) |
| Fair or poor self-rated health | 3,486 (51.9) | 2,712 (48.3) | 774 (68.1) |
| Self-rated health unknown | 11 (0.1) | 7 (0.1) | 4 (0.2) |
| Without disability | 4,384 (61.2) | 3,742 (62.3) | 642 (56.3) |
| With disability | 2,720 (38.8) | 2,178 (37.7) | 542 (43.7) |

Cells are unweighted n (survey-weighted column percentage). Income counts are averages across ten imputations and may be fractional. Unknown values remain in column denominators. Categories within each variable sum to approximately 100% because of rounding. FPL, federal poverty level. AIAN, American Indian or Alaska Native. The race/Hispanic-origin categories follow the published public-use recode.

### Table S4 Pooled component prevalence

| Outcome | Observed n | Events | Weighted % (95% CI) |
| --- | --- | --- | --- |
| Any affordability barrier | 7104 | 1184 | 17.9 (16.8–19.1) |
| Three universal questions | 7106 | 1012 | 15.5 (14.3–16.6) |
| Delayed medical care | 7116 | 554 | 8.5 (7.7–9.4) |
| Forgone medical care | 7115 | 541 | 8.4 (7.6–9.3) |
| Forgone needed prescriptions | 7103 | 647 | 10.0 (9.1–11.0) |
| Medication underuse among users | 6754 | 635 | 10.1 (9.2–11.1) |

Components overlap. Medication-underuse estimates use prescription users only. Each prevalence denominator includes all stroke records with a classifiable corresponding outcome; it is not restricted to complete model covariates. All displayed estimates pass the implemented precision screen.

### Table S5 Full Model 3 associations

| Contrast | aPR (95% CI) | P value |
| --- | --- | --- |
| Year 2020 vs 2019 | 0.89 (0.69–1.14) | 0.351 |
| Year 2021 vs 2019 | 0.96 (0.78–1.19) | 0.702 |
| Year 2022 vs 2019 | 0.84 (0.67–1.04) | 0.112 |
| Year 2023 vs 2019 | 0.85 (0.69–1.05) | 0.140 |
| Year 2024 vs 2019 | 1.06 (0.87–1.29) | 0.569 |
| Year 2025 vs 2019 | 0.89 (0.71–1.10) | 0.274 |
| Female vs male | 1.27 (1.12–1.43) | <0.001 |
| Non-Hispanic White only vs Hispanic | 1.20 (0.95–1.51) | 0.124 |
| Non-Hispanic Black only vs Hispanic | 1.14 (0.88–1.48) | 0.323 |
| Non-Hispanic Asian only vs Hispanic | 0.78 (0.45–1.35) | 0.367 |
| Non-Hispanic AIAN only vs Hispanic | 0.82 (0.42–1.61) | 0.570 |
| Non-Hispanic AIAN with another race vs Hispanic | 1.06 (0.69–1.63) | 0.800 |
| Other single or multiple races vs Hispanic | 1.26 (0.71–2.25) | 0.431 |
| Midwest vs Northeast | 1.21 (0.97–1.50) | 0.098 |
| South vs Northeast | 1.42 (1.15–1.75) | <0.001 |
| West vs Northeast | 1.24 (0.96–1.61) | 0.095 |
| Some college/associate vs bachelor's or higher | 0.89 (0.75–1.06) | 0.202 |
| High school/GED vs bachelor's or higher | 0.75 (0.62–0.89) | 0.001 |
| Less than high school vs bachelor's or higher | 0.80 (0.64–0.99) | 0.038 |
| Income 200–399% vs ≥400% FPL | 2.07 (1.65–2.61) | <0.001 |
| Income 100–199% vs ≥400% FPL | 2.50 (1.94–3.21) | <0.001 |
| Income <100% vs ≥400% FPL | 2.00 (1.52–2.63) | <0.001 |
| Public without private vs private | 0.72 (0.63–0.83) | <0.001 |
| Military only vs private | 0.81 (0.52–1.28) | 0.372 |
| Uninsured vs private | 1.79 (1.49–2.16) | <0.001 |
| Hypertension vs none | 0.99 (0.86–1.14) | 0.863 |
| Diabetes vs none | 1.12 (0.97–1.30) | 0.126 |
| Coronary heart disease vs none | 1.37 (1.18–1.58) | <0.001 |
| Former vs never smoking | 0.98 (0.85–1.14) | 0.820 |
| Current vs never smoking | 1.21 (1.04–1.42) | 0.015 |
| Fair/poor vs good or better health | 1.58 (1.37–1.82) | <0.001 |
| Disability vs none | 1.19 (1.05–1.35) | 0.006 |

The model includes an age spline with 3 degrees of freedom. Spline basis coefficients and the intercept are retained in model_coefficients.csv; they do not individually represent clinical group contrasts. No multiplicity correction was applied. Sparse race and military-coverage contrasts require caution.

### Table S6 Selected associations in sensitivity analyses

| Analysis | n | Income 100–199% vs ≥400% FPL | Uninsured vs private | Disability vs none |
| --- | --- | --- | --- | --- |
| Exclude 2020 | 6,124 | 2.59 (2.00–3.36) | 1.82 (1.49–2.21) | 1.18 (1.04–1.34) |
| Age 18–64 only | 2,231 | 2.33 (1.67–3.25) | 1.85 (1.51–2.27) | 1.08 (0.92–1.27) |
| No disability | 4,209 | 2.50 (1.79–3.47) | 1.80 (1.42–2.28) | Not applicable |
| Universal composite | 6,776 | 2.45 (1.87–3.22) | 2.09 (1.70–2.57) | 1.26 (1.10–1.45) |
| Delayed medical care | 6,774 | 2.58 (1.76–3.79) | 2.69 (1.98–3.66) | 1.35 (1.10–1.65) |
| Forgone medical care | 6,776 | 2.46 (1.66–3.65) | 2.99 (2.23–4.00) | 1.40 (1.15–1.71) |
| Forgone prescriptions | 6,775 | 2.52 (1.75–3.65) | 2.09 (1.58–2.77) | 1.24 (1.04–1.49) |
| Medication underuse | 6,449 | 2.85 (2.01–4.03) | 1.74 (1.32–2.31) | 1.23 (1.03–1.48) |
| Unknown-category diagnostic | 7,104 | 2.45 (1.91–3.14) | 1.85 (1.55–2.21) | 1.16 (1.03–1.31) |

Cells are aPRs (95% CIs) from the corresponding fully adjusted model. No-disability models omit the disability term. The complete coefficient sets, including all income categories, are supplied as CSV. Working-age disability estimates are compatible with no association. Outcome-specific model denominators differ from Table S4 because they require complete adjustment variables.

### Table S7 Bounded logistic standardized sensitivity

| Contrast | Marginal PR (95% CI) | Reference % | Comparison % |
| --- | --- | --- | --- |
| Income 200–399% FPL vs Income ≥400% FPL | 1.99 (1.59–2.49) | 9.6 | 19.0 |
| Income 100–199% FPL vs Income ≥400% FPL | 2.41 (1.88–3.09) | 9.6 | 23.0 |
| Income <100% FPL vs Income ≥400% FPL | 1.91 (1.45–2.51) | 9.6 | 18.3 |
| Public without private vs Private, with or without public coverage | 0.72 (0.63–0.83) | 20.1 | 14.5 |
| Military only vs Private, with or without public coverage | 0.83 (0.52–1.32) | 20.1 | 16.7 |
| Uninsured vs Private, with or without public coverage | 1.99 (1.63–2.43) | 20.1 | 40.0 |
| With disability vs Without disability | 1.18 (1.04–1.33) | 16.7 | 19.6 |
| Age 18–64 years vs Age 65 years or older | 2.13 (1.86–2.44) | 12.0 | 25.5 |

Logistic predictions remain between zero and one. Marginal PRs are pooled on the log scale; displayed prevalences are arithmetic means of imputation-specific margins, so their displayed ratio may differ slightly from the pooled PR. The age contrast uses the age-group model. These standardized estimates have a different estimand from conditional modified Poisson PRs.

### Table S8 Pooled prevalence in principal subgroups

| Subgroup | Observed n | Weighted % (95% CI) |
| --- | --- | --- |
| Age 65 years or older | 4,763 | 10.9 (9.8–12.0) |
| Age 18–64 years | 2,341 | 28.0 (25.9–30.2) |
| Income ≥400% FPL | 1681.2 | 8.2 (6.7–10.0) |
| Income 200–399% FPL | 2133.3 | 18.0 (16.0–20.3) |
| Income 100–199% FPL | 1986.9 | 23.5 (21.1–26.1) |
| Income <100% FPL | 1302.6 | 22.5 (19.6–25.6) |
| Private, with or without public coverage | 2,888 | 16.6 (14.9–18.4) |
| Public without private | 3,871 | 15.8 (14.5–17.3) |
| Military only | 109 | 18.2 (11.1–28.4) |
| Uninsured | 207 | 58.7 (50.7–66.3) |
| Without disability | 4,384 | 16.5 (15.1–17.9) |
| With disability | 2,720 | 20.2 (18.4–22.1) |

Income counts are averages across ten imputations. The unknown-insurance subgroup (29 records) failed the precision screen, and its prevalence is not displayed. These are unadjusted subgroup estimates.

### Table S9 Modified Poisson model diagnostics

| Model | n | Events | Fitted >1 per imputation | Largest fitted value | Convergence |
| --- | --- | --- | --- | --- | --- |
| M1 | 6777 | 1117 | 0–0 | 0.517 | All converged |
| M2 | 6777 | 1117 | 3–4 | 1.190 | All converged |
| M3 | 6777 | 1117 | 14–16 | 1.943 | All converged |
| Age_M1 | 6777 | 1117 | 0–0 | 0.466 | All converged |
| Age_M2 | 6777 | 1117 | 3–4 | 1.106 | All converged |
| Age_M3 | 6777 | 1117 | 15–17 | 1.912 | All converged |
| AgeInteraction | 6777 | 1117 | 17–19 | 1.888 | All converged |
| No2020 | 6124 | 1016 | 12–16 | 1.943 | All converged |
| WorkingAge | 2231 | 620 | 14–15 | 2.127 | All converged |
| NoDisability | 4209 | 607 | 5–6 | 1.802 | All converged |
| Universal | 6776 | 955 | 13–17 | 1.972 | All converged |
| Delayed | 6774 | 523 | 3–5 | 1.518 | All converged |
| ForgoneCare | 6776 | 509 | 4–8 | 1.651 | All converged |
| ForgoneRx | 6775 | 610 | 4–6 | 1.488 | All converged |
| RxUnderuse | 6449 | 598 | 5–6 | 1.709 | All converged |
| MissingCategory | 7104 | 1184 | 16–19 | 1.891 | All converged |

Ten fits per specification. Fitted log-link values above one are not interpreted as individual probabilities. The bounded logistic sensitivity supports the major associations; it does not establish perfect specification. Model labels correspond to the accompanying script and coefficient CSV.



## Supplementary Figure 1 Analytic sample selection

![Selection of annual and pooled samples](figures/figureS1_cohort_flow.png)

Annual and pooled samples use different 2020 inclusion and weighting rules. The 7,555 annual stroke records include the full 2020 sample; the 7,181 pooled stroke records exclude 2020 followback records. The model sample additionally requires an observed outcome and complete nonincome adjustment variables. Annual counts are record counts, not unique persons across years.

## Draft STROBE reporting checklist

### STROBE cross sectional checklist

| Item | Location | Coverage |
| --- | --- | --- |
| 1 | Title and abstract | Design, population, period and quantitative findings supplied. |
| 2–3 | Introduction | Background, prior studies and objectives stated. |
| 4–5 | Methods / Study design | Repeated cross-sectional design, public NHIS setting and 2019–2025 period. |
| 6 | Methods / Population; Figure S1 | Eligibility, stroke definition, age exclusion, annual vs pooled selection. |
| 7–8 | Methods / Outcomes and covariates | Definitions, universes and cross-year source verification; crosswalk files included. |
| 9 | Discussion / Limitations | Self-report, nonresponse, institutional exclusion, confounding and missingness addressed. |
| 10 | Methods / Population | All eligible records in the selected years; no formal power-based sample selection. |
| 11 | Methods / Covariates | Age spline and categorical income/education definitions given. |
| 12 | Methods / Analysis; Supplementary Methods | Survey weighting, MI, missingness, interaction and sensitivity procedures. |
| 13 | Results / Sample; Table S1; Figure S1 | Counts and reasons for exclusions; different annual and pooled paths. |
| 14 | Table 1; Tables S2–S3 | Characteristics and missingness; income counts averaged across imputations. |
| 15 | Table 2; Tables S4 and S8 | Outcome counts and annual, component and subgroup estimates. |
| 16 | Table 3; Table S5; Results | Adjusted PRs, covariate sets, precision and absolute annual difference. |
| 17 | Sensitivity Results; Tables S6–S9 | Sensitivity estimates and model diagnostics. |
| 18–21 | Discussion and Conclusions | Key results, limitations, cautious interpretation and generalizability. |
| 22 | Declarations | Author contributions and competing-interests statement supplied; no funding statement is included at the direction of the authors. |

This is a draft reporting map, not certification of submission readiness. Final page numbers and author declarations can be added after journal adaptation.



## Additional data files

Machine-readable aggregate files include all model coefficients and intervals, per-imputation coefficients and covariance matrices, Table 1 counts and weighted percentages, annual and pooled prevalences, standardized contrasts, model diagnostics, missingness, and the complete source manifest. The working package also includes the exact codebook crosswalks and source excerpts. Public microdata are retained separately in the project workspace and can be reacquired with the supplied downloader. Author-specific declarations remain clearly identified in the main manuscript and author information sheet.
