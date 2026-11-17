"""Independent Python check of the MEPS pipeline (scripts/meps_prepare.R, scripts/meps_analysis.R).

1. Rebuilds June coverage, the H1 exposure, the study population and covariates directly from the raw
   Stata files (no R intermediate file is read) and compares coverage counts with outputs/meps/sample_counts.csv.
2. Refits the H1 and H2 modified Poisson models (design-based linearized variance over the full pooled
   design) on the outcomes that meps_analysis.R used in replicate 1 of a given mode, and compares the
   log prevalence ratios and standard errors with outputs/meps/<mode>/confirmatory_runs.csv.
Usage: python -I scripts/validate_meps.py <mode>   (synthetic, null, or real after registration)
"""
import json
import sys

import numpy as np
import pandas as pd

sys.path.insert(0, 'scripts')
from validate_extended_models import ns_basis  # noqa: E402  (natural-spline basis matching splines::ns)

RAW = 'data/raw_meps/extracted'
FYC = {2019: 'h216', 2020: 'h224', 2021: 'h233', 2022: 'h243', 2023: 'h251', 2024: 'h256'}
MON = ['JA', 'FE', 'MA', 'AP', 'MY', 'JU', 'JL', 'AU', 'SE', 'OC', 'NO', 'DE']


def load():
    frames = []
    for y, f in FYC.items():
        yy = str(y)[2:]
        cols = ['DUPERSID', 'VARSTR', 'VARPSU', f'PERWT{yy}F', 'AGE42X', f'AGE{yy}X', 'SEX', 'RACETHX', f'REGION{yy}', 'HIDEG', f'POVCAT{yy}',
                'HIBPDX', 'DIABDX_M18', 'CHDDX', 'MIDX', 'ANGIDX', 'STRKDX', 'CHOLDX', 'RTHLTH42', 'RTHLTH31', 'OFTSMK53', 'ACCELI42',
                'MCRPHO42', f'PRIJU{yy}', f'MCRJU{yy}', f'MCDJU{yy}', f'GVAJU{yy}', f'GVBJU{yy}', f'GVCJU{yy}', f'VAPJU{yy}', f'TRIJU{yy}X']
        dis = [f'{v}{r}' for v in ['ACTLIM', 'WLKLIM', 'COGLIM', 'ADLHLP', 'IADLHP'] for r in ['31', '53']]
        have = set(pd.read_stata(f'{RAW}/{f}.dta', iterator=True).variable_labels())
        d = pd.read_stata(f'{RAW}/{f}.dta', columns=[c for c in cols + dis if c in have], convert_categoricals=False)
        d.columns = [c.replace(yy + 'F', 'F').replace(f'AGE{yy}X', 'AGEEOY').replace(f'REGION{yy}', 'REGION').replace(f'POVCAT{yy}', 'POVCAT')
                     .replace(f'JU{yy}X', 'JU').replace(f'JU{yy}', 'JU') for c in d.columns]
        for v in ['ACTLIM', 'WLKLIM', 'COGLIM', 'ADLHLP', 'IADLHP']:
            r31 = d.get(f'{v}31', pd.Series(np.nan, index=d.index)); r53 = d.get(f'{v}53', pd.Series(np.nan, index=d.index))
            d[v] = np.where(r31.isin([1, 2]), r31, np.where(r53.isin([1, 2]), r53, np.nan))
        d['year'] = y
        frames.append(d)
    return pd.concat(frames, ignore_index=True)


def derive(d):
    d['age'] = np.where(d.AGE42X >= 0, d.AGE42X, np.where(d.AGEEOY >= 0, d.AGEEOY, np.nan))
    inscope = d.PRIJU.isin([1, 2])
    pri, mcr, mcd = d.PRIJU == 1, d.MCRJU == 1, d.MCDJU == 1
    gv = (d.GVAJU == 1) | (d.GVBJU == 1) | (d.GVCJU == 1); mil = (d.TRIJU == 1) | (d.VAPJU == 1); ma = d.MCRPHO42 == 1
    u65 = np.select([~inscope, pri, mcd | gv, mcr | mil], [None, 'Private', 'Medicaid and other public', 'Other coverage'], default='Uninsured')
    o65 = np.select([~inscope, pri, mcr & mcd, mcr & ~(gv | mil) & ma, mcr & ~(gv | mil), mcd | gv | mil | mcr],
                    [None, 'Private', 'Dual eligible', 'Medicare Advantage', 'Medicare only excluding Medicare Advantage', 'Other coverage'], default='Uninsured')
    d['coverage'] = np.where(d.age < 65, u65, o65)
    d['age_group'] = np.where(d.age < 65, '18-64', '65+')
    d['medicaid_type'] = np.select([d.coverage.isin(['Medicaid and other public', 'Dual eligible']), d.coverage == 'Private'], [1.0, 0.0], default=np.nan)
    d['sex'] = d.SEX.where(d.SEX.isin([1, 2]))
    d['race'] = d.RACETHX.where(d.RACETHX.between(1, 5))
    d['region'] = d.REGION.where(d.REGION.between(1, 4))
    d['education'] = np.select([d.HIDEG == 1, d.HIDEG.isin([2, 3]), d.HIDEG == 7, d.HIDEG.isin([4, 5, 6])], ['LHS', 'HS', 'Other', 'BA'], default=None)
    d['income'] = d.POVCAT.where(d.POVCAT.between(1, 5))
    yn = lambda s: np.where(s == 1, 1.0, np.where(s == 2, 0.0, np.nan))  # noqa: E731
    d['hypertension'] = yn(d.HIBPDX); d['diabetes'] = yn(d.DIABDX_M18)
    d['coronary'] = np.where((d.CHDDX == 1) | (d.MIDX == 1) | (d.ANGIDX == 1), 1.0, np.where((d.CHDDX == 2) & (d.MIDX == 2) & (d.ANGIDX == 2), 0.0, np.nan))
    d['smoking'] = np.where(d.OFTSMK53.isin([1, 2]), 1.0, np.where(d.OFTSMK53.isin([3, -1]), 0.0, np.nan))
    rt = np.where(d.RTHLTH42 > 0, d.RTHLTH42, d.RTHLTH31)
    d['fairpoor'] = np.where(np.isin(rt, [4, 5]), 1.0, np.where(np.isin(rt, [1, 2, 3]), 0.0, np.nan))
    lim = d[['ACTLIM', 'WLKLIM', 'COGLIM', 'ADLHLP', 'IADLHP']]
    d['disability'] = np.where((lim == 1).any(axis=1), 1.0, np.where((lim == 2).all(axis=1), 0.0, np.nan))
    d['adult'] = d.age >= 18
    d['stroke'] = d.STRKDX == 1; d['high_chol'] = d.CHOLDX == 1; d['eligible'] = d.ACCELI42 == 1
    cov = ['age', 'sex', 'race', 'region', 'education', 'income', 'hypertension', 'diabetes', 'coronary', 'smoking', 'fairpoor', 'disability']
    d['complete'] = d[cov].notna().all(axis=1)
    d['wt'] = d.PERWTF / len(FYC)
    d['stratum'] = d.year.astype(str) + '_' + d.VARSTR.astype(str)
    d['psu'] = d.stratum + '_' + d.VARPSU.astype(str)
    d['coverage_c'] = np.where((d.age_group == '65+') & d.coverage.isin(['Uninsured', 'Other coverage']), '65+: Other or uninsured',
                               np.where(d.coverage.notna() & (d.coverage != 'None'), d.age_group + ': ' + d.coverage.astype(str), None))
    return d[d.wt > 0].reset_index(drop=True)


def dummies(dd, var, ref):
    out = {}
    for lv in sorted(set(dd[var].dropna()) - {ref}, key=str):
        out[f'{var}{lv}'] = (dd[var] == lv).astype(float).to_numpy()
    return out


def fit(full, dom, outcome, exposure_cols, extra_factors):
    dd = full[dom]
    cols = {'(Intercept)': np.ones(len(dd))}
    for c in exposure_cols:
        cols[c] = dd[c].to_numpy(float)
    if 'age_group' in extra_factors:
        cols['age_group65+'] = (dd.age_group == '65+').astype(float).to_numpy()
    b = ns_basis(dd.age.to_numpy(float))
    for i in range(b.shape[1]):
        cols[f'ns{i}'] = b[:, i]
    for var, ref in [('sex', 1), ('race', 2), ('region', 1), ('education', 'BA'), ('income', 5), ('year', 2019)] + ([('coverage_c', '18-64: Private')] if 'coverage_c' in extra_factors else []):
        cols.update(dummies(dd, var, ref))
    for c in ['hypertension', 'diabetes', 'coronary', 'smoking', 'fairpoor', 'disability']:
        cols[c] = dd[c].to_numpy(float)
    names = list(cols); X = np.column_stack([cols[k] for k in names])
    y = dd[outcome].to_numpy(float); w = dd.wt.to_numpy(float)
    beta = np.zeros(X.shape[1]); beta[0] = np.log(np.average(y, weights=w))
    for _ in range(200):
        mu = np.exp(X @ beta); step = np.linalg.solve((X * (w * mu)[:, None]).T @ X, X.T @ (w * (y - mu))); beta += step
        if np.max(np.abs(step)) < 1e-12:
            break
    mu = np.exp(X @ beta); A = (X * (w * mu)[:, None]).T @ X
    infl = (X * (w * (y - mu))[:, None]) @ np.linalg.inv(A)
    Z = np.zeros((len(full), X.shape[1])); Z[np.flatnonzero(dom)] = infl
    t = pd.DataFrame(Z).assign(s=full.stratum.to_numpy(), c=full.psu.to_numpy()).groupby(['s', 'c']).sum()
    V = np.zeros((X.shape[1],) * 2); lonely = 0
    grand = t.to_numpy().mean(axis=0)
    for _, g in t.groupby(level='s'):
        a = g.to_numpy(); n = len(a)
        if n > 1:
            dev = a - a.mean(axis=0); V += n / (n - 1) * dev.T @ dev
        else:  # survey.lonely.psu = "adjust": centre the single PSU at the grand mean of PSU totals
            dev = a - grand; V += dev.T @ dev; lonely += 1
    return pd.Series(beta, index=names), pd.DataFrame(V, index=names, columns=names), lonely


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else 'synthetic'
    d = derive(load())
    res = {'mode': mode, 'persons_with_positive_weight': int(len(d))}
    s = d[d.adult & d.stroke & d.eligible]
    counts = pd.read_csv('outputs/meps/sample_counts.csv')
    py_cov = s.groupby(['age_group', 'coverage']).size()
    rc = counts[counts.group.str.startswith('coverage ')].copy(); rc['age_group'] = rc.group.str.replace('coverage ', '')
    mism = [(r.age_group, r.level, int(r.n), int(py_cov.get((r.age_group, r.level), 0))) for r in rc.itertuples() if isinstance(r.level, str) and int(r.n) != int(py_cov.get((r.age_group, r.level), 0))]
    res['coverage_count_mismatches'] = mism
    res['stroke_person_years'] = int(len(s))
    o = pd.read_csv(f'data/processed/meps/validation_outcomes_{mode}.csv', dtype={'DUPERSID': str})
    d['DUPERSID'] = d.DUPERSID.astype(str)
    d = d.merge(o, on=['DUPERSID', 'year'], how='left')
    runs = pd.read_csv(f'outputs/meps/{mode}/confirmatory_runs.csv'); r1 = runs[runs.replicate == 1].set_index('hypothesis')
    checks = []
    dom1 = (d.adult & d.stroke & d.eligible & d.complete & d.medicaid_type.notna() & d.any_barrier.notna()).to_numpy()
    b, V, l1 = fit(d, dom1, 'any_barrier', ['medicaid_type'], ['age_group'])
    checks.append(('H1', b['medicaid_type'], np.sqrt(V.loc['medicaid_type', 'medicaid_type']), r1.loc['H1', 'log_PR'], r1.loc['H1', 'se']))
    dom2 = (d.adult & d.stroke & d.eligible & d.complete & d.high_chol & d.any_barrier.notna() & d.coverage_c.notna()).to_numpy()
    b, V, l2 = fit(d, dom2, 'no_ldl_fill', ['any_barrier'], ['coverage_c'])
    checks.append(('H2', b['any_barrier'], np.sqrt(V.loc['any_barrier', 'any_barrier']), r1.loc['H2', 'log_PR'], r1.loc['H2', 'se']))
    res['lonely_psu_strata'] = [l1, l2]
    res['models'] = [{'hypothesis': h, 'python_log_pr': float(pb), 'r_log_pr': float(rb), 'python_se': float(ps), 'r_se': float(rs),
                      'abs_coef_diff': float(abs(pb - rb)), 'rel_se_diff': float(abs(ps / rs - 1))} for h, pb, ps, rb, rs in checks]
    res['pass'] = (not mism) and all(m['abs_coef_diff'] < 1e-6 and m['rel_se_diff'] < 1e-3 for m in res['models'])
    with open(f'outputs/meps/{mode}/validation_meps.json', 'w', encoding='utf-8') as fh:
        json.dump(res, fh, indent=1)
    print(json.dumps(res, indent=1))
    sys.exit(0 if res['pass'] else 1)


if __name__ == '__main__':
    main()
