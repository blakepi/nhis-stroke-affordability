"""Download the public MEPS (2019-2024) and BRFSS (2011-2025) files and record URL, size and SHA-256.

Approved by the user on 16 November 2026. Files go to data/raw_meps and data/raw_brfss (git-ignored);
manifests go to outputs/meps/source_manifest_meps.json and outputs/brfss/source_manifest_brfss.json.
Existing files with a recorded hash are verified and not downloaded again.
Usage: python -I scripts/acquire_meps_brfss.py [meps] [brfss]
"""
import hashlib
import json
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MEPS = {'h216': 'FYC 2019', 'h224': 'FYC 2020', 'h233': 'FYC 2021', 'h243': 'FYC 2022', 'h251': 'FYC 2023', 'h256': 'FYC 2024',
        'h213a': 'PMED 2019', 'h220a': 'PMED 2020', 'h229a': 'PMED 2021', 'h239a': 'PMED 2022', 'h248a': 'PMED 2023', 'h254a': 'PMED 2024'}


def sha256(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def fetch(url, dest):
    # cdc.gov answers curl normally but refuses Python's default client (HTTP 403), so use curl when available.
    import shutil
    import subprocess
    if shutil.which('curl'):
        part = dest.with_suffix('.part')
        for attempt in range(4):
            r = subprocess.run(['curl', '-sSfL', '--retry', '3', '-o', str(part), url])
            if r.returncode == 0 and part.stat().st_size > 0:
                part.replace(dest)
                return
            print(f'  retry {attempt + 1} for {url}: curl exit {r.returncode}', flush=True); time.sleep(10 * (attempt + 1))
        raise RuntimeError(f'failed: {url}')
    req = urllib.request.Request(url, headers={'User-Agent': 'research-data-download/1.0'})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=120) as r, open(dest.with_suffix('.part'), 'wb') as f:
                expected = int(r.headers.get('Content-Length', 0))
                n = 0
                for chunk in iter(lambda: r.read(1 << 20), b''):
                    f.write(chunk); n += len(chunk)
            if expected and n != expected:
                raise IOError(f'size mismatch {n} vs {expected}')
            dest.with_suffix('.part').replace(dest)
            return
        except Exception as e:  # noqa: BLE001
            print(f'  retry {attempt + 1} for {url}: {e}', flush=True); time.sleep(10 * (attempt + 1))
    raise RuntimeError(f'failed: {url}')


def run(items, rawdir, manifest_path):
    rawdir.mkdir(parents=True, exist_ok=True); manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    for name, (url, desc) in items.items():
        dest = rawdir / Path(url).name
        if dest.exists() and manifest.get(name, {}).get('sha256') == sha256(dest):
            print(f'ok (cached) {dest.name}', flush=True); continue
        print(f'downloading {url}', flush=True)
        fetch(url, dest)
        manifest[name] = {'description': desc, 'url': url, 'file': str(dest.relative_to(ROOT)).replace('\\', '/'), 'bytes': dest.stat().st_size,
                          'sha256': sha256(dest), 'downloaded': time.strftime('%Y-%m-%d %H:%M:%S')}
        manifest_path.write_text(json.dumps(manifest, indent=1))
        print(f'  {dest.name} {dest.stat().st_size:,} bytes', flush=True)


def main():
    which = sys.argv[1:] or ['meps', 'brfss']
    if 'meps' in which:
        run({k: (f'https://meps.ahrq.gov/mepsweb/data_files/pufs/{k}/{k}dta.zip', v) for k, v in MEPS.items()},
            ROOT / 'data/raw_meps', ROOT / 'outputs/meps/source_manifest_meps.json')
    if 'brfss' in which:
        run({f'LLCP{y}': (f'https://www.cdc.gov/brfss/annual_data/{y}/files/LLCP{y}XPT.zip', f'BRFSS {y}') for y in range(2011, 2026)},
            ROOT / 'data/raw_brfss', ROOT / 'outputs/brfss/source_manifest_brfss.json')


if __name__ == '__main__':
    main()
