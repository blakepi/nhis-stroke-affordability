# Cost-Related Barriers to Care and Medications Among US Stroke Survivors, 2019–2025

G. Blake Pierpoint, BS^1,*^ and Alberto E. Musto, MD, PhD^1,2,3^

^1^ Macon & Joan Brock Virginia Health Sciences Eastern Virginia Medical School at Old Dominion University, Norfolk, Virginia, USA

^2^ Department of Biomedical and Translational Sciences, Macon & Joan Brock Virginia Health Sciences Eastern Virginia Medical School at Old Dominion University, Norfolk, Virginia, USA

^3^ Department of Neurology, Macon & Joan Brock Virginia Health Sciences Eastern Virginia Medical School at Old Dominion University, Norfolk, Virginia, USA

*Correspondence: G. Blake Pierpoint, BS, Macon & Joan Brock Virginia Health Sciences Eastern Virginia Medical School at Old Dominion University, 700 West Olney Road, Norfolk, VA 23507, USA; pierpogb@odu.edu

ORCID identifiers: G. Blake Pierpoint, 0000-0001-8288-8549; Alberto E. Musto, 0000-0002-0877-8883

Short title: Affordability barriers after stroke

Keywords: stroke; secondary prevention; healthcare access; cost-related nonadherence; health insurance; National Health Interview Survey

{{counts}}

## Abstract

**Background:** Secondary prevention after stroke requires continued access to follow-up care and medications. Recent national estimates for stroke survivors have addressed medication costs only. We estimated the prevalence of cost-related barriers to both medical care and medications among US stroke survivors from 2019 through 2025 and examined which groups were most affected.

**Methods:** We conducted a repeated cross-sectional analysis of the 2019–2025 National Health Interview Survey. The primary outcome was any past-year cost-related delay in or nonreceipt of medical care, nonreceipt of needed prescription medication, or medication underuse to save money. Survey-weighted modified Poisson models with sequential adjustment estimated prevalence ratios (PRs), incorporating all ten National Center for Health Statistics income imputations; logistic models estimated covariate-standardized annual prevalence.

**Results:** Among 7,104 stroke survivors, 1,184 reported a cost-related barrier, a weighted prevalence of {{pooled}}. Prevalence was {{young}} at ages 18–64 years versus {{older}} at 65 years and older, and {{uninsuredprev}} among uninsured survivors. After full adjustment, working-age survivors remained more than twice as likely to report a barrier (PR, {{agepr_s}}). Income of 100%–199% of the federal poverty level (PR, {{incomepr_s}}), uninsured status (PR, {{uninsuredpr_s}}), and disability (PR, {{disabilitypr_s}}) were independently associated with barriers. Standardized prevalence was {{adj2019}} in 2019 and {{adj2025}} in 2025, with no evidence of change across years (P={{yearp}}).

**Conclusions:** About 1 in 6 US stroke survivors, and more than 1 in 4 of those aged 18–64 years, reported delaying or forgoing care or medications because of cost, and prevalence did not decline between 2019 and 2025. Routine assessment of affordability during post-stroke follow-up may help identify survivors at risk of interrupted secondary prevention.

## Non-standard Abbreviations and Acronyms

FPL, federal poverty level; NCHS, National Center for Health Statistics; NHIS, National Health Interview Survey; PR, prevalence ratio; STROBE, Strengthening the Reporting of Observational Studies in Epidemiology

## Introduction

Millions of US adults have survived a stroke and remain at elevated risk of recurrent vascular events.[1] Guidelines for secondary prevention recommend long-term control of blood pressure, lipids, and glucose and continued antithrombotic therapy,[2] which require regular outpatient follow-up and uninterrupted access to prescription medications. Out-of-pocket costs can limit both.

Cost-related barriers after stroke have been described for more than 2 decades. In the 1998–2002 National Health Interview Survey (NHIS), younger stroke survivors were markedly less likely than older survivors to obtain physician care and medications,[3] and NHIS data from 1999–2010 documented substantial cost-related medication nonadherence that varied with age and insurance.[4] Financial stress and food insecurity were linked to medication nonadherence among stroke survivors in 2014–2018,[5] and a recent analysis of the 2020–2023 NHIS reported that 13% of stroke survivors had cost-related medication nonadherence, most often those who were younger, uninsured, or of lower income.[6] Parallel work in adults with multiple chronic conditions suggested that cost-related nonadherence may have declined between 2019 and 2023.[7]

Recent stroke-specific studies have examined medication nonadherence but not delayed or forgone medical care, which affects the visits at which preventive therapy is prescribed and adjusted. No study has covered the full period from 2019, the first year of the redesigned NHIS, through 2025, which included the COVID-19 pandemic and temporary coverage protections. It is also unclear how much of the higher prevalence among working-age survivors reflects differences in income, insurance, or health status.

We used the 2019–2025 NHIS to estimate the prevalence of cost-related barriers to medical care and medications among US stroke survivors, describe their variation across years, and quantify their distribution by age, income, insurance, and disability. We also examined how the association with working age changed under sequential adjustment for socioeconomic and clinical characteristics.

## Methods

### Data availability

NHIS public-use files and documentation are available from NCHS; no agency endorsement is implied. All acquisition, analysis, verification, and manuscript-generation code, source file hashes, aggregate results, tables, and figures are publicly available at https://github.com/blakepi/nhis-stroke-affordability (release v1.2.0). One author (G.B.P.) had full access to all the data in the study and takes responsibility for its integrity and the data analysis.

### Data source and study population

NHIS is a continuous, cross-sectional household survey of the civilian noninstitutionalized US population conducted by the National Center for Health Statistics (NCHS), with a stratified, multistage probability design.[8] We conducted a repeated cross-sectional analysis of the public-use Sample Adult files for 2019 through 2025. Stroke survivors were adults who reported ever having been told by a doctor or other health professional that they had a stroke. We required a positive survey weight and a valid age of 18–85 years (85 representing 85 years and older); 10 records with unknown age were excluded. The survey does not record stroke subtype, timing, severity, or recurrence.

Annual estimates used each year's full Sample Adult file and its annual weight. Because the 2020 survey re-interviewed a subset of 2019 respondents, pooled analyses followed NCHS guidance for combining 2020 with other years: the follow-back respondents were omitted, and the remaining 2020 records were assigned the partial-sample weight.[9] Weights were divided by seven to represent an average annual population. The public-use stratum and primary sampling unit identifiers were used without modification, consistent with NCHS instructions for pooling survey years from 2019 onward.[8] Survey designs were specified on the full adult files before restricting analyses to the stroke-survivor domain, preserving the design structure for variance estimation. Because NHIS data are publicly available and de-identified, this study did not require institutional review board approval or informed consent.

### Outcomes

The primary outcome was any cost-related barrier in the preceding 12 months, defined from six questions. Three questions asked of all adults captured delaying medical care because of cost, needing but not getting medical care because of cost, and needing but not getting prescription medication because of cost. Three questions asked of adults who had been prescribed medication in the past 12 months captured skipping doses, taking less medication, and delaying a prescription fill to save money.

A survivor with a "yes" response to any applicable question was classified as having a barrier. Classification as having no barrier required "no" responses to all three universal questions and either no prescription use or "no" responses to all three medication-use questions. Other response patterns were classified as unknown, so partially answered negative patterns were never treated as absence of a barrier. Secondary outcomes were each component separately, medication underuse (any of the three medication-use questions, among adults prescribed medication), and a three-question composite restricted to the universal items. Question wording and universes were verified against each year's codebook (Supplemental Methods; Tables S1 and S2).

### Covariates

Demographic covariates were survey year, age (natural cubic spline with three degrees of freedom), sex, race and Hispanic origin (seven published categories), and Census region. Socioeconomic covariates were education (less than high school; high school or equivalent; some college or associate degree; bachelor's degree or higher), family income as a percentage of the federal poverty level (FPL; below 100%, 100%–199%, 200%–399%, and 400% or higher), and health insurance (private coverage with or without public coverage; public coverage without private coverage; military coverage only; uninsured). Clinical and health-status covariates were diagnosed hypertension, diabetes, and coronary heart disease; cigarette smoking (never, former, current); fair or poor self-rated health; and disability, defined by the NCHS recode of the Washington Group questions as substantial difficulty in at least one functional domain. The education variable changed name between 2020 and 2021 and was harmonized across years.

### Statistical analysis

Prevalence estimates were survey-weighted with Taylor-series linearization for variance.[10] Annual confidence intervals used a logit transformation; pooled component intervals used a design-adjusted beta method, and subgroup estimates were pooled on the logit scale. All reported prevalence estimates met the NCHS presentation standards for proportions.[11]

Family income was imputed by NCHS for 26.8% of stroke survivors, and NCHS releases ten multiply imputed income files per year.[12] All analyses involving income were repeated in each of the ten completed data sets and combined with Rubin's rules using finite design degrees of freedom. Other covariates had little missingness (largest, 3.5% for smoking) and were handled by complete-case analysis.

Survey-weighted modified Poisson regression with robust variance estimated prevalence ratios for the primary outcome.[10,13] Three nested models were fit in the same analytic sample: Model 1 included year and demographic covariates; Model 2 added education, income, and insurance; and Model 3 added the clinical and health-status covariates. A parallel set of models replaced the age spline with a working-age indicator (18–64 versus 65 years and older) so that attenuation of the age-group association could be observed across adjustment sets. Adjusted annual prevalence was estimated by fitting a logistic model with the Model 3 covariates and standardizing each year's prediction to the pooled covariate distribution,[14] with variance accounting for both model and reference-distribution uncertainty. We tested categorical year and a year-by-age-group interaction using pooled Wald F tests.

Sensitivity analyses excluded 2020, restricted the sample to working-age adults or to adults without disability, modeled each component outcome, and added explicit "unknown" categories for missing covariates. Because log-binomial-type models can yield fitted values above one, key contrasts were re-estimated as standardized prevalence ratios from bounded logistic models. All primary prevalence estimates, standard errors, and the full model were independently reproduced in a second software environment. Analyses used R version 4.6.0 with the survey and mitools packages. P values are two-sided without adjustment for multiplicity; secondary and sensitivity analyses are exploratory. The analysis was not preregistered. Reporting follows the STROBE guideline;[15] the completed checklist is provided in the Supplemental Material.

## Results

### Study population

The seven annual files contained 207,064 sample adults, of whom 7,565 reported a prior stroke (Figure S1; Table S3). After exclusion of 10 records with unknown age and application of the pooled-sample rules for 2020, the pooled sample comprised 7,181 stroke survivors, of whom 7,104 (98.9%) had a classifiable primary outcome; 6,777 had complete covariates for adjusted models (Table S4). In the weighted pooled sample, 41.0% were aged 18–64 years, 51.5% were female, 38.8% had a disability, and 51.9% rated their health as fair or poor (Table 1; Table S5). More than half (53.6%) had public coverage without private insurance, 40.3% had private coverage, and 4.0% were uninsured.

### Prevalence of cost-related barriers

Overall, 1,184 survivors reported at least one cost-related barrier, a weighted prevalence of {{pooled}}, or approximately 1 in 6 stroke survivors (Table 2). The most common barrier was needing but not getting a prescription medication because of cost ({{forgonerx_s}}), followed by delaying medical care ({{delayed_s}}) and forgoing medical care ({{forgonecare_s}}). Among survivors prescribed medication, {{underuse}} reported skipping doses, taking less, or delaying fills to save money. Restricting the composite to the three universal questions gave a prevalence of {{universal}} (Figure 1B; Table S6).

Observed annual prevalence fluctuated between 15.3% and 20.6% without a monotonic trend (Figure 1A; Table 2). After standardization for demographic, socioeconomic, and clinical characteristics, prevalence was {{adj2019}} in 2019 and {{adj2025}} in 2025, an absolute difference of {{difference}}. Neither categorical year (P={{yearp}}) nor the interaction between year and age group (P={{interactionp}}) showed evidence of change over the period.

### Who reports cost-related barriers

Prevalence differed by age, income, and insurance (Figure 2; Table S7). Working-age survivors reported barriers at {{young}}, compared with {{older}} among survivors aged 65 years and older. Prevalence was higher at lower income levels: 8.2% at 400% FPL or higher to 18.0% at 200%–399% FPL, 23.5% at 100%–199% FPL, and 22.5% below 100% FPL. A barrier was reported by {{uninsuredprev}} of uninsured survivors, compared with {{privateprev}} of privately insured survivors and {{publicprev}} of those with public coverage only. Survivors with a disability reported barriers more often than those without: {{disabilityprev}} versus {{nodisabilityprev}}.

In adjusted models, the association with working age was attenuated but persisted (Table 3). The prevalence ratio for ages 18–64 versus 65 years and older was 2.51 (95% CI, 2.20–2.87) with demographic adjustment, 2.27 (95% CI, 1.98–2.61) after adding education, income, and insurance, and {{agepr}} after further adjustment for clinical and health-status characteristics. Relative to income of 400% FPL or higher, fully adjusted prevalence ratios were {{income200pr}} for 200%–399% FPL, {{incomepr}} for 100%–199% FPL, and {{incomelowpr}} for below 100% FPL. Uninsured survivors had a prevalence ratio of {{uninsuredpr}} relative to privately insured survivors, whereas public coverage without private insurance was associated with a lower adjusted prevalence (PR, {{publicpr_s}}). Disability was associated with a prevalence ratio of {{disabilitypr}}. Female sex (PR, 1.27; 95% CI, 1.12–1.43), coronary heart disease (PR, 1.37; 95% CI, 1.18–1.58), current smoking (PR, 1.21; 95% CI, 1.04–1.42), and fair or poor self-rated health (PR, 1.58; 95% CI, 1.37–1.82) were also independently associated with barriers (Table S8).

### Sensitivity analyses

Results were similar when 2020 was excluded (income 100%–199% FPL: PR, 2.59; 95% CI, 2.00–3.36; uninsured: PR, 1.82; 95% CI, 1.49–2.21; disability: PR, 1.18; 95% CI, 1.04–1.34) and were consistent in direction across component outcomes and the missing-category analysis (Table S9). Within working-age survivors, the disability association was smaller and imprecise (PR, 1.08; 95% CI, 0.92–1.27). The fully adjusted modified Poisson model produced fitted values above one for approximately 0.2% of records; standardized prevalence ratios from bounded logistic models were similar: {{logage}} for working age, {{logincome}} for income 100%–199% FPL, {{loguninsured}} for uninsured status, and {{logdisability}} for disability (Table S10). Model convergence and fitted-value diagnostics are given in Table S11. Barrier prevalence among the 327 survivors excluded from adjusted models for missing covariates (19.2%; 95% CI, 14.0%–25.5%) was similar to that in the analytic sample (17.8%).

## Discussion

In this nationally representative analysis spanning 2019 through 2025, approximately 1 in 6 US stroke survivors reported delaying or forgoing medical care, going without a needed prescription, or rationing medication because of cost in the preceding year. More than 1 in 4 working-age survivors and nearly 3 in 5 uninsured survivors reported a barrier, prevalence was higher at lower income levels, and survivors with disability were affected more often than those without. Working-age survivors remained more than twice as likely as older survivors to report a barrier after adjustment for income, insurance, education, and health status. Prevalence did not change meaningfully between 2019 and 2025.

These findings are consistent with earlier NHIS studies, in which younger stroke survivors were less able to obtain physician care and medications in 1998–2002[3] and cost-related medication nonadherence was common through 2010.[4] The most recent stroke-specific estimate, 13% cost-related medication nonadherence in 2020–2023,[6] is consistent with the {{underuse}} medication underuse and {{forgonerx}} forgone prescriptions observed here. Our estimates add delayed and forgone medical care, each reported by approximately 8% of survivors, indicating that cost affects outpatient visits as well as medication use. The absence of a decline across 2019–2025 differs from the decrease in cost-related nonadherence reported among working-age adults with multiple chronic conditions over 2019–2023.[7] Differences in population, outcome definition, and period may explain this discrepancy.

Medicare eligibility at 65 years is a frequently cited explanation for age differences in affordability. The prevalence ratio for working age decreased from 2.51 to {{agepr}} across models, consistent with income and insurance explaining part of the difference, but most of the excess remained after adjustment. Working-age survivors may face higher deductibles and cost sharing, loss of employment or employer-sponsored coverage after stroke, and fewer accumulated financial resources. NHIS insurance categories do not measure underinsurance, which may be relevant for the 16.6% of privately insured survivors who reported a barrier. These results suggest that affordability screening should not be limited to uninsured patients.

The lower adjusted prevalence among survivors with public coverage than among those with private coverage should be interpreted cautiously. Public coverage in this population is mostly Medicare, often combined with Medicaid or supplemental coverage that limits out-of-pocket costs. Because the comparison is cross-sectional, it does not indicate that changing coverage type would change affordability. The association with disability was modest but persisted after adjustment, consistent with the greater care needs and reduced earning capacity that can follow disabling stroke.

Cost-related nonadherence after stroke is common and potentially modifiable,[4,6] but it may not be recognized unless clinicians ask about it. Brief affordability screening at follow-up, particularly for survivors younger than 65 years, those with lower income, and those with disability, could identify patients who may benefit from generic substitution, patient assistance programs, insurance navigation, or social work referral. The lack of change over the study period also suggests that coverage policies in effect during 2019–2025 did not substantially reduce cost-related barriers in this population.

### Strengths and limitations

Strengths include seven consecutive years of nationally representative data through 2025, a multidomain outcome that captures barriers to visits as well as medications, verification of question wording and universes across years, use of the NCHS-recommended weights for pooling the 2020 survey, incorporation of all ten income imputations, sequential adjustment within a single analytic sample, and independent reproduction of the primary results.

This study has limitations. Stroke history and cost-related barriers were self-reported and are subject to recall and reporting error, and the survey does not identify stroke subtype, timing, or severity, so some barriers may have preceded the stroke. NHIS excludes institutionalized adults and therefore under-represents the most severely disabled survivors. The composite outcome treats different barriers equally and does not capture frequency, duration, or whether the forgone care was related to stroke; the survey cannot show which medications were rationed. Insurance and disability were measured at interview, whereas barriers refer to the preceding year. Unmeasured characteristics including wealth, out-of-pocket spending, benefit design, and caregiving support may confound the observed associations, which are descriptive rather than causal. Complete-case handling of the small amount of nonincome missingness and the approximate multiple-imputation joint tests could introduce minor bias. Finally, the analysis was not preregistered, and secondary comparisons should be interpreted as exploratory.

## Conclusions

Cost-related barriers to medical care and medications were reported by approximately 1 in 6 US stroke survivors and more than 1 in 4 of those aged 18–64 years, with no decline between 2019 and 2025. Routine assessment of affordability during post-stroke follow-up, particularly for younger, lower-income, uninsured, and disabled patients, may help sustain secondary prevention.

## Acknowledgments

Generative artificial intelligence tools were used to assist with statistical programming, numerical verification, and drafting of text. The authors reviewed and edited all content and take full responsibility for the manuscript.

## Sources of Funding

None.

## Disclosures

None.

## Supplemental Material

Supplemental Methods

Figure S1

Tables S1–S12

## References

{{references}}

## Tables

{{main_tables}}

## Figures

![Figure 1](figures/figure1_annual_prevalence.png)

**Figure 1. Cost-related barriers among US stroke survivors, 2019–2025.** (A) Annual prevalence of any cost-related barrier, observed with annual survey weights (blue circles) and standardized to the pooled covariate distribution from the fully adjusted logistic model (orange triangles). (B) Pooled prevalence of the composite outcome and each component barrier. Medication underuse is estimated among survivors prescribed medication in the past 12 months. Error bars are 95% CIs.

![Figure 2](figures/figure2_adjusted_associations.png)

**Figure 2. Distribution of cost-related barriers by survivor characteristics.** (A) Unadjusted pooled prevalence of any cost-related barrier within groups defined by age, family income, insurance coverage, and disability. (B) Fully adjusted prevalence ratios (Model 3) from survey-weighted modified Poisson regression incorporating ten income imputations; the age contrast is from the parallel model that replaces the age spline with an age-group indicator. Reference groups are age 65 years and older, income 400% or more of the federal poverty level (FPL), private insurance, and no disability. Error bars are 95% CIs; the dashed line marks a prevalence ratio of 1. PR indicates prevalence ratio.
