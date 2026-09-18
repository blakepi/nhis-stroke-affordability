param([switch]$Download, [switch]$ExtractDocumentation)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$nhisPython = 'C:\Users\gbp34\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$nhisR = 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe'
if (!(Test-Path -LiteralPath $nhisPython)) { $nhisPython = (Get-Command python -ErrorAction Stop).Source }
if (!(Test-Path -LiteralPath $nhisR)) { $nhisR = (Get-Command Rscript -ErrorAction Stop).Source }
if ($Download) {
    & $nhisPython scripts/acquire.py
    if ($LASTEXITCODE -ne 0) { throw 'Acquisition failed.' }
    & $nhisPython scripts/acquire_partial.py
    if ($LASTEXITCODE -ne 0) { throw '2020 partial-weight acquisition failed.' }
}
if ($ExtractDocumentation) {
    & $nhisPython scripts/extract_crosswalk.py
    if ($LASTEXITCODE -ne 0) { throw 'Codebook extraction failed.' }
}
& $nhisR scripts/analyze.R
if ($LASTEXITCODE -ne 0) { throw 'Survey analysis failed.' }
& $nhisPython scripts/validate.py
if ($LASTEXITCODE -ne 0) { throw 'Independent validation failed.' }
& $nhisPython scripts/build_handoff.py
if ($LASTEXITCODE -ne 0) { throw 'Handoff report generation failed.' }
Write-Host 'NHIS launch analysis and validation completed. See outputs and README.md.'
