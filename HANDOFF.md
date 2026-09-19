# Working manuscript package handoff

Prepared 18 September 2026 in C:/Users/gbp34/Documents/ChatGPT/Stroke.

## Technical summary

**Update, 18 September 2026 (evening):** the package was polished to a submission candidate. The manuscript was rewritten for a journal audience (new title, sharper abstract and discussion, two added references including the 2026 AHA statistical update and Ansong et al. 2026), all process narration was removed from the manuscript and supplement, the Word output was restyled (12-point Times New Roman, double spacing, page breaks, AMA-style references, journal table formatting), and the three figures were rebuilt as two-panel publication figures with 300-dpi PNG/TIFF and vector PDF exports. Every page of both PDFs was inspected. Release v1.1.0 is cited in the manuscript.

The requested full writing package is prepared: Word and Markdown manuscript and supplement; title page, structured abstract and all main sections; declarations with author names, affiliations, ORCIDs, CRediT contributions and a competing-interests statement (funding statement and acknowledgments omitted at the authors' direction; ethics statement confirmed by the authors); 13 references; three main tables, nine numbered supplemental tables, two definition tables and STROBE checklist; two main figures and one cohort figure; key messages, plain-language summary and cover-letter draft. Exact word counts are in outputs/full/manuscript_metadata.json.

Analyses use actual CDC 2019–2025 NHIS data, the appropriate annual/pooled 2020 weights, all ten income imputations, survey-domain variance estimation, sequential adjusted models, annual standardization and sensitivities. The measured outcome is healthcare affordability among stroke survivors. Stroke-specific medication adherence, recurrence, causal insurance effects and policy effects are not established.

Pooled prevalence is 17.9% (95% CI 16.8–19.1%). The working-age aPR is 2.18 (1.90–2.50), uninsured aPR 1.79 (1.49–2.16), and disability aPR 1.19 (1.05–1.35). The overall year test is inconclusive (P=0.258). The within-working-age disability interval includes one. These qualifications are already written into the manuscript.

## Work log

1. Reviewed the planning report, confirmed the NHIS project, and acquired annual adult, income and documentation files plus the 2020 partial file.
2. Verified outcome questions/universes, built survey-weighted annual and pooled estimates, and independently reproduced the primary prevalence estimates and Taylor SEs.
3. Harmonized education, insurance and health covariates. Acquired income methods documents and corrected the original five-imputation expectation to ten.
4. Ran 160 modified Poisson fits, ten standardized-year logistic fits and 20 bounded logistic sensitivity fits. Exported all estimates and diagnostics.
5. Independently reproduced the first-imputation full model and design covariance and Rubin pooling across 16 specifications.
6. Wrote the full manuscript/supplement, references and editorial material. Generated tables and figures.
7. Inspected all three figures, corrected Windows text encoding, and checked Word structure/content. DOCX rendering initially failed because soffice.exe was unavailable.
8. Built and verified the portable ZIP with writing, aggregate outputs, code, source manifest and file inventory.
9. Inserted author names, affiliations, ORCIDs, CRediT contributions and the competing-interests statement; removed the funding placeholder at the authors' direction; hyphenated the title; fixed a doubled period after "et al" in the reference list and a duplicated supplement heading. Added Word-based PDF export to check_manuscript.py, exported manuscript.pdf and supplement.pdf (14 pages each), and visually inspected every page.

## Files

FILE_INVENTORY.csv lists all project files with their full paths and roles. No source data were deleted.

Main writing: manuscript/manuscript.docx and .md; manuscript/supplement.docx and .md. Authoring sources: manuscript/draft_source.md and manuscript/supplement_source.md. Supporting writing: manuscript/EDITORIAL_MATERIAL.md and manuscript/AUTHOR_INFORMATION.md. Tables: manuscript/tables/. Figures: manuscript/figures/. Reference metadata: manuscript/references.json and .ris.

Important current scripts: prepare_full_data.R, full_analysis.R, logistic_sensitivity.R, validate_full.py, make_figures.R, build_manuscript.py, check_manuscript.py and package_manuscript.py, all in scripts/. Acquisition, crosswalk and initial-analysis scripts remain available. Current outputs are in outputs/full/; source URLs/hashes are in outputs/source_manifest.json. The original attachment was reviewed without modification: C:/Users/gbp34/Downloads/deep-research-report (7).md.

## Verification and limitations

All 36 downloaded source-file hashes pass. Twelve primary estimates and their Taylor SEs are independently reconstructed from ZIPs. The independent full-model calculation agrees within 3×10^-13 for coefficients and 3×10^-9 for covariance. Rubin coefficient means and SEs agree across all 16 specifications. Independent model replication uses the exported matrix, rather than independently rebuilding every covariate.

Rare full-model fitted values above one, approximate multivariate MI tests, complete-case nonincome missingness, sparse subgroup contrasts and lack of preregistration are disclosed. Bounded logistic and missing-category sensitivities are supplied; they do not remove all modeling or selection uncertainty.

Figures were visually checked. DOCX content/structure passed checks, and pagination was visually verified from PDFs exported through Microsoft Word (manuscript/manuscript.pdf and manuscript/supplement.pdf, 14 pages each). Table header rows repeat across page breaks and figures sit on their own pages. The PDFs are regenerated on each rebuild when Word is installed; the complete Markdown versions remain readable and editable.

Nothing has been submitted to a journal. The repository was committed and pushed publicly to https://github.com/blakepi/nhis-stroke-affordability on 18 September 2026. Author identity, contributions, competing interests and the ethics statement were supplied or confirmed by the authors. Two long reference author lists are marked as abbreviated in RIS and may be completed through DOI import for final journal formatting.

## Continuation context

Use run_full.ps1 -WritingOnly to rebuild writing from current outputs. Edit the two *_source.md files first; generation overwrites the resulting Word and Markdown documents. Save directly edited Word copies separately. Use run_full.ps1 for cached-data reproduction or run_full.ps1 -Download -ExtractDocumentation for a fresh environment. Analysis stages were executed individually; the writing/package launcher was also exercised. A clean-machine installation test was not performed.

Do not revert to five imputations or ordinary 2020 annual weights for pooling. Keep denominators distinct: 7,555 annual eligible stroke records; 7,181 pooled eligible; 7,104 pooled observed outcomes; 6,777 complete model records. Historical launch outputs remain, but their pending-work descriptions are superseded here.

## Plain language explanation

The project has moved from an idea and preliminary estimates to a complete research draft based on real national data. The writing explains who had difficulty affording care after a reported stroke, how estimates varied over time, and what the survey cannot establish. You can edit a full paper and supporting materials directly rather than assemble them from analysis output.

## Actions for the user

Author names, affiliations, ORCIDs, contributions and competing interests were supplied on 18 September 2026 and are in the draft; no funding statement is included by author instruction. The authors confirmed no institutional review requirement and no acknowledgments, and the code is public at https://github.com/blakepi/nhis-stroke-affordability, tagged as release v1.0.0. Zenodo archiving was attempted on 18 September 2026 but the service was down; .zenodo.json is in place so a later release can be archived. See manuscript/AUTHOR_INFORMATION.md. No decision is needed to begin editing the scientific text.

## Human access or intervention required

Human authors must approve the interpretation and provide their own declarations before submission. No credentials or external action are needed to use the local package.

## Work that can continue with existing information

The requested working draft is complete. Later refinements include journal-specific word limits, citation/table formatting, and replacing the disclosed approximate joint MI tests with a specialized multivariate procedure. These are separate from preparing the complete writing requested here.

## Outside expertise

A survey-statistics coauthor would be useful for final joint-test and sparse-subgroup decisions. A stroke clinician can assess the clinical positioning of the broad access outcome. Neither is needed to open or edit the prepared package.

