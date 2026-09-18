from concurrent.futures import ThreadPoolExecutor, as_completed
from acquire import ROOT, get
import json

def fetch(year):
    name=f'NHIS{year}-imputation-techdoc-508.pdf'
    url=f'https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/{year}/{name}'
    return {'year':year,'kind':'income_technical',**get(url,ROOT/f'data/documentation/{year}/{name}')}

manifest_path=ROOT/'outputs/source_manifest.json'
manifest=json.loads(manifest_path.read_text())
with ThreadPoolExecutor(max_workers=4) as pool:
    for future in as_completed([pool.submit(fetch,y) for y in range(2019,2026)]):
        result=future.result()
        manifest['files']=[r for r in manifest['files'] if not (r.get('kind')=='income_technical' and r['year']==result['year'])]
        manifest['files'].append(result)
        manifest_path.write_text(json.dumps(manifest,indent=2),encoding='utf-8')
        print(result['year'],result['bytes'],flush=True)
