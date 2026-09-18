from pathlib import Path
import csv
import io
import zipfile

root = Path(__file__).resolve().parents[1]
for year in range(2019, 2026):
    p = root / f"data/raw/{year}/adult{str(year)[-2:]}csv.zip"
    if not p.exists():
        continue
    with zipfile.ZipFile(p) as z:
        with z.open(next(n for n in z.namelist() if n.lower().endswith('.csv'))) as f:
            reader = csv.DictReader(io.TextIOWrapper(f))
            names = reader.fieldnames
            rows = list(reader)
    print(year, 'adults', len(rows), 'stroke', sum(r.get('STREV_A') == '1' for r in rows))
    print(', '.join(n for n in names if any(k in n for k in ['RX', 'DLY', 'DNG', 'STRAT', 'PSU', 'WTFA', 'REINT', 'PART', 'AGEP', 'STREV'])))
