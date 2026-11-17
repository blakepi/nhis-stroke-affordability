# Confirmatory results (registered at tag `prereg-2026-11`)

Real outcomes were first read after the registration was public: 2026-11-17 04:30:22 UTC, by GitHub's server-side push time (see `DEVIATIONS.md`). Decisions follow `REGISTERED_ANALYSIS_PLAN.md`, Section 2. Machine-readable summary: `outputs/confirmatory_summary.csv`.

## Decisions

| | Data | Estimate (95% CI) | P | Family-adjusted P | Decision |
|---|---|---|---|---|---|
| H1: Medicaid-type vs private coverage, any cost barrier | MEPS 2019–2024, n = 2,948 person-years | PR 0.56 (0.42–0.75) | <0.001 | Holm 0.0003 | Supported |
| H2: any cost barrier, no LDL-lowering fill (high cholesterol) | MEPS, n = 3,592 | PR 1.22 (1.05–1.42) | 0.011 | Holm 0.011 | Supported |
| H3: Medicaid expansion, uninsured (low-income, 18–64) | BRFSS 2011–2019, n = 22,957, 46 states | ATT −6.3 points (−9.8 to −2.8) | <0.001 | Gate | Supported |
| H4: Medicaid expansion, could not see a doctor because of cost | BRFSS, n = 22,935 | ATT −2.8 points (−6.6 to 0.9) | 0.14 | Fixed sequence | Not supported; inconclusive (95% CI includes effects of 3 points) |

With Holm adjustment across all four (registered sensitivity analysis), H1 (P = 0.0005), H3 (P = 0.001) and H2 (P = 0.022) remain below 0.05.

## MEPS (H1, H2)

- **Independent reproduction:** the Python reimplementation, built from the raw files, matches the R estimates (coefficient difference ≤ 1.5e-9; relative standard-error difference ≤ 2.1e-5). See `outputs/meps/real/validation_meps.json`.
- **H1 sensitivity analyses** (`outputs/meps/real/exploratory_and_sensitivity.csv`):

  | Analysis | PR (95% CI) |
  |---|---|
  | Bounded logistic marginal PR | 0.55 (0.41–0.75) |
  | Excluding 2020 | 0.56 (0.41–0.78) |
  | Same coverage all year | 0.41 (0.29–0.59) |
  | Care barrier only | 0.56 (0.39–0.82) |
  | Medication barrier only | 0.54 (0.37–0.79) |
  | Ages 18–64 | 0.52 (0.36–0.75) |
  | Ages 65+ (dual vs private) | 0.69 (0.43–1.12) |

- **H2 sensitivity analyses:**

  | Analysis | PR (95% CI) |
  |---|---|
  | Bounded logistic marginal PR | 1.22 (1.05–1.43) |
  | Excluding 2020 | 1.17 (0.98–1.39) |
  | Care barrier, entered jointly | 1.32 (1.10–1.59) |
  | Medication barrier, entered jointly | 1.02 (0.84–1.24) |

- **Negative control for H2:** "could not afford dental care" gave PR 1.24 (1.07–1.44), about the same as H2. By the registered interpretation, the H2 association more likely reflects general financial hardship or access than a medication-specific cost barrier. The joint model points the same way: the association is with the care barrier, not the medication barrier.
- **Exploratory coverage models**, PRs vs private coverage (95% CI):

  | Age group | Coverage | PR (95% CI) |
  |---|---|---|
  | 18–64 | Uninsured | 2.48 (1.84–3.34) |
  | 18–64 | Other coverage (mostly Medicare) | 1.38 (1.02–1.87) |
  | 65+ | Medicare Advantage | 1.43 (1.02–2.00) |
  | 65+ | Traditional Medicare only | 1.37 (0.99–1.91) |
  | 65+ | Dual eligible | 0.71 (0.47–1.07) |

## BRFSS difference-in-differences (H3, H4)

- **Pre-trends:**
  - The state-clustered Wald test of the two testable pre-period coefficients gave P = 0.066 for uninsurance and P = 0.57 for the cost barrier.
  - The pre-period coefficients for uninsurance were −2.3 and +1.9 points.
- **HonestDiD relative-magnitude bounds** for the average post-period effect on uninsurance (percentage points):

  | M̄ | Lower | Upper |
  |---|---|---|
  | 0 | −9.8 | −3.0 |
  | 0.5 | −19.2 | 7.2 |
  | 1 | −31.2 | 19.4 |

  The H3 conclusion therefore depends on parallel trends holding closely. The bounds are wide because only two pre-periods can be tested and they are noisy.
- **Falsification groups** (expected near 0 for uninsurance):
  - survivors aged 65+: 0.6 points (−0.6 to 1.9);
  - survivors above 400% of poverty: −1.2 (−3.2 to 0.8).
- **Sensitivity analyses for uninsurance:** all ranged from −5.0 to −7.6 points with 95% CIs excluding 0 (drop Wisconsin, never-treated controls, survey weights, equal state weights, doubly robust, Sun–Abraham, income under $25,000, high school or less, observed household size).
- **Sensitivity analyses for the cost barrier:** estimates ranged from −2.0 to −5.5 points. Only the survey-weighted estimate excluded 0: −5.5 (−9.9 to −1.2).
- **Independent check:** the Python recount of the 2013 and 2019 samples from the raw files matches exactly. An unweighted two-way fixed-effects estimate gave −6.6 points for uninsurance and −4.0 for the cost barrier.
- **Exploratory outcomes:**
  - no routine checkup in the past year: −3.6 points (−6.2 to −1.1);
  - no personal clinician: −2.4 (−4.6 to −0.3).
- **Triple difference against low-income adults without stroke:**
  - uninsurance: 0.6 points (−4.4 to 5.5);
  - cost barrier: 1.7 points (−2.6 to 5.9).

  Survivors' gains were similar to those of other low-income adults.
- **Full 2011–2025 window with all cohorts (exploratory):**
  - uninsurance: −3.7 points (−6.6 to −0.8);
  - cost barrier: −2.2 (−6.6 to 2.2).

## BRFSS age-65 discontinuity (exploratory)

Unweighted honest estimates at the interval-minimizing bandwidth, which was 2 years:

| Outcome or check | Estimate (honest 95% CI) |
|---|---|
| Uninsured | −3.6 points (−5.5 to −1.7) |
| Uninsured, doubled smoothness bound | −6.2 to −1.0 |
| Uninsured, donut excluding age 65 | −4.8 (−7.1 to −2.6) |
| Uninsured, placebo cutoffs at 60 and 70 | Intervals include 0 |
| Cost barrier | +1.4 (−2.5 to 5.2), no detectable change |
| First stage: Medicare as primary coverage (2021–2022) | +25 points (15.7 to 34.4) |
