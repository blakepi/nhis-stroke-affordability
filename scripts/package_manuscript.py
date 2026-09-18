"""Assemble a portable working-writing package with explicit data exclusions."""
from pathlib import Path
from hashlib import sha256
import csv
import json
import zipfile

ROOT=Path(__file__).resolve().parents[1]
ARCHIVE=ROOT/'NHIS_Stroke_Manuscript_Working_Package.zip'
TOP={'README.md','LICENSE','CITATION.cff','.zenodo.json','HANDOFF.md','STUDY_PROTOCOL.md','LITERATURE_NOTES.md','requirements.txt','run.ps1','run_full.ps1','.gitignore'}
CURRENT_OUTPUTS={'source_manifest.json','questionnaire_crosswalk.csv','codebook_excerpts.md','covariate_crosswalk.csv','covariate_codebook_excerpts.md','annual_prevalence.csv','pooled_prevalence.csv','cohort_flow.csv','pooled_cohort_flow.csv','missingness.csv','validation.json','R_session_info.txt'}

def role(rel):
    if rel.startswith('manuscript/tables/'):return 'Editable formatted table'
    if rel.startswith('manuscript/figures/'):return 'Scientific figure'
    if rel.startswith('manuscript/'):return 'Manuscript, source text or supporting writing'
    if rel.startswith('scripts/'):return 'Acquisition, analysis, verification or writing code'
    if rel.startswith('data/raw/'):return 'Unchanged public CDC microdata ZIP; retained locally'
    if rel.startswith('data/documentation/'):return 'Reviewed source documentation or searchable extract'
    if rel.startswith('data/processed/'):return 'Generated analytic records or fitted model object; retained locally'
    if rel.startswith('outputs/full/'):return 'Current aggregate result or verification output'
    if rel.startswith('outputs/'):return 'Launch output or shared provenance; see HANDOFF for current status'
    return 'Project documentation or entrypoint'

def include(rel):
    return rel in TOP or rel.startswith('manuscript/') or rel.startswith('scripts/') or rel.startswith('outputs/full/') or (rel.startswith('outputs/') and rel.split('/')[-1] in CURRENT_OUTPUTS)

def main():
    rows=[];packed=[]
    for p in sorted(ROOT.rglob('*')):
        if not p.is_file():continue
        rel=p.relative_to(ROOT).as_posix()
        if any(x in p.relative_to(ROOT).parts for x in ['.git','.vendor','.Rlib','__pycache__']):continue
        if p==ARCHIVE or rel in ['FILE_INVENTORY.csv','PACKAGE_CONTENTS.csv','outputs/full/package_validation.json']:continue
        yes=include(rel)
        rows.append({'path':rel,'absolute_path':str(p),'role':role(rel),'bytes':p.stat().st_size,'included_in_zip':yes})
        if yes:packed.append(p)
    rows.append({'path':'EXTERNAL_REFERENCE','absolute_path':'C:/Users/gbp34/Downloads/deep-research-report (7).md','role':'User planning attachment materially reviewed; not modified or included','bytes':'','included_in_zip':False})
    with (ROOT/'FILE_INVENTORY.csv').open('w',newline='',encoding='utf-8-sig') as f:
        writer=csv.DictWriter(f,fieldnames=rows[0].keys());writer.writeheader();writer.writerows(rows)
    packed.append(ROOT/'FILE_INVENTORY.csv')
    contents=[{'path':p.relative_to(ROOT).as_posix(),'bytes':p.stat().st_size,'sha256':sha256(p.read_bytes()).hexdigest()} for p in packed]
    with (ROOT/'PACKAGE_CONTENTS.csv').open('w',newline='',encoding='utf-8-sig') as f:
        writer=csv.DictWriter(f,fieldnames=['path','bytes','sha256']);writer.writeheader();writer.writerows(contents)
    packed.append(ROOT/'PACKAGE_CONTENTS.csv')
    with zipfile.ZipFile(ARCHIVE,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
        for p in packed:z.write(p,p.relative_to(ROOT).as_posix())
    with zipfile.ZipFile(ARCHIVE) as z:
        assert z.testzip() is None
        for r in contents:assert sha256(z.read(r['path'])).hexdigest()==r['sha256']
        assert 'manuscript/manuscript.docx' in z.namelist()
        assert 'manuscript/supplement.docx' in z.namelist()
        assert not any(n.startswith('data/raw/') for n in z.namelist())
    result={'status':'PASS','archive':str(ARCHIVE),'files':len(packed),'bytes':ARCHIVE.stat().st_size,'sha256':sha256(ARCHIVE.read_bytes()).hexdigest(),
       'scope':'Full writing, current aggregate results and reproducibility code. Raw public microdata, large PDFs, local dependencies and processed individual records excluded; download scripts and source hashes included.'}
    (ROOT/'outputs/full/package_validation.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result,indent=2))

if __name__=='__main__':main()
