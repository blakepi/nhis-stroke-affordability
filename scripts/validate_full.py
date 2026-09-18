"""Independently replicate Poisson IRLS, design covariance and Rubin pooling."""
from pathlib import Path
import json
import numpy as np
import pandas as pd
from validate import load_zip

ROOT = Path(__file__).resolve().parents[1]

def main():
    raw = json.loads((ROOT/'outputs/full/model_imputation_summaries.json').read_text())
    reported = pd.read_csv(ROOT/'outputs/full/model_coefficients.csv')
    pool_checks = []
    for label, fits in raw.items():
        assert len(fits) == 10
        b = np.array([f['coef'] for f in fits])
        within = np.mean([f['vcov'] for f in fits], axis=0)
        total = within + 1.1*np.cov(b, rowvar=False, ddof=1)
        out = reported[reported.model.eq(label)].set_index('term').loc[fits[0]['terms']]
        bdiff = float(np.max(np.abs(b.mean(axis=0)-out.log_PR.to_numpy())))
        sdiff = float(np.max(np.abs(np.sqrt(np.diag(total))-out.se.to_numpy())))
        assert bdiff < 1e-10 and sdiff < 1e-10, (label, bdiff, sdiff)
        pool_checks.append({'model':label,'coefficients':len(out),'max_log_coefficient_error':bdiff,'max_se_error':sdiff})
    f = raw['M3'][0]
    data = pd.read_csv(ROOT/'data/processed/full/model_matrix_m1.csv')
    x = data[f['terms']].to_numpy(); y = data.y.to_numpy(); w = data.weight.to_numpy()
    w = w/w.mean()
    beta = np.zeros(x.shape[1]); beta[0] = np.log(np.average(y,weights=w))
    for iterations in range(100):
        mu = np.exp(x@beta)
        info = x.T @ ((w*mu)[:,None]*x)
        step = np.linalg.solve(info,x.T@(w*(y-mu)))
        beta += step
        if np.max(np.abs(step)) < 1e-11: break
    else: raise AssertionError('Independent IRLS did not converge')
    mu = np.exp(x@beta)
    bread = np.linalg.inv(x.T@((w*mu)[:,None]*x))
    influence = ((w*(y-mu))[:,None]*x)@bread
    units = []
    for year in range(2019,2026):
        d = load_zip(ROOT/f'data/raw/{year}/adult{str(year)[-2:]}csv.zip',['HHX','WTFA_A','PSTRAT','PPSU'])
        if year == 2020:
            part = load_zip(ROOT/'data/raw/2020/adultpart20csv.zip',['HHX_2020','WTSA_P'])
            d = d[d.HHX.isin(part.loc[part.WTSA_P.gt(0),'HHX_2020'])]
        d = d[d.WTFA_A.gt(0)]
        units.append(d[['PSTRAT','PPSU']])
    universe = pd.concat(units).drop_duplicates().set_index(['PSTRAT','PPSU']).index
    u = pd.DataFrame(influence)
    u[['PSTRAT','PPSU']] = data[['PSTRAT','PPSU']]
    totals = u.groupby(['PSTRAT','PPSU']).sum().reindex(universe,fill_value=0)
    variance = np.zeros((x.shape[1],x.shape[1]))
    for _, group in totals.groupby(level=0):
        a = group.to_numpy(copy=True); n = len(a)
        assert n >= 2
        a -= a.mean(axis=0)
        variance += n/(n-1)*(a.T@a)
    coefficient_error = float(np.max(np.abs(beta-np.array(f['coef']))))
    covariance_error = float(np.max(np.abs(variance-np.array(f['vcov']))))
    assert coefficient_error < 1e-6 and covariance_error < 1e-6, (coefficient_error,covariance_error)
    diagnostics = pd.read_csv(ROOT/'outputs/full/model_diagnostics.csv')
    assert diagnostics.converged.all()
    assert len(diagnostics) == 160
    result = {'status':'PASS','independent_method':'NumPy Newton IRLS and full-design stratified PSU sandwich covariance',
      'first_imputation_M3':{'n':len(y),'events':int(y.sum()),'terms':len(beta),'iterations':iterations+1,
          'max_coefficient_error':coefficient_error,'max_covariance_error':covariance_error},
      'rubin_pooling_checks':pool_checks,'converged_poisson_fits':len(diagnostics),
      'limitations':'Uses the exported model matrix for independent coefficient replication. Does not independently recreate every covariate or every sensitivity model.'}
    (ROOT/'outputs/full/validation.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k!='rubin_pooling_checks'},indent=2))

if __name__ == '__main__': main()
