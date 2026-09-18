"""Independent checks from the source ZIPs, including Taylor-linearized SEs."""
from pathlib import Path
from hashlib import sha256
import json
import zipfile
import numpy as np
import pandas as pd

ROOT=Path(__file__).resolve().parents[1]
CORE=['MEDDL12M_A','MEDNG12M_A','RXDG12M_A']
RX=['RXSK12M_A','RXLS12M_A','RXDL12M_A']


def load_zip(path, columns=None):
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None
        names=[n for n in z.namelist() if n.lower().endswith('.csv')]
        assert len(names)==1
        with z.open(names[0]) as f:
            return pd.read_csv(f,usecols=columns)


def classify(row):
    responses=list(row[:3])
    if row[3]==1:
        responses.extend(row[4:])
    elif row[3]!=2:
        responses.append(np.nan)
    if 1 in responses:
        return 1.0
    if all(x==2 for x in responses):
        return 0.0
    return np.nan


def linearized(d, weight, domain):
    eligible=domain & d['outcome'].notna()
    w=d[weight].where(eligible,0)
    total=w.sum()
    p=(w*d.outcome.fillna(0)).sum()/total
    influence=w*(d.outcome.fillna(0)-p)/total
    # Retain the entire adult design, including zero-influence PSUs.
    units=d[['PSTRAT','PPSU']].copy()
    units['u']=influence
    totals=units.groupby(['PSTRAT','PPSU']).u.sum()
    variance=0.0
    for _, stratum in totals.groupby(level=0):
        m=len(stratum)
        assert m>=2
        variance += m/(m-1)*float(((stratum-stratum.mean())**2).sum())
    return int(eligible.sum()),int(d.loc[eligible,'outcome'].sum()),p,variance**.5


def main():
    manifest=json.loads((ROOT/'outputs/source_manifest.json').read_text())
    checked=0
    for item in manifest['files']:
        if 'path' not in item:
            continue
        p=ROOT/item['path']
        assert p.stat().st_size==item['bytes'],p
        assert sha256(p.read_bytes()).hexdigest()==item['sha256'],p
        checked+=1
    annual=pd.read_csv(ROOT/'outputs/annual_prevalence.csv')
    flow=pd.read_csv(ROOT/'outputs/cohort_flow.csv').set_index('year')
    frames=[]; checks=[]
    cols=['HHX','STREV_A','AGEP_A','WTFA_A','PSTRAT','PPSU','DISAB3_A']+CORE+['RX12M_A']+RX
    for year in range(2019,2026):
        d=load_zip(ROOT/f'data/raw/{year}/adult{str(year)[-2:]}csv.zip',cols)
        assert d.HHX.is_unique
        d['outcome']=[classify(row) for row in d[CORE+['RX12M_A']+RX].to_numpy()]
        d['domain']=d.STREV_A.eq(1)&d.AGEP_A.between(18,85)&d.WTFA_A.gt(0)
        d['year']=year
        n,events,p,se=linearized(d,'WTFA_A',d.domain)
        expected=annual[(annual.year==year)&(annual.outcome=='any_barrier')&(annual.group=='All survivors')].iloc[0]
        assert n==expected['n'] and events==expected.events
        assert abs(p-expected.estimate)<1e-8
        assert abs(se-expected.se)<1e-8,(year,se,expected.se)
        assert len(d)==flow.loc[year,'adults']
        assert int(d.domain.sum())==flow.loc[year,'stroke_eligible']
        checks.append({'year':year,'n':n,'events':events,'estimate':p,'se':se,'status':'PASS'})
        d['pooled_weight']=d.WTFA_A
        if year==2020:
            part=load_zip(ROOT/'data/raw/2020/adultpart20csv.zip')
            assert part.HHX_2020.is_unique
            d['pooled_weight']=d.HHX.map(part.set_index('HHX_2020').WTSA_P)
        frames.append(d[d.pooled_weight.gt(0)].copy())
    combined=pd.concat(frames,ignore_index=True)
    combined['pooled_weight']/=7
    pooled=pd.read_csv(ROOT/'outputs/pooled_prevalence.csv')
    for group,domain in {
        'All survivors':combined.domain,
        '18-64':combined.domain&combined.AGEP_A.lt(65),
        '65+':combined.domain&combined.AGEP_A.ge(65),
        'With disability':combined.domain&combined.DISAB3_A.eq(1),
        'Without disability':combined.domain&combined.DISAB3_A.eq(2)}.items():
        n,events,p,se=linearized(combined,'pooled_weight',domain)
        expected=pooled[(pooled.group==group)&(pooled.outcome=='any_barrier')].iloc[0]
        assert n==expected['n'] and events==expected.events
        assert abs(p-expected.estimate)<1e-8
        assert abs(se-expected.se)<1e-8,(group,se,expected.se)
        checks.append({'group':group,'n':n,'events':events,'estimate':p,'se':se,'status':'PASS'})
    cross=pd.read_csv(ROOT/'outputs/questionnaire_crosswalk.csv').fillna('')
    for var in ['STREV_A']+CORE+['RX12M_A']+RX:
        rows=cross[cross.variable==var]
        assert len(rows)==7
        assert rows.question.str.lower().nunique()==1
        assert rows.universe.nunique()==1
    results={'status':'PASS','source_files_sha256_verified':checked,
             'independent_estimates_and_taylor_ses_verified':len(checks),
             'tolerance_absolute':1e-8,'checks':checks,
             'scope':'Primary annual and pooled prevalence, denominators, primary SEs, questionnaire wording/universes, source hashes. Model coefficients are not independently replicated.'}
    (ROOT/'outputs/validation.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    print(json.dumps({k:v for k,v in results.items() if k!='checks'},indent=2))


if __name__=='__main__': main()
