"""2020 non-followback weights required for pooled 2019+2020 analyses."""
from acquire import ROOT, get
import json

url = 'https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2020/adultpart20csv.zip'
result = get(url, ROOT / 'data/raw/2020/adultpart20csv.zip')
p = ROOT / 'outputs/source_manifest.json'
manifest = json.loads(p.read_text(encoding='utf-8'))
manifest['files'] = [r for r in manifest['files'] if r.get('kind') != 'partial']
manifest['files'].append({'year':2020, 'kind':'partial', **result})
p.write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print(result)
