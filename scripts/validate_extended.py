"""Independent check of extended-analysis descriptive estimates.

Rebuilds the pooled analysis file from the extracted raw CSVs (not from the R
intermediate files), recomputes survey-weighted proportions, totals and Taylor
standard errors with numpy/pandas, and compares them with outputs/extended/*.csv.
Run from the project root after scripts/extended_analysis.R.
"""
import json
import sys

import numpy as np
import pandas as pd

RAW = "data/processed/extracted"
OUT = "outputs/extended"
COLS = ["HHX", "WTFA_A", "PSTRAT", "PPSU", "AGEP_A", "STREV_A", "MEDDL12M_A", "MEDNG12M_A", "RXDG12M_A",
        "RX12M_A", "RXSK12M_A", "RXLS12M_A", "RXDL12M_A", "COVER_A", "COVER65_A", "HYPEV_A", "HYPMED_A",
        "CHLEV_A", "CHLMED_A", "PAYBLL12M_A"]

frames = []
for y in range(2019, 2026):
    d = pd.read_csv(f"{RAW}/adult{str(y)[2:]}.csv", usecols=COLS, low_memory=False)
    d["year"] = y
    d["w"] = d["WTFA_A"].astype(float)
    if y == 2020:  # NCHS 2020 guidance: drop follow-back respondents, use the partial-sample weight
        part = pd.read_csv(f"{RAW}/adultpart20.csv")
        d["w"] = d["HHX"].map(dict(zip(part["HHX_2020"], part["WTSA_P"])))
    frames.append(d)
d = pd.concat(frames, ignore_index=True)
d = d[d["w"].notna() & (d["w"] > 0)].copy()
d["w"] = d["w"] / 7.0
num = [c for c in COLS if c != "HHX"]
d[num] = d[num].apply(pd.to_numeric, errors="coerce")
age_ok = d["AGEP_A"].between(18, 85)
stroke = (d["STREV_A"] == 1) & age_ok
nostroke = (d["STREV_A"] == 2) & age_ok
u65 = d["AGEP_A"] < 65


def yn(c):
    return np.where(d[c] == 1, 1.0, np.where(d[c] == 2, 0.0, np.nan))


def any_known(*cols):
    m = np.column_stack(cols)
    yes = np.nansum(m == 1, axis=1) > 0
    no = (~np.isnan(m)).all(axis=1) & (m == 0).all(axis=1)
    return np.where(yes, 1.0, np.where(no, 0.0, np.nan))


care = any_known(yn("MEDDL12M_A"), yn("MEDNG12M_A"))
universal = any_known(yn("MEDDL12M_A"), yn("MEDNG12M_A"), yn("RXDG12M_A"))
rx3 = any_known(yn("RXSK12M_A"), yn("RXLS12M_A"), yn("RXDL12M_A"))
uses = (d["RX12M_A"] == 1).to_numpy()
nonuse = (d["RX12M_A"] == 2).to_numpy()
pos = (universal == 1) | (uses & (rx3 == 1))
neg = (universal == 0) & (nonuse | (uses & (rx3 == 0)))
d["any_barrier"] = np.where(pos, 1.0, np.where(neg, 0.0, np.nan))
d["care_barrier"] = care
frx = yn("RXDG12M_A")
rxpos = (frx == 1) | (uses & (rx3 == 1))
rxneg = (frx == 0) & (nonuse | (uses & (rx3 == 0)))
d["rx_barrier"] = np.where(rxpos, 1.0, np.where(rxneg, 0.0, np.nan))
d["bills"] = yn("PAYBLL12M_A")
d["bp_nonuse"] = np.where(d["HYPEV_A"] == 1, 1 - yn("HYPMED_A"), np.nan)
d["chol_nonuse"] = np.where(d["CHLEV_A"] == 1, 1 - yn("CHLMED_A"), np.nan)
strata = d["PSTRAT"].to_numpy()
psu = d["PPSU"].to_numpy()


def taylor(z):
    t = pd.DataFrame({"z": z, "s": strata, "c": psu}).groupby(["s", "c"])["z"].sum().reset_index()
    return float(np.sqrt(t.groupby("s")["z"].apply(lambda x: len(x) / max(len(x) - 1, 1) * ((x - x.mean()) ** 2).sum()).sum()))


def prop(var, domain):
    m = (domain & d[var].notna()).to_numpy()
    w = np.where(m, d["w"].to_numpy(), 0.0)
    yv = np.nan_to_num(d[var].to_numpy())
    p = (w * yv).sum() / w.sum()
    return int(m.sum()), p, taylor(w * (yv - p) / w.sum())


def total(ind):
    z = d["w"].to_numpy() * ind.to_numpy().astype(float)
    return z.sum(), taylor(z)


checks = []


def compare(label, got, ref_est, ref_se, n=None, ref_n=None, rel=False):
    est, se = got
    scale = abs(ref_est) if rel else 1.0
    ok = abs(est - ref_est) <= 1e-8 * max(scale, 1) and abs(se - ref_se) <= 1e-8 * max(scale, 1) and (n is None or n == ref_n)
    checks.append({"check": label, "python_estimate": est, "r_estimate": ref_est, "python_se": se, "r_se": ref_se,
                   "python_n": n, "r_n": ref_n, "pass": bool(ok)})


comp = pd.read_csv(f"{OUT}/E1_E6_comparator_prevalence.csv")
for s, dom in (("Stroke", stroke), ("No stroke", nostroke)):
    for g, gm in (("18-64", u65), ("65+", ~u65)):
        for o in ("any_barrier", "care_barrier", "rx_barrier", "bills"):
            r = comp[(comp.stroke == s) & (comp.group == g) & (comp.outcome == o)].iloc[0]
            n, p, se = prop(o, dom & gm)
            compare(f"{o} | {s} {g}", (p, se), r.estimate, r.se, n, int(r.n))

cov = pd.read_csv(f"{OUT}/E3_coverage_prevalence.csv")
u_lab = {1: "Private", 2: "Medicaid and other public", 3: "Other coverage", 4: "Uninsured"}
o_lab = {1: "Private", 2: "Dual eligible", 3: "Medicare Advantage", 4: "Medicare only excluding Medicare Advantage", 5: "Other coverage"}
for code, lab in u_lab.items():
    r = cov[(cov.age_group == "18-64") & (cov.coverage == lab) & (cov.outcome == "any_barrier")].iloc[0]
    n, p, se = prop("any_barrier", stroke & u65 & (d["COVER_A"] == code))
    compare(f"any_barrier | stroke 18-64 {lab}", (p, se), r.estimate, r.se, n, int(r.n))
for code, lab in o_lab.items():
    r = cov[(cov.age_group == "65+") & (cov.coverage == lab) & (cov.outcome == "any_barrier")].iloc[0]
    n, p, se = prop("any_barrier", stroke & ~u65 & (d["COVER65_A"] == code))
    compare(f"any_barrier | stroke 65+ {lab}", (p, se), r.estimate, r.se, n, int(r.n))

med = pd.read_csv(f"{OUT}/E4_E5_outcomes_by_barrier.csv")
for o in ("bp_nonuse", "chol_nonuse"):
    for b in (0, 1):
        r = med[(med.outcome == o) & (med.group == "All ages") & (med.exposure == "any_barrier") & (med.exposed == b)].iloc[0]
        n, p, se = prop(o, stroke & (d["any_barrier"] == b))
        compare(f"{o} | stroke, any_barrier={b}", (p, se), r.estimate, r.se, n, int(r.n))

bur = pd.read_csv(f"{OUT}/E2_national_burden.csv").set_index("quantity")
for q, ind in (("n_stroke", stroke), ("n_barrier", stroke & (d["any_barrier"] == 1)), ("n_barrier_u65", stroke & u65 & (d["any_barrier"] == 1)),
               ("n_bills", stroke & (d["bills"] == 1))):
    compare(f"total {q}", total(ind), bur.loc[q, "average_annual_persons"], bur.loc[q, "se"], int(ind.sum()), int(bur.loc[q, "unweighted_n"]), rel=True)

result = {"checks": len(checks), "passed": int(sum(c["pass"] for c in checks)),
          "max_abs_estimate_difference_proportions": max(abs(c["python_estimate"] - c["r_estimate"]) for c in checks if not c["check"].startswith("total")),
          "max_abs_se_difference_proportions": max(abs(c["python_se"] - c["r_se"]) for c in checks if not c["check"].startswith("total")),
          "max_rel_difference_totals": max(max(abs(c["python_estimate"] / c["r_estimate"] - 1), abs(c["python_se"] / c["r_se"] - 1)) for c in checks if c["check"].startswith("total")),
          "details": checks}
with open(f"{OUT}/validation_extended.json", "w", encoding="utf-8") as fh:
    json.dump(result, fh, indent=1)
print({k: v for k, v in result.items() if k != "details"})
for c in checks:
    if not c["pass"]:
        print("FAIL", c)
sys.exit(0 if result["passed"] == result["checks"] else 1)
