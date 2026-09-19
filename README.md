# NHIS stroke survivor healthcare affordability study

Code, aggregate results, and submission-ready manuscript for *Cost-Related Barriers to Care and Medications Among US Stroke Survivors, 2019–2025* (G. Blake Pierpoint and Alberto E. Musto, Macon & Joan Brock Virginia Health Sciences Eastern Virginia Medical School at Old Dominion University). Public repository: https://github.com/blakepi/nhis-stroke-affordability. Tagged release cited in the manuscript: [v1.1.0](https://github.com/blakepi/nhis-stroke-affordability/releases/tag/v1.1.0). Analysis code is released under the MIT License (see LICENSE); the manuscript text, tables and figures remain the authors' work and are provided for review.

The analysis uses the 2019–2025 CDC public-use files. Start with the [manuscript PDF](manuscript/manuscript.pdf) or [Word file](manuscript/manuscript.docx); the [supplement](manuscript/supplement.pdf) contains the supplementary methods, Tables S1–S12 and Figure S1. [HANDOFF.md](HANDOFF.md) records the build history and verification.

## Manuscript files

- manuscript/manuscript.docx, .pdf and .md: title page, structured abstract, full text with continuous line numbers, declarations, 15 references, three tables, figure legends and two figures.
- manuscript/supplement.docx, .pdf and .md: supplementary methods, Tables S1–S12 (including outcome and covariate definitions and the STROBE checklist) and Figure S1.
- manuscript/tables/: editable CSV for each formatted table.
- manuscript/figures/: each figure as 300-dpi PNG and TIFF and as vector PDF.
- manuscript/references.json and .ris: verified source-linked reference metadata.
- manuscript/EDITORIAL_MATERIAL.md: cover letter, key points, plain-language summary and short title.
- manuscript/AUTHOR_INFORMATION.md: record of the author-supplied declarations.
- NHIS_Stroke_Manuscript_Working_Package.zip (built locally, not committed): portable writing, aggregate results and reproducibility code. Public microdata and large PDFs are not committed; they are downloadable with the included scripts.

## Main results

The pooled sample includes 7,104 records with observed outcomes; 1,184 reported a barrier, giving weighted prevalence 17.9% (95% CI 16.8–19.1%). Full models include 6,777 records. The age 18–64 versus 65+ adjusted PR is 2.18 (1.90–2.50); the uninsured versus private PR is 1.79 (1.49–2.16). The adjusted 2025-minus-2019 difference is -2.1 percentage points (-6.0 to 1.8). These are descriptive associations, not causal or recurrence effects.

## Reproduce or edit

From PowerShell in this directory:

    .\run_full.ps1 -WritingOnly

This rebuilds figures, tables, Word/Markdown documents, structural checks and the ZIP from existing aggregate results. Edit manuscript/draft_source.md and manuscript/supplement_source.md before rebuilding. Rebuilding overwrites generated Word/Markdown files; save an author-edited Word copy separately.

    .\run_full.ps1

This reruns all analysis from cached public files before rebuilding the package. For a fresh environment without raw files:

    .\run_full.ps1 -Download -ExtractDocumentation

The launcher resolves R 4.6.0 and a bundled Python at their original local paths, falling back to Rscript and python on PATH elsewhere. R packages: data.table, survey, mitools, ggplot2, jsonlite. Exact versions are recorded in outputs/full/R_session_info.txt. Python requirements are in requirements.txt; PyMuPDF is needed only for documentation extraction. The original run.ps1 is the historical launch-only pipeline; use run_full.ps1 for the complete package.

## Design and verification

Annual analyses use full-year weights. Pooled analyses omit 2020 followback records and use WTSA_P that year. All ten income imputations are used. Designs precede stroke-domain restriction, and public-use strata/PSU identifiers follow NCHS pooling instructions. See STUDY_PROTOCOL.md and the supplement.

Independent checks reproduce 12 primary prevalence estimates and Taylor SEs from source ZIPs, first-imputation full-model coefficients/covariance, and Rubin pooling across 16 specifications. All 160 modified Poisson fits converged. Rare fitted values above one are disclosed; bounded logistic sensitivity supports the principal patterns. All 36 downloaded source hashes are checked.

Figures were visually inspected and encoding defects corrected. DOCX structure and contents were checked, and PDFs exported through Microsoft Word were inspected page by page (14 pages each). When Word is not installed, check_manuscript.py records the export as not completed; Markdown copies contain all text and tables.

The study was not preregistered; full-model choices followed launch descriptives. Author details, contributions, competing interests and the ethics statement were supplied by the authors. No journal submission has occurred.

## Files

FILE_INVENTORY.csv lists files, full paths and roles. data/raw contains unchanged public ZIPs; data/documentation holds source PDFs and text; data/processed holds generated records/models. outputs/full holds current results. Root-level launch outputs and outputs/LAUNCH_REPORT.md remain historical; their statements that full modeling is pending are superseded by HANDOFF.md.

