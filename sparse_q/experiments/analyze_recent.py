#!/usr/bin/env python3
"""Analysis for the recent-GWO-baseline comparison batch (screen13)."""
import os, sys
import numpy as np, pandas as pd
from scipy import stats
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass
SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"

def holm(p):
    p = np.asarray(p, float); order = np.argsort(p); adj = np.empty_like(p); cur = 0.0
    for i, idx in enumerate(order):
        cur = max(cur, p[idx] * (len(p) - i)); adj[idx] = min(cur, 1.0)
    return adj

def stats_vs(piv, A, B):
    funcs = sorted(set(piv.index.get_level_values(0)))
    w = l = 0; rs = []; ps = []; ds = []; per = {}
    for f in funcs:
        ra, rb = piv.loc[f, A].dropna(), piv.loc[f, B].dropna()
        c = ra.index.intersection(rb.index)
        if len(c) == 0: continue
        ra, rb = ra.loc[c], rb.loc[c]
        rr = np.median(ra / rb); rs.append(rr); per[int(f)] = rr
        w += ra.mean() < rb.mean(); l += ra.mean() > rb.mean()
        d = np.log10(rb) - np.log10(ra)
        ps.append(stats.wilcoxon(d).pvalue if np.any(d != 0) else 1.0); ds.append(np.median(d))
    q = holm(ps)
    sb = sum((qi < 0.05) and (di > 0) for qi, di in zip(q, ds))
    sw = sum((qi < 0.05) and (di < 0) for qi, di in zip(q, ds))
    return float(np.median(rs)), w, l, sb, sw, per

def main():
    b = sorted([d for d in os.listdir(os.path.join(SQ, "results")) if d.startswith("recent_")])[-1]
    df = pd.read_csv(os.path.join(SQ, "results", b, "runs.csv"))
    df = df[df.Status == "ok"]
    piv = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
    print("=== recent-GWO baselines vs S-star (D=50, 29 fn, seeds in batch) ===")
    for A in ["S-star", "DMSGWO-port", "RLGWO-port", "IGWO", "GWO"]:
        if A not in piv.columns: continue
        for B in ["GWO"]:
            if A == B: continue
            r, w, l, sb, sw, _ = stats_vs(piv, A, B)
            print(f"{A:12s} vs {B:4s}: ratio {r:.3f}  W-L {w}-{l}  Holm +{sb}/-{sw}")
    print()
    for A in ["DMSGWO-port", "RLGWO-port", "IGWO"]:
        r, w, l, sb, sw, per = stats_vs(piv, "S-star", A)
        print(f"S-star vs {A:12s}: ratio {r:.3f}  W-L {w}-{l}  Holm +{sb}/-{sw}")
        losses = {f: round(v,2) for f,v in per.items() if v > 1.05}
        print(f"   losses>1.05: {losses}")
    rank = piv.groupby(level=0).median().rank(axis=1).mean(axis=0).sort_values()
    print("\nmean ranks:", {k: round(v,2) for k,v in rank.items()})
    for a in piv.columns:
        e = df[df.Algorithm == a]
        print(f"{a:12s} sec {e.Seconds.mean():.2f}")

if __name__ == "__main__":
    main()
