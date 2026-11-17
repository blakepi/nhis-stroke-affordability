"""Independent Python check of the BRFSS pipeline (scripts/brfss_prepare.R, scripts/brfss_did.R).

1. For two years (2013, pre-expansion; 2019, post), re-reads the raw XPT file inside its zip, rebuilds the
   low-income stroke sample aged 18-64 (poverty guideline, household-size imputation from marital status,
   state exclusions) and compares the count with outputs/brfss/sample_counts.csv.
2. On the primary-sample data that brfss_did.R used in replicate 1 of a mode, estimates a weighted two-way
   fixed-effects difference-in-differences (state and year effects, standard errors clustered by state) and
   reports it beside the Callaway-Sant'Anna estimate. With a homogeneous planted effect both should recover it.
Usage: python -I scripts/validate_brfss.py <mode>
"""
import json
import sys
import zipfile

import numpy as np
import pandas as pd

MID2 = [5000, 12500, 17500, 22500, 30000, 42500, 62500, 100000]
EXCL = {10, 11, 25, 36, 50}


def recount(year):
    pov = pd.read_csv('outputs/brfss/hhs_poverty_guidelines.csv')
    pov = pov[pov.year == year].set_index('area')
    with zipfile.ZipFile(f'data/raw_brfss/LLCP{year}XPT.zip') as z:
        name = [n for n in z.namelist() if n.lower().strip().endswith('xpt')][0]
        with z.open(name) as fh:
            cols = ['_STATE', '_LLCPWT', 'CVDSTRK3', '_AGE80', 'INCOME2', 'NUMADULT', 'HHADULT', 'CHILDREN', 'MARITAL']
            reader = pd.read_sas(fh, format='xport', chunksize=100000)
            parts = []
            for chunk in reader:
                parts.append(chunk[[c for c in cols if c in chunk.columns]])
    d = pd.concat(parts, ignore_index=True)
    d = d[(d._STATE <= 56) & ~d._STATE.isin(EXCL) & (d._LLCPWT > 0)]
    adults = d.NUMADULT.where(d.NUMADULT.between(1, 76))
    if 'HHADULT' in d:
        adults = adults.fillna(d.HHADULT.where(d.HHADULT.between(1, 76)))
    adults = adults.fillna(pd.Series(np.where(d.MARITAL.isin([1, 6]), 2, np.where(d.MARITAL.between(2, 5), 1, np.nan)), index=d.index))
    kids = np.where(d.CHILDREN == 88, 0, np.where(d.CHILDREN.between(0, 87), d.CHILDREN, 0))
    hh = adults + kids
    area = np.where(d._STATE == 2, 'ak', np.where(d._STATE == 15, 'hi', 'us'))
    line = pov.loc[area, 'first_person'].to_numpy() + pov.loc[area, 'each_additional'].to_numpy() * np.maximum(hh - 1, 0)
    inc = d.INCOME2.where(d.INCOME2.between(1, 8))
    mid = inc.map(dict(enumerate(MID2, start=1)))
    low = (mid / line) <= 1.38
    sel = (d.CVDSTRK3 == 1) & d._AGE80.between(18, 64) & low & inc.notna() & hh.notna()
    return int(sel.sum())


def twfe(path, weighted=True):
    d = pd.read_csv(path)
    out = {}
    for y in ['uninsured', 'cost_barrier']:
        x = d[d[y].notna()].copy()
        x['D'] = ((x.g > 0) & (x.year >= x.g)).astype(float)
        X = pd.get_dummies(x[['state', 'year']].astype(str), drop_first=True, dtype=float)
        X.insert(0, 'D', x.D.to_numpy()); X.insert(0, 'const', 1.0)
        Xm = X.to_numpy(); w = x.wt.to_numpy() if weighted else np.ones(len(x)); yy = x[y].to_numpy(float)
        XtW = Xm.T * w
        beta = np.linalg.solve(XtW @ Xm, XtW @ yy)
        e = yy - Xm @ beta
        bread = np.linalg.inv(XtW @ Xm)
        sc = pd.DataFrame(Xm * (w * e)[:, None]).groupby(x.state.to_numpy()).sum().to_numpy()
        G = sc.shape[0]; meat = sc.T @ sc * G / (G - 1)
        V = bread @ meat @ bread
        out[y] = {'twfe_att': float(beta[1]), 'twfe_se': float(np.sqrt(V[1, 1])), 'n': int(len(x)), 'clusters': int(G)}
    return out


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else 'synthetic'
    counts = pd.read_csv('outputs/brfss/sample_counts.csv')
    res = {'mode': mode, 'recount': {}}
    for y in (2013, 2019):
        r = int(counts[(counts['sample'] == 'stroke 18-64, <=138% FPL') & (counts.year == y)].n.iloc[0])
        res['recount'][y] = {'python': recount(y), 'r': r}
    res['twfe_survey_weighted'] = twfe(f'data/processed/brfss/validation_did_{mode}.csv', True)
    res['twfe_unweighted'] = twfe(f'data/processed/brfss/validation_did_{mode}.csv', False)
    cs = pd.read_csv(f'outputs/brfss/did_{mode}/confirmatory_runs.csv')
    cs = cs[cs.replicate == 1]
    res['callaway_santanna_rep1'] = {r.analysis: {'att': r.ATT, 'se': r.se} for r in cs.itertuples()}
    res['recount_pass'] = all(v['python'] == v['r'] for v in res['recount'].values())
    with open(f'outputs/brfss/did_{mode}/validation_brfss.json', 'w', encoding='utf-8') as fh:
        json.dump(res, fh, indent=1)
    print(json.dumps(res, indent=1))


if __name__ == '__main__':
    main()
