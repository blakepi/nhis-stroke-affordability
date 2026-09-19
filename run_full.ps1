param([switch]$Download, [switch]$WritingOnly, [switch]$ExtractDocumentation)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$nhisPython = 'C:\Users\gbp34\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$nhisR = 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe'
if (!(Test-Path -LiteralPath $nhisPython)) { $nhisPython = (Get-Command python -ErrorAction Stop).Source }
if (!(Test-Path -LiteralPath $nhisR)) { $nhisR = (Get-Command Rscript -ErrorAction Stop).Source }
function Invoke-NhisPython([string]$Script) {
    & $nhisPython $Script
    if ($LASTEXITCODE -ne 0) { throw "Failed: $Script" }
}
function Invoke-NhisR([string]$Script) {
    & $nhisR $Script
    if ($LASTEXITCODE -ne 0) { throw "Failed: $Script" }
}
if ($Download) {
    Invoke-NhisPython 'scripts/acquire.py'
    Invoke-NhisPython 'scripts/acquire_partial.py'
    Invoke-NhisPython 'scripts/acquire_income_docs.py'
}
if ($ExtractDocumentation) {
    Invoke-NhisPython 'scripts/extract_crosswalk.py'
    Invoke-NhisPython 'scripts/extend_covariate_crosswalk.py'
}
if (!$WritingOnly) {
    Invoke-NhisR 'scripts/analyze.R'
    Invoke-NhisR 'scripts/prepare_full_data.R'
    Invoke-NhisR 'scripts/full_analysis.R'
    Invoke-NhisR 'scripts/logistic_sensitivity.R'
    Invoke-NhisPython 'scripts/validate.py'
    Invoke-NhisPython 'scripts/validate_full.py'
}
Invoke-NhisR 'scripts/make_figures.R'
Invoke-NhisR 'scripts/make_graphical_abstract.R'
Invoke-NhisPython 'scripts/build_manuscript.py'
Invoke-NhisPython 'scripts/check_manuscript.py'
Invoke-NhisPython 'scripts/package_manuscript.py'
Write-Host 'Working manuscript package rebuilt. See manuscript, HANDOFF.md, and the ZIP package.'
