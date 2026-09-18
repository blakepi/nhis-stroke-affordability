# NHIS study launch — results and continuation

18 September 2026. **The local study is running and the first analysis is verified.**
This handoff covers acquisition, question harmonization, feasibility, and an
initial survey analysis. It is not a completed submission package.

## First results

The seven CDC adult files contain **207,064 annual records** and
**7,565 records reporting prior stroke**. Excluding
10 stroke records with unknown age leaves
7,555 annual stroke-domain records. The primary outcome
is observed for 7,476; 79
(1.05%) remain unknown.
Annual records include 2019/2020 followback interviews and must not be described
as that many distinct people.

| Year | Observed stroke-domain records | Barrier events | Weighted prevalence (95% CI) |
|---|---:|---:|---:|
| 2019 | 1,191 | 231 | 20.6% (17.9%–23.6%) |
| 2020 | 1,051 | 156 | 17.3% (14.4%–20.6%) |
| 2021 | 1,001 | 179 | 19.4% (16.5%–22.8%) |
| 2022 | 999 | 147 | 16.0% (13.4%–19.0%) |
| 2023 | 1,116 | 169 | 15.3% (12.8%–18.2%) |
| 2024 | 1,229 | 215 | 20.0% (17.3%–23.1%) |
| 2025 | 889 | 138 | 16.8% (14.0%–20.0%) |

![Annual weighted estimates](C:/Users/gbp34/Documents/ChatGPT/Stroke/outputs/annual_prevalence.png)

Pooled analyses exclude the 2020 followback sample and apply its non-followback
weights. This leaves 7,181 eligible stroke-domain records,
7,104 with observed outcome and
1,184 barrier events.

| Pooled group | Observed records | Weighted prevalence (95% CI) |
|---|---:|---:|
| All survivors | 7,104 | 17.9% (16.8%–19.1%) |
| 18-64 | 2,341 | 28.0% (25.9%–30.2%) |
| 65+ | 4,763 | 10.9% (9.8%–12.0%) |
| With disability | 2,720 | 20.2% (18.4%–22.1%) |
| Without disability | 4,384 | 16.5% (15.1%–17.9%) |

These are **unadjusted descriptive estimates**. The annual pattern fluctuates;
neither a monotonic trend nor a causal age effect is established. The pooled
estimate targets the average population over seven survey years, not the 2025
population alone. Age groups differ in insurance, income, and care needs.

## Technical summary

- Confirmed all seven public-use releases and acquired 29 source files: seven
  adult ZIPs, seven income ZIPs, seven codebooks, seven survey descriptions,
  and the special 2020 partial-weight ZIP.
- Verified identical substantive question wording and universes for stroke
  history and the affordability items; RX12M_A capitalization is the only
  wording difference in this core set. The crosswalk includes sex, age, region,
  race/ethnicity, disability, insurance hierarchies, and design metadata.
  Presence of a covariate in the crosswalk is not a completed pooled recode audit.
- The composite includes delayed/forgone medical care, forgone prescriptions,
  and three underuse behaviors when prescription use is reported. A yes in any
  applicable item establishes the outcome. A no requires all applicable items
  negative. Unknown/refused responses remain unknown unless another item
  establishes yes. Original structural blanks remain intact.
- Constructed survey designs on all adults before stroke-domain subsetting.
  Annual estimates use WTFA_A. Pooled results replace the 2020 weight with
  WTSA_P, exclude followback interviews, and divide weights by seven.
  PSTRAT/PPSU are retained as NCHS specifies for these public-use files.
- Produced component outcomes, a three-all-adult-item sensitivity composite,
  annual age groups, pooled age/disability groups, and a first demographic
  quasi-Poisson model. Its 7,104 records include 1,184
  events; it converged, and fitted probabilities range from
  0.025 to 0.502, with no values above one.
  The model includes categorical year, a 3-df age spline, sex, race/ethnicity,
  and Census region. Full socioeconomic/clinical adjustment is not complete.

## Verification and limitations

Independent Python reconstruction from the untouched ZIPs reproduced all
seven primary annual estimates and five pooled estimates **and their
Taylor-linearized standard errors**, with absolute tolerance 1e-8. Source
SHA-256 checks passed for 29 files.
Duplicate yearly household identifiers, invalid response codes, and observed
prescription-item answers outside their universe were checked. R also checks
that confidence intervals contain their estimates and remain within 0–1.
The chart was visually reviewed after correcting a locale-related subtitle issue.

Independent checks do not yet replicate model coefficients, every component
estimate, or the confidence-interval transformation. Initial precision flags
use n, effective n, relative standard error, and design degrees of freedom;
these flags are not a completed NCHS publication-reliability assessment.

The full adult CSVs have more observations in some years than the planning
report's approximate sample figures. Actual downloaded files and annual
codebooks control these counts. Education changes naming across years, so it
was deliberately omitted from this first model rather than combined silently.
Income files are present but have not been merged or analyzed.

Self-reported stroke history does not establish stroke type, date, severity, or
recurrence. The sampled population excludes institutionalized survivors.
Prescription questions do not identify the drug or its indication. These data
describe affordability barriers among survivors; they cannot establish that
cost caused another stroke or that every affected drug was for secondary prevention.

## Work log

1. Read the supplied report and empty workspace; user confirmed NHIS as the project.
2. Verified CDC release availability and screened closely related literature.
3. Downloaded public data/codebooks; recorded source URLs and hashes. CDC HTML
   pages rejected command-line requests, so acquisition used CDC's documented
   public HTTPS distribution server successfully.
4. Extracted exact questions/universes and corrected the 2020 pooling approach.
5. Built cohorts, missingness profiles, weighted estimates, and the first model.
6. Independently checked primary estimates/SEs and source integrity; executed
   the reusable PowerShell launcher and reviewed the plotted result.

## Files and resumption

[README](../README.md) provides the commands and output map.
[Study protocol](../STUDY_PROTOCOL.md) records operational definitions.
[Literature notes](../LITERATURE_NOTES.md) identify close prior studies and
the limits of the rapid novelty screen. [Complete file inventory](FILE_INVENTORY.csv)
lists every project file, including downloaded and generated files, with its
absolute path and role. The user's original report is also listed as reviewed.
[Source manifest](source_manifest.json) supplies provenance for the 29 downloads.

Run `.\run.ps1` in `C:/Users/gbp34/Documents/ChatGPT/Stroke` to rebuild the analysis and validation
offline. Use `-Download` to acquire missing sources, and `-ExtractDocumentation`
to rebuild the codebook crosswalk. The repository started without commits;
no commit, push, external publication, or submission was performed.

## Next work

**Work that can continue without additional input:** harmonize education and
the age-specific insurance hierarchies; merge all five income imputations with
year-specific identifiers and check merge completeness; fit sequential
socioeconomic and clinical models; compute standardized margins and the
prespecified age-by-year interaction; run the exclusion-of-2020 and working-age
sensitivities; apply full NCHS reliability criteria; complete the focused
literature review; then draft Methods/Results and the STROBE checklist.

**Actions for the user / human intervention:** none is needed to rerun or extend
this local public-data analysis. Before journal submission, the authors need
to supply authorship/affiliations, contributions, disclosures and funding, and
the applicable institutional research determination. No IRB exemption is
asserted here. Those matters do not prevent continued local analysis.

## Plain-language explanation

The project has moved from a proposal to a working analysis of real national
survey data. The first estimates suggest affordability problems are common
among stroke survivors, especially those under 65. The files and code can be
rerun, and an independent calculation agrees with the main numbers. The next
stage must determine how much of the group differences remains after accounting
for income, insurance, disability, and other health needs before writing a final paper.

Sources: [CDC 2025 release](https://www.cdc.gov/nchs/nhis/documentation/2025-nhis.html),
[CDC 2020 design guidance](https://www.cdc.gov/nchs/nhis/documentation/2020-nhis.html),
and annual codebooks documented in the source manifest and questionnaire crosswalk.
