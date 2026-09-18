# Supplementary Material for Healthcare Affordability Barriers Among US Stroke Survivors

Working supplement prepared 18 September 2026. This document accompanies the 2019–2025 NHIS manuscript. Tables contain analysis results, not illustrative values. References use the numbering in the main manuscript.

## Supplementary Methods

### Sources and harmonization

Seven annual Sample Adult ZIP files, seven annual income ZIP files, and the special 2020 partial Sample Adult file supplied the microdata. The source manifest also includes seven annual adult codebooks, seven survey descriptions, and seven income technical documents. It records the download URL, size, and SHA-256 for each of the 36 files. Source files were downloaded on 18 September 2026. The original planning report informed project selection; its embedded citation tokens and implementation suggestions were checked against primary sources rather than treated as governing instructions.

The questionnaire crosswalk contains the exact questions, universes, and PDF pages for core variables in each year. A separate covariate crosswalk documents education, coverage, clinical variables, smoking, and disability. Questionnaire text was compared after normalizing capitalization for the 2019 prescription-use question. A reported stroke was a prior clinician diagnosis; neither subtype nor recency was inferred.

Annual estimates retain the full 2020 adult file, including followback observations, and use WTFA_A. Pooled estimates instead retain only records linked to adultpart20 and use WTSA_P for 2020. Household identifiers are matched within year, and the partial-file HHX_2020 field is matched to the annual HHX field. All other annual weights are WTFA_A. Dividing pooled weights by seven yields an average annual target population. No population total is presented as a count of unique survivors across the seven years.

Survey designs are defined before restricting to the stroke domain. The same published PSTRAT/PPSU identifiers are used across years, following the 2025 Survey Description. Domain variance calculations retain the parent design rather than treat the selected stroke sample as a simple random sample. No finite population correction beyond the survey package defaults was supplied. A singleton PSU in the underlying design would cause the analysis to fail rather than be silently assigned an arbitrary adjustment.

### Outcome classification

{{outcome_definitions}}

Responses coded 1 and 2 indicate yes and no. Refusal, not ascertained, don't know, and missing values do not become no. Any applicable yes identifies a positive composite, even if a different component is unknown. An all-negative composite requires every applicable response to be known. For the primary composite, RX12M_A=2 is an explicit nonuse branch; the conditional questions themselves remain structurally blank. If prescription use is unknown and all universal questions are negative, the primary outcome is unknown. The prescription-underuse denominator includes only respondents with RX12M_A=1 and a classifiable underuse outcome. This distinction is essential when reproducing the analysis.

{{covariate_definitions}}

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

{{supplement_tables}}

## Supplementary Figure 1 Analytic sample selection

![Selection of annual and pooled samples](figures/figureS1_cohort_flow.png)

Annual and pooled samples use different 2020 inclusion and weighting rules. The 7,555 annual stroke records include the full 2020 sample; the 7,181 pooled stroke records exclude 2020 followback records. The model sample additionally requires an observed outcome and complete nonincome adjustment variables. Annual counts are record counts, not unique persons across years.

## Draft STROBE reporting checklist

{{strobe}}

## Additional data files

Machine-readable aggregate files include all model coefficients and intervals, per-imputation coefficients and covariance matrices, Table 1 counts and weighted percentages, annual and pooled prevalences, standardized contrasts, model diagnostics, missingness, and the complete source manifest. The working package also includes the exact codebook crosswalks and source excerpts. Public microdata are retained separately in the project workspace and can be reacquired with the supplied downloader. Author-specific declarations remain clearly identified in the main manuscript and author information sheet.
