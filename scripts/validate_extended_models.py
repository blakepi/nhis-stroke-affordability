"""Independent reproduction of key extended NHIS models (E1, E3, E4/E5) from the raw CSV files.

Does not read any R intermediate file. Rebuilds the pooled analysis file, all covariates, the ten
income imputations, a natural-spline age basis with the same knots as splines::ns(age, df=3), the
survey-weighted Poisson (log-link) estimating equations, the linearized design-based sandwich
variance (stratified, PSUs nested in strata, domain estimation over the full design), and
Rubin's rules. Compares the terms of interest with outputs/extended/*.csv.
Run from the project root with the project Python:  python scripts/validate_extended_models.py
"""
import json
import sys

import numpy as np
import pandas as pd

RAW = 'data/processed/extracted'
OUT = 'outputs/extended'
M = 10
COLS = ['HHX', 'WTFA_A', 'PSTRAT', 'PPSU', 'AGEP_A', 'SEX_A', 'HISPALLP_A', 'REGION', 'STREV_A', 'MEDDL12M_A', 'MEDNG12M_A',
        'RXDG12M_A', 'RX12M_A', 'RXSK12M_A', 'RXLS12M_A', 'RXDL12M_A', 'DISAB3_A', 'COVER_A', 'COVER65_A', 'NOTCOV_A', 'PRIVATE_A',
        'MEDICARE_A', 'MEDICAID_A', 'CHIP_A', 'OTHPUB_A', 'OTHGOV_A', 'MILITARY_A', 'PHSTAT_A', 'DIBEV_A', 'HYPEV_A', 'CHDEV_A',
        'SMKCIGST_A', 'HYPMED_A', 'CHLEV_A', 'CHLMED_A', 'EMERG12MTC_A', 'HOSPONGT_A']


# ----------------------------------------------------------------------------- data
def load():
    frames = []
    for y in range(2019, 2026):
        yy = str(y)[2:]
        hdr = pd.read_csv(f'{RAW}/adult{yy}.csv', nrows=0).columns
        edu = 'EDUC_A' if y < 2021 else 'EDUCP_A'
        d = pd.read_csv(f'{RAW}/adult{yy}.csv', usecols=[c for c in COLS if c in hdr] + [edu], low_memory=False).rename(columns={edu: 'EDU'})
        d['year'] = y
        frames.append(d)
    d = pd.concat(frames, ignore_index=True)
    num = [c for c in d.columns if c != 'HHX']
    d[num] = d[num].apply(pd.to_numeric, errors='coerce')
    part = pd.read_csv(f'{RAW}/adultpart20.csv')
    d['w'] = d['WTFA_A']
    m20 = d.year == 2020
    d.loc[m20, 'w'] = d.loc[m20, 'HHX'].map(dict(zip(part.HHX_2020, part.WTSA_P)))
    d = d[d.w.notna() & (d.w > 0)].copy()
    d['w'] = d.w / 7.0
    return d.reset_index(drop=True)


def yn(s):
    return np.where(s == 1, 1.0, np.where(s == 2, 0.0, np.nan))


def derive(d):
    d['age'] = np.where(d.AGEP_A.between(18, 85), d.AGEP_A, np.nan)
    med = np.column_stack([yn(d[c]) for c in ['MEDDL12M_A', 'MEDNG12M_A', 'RXDG12M_A']])
    rx3 = np.column_stack([yn(d[c]) for c in ['RXSK12M_A', 'RXLS12M_A', 'RXDL12M_A']])

    def any_known(m):
        yes = np.nansum(m == 1, axis=1) > 0
        no = (~np.isnan(m)).all(axis=1) & (m == 0).all(axis=1)
        return np.where(yes, 1.0, np.where(no, 0.0, np.nan))
    base = any_known(med); rx = any_known(rx3)
    uses = (d.RX12M_A == 1).to_numpy(); nonuse = (d.RX12M_A == 2).to_numpy()
    pos = (base == 1) | (uses & (rx == 1)); neg = (base == 0) & (nonuse | (uses & (rx == 0)))
    d['any_barrier'] = np.where(pos, 1.0, np.where(neg, 0.0, np.nan))
    dc, fc, fr = yn(d.MEDDL12M_A), yn(d.MEDNG12M_A), yn(d.RXDG12M_A)
    d['care_barrier'] = np.where((dc == 1) | (fc == 1), 1.0, np.where((dc == 0) & (fc == 0), 0.0, np.nan))
    under = np.where(uses, rx, np.nan)
    d['rx_barrier'] = np.where((fr == 1) | (under == 1), 1.0, np.where((fr == 0) & (nonuse | (under == 0)), 0.0, np.nan))
    d['stroke'] = (d.STREV_A == 1) & d.age.notna()
    d['known'] = d.STREV_A.isin([1, 2]) & d.age.notna()
    d['strokef'] = np.where(d.known, np.where(d.STREV_A == 1, 'Stroke', 'No stroke'), None)
    d['sex'] = d.SEX_A.where(d.SEX_A.isin([1, 2]))
    d['race'] = d.HISPALLP_A.where(d.HISPALLP_A.between(1, 7))
    d['region'] = d.REGION.where(d.REGION.between(1, 4))
    e = d.EDU
    d['education'] = np.select([e.between(0, 2), e.between(3, 4), e.between(5, 7), e.between(8, 11)],
                               ['Less than high school', 'High school or GED', 'Some college or associate', 'Bachelor or higher'], default=None)
    cov = lambda c: d[c].isin([1, 2])  # noqa: E731
    absent = lambda c: d[c] == 3  # noqa: E731
    pub = cov('MEDICARE_A') | cov('MEDICAID_A') | cov('CHIP_A') | cov('OTHPUB_A') | cov('OTHGOV_A')
    allabs = absent('MEDICARE_A') & absent('MEDICAID_A') & absent('CHIP_A') & absent('OTHPUB_A') & absent('OTHGOV_A')
    d['insurance'] = np.select([d.NOTCOV_A == 1, (d.NOTCOV_A == 2) & cov('PRIVATE_A'), (d.NOTCOV_A == 2) & absent('PRIVATE_A') & pub,
                                (d.NOTCOV_A == 2) & absent('PRIVATE_A') & allabs & cov('MILITARY_A')],
                               ['Uninsured', 'Private', 'Public without private', 'Military only'], default=None)
    d['hypertension'] = yn(d.HYPEV_A); d['diabetes'] = yn(d.DIBEV_A); d['coronary'] = yn(d.CHDEV_A)
    d['fairpoor'] = np.where(d.PHSTAT_A.isin([4, 5]), 1.0, np.where(d.PHSTAT_A.isin([1, 2, 3]), 0.0, np.nan))
    d['smoking'] = np.select([d.SMKCIGST_A.isin([1, 2]), d.SMKCIGST_A == 3, d.SMKCIGST_A == 4], ['Current', 'Former', 'Never'], default=None)
    d['disability'] = np.where(d.DISAB3_A == 1, 1.0, np.where(d.DISAB3_A == 2, 0.0, np.nan))
    nonincome = ['any_barrier', 'age', 'sex', 'race', 'region', 'education', 'insurance', 'hypertension', 'diabetes', 'coronary', 'fairpoor', 'smoking', 'disability']
    d['complete'] = d[nonincome].notna().all(axis=1)
    u65 = d.age < 65
    d['cover_u65'] = np.where(u65 & d.COVER_A.isin([1, 2, 3, 4]), d.COVER_A.map({1: 'Private', 2: 'Medicaid and other public', 3: 'Other coverage', 4: 'Uninsured'}), None)
    d['cover_65'] = np.where((d.age >= 65) & d.COVER65_A.isin([1, 2, 3, 4, 5]),
                             d.COVER65_A.map({1: 'Private', 2: 'Dual eligible', 3: 'Medicare Advantage', 4: 'Medicare only excluding Medicare Advantage', 5: 'Other coverage'}), None)
    d['chol_nonuse'] = np.where(d.CHLEV_A == 1, 1 - yn(d.CHLMED_A), np.nan)
    d['ed_2plus'] = np.where(d.EMERG12MTC_A.isin([2, 3, 4]), 1.0, np.where(d.EMERG12MTC_A.isin([0, 1]), 0.0, np.nan))
    return d


def incomes():
    out = {}
    for y in range(2019, 2026):
        inc = pd.read_csv(f'{RAW}/adultinc{str(y)[2:]}.csv')
        if 'IMPNUM' in inc.columns:
            inc = inc.rename(columns={'IMPNUM': 'IMPNUM_A'})
        inc['year'] = y
        out[y] = inc[['year', 'HHX', 'IMPNUM_A', 'RATCAT_A']]
    inc = pd.concat(out.values(), ignore_index=True)
    inc['income_group'] = pd.cut(inc.RATCAT_A, [0, 3, 7, 11, 14], labels=['<100%', '100-199%', '200-399%', '400%+']).astype(str)
    return inc


# ----------------------------------------------------------------------------- model machinery
def ns_basis(x, df=3):
    """Natural cubic spline basis spanning the same space as R splines::ns(x, df) (interior knots at type-7 quantiles)."""
    inner = np.quantile(x, np.linspace(0, 1, df + 1)[1:-1])
    knots = np.concatenate([[x.min()], inner, [x.max()]])
    K = len(knots)
    dk = lambda k: (np.clip(x - knots[k], 0, None) ** 3 - np.clip(x - knots[-1], 0, None) ** 3) / (knots[-1] - knots[k])  # noqa: E731
    cols = [x] + [dk(k) - dk(K - 2) for k in range(K - 2)]
    return np.column_stack(cols)


REFS = {'yearf': 2019, 'sex': 1, 'race': 1, 'region': 1, 'education': 'Bachelor or higher', 'income_group': '400%+', 'insurance': 'Private',
        'smoking': 'Never', 'cover_u65': 'Private', 'cover_65': 'Private', 'strokef': 'No stroke'}
NAME = {'hypertension': 'hypertensionYes', 'diabetes': 'diabetesYes', 'coronary': 'coronaryYes', 'fairpoor': 'fairpoorFair or poor',
        'disability': 'disabilityWith disability', 'any_barrier': 'any_barrier', 'care_barrier': 'care_barrier', 'rx_barrier': 'rx_barrier'}


def design_matrix(dd, terms):
    cols, names = [np.ones(len(dd))], ['(Intercept)']
    for t in terms:
        if t == 'age':
            b = ns_basis(dd.age.to_numpy(float)); cols += list(b.T); names += [f'ns{i}' for i in range(b.shape[1])]
        elif t in REFS:
            v = dd[t if t != 'yearf' else 'year']
            for lv in sorted(set(v.dropna()) - {REFS[t]}, key=str):
                cols.append((v == lv).to_numpy(float)); names.append(f'{t}{lv}')
        else:
            cols.append(dd[t].to_numpy(float)); names.append(NAME.get(t, t))
    return np.column_stack(cols), names


def fit(full, dom, outcome, terms):
    """Survey-weighted Poisson (log link) with linearized sandwich variance over the full design."""
    dd = full[dom]
    X, names = design_matrix(dd, terms)
    y = dd[outcome].to_numpy(float); w = dd.w.to_numpy(float)
    beta = np.zeros(X.shape[1]); beta[0] = np.log(np.average(y, weights=w))
    for _ in range(100):
        mu = np.exp(X @ beta)
        step = np.linalg.solve((X * (w * mu)[:, None]).T @ X, X.T @ (w * (y - mu)))
        beta += step
        if np.max(np.abs(step)) < 1e-12:
            break
    mu = np.exp(X @ beta)
    A = (X * (w * mu)[:, None]).T @ X
    infl = (X * (w * (y - mu))[:, None]) @ np.linalg.inv(A)
    # Domain estimation: out-of-domain records contribute zero but their PSUs still count.
    Z = np.zeros((len(full), X.shape[1])); Z[np.flatnonzero(dom)] = infl
    t = pd.DataFrame(Z).assign(s=full.PSTRAT.to_numpy(), c=full.PPSU.to_numpy()).groupby(['s', 'c']).sum()
    V = np.zeros((X.shape[1], X.shape[1]))
    for _, g in t.groupby(level='s'):
        a = g.to_numpy(); n = len(a)
        if n > 1:
            dev = a - a.mean(axis=0); V += n / (n - 1) * dev.T @ dev
    return pd.Series(beta, index=names), pd.DataFrame(V, index=names, columns=names)


def rubin(fits, term):
    b = np.array([f[0][term] for f in fits]); v = np.array([f[1].loc[term, term] for f in fits])
    W, B = v.mean(), b.var(ddof=1) if len(b) > 1 else 0.0
    return b.mean(), np.sqrt(W + (1 + 1 / len(b)) * B)


# ----------------------------------------------------------------------------- run
def main():
    d = derive(load())
    inc = incomes()
    dem = ['yearf', 'age', 'sex', 'race', 'region']
    clin = ['hypertension', 'diabetes', 'coronary', 'smoking', 'fairpoor', 'disability']
    full = dem + ['education', 'income_group', 'insurance'] + clin
    specs = [  # label, outcome, terms, domain function, reference csv, reference filter, terms to compare
        ('E3 coverage 18-64', 'any_barrier', dem + ['education', 'income_group', 'cover_u65'] + clin,
         lambda x: x.stroke & x.complete & (x.age < 65) & x.cover_u65.notna(), 'E3_coverage_PR.csv', {'age_group': '18-64'},
         ['cover_u65Medicaid and other public', 'cover_u65Other coverage', 'cover_u65Uninsured']),
        ('E3 coverage 65+', 'any_barrier', dem + ['education', 'income_group', 'cover_65'] + clin,
         lambda x: x.stroke & x.complete & (x.age >= 65) & x.cover_65.notna(), 'E3_coverage_PR.csv', {'age_group': '65+'},
         ['cover_65Dual eligible', 'cover_65Medicare Advantage', 'cover_65Medicare only excluding Medicare Advantage', 'cover_65Other coverage']),
        ('E4 cholesterol, any barrier', 'chol_nonuse', ['any_barrier'] + full, lambda x: x.stroke & x.complete & x.chol_nonuse.notna(),
         'E4_E5_barrier_PR.csv', {'outcome': 'chol_nonuse', 'model': 'Full + any barrier'}, ['any_barrier']),
        ('E4 cholesterol, joint', 'chol_nonuse', ['care_barrier', 'rx_barrier'] + full,
         lambda x: x.stroke & x.complete & x.chol_nonuse.notna() & x.care_barrier.notna() & x.rx_barrier.notna(),
         'E4_E5_barrier_PR.csv', {'outcome': 'chol_nonuse', 'model': 'Full + care and medication barriers'}, ['care_barrier', 'rx_barrier']),
        ('E5 2+ ED visits, any barrier', 'ed_2plus', ['any_barrier'] + full, lambda x: x.stroke & x.complete & x.ed_2plus.notna(),
         'E4_E5_barrier_PR.csv', {'outcome': 'ed_2plus', 'model': 'Full + any barrier'}, ['any_barrier']),
        ('E5 2+ ED visits, joint', 'ed_2plus', ['care_barrier', 'rx_barrier'] + full,
         lambda x: x.stroke & x.complete & x.ed_2plus.notna() & x.care_barrier.notna() & x.rx_barrier.notna(),
         'E4_E5_barrier_PR.csv', {'outcome': 'ed_2plus', 'model': 'Full + care and medication barriers'}, ['care_barrier', 'rx_barrier']),
        ('E1 stroke vs no stroke, Full', 'any_barrier', ['strokef'] + full, lambda x: x.known & x.complete & x.any_barrier.notna(),
         'E1_E6_stroke_vs_no_stroke_PR.csv', {'outcome': 'any_barrier', 'group': 'All ages', 'covariates': 'Full'}, ['strokefStroke']),
    ]
    results = []
    # Demographic-only comparison needs no income imputation.
    dom = (d.known & d.complete & d.any_barrier.notna()).to_numpy()
    b, V = fit(d, dom, 'any_barrier', ['strokef'] + dem)
    ref = pd.read_csv(f'{OUT}/E1_E6_stroke_vs_no_stroke_PR.csv')
    r = ref[(ref.outcome == 'any_barrier') & (ref.group == 'All ages') & (ref.covariates == 'Dem')].iloc[0]
    results.append(dict(model='E1 stroke vs no stroke, Dem', term='strokefStroke', python_log_pr=b['strokefStroke'], r_log_pr=r.log_PR,
                        python_se=float(np.sqrt(V.loc['strokefStroke', 'strokefStroke'])), r_se=r.se))
    fits = {s[0]: [] for s in specs}
    for m in range(1, M + 1):
        im = inc[inc.IMPNUM_A == m]
        key = dict(zip(zip(im.year, im.HHX), im.income_group))
        d['income_group'] = [key.get(k) for k in zip(d.year, d.HHX)]
        assert d.income_group.notna().all(), 'income linkage incomplete'
        for label, outcome, terms, domf, *_ in specs:
            fits[label].append(fit(d, domf(d).to_numpy(), outcome, terms))
        print(f'imputation {m} done', flush=True)
    for label, outcome, terms, domf, csvname, filt, compare in specs:
        ref = pd.read_csv(f'{OUT}/{csvname}')
        for k, v in filt.items():
            ref = ref[ref[k] == v]
        for t in compare:
            r = ref[ref.term == t].iloc[0]
            est, se = rubin(fits[label], t)
            results.append(dict(model=label, term=t, python_log_pr=est, r_log_pr=r.log_PR, python_se=se, r_se=r.se))
    res = pd.DataFrame(results)
    res['abs_coef_diff'] = (res.python_log_pr - res.r_log_pr).abs()
    res['rel_se_diff'] = (res.python_se / res.r_se - 1).abs()
    res['pass'] = (res.abs_coef_diff < 1e-6) & (res.rel_se_diff < 1e-4)
    res.to_csv(f'{OUT}/validation_extended_models.csv', index=False)
    summary = {'terms_checked': int(len(res)), 'passed': int(res['pass'].sum()), 'max_abs_coef_diff': float(res.abs_coef_diff.max()),
               'max_rel_se_diff': float(res.rel_se_diff.max()), 'tolerance': 'coefficient 1e-6 absolute (log scale); SE 1e-4 relative'}
    with open(f'{OUT}/validation_extended_models.json', 'w', encoding='utf-8') as fh:
        json.dump(summary, fh, indent=1)
    print(res[['model', 'term', 'abs_coef_diff', 'rel_se_diff', 'pass']].to_string(index=False))
    print(summary)
    sys.exit(0 if summary['passed'] == summary['terms_checked'] else 1)


if __name__ == '__main__':
    main()
