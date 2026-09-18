# Implemented NHIS stroke affordability specification

Final working specification, 18 September 2026. This descriptive repeated cross-sectional study was not preregistered. The full covariate specification followed initial descriptive results. The user's report informed project selection; CDC documents govern measurement and design.

## Population and design

NHIS Sample Adult 2019–2025; STREV_A=1, positive applicable weight, valid AGEP_A=18–85 (85 means 85+). Unknown age is excluded and counted. Define the design on all adults before restricting to the stroke domain. Preserve published PSTRAT/PPSU without arbitrary year suffixes, following 2025 guidance.

Annual analyses use full Sample Adult files and WTFA_A. Pooled analyses omit 2020 followback observations by linking to adultpart20 and using WTSA_P, per the 2020 Survey Description pp. 50–52. Other years use WTFA_A; pooled weights are divided by seven. There are 7,555 age-eligible annual stroke records and 7,181 pooled stroke records. Annual counts are not unique persons across years.

## Outcomes

Primary: any applicable yes among MEDDL12M_A, MEDNG12M_A, RXDG12M_A and, when RX12M_A=1, RXSK12M_A, RXLS12M_A, RXDL12M_A. Any yes establishes a barrier. No requires all universal items to be no and either known prescription nonuse or all conditional items to be no. Remaining patterns are unknown. Structural blanks remain missing in source variables. The seven codebooks show consistent substantive wording and universes.

The construct is general healthcare affordability among stroke survivors, not proven interruption of stroke-prevention treatment. Individual medical-care/prescription outcomes, underuse among prescription users and the three universal-question composite are secondary outcomes.

## Covariates and imputations

Age: natural cubic spline, 3 df; sex; seven published race/Hispanic-origin categories; Census region; categorical year. Education harmonizes EDUC_A (2019–2020) and EDUCP_A (2021+) into less than high school, high school/GED, some college/associate and bachelor's or higher.

Income: RATCAT_A groups 1–3, 4–7, 8–11 and 12–14 represent <100%, 100–199%, 200–399% and ≥400% of the poverty threshold. Link income by year and HHX, normalize IMPNUM/IMPNUM_A, and use **all ten imputations**. The initial five-imputation expectation was corrected using the actual files before full-model estimation. Use Rubin pooling with finite complete-data design degrees of freedom.

Insurance: NOTCOV_A identifies uninsured; among covered respondents use private first (including concurrent public), public without private next, then military only with explicit absence of other listed coverage. Individual coverage indicators use 1 or 2 for present and 3 for absent. Ambiguity remains missing. These groups do not measure underinsurance.

Health covariates: hypertension, diabetes, coronary disease, smoking, fair/poor self-rated health, DISAB3_A disability. Disability need not be caused by stroke. Employment is omitted. Nonincome unknowns remain missing. Primary models use 6,777 complete-covariate records and 1,117 events. Descriptives use 7,104 observed outcomes and 1,184 events.

## Models and inference

Modified Poisson with survey-robust covariance: Model 1 year/demographics; Model 2 adds education/income/insurance; Model 3 adds health covariates. Use the same sample throughout. Separate age-group models replace the age spline with 18–64 versus 65+, avoiding conditioning on the age defining the contrast. Attenuation is descriptive, not mediation.

Fully adjusted logistic models standardize annual prevalence to the pooled complete-case covariate distribution. Joint influences include model and reference-distribution uncertainty. Pool margins on the logit scale and the 2025-minus-2019 difference on the probability scale. Year and year-by-age tests use approximate Rubin-pooled Wald F inference with minimum scalar pooled df. No linear trend is imposed. Insurance-by-year interaction is not fit because military-only coverage has 109 observed records and 17 events across all seven years.

Sensitivities: omit 2020; working age only; no disability; universal composite; individual components; missing-category diagnostic; bounded logistic standardized PRs. All 160 Poisson fits converge. Full-model fitted values exceed one in 14–16 records per imputation; these are disclosed and not treated as individual probabilities. Twenty bounded-sensitivity logistic fits also converge.

Annual CIs use a logit method; pooled component CIs use design-adjusted effective-size beta intervals; subgroup CIs use logit pooling. The precision screen is informed by NCHS standards, not certified as an exact production implementation. Unknown-insurance prevalence is omitted from formatted results after failing the screen. No multiplicity adjustment or significance-based model selection is applied.

## Verification and scope

Source manifest: 36 downloaded files with URLs, sizes and SHA-256. Python independently checks primary classification, 12 prevalence/SE estimates, first-imputation full-model coefficients/covariance using the exported matrix, and Rubin pooling across 16 specifications. Figures and Word structure are checked. Word pagination is unverified because LibreOffice is unavailable.

Delivered scope is full working writing, tables, figures, references, supplement, code and a portable package. No journal submission occurred. Author identities, contributions, competing interests and the ethics statement were supplied by the authors; code and aggregate results are public at https://github.com/blakepi/nhis-stroke-affordability. See HANDOFF.md and FILE_INVENTORY.csv.

