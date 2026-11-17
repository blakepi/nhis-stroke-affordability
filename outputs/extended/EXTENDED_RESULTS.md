# Extended analyses: results

Run 14 November 2026. Specifications are in `EXTENDED_ANALYSIS_PLAN.md`. All analyses are post hoc and exploratory. The primary analysis, manuscript and supplement were not changed.

Method in brief: pooled NHIS 2019–2025 design with the 2020 partial-sample weights, survey-weighted modified Poisson models, all ten income imputations wherever income is in the model. An independent Python script rebuilt the pooled file from the raw CSVs and reproduced 33 descriptive estimates and standard errors to machine precision (`validation_extended.json`).

## Summary

1. Stroke survivors report cost barriers at about 1.8 times the rate of adults of the same age, sex, race and region. The excess is accounted for by lower income, coverage and poorer health, not by stroke itself.
2. About 1.3 million survivors a year report a barrier; 28% report a barrier or problems paying medical bills.
3. Medicaid is the coverage type associated with fewer barriers, in both age groups. Private coverage does not protect working-age survivors, and Medicare Advantage and traditional Medicare are no better than Medicare with private coverage after adjustment.
4. Cost barriers to care fell between 2019 and 2025, mainly at 65 and older. Medication barriers did not. The composite outcome hides this.
5. Barriers are associated with more emergency department use. The link to secondary-prevention medication is weaker than the crude check suggested: it holds for cholesterol medication only.
6. Race, rurality and employment show no association after adjustment. The discontinuity at 65 is not detectable among stroke survivors.

## E1. Comparison with adults without stroke

| Any cost barrier | Stroke | No stroke |
|---|---|---|
| All ages | 17.9% (16.8–19.1) | 12.9% (12.6–13.2) |
| 18–64 | 28.0% (25.9–30.3) | 14.4% (14.1–14.7) |
| 65 and older | 10.9% (9.8–12.0) | 7.3% (7.0–7.6) |
| 18–44 | 30.4% | 14.3% |
| 45–54 | 30.1% | 15.1% |
| 55–64 | 26.0% | 14.1% |
| 65–74 | 14.8% | 8.8% |
| 75–85 | 7.6% | 5.0% |

| PR, stroke vs no stroke | All ages | 18–64 | 65 and older |
|---|---|---|---|
| Demographic adjustment | 1.77 (1.66–1.89) | 1.84 (1.70–1.99) | 1.66 (1.49–1.85) |
| Plus education, income, insurance | 1.55 (1.46–1.65) | 1.59 (1.47–1.72) | 1.46 (1.31–1.62) |
| Plus comorbidity, health, disability | 1.06 (0.99–1.13) | 1.08 (1.00–1.17) | 1.05 (0.95–1.17) |

The fully adjusted model conditions on health status and disability, which stroke itself worsens. It answers "more than equally sick adults?" (no), not "more than their peers?" (yes).

## E2. National burden (average per year)

| | Persons | 95% CI |
|---|---|---|
| Stroke survivors | 7.36 million | 7.06–7.66 |
| With any cost barrier | 1.31 million | 1.20–1.41 |
| of whom aged 18–64 | 0.84 million | 0.75–0.92 |
| of whom 65 and older | 0.47 million | 0.42–0.52 |
| With problems paying medical bills | 1.36 million | 1.25–1.47 |
| Uninsured, aged 18–64 | 0.27 million | 0.22–0.32 |

## E3. Coverage type within age group (stroke survivors)

| Coverage | Share | Any barrier | Adjusted PR vs private |
|---|---|---|---|
| **18–64** | | | |
| Private | 40.4% | 25.6% (22.4–29.1) | reference |
| Medicaid and other public | 36.4% | 21.2% (18.0–24.8) | 0.60 (0.48–0.75) |
| Other coverage | 14.3% | 31.5% (25.7–37.7) | 0.94 (0.74–1.21) |
| Uninsured | 8.9% | 60.8% (52.1–69.0) | 1.81 (1.49–2.22) |
| **65 and older** | | | |
| Private (with Medicare) | 30.9% | 8.6% (7.0–10.4) | reference |
| Dual eligible | 13.0% | 10.6% (8.0–13.7) | 0.53 (0.37–0.76) |
| Medicare Advantage | 32.6% | 12.3% (10.5–14.3) | 1.07 (0.84–1.35) |
| Traditional Medicare only | 11.6% | 16.0% (12.2–20.5) | 1.23 (0.92–1.64) |
| Other coverage | 11.3% | 6.7% (4.5–9.7) | 0.65 (0.42–1.00) |

- "Other coverage" under 65 is 78% Medicare and 27% military (categories overlap).
- The manuscript's pooled "public coverage PR 0.72" is a Medicaid association. It does not extend to Medicare.
- High-deductible plans among privately insured survivors under 65: 26.4% with a barrier versus 25.7% with no deductible; adjusted PR 1.37 (0.94–2.00). Inconclusive with 801 people.

## E4. Secondary-prevention medication (stroke survivors)

| Not taking medication | With barrier | Without barrier | Adjusted PR |
|---|---|---|---|
| Blood pressure (if hypertensive) | 13.7% (11.0–16.6) | 8.5% (7.5–9.5) | 1.10 (0.84–1.44) |
| Cholesterol (if high cholesterol) | 20.5% (16.8–24.7) | 14.3% (12.9–15.7) | 1.27 (1.01–1.60) |

With care and medication barriers entered together, cholesterol non-use is associated with the care barrier (PR 1.70; 1.32–2.21) and not the medication barrier (0.89; 0.69–1.15). Blood-pressure non-use is associated with neither.

## E5. Acute care use (stroke survivors)

| Past 12 months | With barrier | Without barrier | Adjusted PR |
|---|---|---|---|
| Any emergency visit | 53.9% (50.4–57.5) | 40.7% (39.0–42.3) | 1.19 (1.09–1.30) |
| Two or more emergency visits | 28.9% (25.7–32.3) | 17.8% (16.6–19.1) | 1.31 (1.14–1.51) |
| Overnight hospitalization | 34.8% (31.4–38.4) | 29.0% (27.5–30.5) | 1.08 (0.96–1.22) |

Emergency use tracks the medication barrier (two or more visits: PR 1.38; 1.18–1.62), not the care barrier (1.08; 0.90–1.31). Direction cannot be inferred: emergency visits also generate bills.

## E6. Medical bills

| | Stroke | No stroke |
|---|---|---|
| Problems paying medical bills | 18.6% (17.4–19.9) | 11.2% (10.9–11.4) |
| 18–64 | 25.9% | 12.2% |
| 65 and older | 13.6% | 7.2% |
| Very worried about paying bills | 18.0% | 14.7% |

- PR for bill problems, stroke vs no stroke: 1.93 (1.80–2.06) with demographic adjustment; 1.13 (1.05–1.22) fully adjusted.
- Cost barrier or bill problems among survivors: 27.8% (26.4–29.3) overall, 39.4% (37.0–41.8) at 18–64, 19.8% (18.3–21.4) at 65 and older.
- The bills question covers the respondent's family, not only the respondent.

## E7. Trends by age and domain

Change from 2019 to 2025, standardized on demographics only (percentage points):

| | Any barrier | Care barrier | Medication barrier |
|---|---|---|---|
| All ages | −3.4 (−7.3 to 0.6) | −4.6 (−7.8 to −1.4) | −1.3 (−4.9 to 2.3) |
| 18–64 | −5.9 (−13.6 to 1.8) | −5.3 (−11.8 to 1.2) | −3.6 (−10.4 to 3.2) |
| 65 and older | −1.8 (−6.1 to 2.5) | −4.0 (−7.0 to −1.1) | −0.1 (−4.0 to 3.8) |

- Linear trend per year: none of the six age-by-domain tests is significant after Holm adjustment. The strongest is the care barrier at 65 and older, PR 0.93 per year (0.86–1.00), unadjusted p=0.06.
- 2020–2023 versus 2019, all ages: PR 0.84 (0.71–0.99). 2024–2025 versus 2020–2023: 1.10 (0.96–1.27).
- Medication barrier at 65 and older, 2025 versus 2019–2024: PR 1.15 (0.82–1.61). No detectable change in the first year of the Part D cap.
- 2019 is the highest year, so endpoint contrasts starting there are favourable to finding a decline.
- With demographic-only standardization the 2019-to-2025 change in the composite is −3.4 points, versus −2.1 in the manuscript's fully adjusted version.

## E8. Age profile

`age_profile.png` and `E8_age_profile.csv`. Prevalence among survivors peaks near 34% in the mid-40s, is 20% at 65, 11% at 75 and 4.5% at 85. Among adults without stroke it is about half that at every age up to 75.

## E9. Discontinuity at 65 (secondary)

Change at 65 in percentage points, bandwidth 10 years:

| | Stroke | No stroke |
|---|---|---|
| Any barrier | −4.0 (−11.2 to 3.2) | −2.4 (−3.8 to −1.0) |
| Care barrier | −3.5 (−9.4 to 2.4) | −3.6 (−4.7 to −2.5) |
| Medication barrier | −2.2 (−8.0 to 3.6) | 0.2 (−1.0 to 1.4) |
| Uninsured | −2.4 (−6.4 to 1.6) | −6.4 (−7.3 to −5.5) |

Narrower bandwidths give −7.3 and −7.4 for any barrier among survivors, with wider intervals that still include zero. The no-stroke pattern (care barriers fall at 65, medication barriers do not) matches Aggarwal et al. 2022.

## E10. Equity descriptives (secondary)

| | Any barrier | Adjusted PR |
|---|---|---|
| Non-Hispanic Black | 22.4% (19.3–25.7) | 0.95 (0.81–1.12) vs White |
| Hispanic | 20.0% (15.8–24.8) | 0.83 (0.66–1.05) vs White |
| Non-Hispanic White | 16.6% (15.3–17.9) | reference |
| Female / male | 19.7% / 16.0% | in Table S8 |
| South / Northeast | 21.9% / 13.6% | in Table S8 |
| Nonmetropolitan / large central metro | 18.8% / 16.4% | 1.05 (0.87–1.27) |
| Worked last week / did not (18–64) | 28.2% / 28.5% | 1.10 (0.91–1.31) |

39.4% of survivors aged 18–64 worked in the past week.

## What changed relative to the crude check in the review

- **Coverage at 65 and older.** The crude gradient (traditional Medicare 16.0% vs private 8.6%) is mostly explained by income and health. After adjustment only dual eligibility differs from private.
- **Blood-pressure medication.** The crude gap does not survive adjustment. Only cholesterol medication does, and through the care barrier.
- **High-deductible plans.** Previously described as "no difference"; the adjusted estimate (1.37; 0.94–2.00) is better described as inconclusive.
- **Stroke versus no stroke.** The doubling is real against demographic peers but disappears once health status and disability are held equal.
- **Decline in care barriers.** Confirmed for the 2019-to-2025 contrast; the linear trend is not significant after multiplicity adjustment.

## Cautions

- Every result here is exploratory. Only the six linear trend tests carry a multiplicity adjustment.
- Modified Poisson fitted values exceed 1 for some records in the larger models (maximum 2.99 in the all-adult model at 18–64; 2.13 in the under-65 coverage model). Bounded logistic marginal PRs (E11, added 14 November) agree with the modified Poisson PRs for all 40 new contrasts, with a largest absolute difference of 0.038 (`E11_bounded_logistic.csv`).
- All associations are cross-sectional.
- `urban4` uses the 2013 county scheme for 2019–2023 and the 2023 scheme for 2024–2025.

## Not done

- Aspirin, diabetes medication and insulin-specific items.
- Any change to the original manuscript, supplement, figures or submission package. A separate revised draft built from these results is kept outside the public repository until submission.

## Files

| File | Content |
|---|---|
| `E1_E6_comparator_prevalence.csv`, `E1_E6_stroke_vs_no_stroke_PR.csv` | E1, E6 |
| `E2_national_burden.csv` | E2 |
| `E3_coverage_prevalence.csv`, `E3_coverage_PR.csv`, `E3_other_coverage_composition_under65.csv`, `E3_hdhp_prevalence_private_under65.csv` | E3 |
| `E4_E5_outcomes_by_barrier.csv`, `E4_E5_barrier_PR.csv` | E4, E5 |
| `E7_*.csv` (six files) | E7 |
| `E8_age_profile.csv`, `age_profile.png` | E8 |
| `E9_discontinuity_at_65.csv` | E9 |
| `E10_equity_prevalence.csv`, `E10_equity_PR.csv` | E10 |
| `validation_extended.json` | Independent Python check |
| `raw_response_counts_extended.csv` | Raw code counts for the new variables by year |

Reproduce with `Rscript scripts/prepare_extended_data.R`, `Rscript scripts/extended_analysis.R`, `python scripts/validate_extended.py`.
