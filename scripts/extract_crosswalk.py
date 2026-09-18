"""Extract exact annual outcome metadata, with PDF page provenance."""
from pathlib import Path
import csv
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.vendor'))
import pymupdf

VARIABLES = ['STREV_A','AGEP_A','SEX_A','REGION','WTFA_A','PSTRAT','PPSU','MEDDL12M_A',
             'MEDNG12M_A','RX12M_A','RXSK12M_A','RXLS12M_A','RXDL12M_A',
             'RXDG12M_A','DISAB3_A','COVER_A','COVER65_A','HISPALLP_A']


def main():
    records, excerpts = [], []
    for year in range(2019, 2026):
        folder = ROOT / 'data/documentation' / str(year)
        for pdf in sorted(folder.glob('*.pdf')):
            with pymupdf.open(pdf) as doc:
                pages = [p.get_text() for p in doc]
            # Different destination from acquisition's pypdf text: no shared writes.
            pdf.with_suffix('.fast.txt').write_text('\n'.join(
                f'===== PDF PAGE {i+1} =====\n{t}' for i,t in enumerate(pages)), encoding='utf-8')
            if pdf.name != 'adult-codebook.pdf':
                continue
            for i, page in enumerate(pages):
                variable = re.search(r'Variable:\s*(\w+)', page)
                if not variable or variable.group(1) not in VARIABLES:
                    continue
                var = variable.group(1)
                def section(start, end):
                    m = re.search(re.escape(start)+r'\s*(.*?)\s*'+re.escape(end),page,re.S)
                    return ' '.join(m.group(1).split()) if m else ''
                records.append({'year': year,'variable': var,'pdf_page': i+1,
                    'question': section('Question Text:', 'Description:'),
                    'description': section('Description:', 'Recode:'),
                    'universe': section('Universe:', 'Universe Description:'),
                    'universe_description': section('Universe Description:', 'Sources:'),
                    'question_id': section('Question ID:', 'Keywords:'),
                    'notes': section('Notes:', 'Evaluation Report:'),
                    'source': f'https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/{year}/adult-codebook.pdf'})
                excerpts.append(f'## {year} {var}, PDF page {i+1}\n\n```text\n{page}\n```')
        found = {r['variable'] for r in records if r['year']==year}
        if found != set(VARIABLES):
            raise ValueError(f'{year}: missing codebook metadata for {set(VARIABLES)-found}')
    out=ROOT/'outputs'
    out.mkdir(exist_ok=True)
    with (out/'questionnaire_crosswalk.csv').open('w',newline='',encoding='utf-8') as f:
        writer=csv.DictWriter(f, fieldnames=list(records[0])); writer.writeheader(); writer.writerows(records)
    (out/'codebook_excerpts.md').write_text('# Exact codebook excerpts\n\n'+'\n\n'.join(excerpts),encoding='utf-8')
    for var in VARIABLES:
        rs=[r for r in records if r['variable']==var]
        variants = {}
        for r in rs:
            key=(r['question'],r['universe'])
            variants.setdefault(key,[]).append(r['year'])
        print(var, json.dumps([{'years':v,'question':k[0],'universe':k[1]} for k,v in variants.items()]),flush=True)


if __name__=='__main__': main()
