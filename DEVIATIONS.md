# Deviations from the registered analysis plan

Registered plan: `REGISTERED_ANALYSIS_PLAN.md` at tag `prereg-2026-11`.

## Registration record

- **Registered commit:** `57b545e44b8fe013915cfa9d0b1024882b722560`; annotated tag object `7c30a1bc5bf4cae7f159c2e281c89abc310fcf8d`.
- **Public since:** 2026-11-17 04:30:22 UTC (23:30 on 16 November 2026, US Eastern). This is GitHub's server-side timestamp for the push of `master` from `e4984de` to `57b545e`, from the repository activity API (`GET /repos/blakepi/nhis-stroke-affordability/activity`). Commit and tagger dates are set by the author and are not evidence of timing.
- **Before the first push**, the local registration commit was rebuilt so that a pre-submission review and a revised manuscript draft (with its two build scripts) stayed out of the public repository. In the same rebuild, `outputs/meps/validate_null.log`, a stale traceback from a fixed data-type error, was replaced by the log of a clean rerun on simulated outcomes. No analysis code, registered text or outcome-blind output changed. No version of the tag was public before `57b545e`.
- **First access to real outcomes:** after the push. `scripts/meps_analysis.R real` was the first real-outcome run; the real-mode guard in every analysis script checks that the tag is on the public remote before it reads a sealed file.

## Deviations

Each entry gives the date, what changed, why, and whether any registered estimate is affected.

1. **2026-11-16 (after registration). Intervals for the MEPS bounded-logistic sensitivity analysis computed by a separate script.**
   - *Change:* `scripts/meps_marginal_ci.R` computes 95% confidence intervals for the bounded-logistic marginal prevalence ratios of H1 and H2. Output: `outputs/meps/real/bounded_logistic_marginal_PR.csv`.
   - *Why:* the registered code (`scripts/meps_analysis.R`) reports these as point estimates and states that the interval is computed with the influence-function method of `scripts/extended_analysis.R` once real outcomes are analyzed. The new script implements that method.
   - *Effect:* none on registered estimates. The script refits the same models and stops unless its point estimates equal the registered output to 1e-8.

2. **2026-11-16 (after registration). Binned means and fitted lines for the exploratory age-65 figure.**
   - *Change:* `scripts/brfss_rd_bins.R` writes unweighted means by single year of age and the local linear fits on each side of 65, at the bandwidth `scripts/brfss_rd.R` chose. Outputs: `outputs/brfss/rd_real/binned_means.csv` and `local_linear_fits.csv`.
   - *Why:* to plot the registered exploratory analysis (Section 5), which writes estimates but no plotting data.
   - *Effect:* none. The script stops unless its fitted jump equals the RDHonest estimate to 1e-6. The bandwidth chosen to minimize the honest interval was 2 years for both outcomes, so each side's fit uses only about two ages. The figure therefore shows binned means and states the honest estimate, without fitted lines.

3. **2026-11-16 (after registration). Holm adjustment across all four hypotheses computed by a separate script.**
   - *Change:* `scripts/confirmatory_summary.R` collects H1–H4 and applies the registered decision rules (Holm within MEPS; fixed sequence H3 → H4), the registered no-effect rules (Sections 2 and 6), and the registered sensitivity analysis of Holm adjustment across all four. Output: `outputs/confirmatory_summary.csv`.
   - *Why:* the registration lists this sensitivity analysis, but no registered script computed it.
   - *Effect:* none. The script reads only result files.

## Additional outputs not described in the registration

These are descriptive and use no outcome, or present registered results without changing them:
- `scripts/v3_characteristics.R`: characteristics of the MEPS and BRFSS study populations for Table 1 (covariates only). Output: `outputs/v3/`.
- `scripts/make_v3_figures.R`: event-study and age-65 figures drawn from the registered outputs.
