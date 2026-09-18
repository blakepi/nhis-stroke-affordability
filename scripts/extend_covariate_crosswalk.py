"""Use retained CDC text extracts to document model covariates without rereading PDFs."""
from pathlib import Path
import csv,re,json
ROOT=Path(__file__).resolve().parents[1]
COMMON=['NOTCOV_A','PRIVATE_A','MEDICARE_A','MEDICAID_A','CHIP_A','OTHPUB_A','OTHGOV_A','MILITARY_A',
        'PHSTAT_A','DIBEV_A','HYPEV_A','CHDEV_A','SMKCIGST_A','DISAB3_A']
out=[];excerpts=[]
for year in range(2019,2026):
    text=(ROOT/f'data/documentation/{year}/adult-codebook.fast.txt').read_text(encoding='utf-8')
    for page in text.split('===== PDF PAGE '):
        m=re.search(r'Variable:\s*(\w+)',page)
        if not m or m.group(1) not in COMMON+['EDUC_A','EDUCP_A']:continue
        var=m.group(1)
        def section(a,b):
            m=re.search(re.escape(a)+r'\s*(.*?)\s*'+re.escape(b),page,re.S)
            return ' '.join(m.group(1).split()) if m else ''
        out.append(dict(year=year,variable=var,pdf_page=int(page.split()[0]),question=section('Question Text:','Description:'),
                        universe=section('Universe:','Universe Description:'),notes=section('Notes:','Evaluation Report:')))
        excerpts.append(f'## {year} {var}\n\n```text\n{page}\n```')
    assert len([r for r in out if r['year']==year])==len(COMMON)+1
with (ROOT/'outputs/covariate_crosswalk.csv').open('w',newline='',encoding='utf-8') as f:
    w=csv.DictWriter(f,fieldnames=list(out[0]));w.writeheader();w.writerows(out)
(ROOT/'outputs/covariate_codebook_excerpts.md').write_text('\n\n'.join(excerpts),encoding='utf-8')
for var in COMMON:
    rs=[r for r in out if r['variable']==var]
    print(var,'question variants',len(set(r['question'].lower() for r in rs)),'universe variants',len(set(r['universe'] for r in rs)))
print('Education mapping:',[(r['year'],r['variable']) for r in out if r['variable'].startswith('EDUC')])
