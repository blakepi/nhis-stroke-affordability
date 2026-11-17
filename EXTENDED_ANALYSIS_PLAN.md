# Extended analysis plan — NHIS stroke affordability

Written 14 November 2026, before any of the estimates below were computed with the project's design-based pipeline.

**Status of these analyses.** They are post hoc and exploratory. They were proposed after a pre-submission review of the manuscript, and a crude look at the same raw files (annual weights, simplified variance, no income imputation) had already been seen when this plan was written. This document fixes the specifications in advance of the proper estimates; it is not a preregistration. The primary analysis and `STUDY_PROTOCOL.md` are unchanged.

## Rules carried over from the primary analysis

- Pooled estimates use `data/processed/full/base.rds`: public PSTRAT/PPSU, 2020 follow-back respondents removed, 2020 partial-sample weight `WTSA_P`, weights divided by seven. The design is declared on all adults and then restricted to the domain.
- Annual estimates use each year's full Sample Adult file and `WTFA_A`.
- Outcome and covariate definitions are those of the primary analysis. Refused, not ascertained and don't know are never recoded as "no".
- Whenever family income is in a model, all ten NCHS imputations are fitted and combined with Rubin's rules (`mitools::MIcombine`, complete-data df = minimum residual design df).
- Associations are prevalence ratios (PRs) from survey-weighted modified Poisson regression. Descriptive proportions use the project's design-adjusted beta intervals and precision screen.
- Covariate sets. **Dem**: year (categorical), age (natural spline, 3 df), sex, race and Hispanic origin, region. **Soc**: Dem plus education, income, four-level insurance. **Full**: Soc plus hypertension, diabetes, coronary heart disease, smoking, fair or poor health, disability.

## New derived variables

| Variable | Definition |
|---|---|
| `care_barrier` | Delayed or forgone medical care because of cost; "no" requires both items answered "no" |
| `rx_barrier` | Forgone prescription because of cost, or (among prescription users) skipped, reduced or delayed medication to save money; "no" requires a known "no" on every applicable item |
| `cover_u65` | `COVER_A`: private; Medicaid and other public; other coverage; uninsured (don't know excluded) |
| `cover_65` | `COVER65_A`: private; dual eligible; Medicare Advantage; Medicare only excluding Medicare Advantage; other coverage (uninsured and don't know excluded from models because of sparse counts) |
| `hdhp` | Among privately insured (plan 1): no deductible (`PRDEDUC1_A`=2); deductible below the high-deductible threshold (`PRHDHP1_A`=1); high deductible (`PRHDHP1_A`=2) |
| `bp_nonuse` | Among adults ever told they had hypertension: not now taking prescribed blood-pressure medication (`HYPMED_A`=2 vs 1) |
| `chol_nonuse` | Among adults ever told they had high cholesterol: not now taking prescribed cholesterol medication (`CHLMED_A`=2 vs 1) |
| `ed_any`, `ed_2plus` | At least one, and at least two, emergency department visits in 12 months (`EMERG12MTC_A`) |
| `hosp` | Hospitalized overnight in 12 months (`HOSPONGT_A`) |
| `bills` | Problems paying medical bills in 12 months, respondent or family (`PAYBLL12M_A`) |
| `worry_any`, `worry_very` | Somewhat or very worried, and very worried, about paying medical bills (`PAYWORRY_A`) |
| `urban4` | `URBRRL` (2013 scheme, 2019–2023) and `URBRRL23` (2023 scheme, 2024–2025), four levels |
| `worked` | Worked last week (`EMPWRKLSWK_A` 2019–2020, `EMPWRKLSW1_A` 2021–2025) |

## Analyses

**E1. Adults without stroke as comparator.** Pooled prevalence of any barrier, care barrier and medication barrier by stroke status within 18–64 and 65+, and within bands 18–44, 45–54, 55–64, 65–74, 75–85. PR for stroke versus no stroke under Dem, Soc and Full within each age group, and overall under Dem and Full.

**E2. National burden.** Average annual weighted number of stroke survivors and of survivors reporting a barrier, overall and by age group, with design-based intervals.

**E3. Age-specific coverage.** Among stroke survivors, the weighted distribution of `cover_u65` and `cover_65`, barrier prevalence in each category, and Full-model PRs with the coverage hierarchy replacing four-level insurance, fitted separately under 65 and at 65 and older (reference: private). The composition of "other coverage" under 65 (Medicare, military) is described. `hdhp` is examined among privately insured survivors under 65 (prevalence and adjusted PR).

**E4. Secondary-prevention medication use.** Among stroke survivors, the proportion taking blood-pressure medication (if hypertensive) and cholesterol medication (if high cholesterol) by barrier status. Full-model PR of non-use for any barrier, and for care and medication barriers entered together. Cross-sectional association only.

**E5. Acute care use.** `ed_any`, `ed_2plus` and `hosp` by barrier status among stroke survivors; Full-model PRs. Hospital use can itself create bills, so direction is not inferred.

**E6. Medical-bill hardship.** `bills`, `worry_any`, `worry_very` by stroke status and age group; Dem and Full PRs for `bills`, stroke versus no stroke, within age group. Among survivors, the proportion with a cost barrier or bill problems.

**E7. Trends by age and domain.**
- Annual observed prevalence (annual weights) of any, care and medication barriers, overall and by age group.
- Annual prevalence standardized on Dem covariates only (logistic model, pooled design, standardized to the pooled stroke-survivor distribution), overall and by age group.
- Linear trend: PR per calendar year from Dem-adjusted modified Poisson models, for the three outcomes within each age group (six tests, Holm-adjusted) and overall.
- Period contrasts for any barrier within age group: 2020–2023 versus 2019, 2024–2025 versus 2019, 2024–2025 versus 2020–2023. Each interview covers the preceding 12 months, so periods overlap policy dates.
- One contrast for the 2025 Part D out-of-pocket cap: medication barrier at 65 and older, 2025 versus 2019–2024.

**E8. Age profile.** Any-barrier prevalence by age from a survey-weighted logistic model with a natural spline (4 df), separately for adults with and without stroke, with pointwise 95% intervals, plus five-year-band estimates. One figure.

**E9. Discontinuity at 65 (secondary).** Local linear probability model with a triangular kernel, bandwidths 5, 7 and 10 years, separate slopes either side of 65, age 65 excluded because the 12-month recall straddles eligibility. Outcomes: any, care and medication barriers, bills, and uninsured (as a check that coverage changes at 65). Adults with and without stroke. Age is recorded in whole years, so this is a coarse design and is reported as exploratory.

**E10. Equity descriptives (secondary).** Among stroke survivors: any-barrier prevalence by race and Hispanic origin, sex, region and `urban4`; Full-model PRs with non-Hispanic White as the reference; Full model with `urban4` added. Under 65: prevalence by `worked`, and the Full model with `worked` added.

## Inference

No hypothesis in E1–E10 was prespecified before the data were examined. All results are reported with 95% confidence intervals and labelled exploratory. Holm adjustment is applied within the six age-by-domain linear trend tests in E7; other contrasts are unadjusted and should be read as descriptive.

## Verification

An independent Python script recomputes a set of descriptive estimates and Taylor standard errors from the raw CSV files (stroke versus no-stroke prevalence by age group, coverage-category prevalences, medication use by barrier status, weighted counts) and compares them with the R output.

## Files

- `scripts/prepare_extended_data.R` → `data/processed/extended/`
- `scripts/extended_analysis.R` → `outputs/extended/*.csv`, `outputs/extended/age_profile.png`
- `scripts/validate_extended.py` → `outputs/extended/validation_extended.json`
- `outputs/extended/EXTENDED_RESULTS.md` — summary of results
