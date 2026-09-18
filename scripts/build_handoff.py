"""Write a data-derived handoff and complete file inventory."""
from pathlib import Path
import csv
import json
import platform
import pandas as pd
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'outputs'


def pct(x): return f'{100*x:.1f}%'
def interval(row): return f'{pct(row.estimate)} ({pct(row.lower)}–{pct(row.upper)})'


def main():
    annual=pd.read_csv(OUT/'annual_prevalence.csv')
    flow=pd.read_csv(OUT/'cohort_flow.csv')
    poolflow=pd.read_csv(OUT/'pooled_cohort_flow.csv')
    pooled=pd.read_csv(OUT/'pooled_prevalence.csv')
    valid=json.loads((OUT/'validation.json').read_text())
    model=pd.read_csv(OUT/'model_diagnostics.csv').iloc[0]
    rows=annual[(annual.outcome=='any_barrier') & (annual.group=='All survivors')]
    annual_table='\n'.join(f'| {int(r.year)} | {int(r.n):,} | {int(r.events):,} | {interval(r)} |' for r in rows.itertuples())
    group_rows=pooled[pooled.outcome=='any_barrier']
    group_table='\n'.join(f'| {r.group} | {int(r.n):,} | {interval(r)} |' for r in group_rows.itertuples())
    report=f'''# NHIS study launch — results and continuation

18 September 2026. **The local study is running and the first analysis is verified.**
This handoff covers acquisition, question harmonization, feasibility, and an
initial survey analysis. It is not a completed submission package.

## First results

The seven CDC adult files contain **{flow.adults.sum():,} annual records** and
**{flow.raw_stroke.sum():,} records reporting prior stroke**. Excluding
{flow.stroke_unknown_age.sum()} stroke records with unknown age leaves
{flow.stroke_eligible.sum():,} annual stroke-domain records. The primary outcome
is observed for {flow.primary_observed.sum():,}; {flow.primary_unknown.sum()}
({100*flow.primary_unknown.sum()/flow.stroke_eligible.sum():.2f}%) remain unknown.
Annual records include 2019/2020 followback interviews and must not be described
as that many distinct people.

| Year | Observed stroke-domain records | Barrier events | Weighted prevalence (95% CI) |
|---|---:|---:|---:|
{annual_table}

![Annual weighted estimates]({(OUT/'annual_prevalence.png').as_posix()})

Pooled analyses exclude the 2020 followback sample and apply its non-followback
weights. This leaves {poolflow.stroke.sum():,} eligible stroke-domain records,
{poolflow.primary_observed.sum():,} with observed outcome and
{poolflow.primary_events.sum():,} barrier events.

| Pooled group | Observed records | Weighted prevalence (95% CI) |
|---|---:|---:|
{group_table}

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
  quasi-Poisson model. Its {int(model.n):,} records include {int(model.events):,}
  events; it converged, and fitted probabilities range from
  {model.fitted_min:.3f} to {model.fitted_max:.3f}, with no values above one.
  The model includes categorical year, a 3-df age spline, sex, race/ethnicity,
  and Census region. Full socioeconomic/clinical adjustment is not complete.

## Verification and limitations

Independent Python reconstruction from the untouched ZIPs reproduced all
seven primary annual estimates and five pooled estimates **and their
Taylor-linearized standard errors**, with absolute tolerance 1e-8. Source
SHA-256 checks passed for {valid['source_files_sha256_verified']} files.
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

Run `.\\run.ps1` in `{ROOT.as_posix()}` to rebuild the analysis and validation
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
'''
    (OUT/'LAUNCH_REPORT.md').write_text(report,encoding='utf-8')
    (ROOT/'requirements.txt').write_text(f'numpy=={np.__version__}\npandas=={pd.__version__}\nPyMuPDF==1.28.2\n',encoding='utf-8')
    inventory=OUT/'FILE_INVENTORY.csv'
    inventory.touch(exist_ok=True)
    def role(path):
        rel=path.relative_to(ROOT).as_posix()
        if rel.startswith('.vendor/'): return 'Workspace-local PDF-reader dependency; installed for codebook extraction'
        if '__pycache__/' in rel: return 'Generated Python bytecode cache'
        if rel.startswith('data/raw/'): return 'Untouched CDC public-use data ZIP'
        if rel.startswith('data/documentation/'): return 'CDC documentation or searchable local extraction; reviewed for methods'
        if rel.startswith('data/processed/'): return 'Generated analysis input, unpacked public CSV, or fitted R object'
        if rel.startswith('outputs/'): return 'Generated result, validation, provenance, or handoff artifact'
        if rel.startswith('scripts/'): return 'Executable acquisition, analysis, verification, or documentation script'
        return 'Project documentation, dependency specification, or launcher'
    items=[]
    for p in sorted(ROOT.rglob('*')):
        if '.git' in p.relative_to(ROOT).parts or not p.is_file(): continue
        items.append({'path':str(p.resolve()),'relative_path':p.relative_to(ROOT).as_posix(),'role':role(p)})
    items.append({'path':'C:\\Users\\gbp34\\Downloads\\deep-research-report (7).md','relative_path':'[external planning reference]','role':'Read only; project proposal, not independently verified instructions or citations'})
    with inventory.open('w',newline='',encoding='utf-8') as f:
        writer=csv.DictWriter(f,fieldnames=['path','relative_path','role']);writer.writeheader();writer.writerows(items)
    print(f'Wrote launch report and inventory of {len(items)} files. Python {platform.python_version()}.')


if __name__=='__main__': main()
