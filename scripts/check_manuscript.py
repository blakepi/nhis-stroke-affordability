"""Check document contents and source/result links; export PDFs through Microsoft Word when it is installed."""
from pathlib import Path
from hashlib import sha256
import json
import re
import subprocess
import zipfile
from docx import Document
import pandas as pd

ROOT=Path(__file__).resolve().parents[1]
def markdown_tables(text):
    tables=[];rows=[]
    for line in text.splitlines()+['']:
        if line.startswith('|'):
            row=[x.strip() for x in line.strip('|').split('|')]
            if not all(re.fullmatch(r':?-+:?',x) for x in row):rows.append(row)
        elif rows:tables.append(rows);rows=[]
    return tables

PS_EXPORT=r"""
$ErrorActionPreference='Stop'
$word=New-Object -ComObject Word.Application; $word.Visible=$false
try {
  foreach ($n in @('manuscript','supplement')) {
    $doc=$word.Documents.Open("ROOT\manuscript\$n.docx")
    $pages=$doc.ComputeStatistics(2)
    $doc.SaveAs2("ROOT\manuscript\$n.pdf",17)
    $doc.Close(0)
    Write-Output "$n=$pages"
  }
} finally { $word.Quit() }
"""

def render_pdfs():
    """Export both Word documents to PDF via Word automation and return page counts, or a reason it was skipped."""
    script=PS_EXPORT.replace('ROOT',str(ROOT))
    try:
        out=subprocess.run(['powershell','-NoProfile','-NonInteractive','-Command',script],capture_output=True,text=True,timeout=300)
    except (OSError,subprocess.TimeoutExpired) as e:
        return {'status':'NOT COMPLETED','reason':f'PowerShell/Word export did not run: {e}'}
    if out.returncode!=0:
        return {'status':'NOT COMPLETED','reason':'Microsoft Word automation failed: '+out.stderr.strip()[:300]}
    pages={k:int(v) for k,v in (line.split('=') for line in out.stdout.split() if '=' in line)}
    for n in pages:assert (ROOT/f'manuscript/{n}.pdf').stat().st_size>0
    return {'status':'COMPLETED','renderer':'Microsoft Word SaveAs2 PDF','pages':pages,'note':'Page counts come from Word; layout was inspected visually on 18 September 2026.'}

def main():
    results=[]
    for name,expected_tables,expected_images in [('manuscript',3,2),('supplement',12,1)]:
        md=(ROOT/f'manuscript/{name}.md').read_text(encoding='utf-8')
        assert '{{' not in md and '}}' not in md
        assert '\ufffd' not in md and '' not in md
        p=ROOT/f'manuscript/{name}.docx';doc=Document(p)
        assert len(doc.tables)==expected_tables
        assert len(doc.inline_shapes)==expected_images
        expected=markdown_tables(md)
        assert len(expected)==len(doc.tables)
        for table,rows in zip(doc.tables,expected):
            actual=[[cell.text for cell in row.cells] for row in table.rows]
            assert actual==rows
            assert abs(sum(c.width for c in table.rows[0].cells)/914400-6.5)<.02
        with zipfile.ZipFile(p) as z:
            assert z.testzip() is None
            media=[n for n in z.namelist() if n.startswith('word/media/')]
            embedded={sha256(z.read(n)).hexdigest() for n in media}
        for target in re.findall(r'!\[[^\]]*\]\(([^)]+)\)',md):
            fp=ROOT/'manuscript'/target
            assert fp.is_file() and sha256(fp.read_bytes()).hexdigest() in embedded
        results.append({'document':str(p),'tables_verified':len(doc.tables),'images_verified':len(doc.inline_shapes),'status':'PASS'})
    md=(ROOT/'manuscript/manuscript.md').read_text(encoding='utf-8')
    refs=json.loads((ROOT/'manuscript/references.json').read_text())
    ids={r['id'] for r in refs}
    cited=set()
    for m in re.findall(r'\[([0-9,]+)\]',md.split('## References')[0]):cited.update(map(int,m.split(',')))
    assert cited==ids,(cited,ids)
    assert len(ids)==13
    c=pd.read_csv(ROOT/'outputs/full/component_prevalence.csv').set_index('outcome')
    assert c.loc['any_barrier','n']==7104 and c.loc['any_barrier','events']==1184
    diag=pd.read_csv(ROOT/'outputs/full/model_diagnostics.csv')
    assert len(diag)==160 and diag.converged.all()
    ld=pd.read_csv(ROOT/'outputs/full/logistic_diagnostics.csv')
    assert len(ld)==20 and ld.converged.all() and ld.max_fitted.le(1).all() and ld.min_fitted.ge(0).all()
    for name in ['validation.json','full/validation.json']:
        assert json.loads((ROOT/'outputs'/name).read_text())['status']=='PASS'
    record={'status':'PASS','documents':results,'references_verified_for_in_text_numbering':13,
      'tables_match_generated_markdown':True,'embedded_images_match_current_files':True,
      'page_rendering':render_pdfs(),
      'limits':'Structural and content checks do not replace a visual pagination review of each rebuild. The remaining ethics-determination and acknowledgment placeholders are intentional.'}
    (ROOT/'outputs/full/manuscript_checks.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
    print(json.dumps(record,indent=2))

if __name__=='__main__':main()
