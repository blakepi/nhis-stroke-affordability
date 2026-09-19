# Cost-Related Barriers to Care and Medications Among US Stroke Survivors, 2019–2025

G. Blake Pierpoint^1,*^ and Alberto E. Musto^1,2,3^

^1^ Macon & Joan Brock Virginia Health Sciences Eastern Virginia Medical School at Old Dominion University, Norfolk, Virginia, USA

^2^ Department of Biomedical and Translational Sciences, Macon & Joan Brock Virginia Health Sciences Eastern Virginia Medical School at Old Dominion University, Norfolk, Virginia, USA

^3^ Department of Neurology, Macon & Joan Brock Virginia Health Sciences Eastern Virginia Medical School at Old Dominion University, Norfolk, Virginia, USA

*Correspondence: G. Blake Pierpoint, Macon & Joan Brock Virginia Health Sciences Eastern Virginia Medical School at Old Dominion University, Norfolk, Virginia, USA. E-mail: pierpogb@odu.edu

ORCID: G. Blake Pierpoint, 0000-0001-8288-8549; Alberto E. Musto, 0000-0002-0877-8883

Short title: Affordability barriers after stroke

Keywords: stroke; secondary prevention; healthcare access; cost-related nonadherence; health insurance; National Health Interview Survey

Total word count: 5,028 (title page, abstract, text, references, tables, and figure legends). Main text: 2,908 words. Abstract: 284 words. Tables: 3. Figures: 2.

## Abstract

**Background:** Secondary prevention after stroke depends on sustained access to follow-up care and medications, yet no contemporary national estimate describes how often US stroke survivors cannot afford them. We quantified cost-related barriers to medical care and medications among stroke survivors from 2019 through 2025 and identified the groups most affected.

**Methods:** We analyzed the 2019–2025 National Health Interview Survey. The primary outcome was any past-year cost-related delay in or nonreceipt of medical care, nonreceipt of needed prescription medication, or medication underuse to save money. Survey-weighted modified Poisson models with sequential adjustment estimated prevalence ratios (PRs), incorporating all ten National Center for Health Statistics income imputations; logistic models estimated covariate-standardized annual prevalence.

**Results:** Among 7,104 stroke survivors, 1,184 reported a cost-related barrier, a weighted prevalence of 17.9% (95% CI, 16.8%–19.1%). Prevalence was 28.0% (95% CI, 25.9%–30.2%) at ages 18–64 years versus 10.9% (95% CI, 9.8%–12.0%) at 65 years and older, and 58.7% (95% CI, 50.7%–66.3%) among uninsured survivors. After full adjustment, working-age survivors remained more than twice as likely to report a barrier (PR, 2.18 (95% CI, 1.90–2.50)). Income of 100%–199% of the federal poverty level (PR, 2.50 (95% CI, 1.94–3.21)), uninsured status (PR, 1.79 (95% CI, 1.49–2.16)), and disability (PR, 1.19 (95% CI, 1.05–1.35)) were independently associated with barriers. Standardized prevalence was 19.2% (95% CI, 16.6%–22.0%) in 2019 and 17.0% (95% CI, 14.3%–20.1%) in 2025, with no evidence of change across years (P=0.258).

**Conclusions:** One in six US stroke survivors, and more than one in four of working age, reported forgoing or rationing care because of cost, with no improvement over seven years. Affordability is a persistent, measurable threat to secondary prevention that concentrates in identifiable groups and warrants routine attention in post-stroke care.

## Non-standard Abbreviations and Acronyms

FPL, federal poverty level; NCHS, National Center for Health Statistics; NHIS, National Health Interview Survey; PR, prevalence ratio; STROBE, Strengthening the Reporting of Observational Studies in Epidemiology

## Introduction

Millions of US adults are living after a stroke, and their risk of recurrent vascular events is highest when medical follow-up and preventive medications lapse.[1,2] Current guidelines call for sustained control of blood pressure, lipids, and glucose and for continuous antithrombotic therapy, all of which require regular contact with the health system and uninterrupted access to prescriptions.[2] For many survivors, the constraint is not the availability of effective therapy but the ability to pay for it.

Cost has long shaped access to care after stroke. In the 1998–2002 National Health Interview Survey (NHIS), younger stroke survivors were markedly less likely than older survivors to obtain physician care and medications,[3] and NHIS data from 1999–2010 documented substantial cost-related medication nonadherence that varied with age and insurance.[4] Financial stress and food insecurity were linked to medication nonadherence among stroke survivors in 2014–2018,[5] and a recent analysis of the 2020–2023 NHIS reported that 13% of stroke survivors had cost-related medication nonadherence, most often those who were younger, uninsured, or of lower income.[6] Parallel work in adults with multiple chronic conditions suggested that cost-related nonadherence may have declined between 2019 and 2023.[7]

Three gaps remain. First, existing stroke-specific estimates focus on medications alone, whereas cost also causes survivors to delay or forgo physician visits, the point of contact at which secondary prevention is prescribed and adjusted. Second, no analysis spans the full period from 2019, the first year of the redesigned NHIS, through 2025, a period that included the COVID-19 pandemic and its temporary coverage protections. Third, prior work has not examined whether the excess burden among working-age survivors is explained by their income, insurance, or health status, which bears on where interventions should be aimed.

We used the 2019–2025 NHIS to estimate the prevalence of cost-related barriers to medical care and medications among US stroke survivors, describe their variation across years, and quantify their distribution by age, income, insurance, and disability. We also examined how the association with working age changed under sequential adjustment for socioeconomic and clinical characteristics.

## Methods

### Data Availability

NHIS public-use files and documentation are available from NCHS; no agency endorsement is implied. All acquisition, analysis, verification, and manuscript-generation code, source file hashes, aggregate results, tables, and figures are publicly available at https://github.com/blakepi/nhis-stroke-affordability (release v1.1.0). One author (G.B.P.) had full access to all the data in the study and takes responsibility for its integrity and the data analysis.

### Data source and study population

NHIS is a continuous, cross-sectional household survey of the civilian noninstitutionalized US population conducted by the National Center for Health Statistics (NCHS), with a stratified, multistage probability design.[8] We conducted a repeated cross-sectional analysis of the public-use Sample Adult files for 2019 through 2025. Stroke survivors were adults who reported ever having been told by a doctor or other health professional that they had a stroke. We required a positive survey weight and a valid age of 18–85 years (85 representing 85 years and older); 10 records with unknown age were excluded. The survey does not record stroke subtype, timing, severity, or recurrence.

Annual estimates used each year's full Sample Adult file and its annual weight. Because the 2020 survey re-interviewed a subset of 2019 respondents, pooled analyses followed NCHS guidance for combining 2020 with other years: the follow-back respondents were omitted, and the remaining 2020 records were assigned the partial-sample weight.[9] Weights were divided by seven to represent an average annual population. The public-use stratum and primary sampling unit identifiers were used without modification, consistent with NCHS instructions for pooling survey years from 2019 onward.[8] Survey designs were specified on the full adult files before restricting analyses to the stroke-survivor domain, preserving the design structure for variance estimation. Because NHIS data are publicly available and de-identified, this study did not require institutional review board approval or informed consent.

### Outcomes

The primary outcome was any cost-related barrier in the preceding 12 months, defined from six questions. Three questions asked of all adults captured delaying medical care because of cost, needing but not getting medical care because of cost, and needing but not getting prescription medication because of cost. Three questions asked of adults who had been prescribed medication in the past 12 months captured skipping doses, taking less medication, and delaying a prescription fill to save money.

A survivor with a "yes" response to any applicable question was classified as having a barrier. Classification as having no barrier required "no" responses to all three universal questions and either no prescription use or "no" responses to all three medication-use questions. Other response patterns were classified as unknown, so partially answered negative patterns were never treated as absence of a barrier. Secondary outcomes were each component separately, medication underuse (any of the three medication-use questions, among adults prescribed medication), and a three-question composite restricted to the universal items. Question wording and universes were verified against each year's codebook (Supplementary Methods).

### Covariates

Demographic covariates were survey year, age (natural cubic spline with three degrees of freedom), sex, race and Hispanic origin (seven published categories), and Census region. Socioeconomic covariates were education (less than high school; high school or equivalent; some college or associate degree; bachelor's degree or higher), family income as a percentage of the federal poverty level (FPL; below 100%, 100%–199%, 200%–399%, and 400% or higher), and health insurance (private coverage with or without public coverage; public coverage without private coverage; military coverage only; uninsured). Clinical and health-status covariates were diagnosed hypertension, diabetes, and coronary heart disease; cigarette smoking (never, former, current); fair or poor self-rated health; and disability, defined by the NCHS recode of the Washington Group questions as substantial difficulty in at least one functional domain. The education variable changed name between 2020 and 2021 and was harmonized across years.

### Statistical analysis

Prevalence estimates were survey-weighted with Taylor-series linearization for variance.[10] Annual confidence intervals used a logit transformation; pooled component intervals used a design-adjusted beta method, and subgroup estimates were pooled on the logit scale. All reported prevalence estimates met the NCHS presentation standards for proportions.[11]

Family income was imputed by NCHS for 26.8% of stroke survivors, and NCHS releases ten multiply imputed income files per year.[12] All analyses involving income were repeated in each of the ten completed data sets and combined with Rubin's rules using finite design degrees of freedom. Other covariates had little missingness (largest, 3.5% for smoking) and were handled by complete-case analysis.

Survey-weighted modified Poisson regression with robust variance estimated prevalence ratios for the primary outcome.[10,13] Three nested models were fit in the same analytic sample: Model 1 included year and demographic covariates; Model 2 added education, income, and insurance; and Model 3 added the clinical and health-status covariates. A parallel set of models replaced the age spline with a working-age indicator (18–64 versus 65 years and older) so that attenuation of the age-group association could be observed across adjustment sets. Adjusted annual prevalence was estimated by fitting a logistic model with the Model 3 covariates and standardizing each year's prediction to the pooled covariate distribution,[14] with variance accounting for both model and reference-distribution uncertainty. We tested categorical year and a year-by-age-group interaction using pooled Wald F tests.

Sensitivity analyses excluded 2020, restricted the sample to working-age adults or to adults without disability, modeled each component outcome, and added explicit "unknown" categories for missing covariates. Because log-binomial-type models can yield fitted values above one, key contrasts were re-estimated as standardized prevalence ratios from bounded logistic models. All primary prevalence estimates, standard errors, and the full model were independently reproduced in a second software environment. Analyses used R version 4.6.0 with the survey and mitools packages. P values are two-sided without adjustment for multiplicity; secondary and sensitivity analyses are exploratory. The analysis was not preregistered. Reporting follows the STROBE guideline.[15]

## Results

### Study population

The seven annual files contained 207,064 sample adults, of whom 7,565 reported a prior stroke (Figure S1). After exclusion of 10 records with unknown age and application of the pooled-sample rules for 2020, the pooled sample comprised 7,181 stroke survivors, of whom 7,104 (98.9%) had a classifiable primary outcome; 6,777 had complete covariates for adjusted models. In the weighted pooled sample, 41.0% were aged 18–64 years, 51.5% were female, 38.8% had a disability, and 51.9% rated their health as fair or poor (Table 1). More than half (53.6%) had public coverage without private insurance, 40.3% had private coverage, and 4.0% were uninsured.

### Prevalence of cost-related barriers

Overall, 1,184 survivors reported at least one cost-related barrier, a weighted prevalence of 17.9% (95% CI, 16.8%–19.1%), or approximately one in six stroke survivors (Table 2). The most common barrier was needing but not getting a prescription medication because of cost (10.0% (95% CI, 9.1%–11.0%)), followed by delaying medical care (8.5% (95% CI, 7.7%–9.4%)) and forgoing medical care (8.4% (95% CI, 7.6%–9.3%)). Among survivors prescribed medication, 10.1% (95% CI, 9.2%–11.1%) reported skipping doses, taking less, or delaying fills to save money. Restricting the composite to the three universal questions gave a prevalence of 15.5% (95% CI, 14.3%–16.6%) (Figure 1B).

Observed annual prevalence fluctuated between 15.3% and 20.6% without a monotonic trend (Figure 1A; Table 2). After standardization for demographic, socioeconomic, and clinical characteristics, prevalence was 19.2% (95% CI, 16.6%–22.0%) in 2019 and 17.0% (95% CI, 14.3%–20.1%) in 2025, an absolute difference of -2.1 percentage points (95% CI, -6.0 to 1.8). Neither categorical year (P=0.258) nor the interaction between year and age group (P=0.830) showed evidence of change over the period.

### Who reports cost-related barriers

Cost-related barriers were strongly patterned by age, income, and insurance (Figure 2). Working-age survivors reported barriers at 28.0% (95% CI, 25.9%–30.2%), compared with 10.9% (95% CI, 9.8%–12.0%) among survivors aged 65 years and older. Prevalence rose steeply with lower income, from 8.2% at 400% FPL or higher to 18.0% at 200%–399% FPL, 23.5% at 100%–199% FPL, and 22.5% below 100% FPL. Nearly three in five uninsured survivors reported a barrier (58.7% (95% CI, 50.7%–66.3%)), compared with 16.6% (95% CI, 14.9%–18.4%) of privately insured survivors and 15.8% (95% CI, 14.5%–17.3%) of those with public coverage only. Survivors with a disability reported barriers more often than those without (20.2% (95% CI, 18.4%–22.1%) versus 16.5% (95% CI, 15.1%–17.9%)).

In adjusted models, the working-age association attenuated but persisted (Table 3). The prevalence ratio for ages 18–64 versus 65 years and older was 2.51 (95% CI, 2.20–2.87) with demographic adjustment, 2.27 (95% CI, 1.98–2.61) after adding education, income, and insurance, and 2.18 (95% CI, 1.90–2.50) after further adjustment for clinical and health-status characteristics. Socioeconomic and clinical characteristics therefore accounted for only part of the age difference. Relative to income of 400% FPL or higher, fully adjusted prevalence ratios were 2.07 (95% CI, 1.65–2.61) for 200%–399% FPL, 2.50 (95% CI, 1.94–3.21) for 100%–199% FPL, and 2.00 (95% CI, 1.52–2.63) for below 100% FPL. Uninsured survivors had a prevalence ratio of 1.79 (95% CI, 1.49–2.16) relative to privately insured survivors, whereas public coverage without private insurance was associated with a lower adjusted prevalence (0.72 (95% CI, 0.63–0.83)). Disability was associated with a prevalence ratio of 1.19 (95% CI, 1.05–1.35). Female sex (PR, 1.27; 95% CI, 1.12–1.43), coronary heart disease (PR, 1.37; 95% CI, 1.18–1.58), current smoking (PR, 1.21; 95% CI, 1.04–1.42), and fair or poor self-rated health (PR, 1.58; 95% CI, 1.37–1.82) were also independently associated with barriers (Table S5).

### Sensitivity analyses

Results were materially unchanged when 2020 was excluded (income 100%–199% FPL: PR, 2.59; 95% CI, 2.00–3.36; uninsured: PR, 1.82; 95% CI, 1.49–2.21; disability: PR, 1.18; 95% CI, 1.04–1.34) and were consistent in direction across component outcomes and the missing-category analysis (Table S6). Within working-age survivors, the disability association was smaller and imprecise (PR, 1.08; 95% CI, 0.92–1.27). The fully adjusted modified Poisson model produced fitted values above one for approximately 0.2% of records; standardized prevalence ratios from bounded logistic models were closely similar (2.13 (95% CI, 1.86–2.44) for working age, 2.41 (95% CI, 1.88–3.09) for income 100%–199% FPL, 1.99 (95% CI, 1.63–2.43) for uninsured status, and 1.18 (95% CI, 1.04–1.33) for disability; Table S7). Barrier prevalence among the 327 survivors excluded from adjusted models for missing covariates (19.2%; 95% CI, 14.0%–25.5%) was similar to that in the analytic sample (17.8%).

## Discussion

In this nationally representative analysis spanning 2019 through 2025, roughly one in six US stroke survivors reported delaying or forgoing medical care, going without a needed prescription, or rationing medication because of cost in the preceding year. The burden was not evenly distributed. More than one in four working-age survivors and nearly three in five uninsured survivors reported a barrier, prevalence rose steeply as income fell, and survivors with disability were affected more often than those without. Working-age survivors remained more than twice as likely as older survivors to report a barrier even after accounting for income, insurance, education, and health status. Across seven years that included the pandemic and its temporary coverage protections, there was no evidence that affordability improved.

These findings update and extend a consistent body of evidence. Two decades ago, younger stroke survivors in NHIS were already less able to obtain physician care and medications,[3] and cost-related medication nonadherence was common through 2010.[4] The most recent stroke-specific estimate, 13% cost-related medication nonadherence in 2020–2023,[6] is consistent with the 10.1% (95% CI, 9.2%–11.1%) medication underuse and 10.0% (95% CI, 9.1%–11.0%) forgone prescriptions observed here. By also measuring delayed and forgone medical care, we show that the reach of cost extends beyond the pharmacy: for many survivors it is the visit itself, where risk factors are monitored and therapy adjusted, that is deferred. The stability of prevalence across 2019–2025 contrasts with the decline in cost-related nonadherence reported among working-age adults with multiple chronic conditions over 2019–2023,[7] suggesting that whatever relief reached other populations did not measurably reach stroke survivors.

The persistence of the working-age gradient after adjustment is the central finding for practice. Medicare eligibility at 65 years has long been the presumed explanation for the age difference, and the attenuation of the prevalence ratio from 2.51 to 2.18 (95% CI, 1.90–2.50) across models confirms that insurance and income account for part of it. Yet most of the excess remained. Working-age survivors face costs that older survivors do not: higher deductibles and cost sharing in commercial plans, loss of employment and employer coverage after stroke, competing household obligations, and fewer accumulated resources. Insurance categories in NHIS cannot capture underinsurance, which may be the operative mechanism for many privately insured survivors, 16.6% of whom reported a barrier. Screening for affordability problems should not be reserved for the uninsured.

The lower adjusted prevalence among survivors with public coverage relative to private coverage deserves careful interpretation. Public coverage in this population is predominantly Medicare, often with Medicaid or supplemental coverage that limits out-of-pocket exposure. The comparison is cross-sectional and does not show that a change in coverage type would change affordability; it does indicate that publicly insured survivors are not, as a group, the most affected. The independent association with disability, although modest, is consistent with the greater care needs and reduced earning capacity that follow disabling stroke, and it identifies a group in which affordability problems compound functional ones.

These results have direct implications for post-stroke care. Cost-related nonadherence is a modifiable cause of treatment failure, and clinicians rarely detect it unless they ask.[4,6] Brief affordability screening at follow-up, particularly for survivors younger than 65 years, those with lower income, and those with disability, could identify patients for whom generic substitution, patient assistance programs, insurance navigation, or social work referral would preserve secondary prevention. At the system level, the absence of improvement over seven years indicates that recent coverage policies have not resolved affordability for this high-risk population, and that stroke survivors merit specific consideration in policies addressing cost sharing for chronic disease medications.

### Strengths and limitations

Strengths include seven consecutive years of nationally representative data through 2025, a multidomain outcome that captures barriers to visits as well as medications, verification of question wording and universes across years, use of the NCHS-recommended weights for pooling the 2020 survey, incorporation of all ten income imputations, sequential adjustment within a single analytic sample, and independent reproduction of the primary results.

Several limitations apply. Stroke history and cost-related barriers were self-reported and are subject to recall and reporting error, and the survey does not identify stroke subtype, timing, or severity, so some barriers may have preceded the stroke. NHIS excludes institutionalized adults and therefore under-represents the most severely disabled survivors. The composite outcome treats different barriers equally and does not capture frequency, duration, or whether the forgone care was related to stroke; the survey cannot show which medications were rationed. Insurance and disability were measured at interview, whereas barriers refer to the preceding year. Unmeasured characteristics including wealth, out-of-pocket spending, benefit design, and caregiving support may confound the observed associations, which are descriptive rather than causal. Complete-case handling of the small amount of nonincome missingness and the approximate multiple-imputation joint tests could introduce minor bias. Finally, the analysis was not preregistered, and secondary comparisons should be interpreted as exploratory.

## Conclusions

Cost-related barriers to medical care and medications affect approximately one in six US stroke survivors and more than one in four of working age, and they showed no improvement between 2019 and 2025. Because these barriers interrupt the follow-up and pharmacotherapy on which secondary prevention depends, affordability should be assessed as routinely as blood pressure in the care of stroke survivors, with particular attention to younger, lower-income, uninsured, and disabled patients.

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

1. Palaniappan LP, Allen NB, Almarzooq ZI, et al. 2026 Heart Disease and Stroke Statistics: A Report of US and Global Data From the American Heart Association. Circulation. 2026;153:e275–e906. doi:10.1161/CIR.0000000000001412

2. Kleindorfer DO, Towfighi A, Chaturvedi S, Cockroft KM, Gutierrez J, Lombardi-Hill D, Kamel H, Kernan WN, Kittner SJ, Leira EC, et al. 2021 Guideline for the Prevention of Stroke in Patients With Stroke and Transient Ischemic Attack: A Guideline From the American Heart Association/American Stroke Association. Stroke. 2021;52:e364–e467. doi:10.1161/STR.0000000000000375

3. Levine DA, Kiefe CI, Houston TK, Allison JJ, McCarthy EP, Ayanian JZ. Younger stroke survivors have reduced access to physician care and medications: National Health Interview Survey from years 1998 to 2002. Arch Neurol. 2007;64:37–42. doi:10.1001/archneur.64.1.noc60002

4. Levine DA, Morgenstern LB, Langa KM, Piette JD, Rogers MAM, Karve SJ. Recent trends in cost-related medication nonadherence among stroke survivors in the United States. Ann Neurol. 2013;73:180–188. doi:10.1002/ana.23823

5. Springer MV, Skolarus LE, Patel M. Food Insecurity and Perceived Financial Stress are Associated with Cost-related Medication Non-adherence in Stroke. J Health Care Poor Underserved. 2023;34:625–639. doi:10.1353/hpu.2023.0054

6. Ansong R, Kyei G, Miezah D, Abubakari M, Kyei E. Cost-related medication nonadherence among adults with stroke in the United States: insight from the 2020-2023 National Health Interview Survey. J Racial Ethn Health Disparities. Published online January 27, 2026. doi:10.1007/s40615-026-02863-w

7. Amill-Rosario A, Slejko JF, dosReis S. Changes in cost-related nonadherence among US adults with multiple chronic conditions from 2019 to 2023. J Manag Care Spec Pharm. 2025;31:662–670. doi:10.18553/jmcp.2025.31.7.662

8. National Center for Health Statistics. 2025 National Health Interview Survey Survey Description. National Center for Health Statistics; 2026. Accessed September 18, 2026. https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2025/srvydesc-508.pdf

9. National Center for Health Statistics. 2020 National Health Interview Survey Survey Description. National Center for Health Statistics; 2021. Accessed September 18, 2026. https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2020/srvydesc-508.pdf

10. Lumley T. Analysis of Complex Survey Samples. J Stat Softw. 2004;9:1–19. doi:10.18637/jss.v009.i08

11. Parker JD, Talih M, Malec DJ, et al. National Center for Health Statistics Data Presentation Standards for Proportions. Vital Health Stat 2. 2017;:1–22.

12. National Center for Health Statistics. Multiple Imputation of Family Income in 2025 National Health Interview Survey Methods. National Center for Health Statistics; 2026. Accessed September 18, 2026. https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2025/NHIS2025-imputation-techdoc-508.pdf

13. Zou G. A modified Poisson regression approach to prospective studies with binary data. Am J Epidemiol. 2004;159:702–706. doi:10.1093/aje/kwh090

14. Graubard BI, Korn EL. Predictive Margins with Survey Data. Biometrics. 1999;55:652–659. doi:10.1111/j.0006-341X.1999.00652.x

15. von Elm E, Altman DG, Egger M, Pocock SJ, Gøtzsche PC, Vandenbroucke JP, STROBE Initiative. The Strengthening the Reporting of Observational Studies in Epidemiology Statement Guidelines for Reporting Observational Studies. PLoS Med. 2007;4:e296. doi:10.1371/journal.pmed.0040296

## Tables

### Table 1. Characteristics of US stroke survivors in the pooled 2019–2025 NHIS sample, overall and by cost-related barrier status

| Characteristic | Overall (N=7,104) | No barrier (n=5,920) | Any barrier (n=1,184) |
| --- | --- | --- | --- |
| Age 65 years or older | 4,763 (59.0) | 4,237 (64.0) | 526 (35.9) |
| Age 18–64 years | 2,341 (41.0) | 1,683 (36.0) | 658 (64.1) |
| Male | 3,269 (48.5) | 2,777 (49.7) | 492 (43.3) |
| Female | 3,835 (51.5) | 3,143 (50.3) | 692 (56.7) |
| Income ≥400% FPL | 1,681.2 (24.2) | 1,559.9 (27.0) | 121.3 (11.0) |
| Income 200–399% FPL | 2,133.3 (31.0) | 1,786.9 (31.0) | 346.4 (31.2) |
| Income 100–199% FPL | 1,986.9 (27.5) | 1,549.6 (25.6) | 437.3 (36.0) |
| Income <100% FPL | 1,302.6 (17.4) | 1,023.6 (16.4) | 279.0 (21.8) |
| Private, with or without public coverage | 2,888 (40.3) | 2,465 (40.9) | 423 (37.2) |
| Public without private | 3,871 (53.6) | 3,263 (54.9) | 608 (47.4) |
| Military only | 109 (1.6) | 92 (1.6) | 17 (1.7) |
| Uninsured | 207 (4.0) | 80 (2.0) | 127 (13.2) |
| Insurance unknown | 29 (0.5) | 20 (0.5) | 9 (0.6) |
| Without disability | 4,384 (61.2) | 3,742 (62.3) | 642 (56.3) |
| With disability | 2,720 (38.8) | 2,178 (37.7) | 542 (43.7) |
| Good or better self-rated health | 3,607 (48.0) | 3,201 (51.6) | 406 (31.7) |
| Fair or poor self-rated health | 3,486 (51.9) | 2,712 (48.3) | 774 (68.1) |
| Self-rated health unknown | 11 (0.1) | 7 (0.1) | 4 (0.2) |
| Never smoked | 3,196 (46.0) | 2,710 (46.6) | 486 (43.5) |
| Former smoker | 2,592 (34.0) | 2,240 (35.5) | 352 (27.2) |
| Current smoker | 1,132 (16.8) | 821 (14.7) | 311 (26.3) |
| Smoking unknown | 184 (3.2) | 149 (3.2) | 35 (3.0) |

Values are unweighted number (survey-weighted column percentage). Income counts are averaged across the ten NCHS imputations and may be fractional. Unknown values are retained in denominators; percentages within a variable may not sum to 100 because of rounding. FPL indicates federal poverty level; NHIS, National Health Interview Survey. Additional characteristics are given in Table S3.

### Table 2. Observed and standardized annual prevalence of any cost-related barrier among US stroke survivors, 2019–2025

| Year | No. with observed outcome | No. with barrier | Observed prevalence, % (95% CI) | Standardized prevalence, % (95% CI) |
| --- | --- | --- | --- | --- |
| 2019 | 1,191 | 231 | 20.6 (17.9–23.6) | 19.2 (16.6–22.0) |
| 2020 | 1,051 | 156 | 17.3 (14.4–20.6) | 17.1 (13.8–21.0) |
| 2021 | 1,001 | 179 | 19.4 (16.5–22.8) | 18.5 (15.6–21.8) |
| 2022 | 999 | 147 | 16.0 (13.4–19.0) | 16.0 (13.6–18.8) |
| 2023 | 1,116 | 169 | 15.3 (12.8–18.2) | 16.4 (13.9–19.2) |
| 2024 | 1,229 | 215 | 20.0 (17.3–23.1) | 20.4 (17.8–23.4) |
| 2025 | 889 | 138 | 16.8 (14.0–20.0) | 17.0 (14.3–20.1) |

Observed estimates use each year's full sample and annual weights. Standardized estimates come from the fully adjusted logistic model fitted in the pooled complete-case sample with 2020 partial-sample weights and ten income imputations, standardized to the pooled covariate distribution. Confidence intervals account for the complex survey design.

### Table 3. Prevalence ratios for any cost-related barrier among US stroke survivors under sequential adjustment

| Characteristic | Model 1, PR (95% CI) | Model 2, PR (95% CI) | Model 3, PR (95% CI) |
| --- | --- | --- | --- |
| Age 18–64 vs ≥65 years | 2.51 (2.20–2.87) | 2.27 (1.98–2.61) | 2.18 (1.90–2.50) |
| Female vs male | 1.30 (1.14–1.47) | 1.25 (1.10–1.42) | 1.27 (1.12–1.43) |
| Some college/associate vs bachelor's or higher | — | 0.94 (0.79–1.12) | 0.89 (0.75–1.06) |
| High school/GED vs bachelor's or higher | — | 0.81 (0.67–0.97) | 0.75 (0.62–0.89) |
| Less than high school vs bachelor's or higher | — | 0.91 (0.73–1.13) | 0.80 (0.64–0.99) |
| Income 200–399% vs ≥400% FPL | — | 2.29 (1.81–2.89) | 2.07 (1.65–2.61) |
| Income 100–199% vs ≥400% FPL | — | 2.95 (2.30–3.78) | 2.50 (1.94–3.21) |
| Income <100% vs ≥400% FPL | — | 2.43 (1.86–3.19) | 2.00 (1.52–2.63) |
| Public without private vs private | — | 0.79 (0.68–0.91) | 0.72 (0.63–0.83) |
| Military only vs private | — | 0.83 (0.53–1.30) | 0.81 (0.52–1.28) |
| Uninsured vs private | — | 1.76 (1.46–2.12) | 1.79 (1.49–2.16) |
| Hypertension vs none | — | — | 0.99 (0.86–1.14) |
| Diabetes vs none | — | — | 1.12 (0.97–1.30) |
| Coronary heart disease vs none | — | — | 1.37 (1.18–1.58) |
| Former vs never smoking | — | — | 0.98 (0.85–1.14) |
| Current vs never smoking | — | — | 1.21 (1.04–1.42) |
| Fair/poor vs good or better health | — | — | 1.58 (1.37–1.82) |
| Disability vs none | — | — | 1.19 (1.05–1.35) |

Survey-weighted modified Poisson regression with ten income imputations; all models include the same 6,777 survivors (1,117 with a barrier). Model 1 adjusts for survey year, age (spline), sex, race and Hispanic origin, and region. Model 2 adds education, family income, and insurance. Model 3 adds hypertension, diabetes, coronary heart disease, smoking, self-rated health, and disability. The age-group estimate is from a parallel model that replaces the age spline with an age-group indicator. Private coverage (with or without public coverage) is the reference for insurance. A dash indicates that the variable was not in the model. FPL indicates federal poverty level; GED, General Educational Development; PR, prevalence ratio. Complete Model 3 estimates are given in Table S5.



## Figures

![Figure 1](figures/figure1_annual_prevalence.png)

**Figure 1. Cost-related barriers among US stroke survivors, 2019–2025.** (A) Annual prevalence of any cost-related barrier, observed with annual survey weights (blue circles) and standardized to the pooled covariate distribution from the fully adjusted logistic model (orange triangles). (B) Pooled prevalence of the composite outcome and each component barrier. Medication underuse is estimated among survivors prescribed medication in the past 12 months. Error bars are 95% CIs.

![Figure 2](figures/figure2_adjusted_associations.png)

**Figure 2. Distribution of cost-related barriers by survivor characteristics.** (A) Unadjusted pooled prevalence of any cost-related barrier within groups defined by age, family income, insurance coverage, and disability. (B) Fully adjusted prevalence ratios (Model 3) from survey-weighted modified Poisson regression incorporating ten income imputations; the age contrast is from the parallel model that replaces the age spline with an age-group indicator. Reference groups are age 65 years and older, income 400% or more of the federal poverty level (FPL), private insurance, and no disability. Error bars are 95% CIs; the dashed line marks a prevalence ratio of 1. PR indicates prevalence ratio.
