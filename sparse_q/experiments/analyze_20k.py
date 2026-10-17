#!/usr/bin/env python3
"""20k-FE resource-tier analysis (all methods share the 20k budget)."""
import os, sys
import numpy as np, pandas as pd
from scipy import stats
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass
ROOT = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
SQ = os.path.join(ROOT, "sparse_q")

def holm(p):
    p = np.asarray(p, float); order = np.argsort(p); adj = np.empty_like(p); cur = 0.0
    for i, idx in enumerate(order):
        cur = max(cur, p[idx] * (len(p) - i)); adj[idx] = min(cur, 1.0)
    return adj

def stats_vs(piv, A, B):
    funcs = sorted(set(piv.index.get_level_values(0)))
    w = l = 0; rs = []; ps = []; ds = []
    for f in funcs:
        ra, rb = piv.loc[f, A].dropna(), piv.loc[f, B].dropna()
        c = ra.index.intersection(rb.index)
        if len(c) == 0: continue
        ra, rb = ra.loc[c], rb.loc[c]
        rs.append(np.median(ra / rb)); w += ra.mean() < rb.mean(); l += ra.mean() > rb.mean()
        d = np.log10(rb) - np.log10(ra)
        ps.append(stats.wilcoxon(d).pvalue if np.any(d != 0) else 1.0); ds.append(np.median(d))
    q = holm(ps)
    sb = sum((qi < 0.05) and (di > 0) for qi, di in zip(q, ds))
    sw = sum((qi < 0.05) and (di < 0) for qi, di in zip(q, ds))
    return float(np.median(rs)), w, l, sb, sw

def main():
    b = sorted([d for d in os.listdir(os.path.join(SQ, "results")) if d.startswith("f20k_")])[-1]
    df = pd.read_csv(os.path.join(SQ, "results", b, "runs.csv"))
    df = df[df.Status == "ok"]
    piv = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
    A = "S-star"
    print("=== 20k-FE resource tier (29 fn x 10 seeds) ===")
    for B in ["GWO", "B0-ANGWO", "B1-dense-sync", "S1-pool38"]:
        if B not in piv.columns: continue
        r, w, l, sb, sw = stats_vs(piv, A, B)
        print(f"S-star vs {B:14s}: ratio {r:.3f}  W-L {w}-{l}  Holm +{sb}/-{sw}")
    rank = piv.groupby(level=0).median().rank(axis=1).mean(axis=0).sort_values()
    print("mean ranks:", {k: round(v,2) for k,v in rank.items()})

if __name__ == "__main__":
    main()
