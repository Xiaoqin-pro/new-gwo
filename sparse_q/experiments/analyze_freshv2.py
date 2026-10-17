#!/usr/bin/env python3
"""Fresh-seed v2 vs IGWO analysis (screen12)."""
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
    w = l = 0; rs = []; ps = []; ds = []
    for f in funcs:
        ra, rb = piv.loc[f, A].dropna(), piv.loc[f, B].dropna()
        c = ra.index.intersection(rb.index)
        if len(c) == 0: continue
        ra, rb = ra.loc[c], rb.loc[c]
        rs.append(np.median(ra / rb))
        w += ra.mean() < rb.mean(); l += ra.mean() > rb.mean()
        d = np.log10(rb) - np.log10(ra)
        ps.append(stats.wilcoxon(d).pvalue if np.any(d != 0) else 1.0)
        ds.append(np.median(d))
    q = holm(ps)
    sb = sum((qi < 0.05) and (di > 0) for qi, di in zip(q, ds))
    sw = sum((qi < 0.05) and (di < 0) for qi, di in zip(q, ds))
    return float(np.median(rs)), w, l, sb, sw

def main():
    b = sorted([d for d in os.listdir(os.path.join(SQ, "results")) if d.startswith("freshv2_")])[-1]
    df = pd.read_csv(os.path.join(SQ, "results", b, "runs.csv"))
    df = df[df.Status == "ok"]
    piv = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
    print("=== FRESH SEEDS 3031:3060, D=50, 29 fn x 30 seeds ===")
    for A in ["V1-frozen", "V2-steer25", "V2-steer50", "V2-subset20", "V2-K5"]:
        for B in ["IGWO-fresh", "V1-frozen"]:
            if A == B: continue
            r, w, l, sb, sw = stats_vs(piv, A, B)
            print(f"{A:12s} vs {B:11s}: ratio {r:.3f}  W-L {w}-{l}  Holm +{sb}/-{sw}")
    print()
    rank = piv.groupby(level=0).median().rank(axis=1).mean(axis=0).sort_values()
    print("mean ranks:", {k: round(v, 2) for k, v in rank.items()})
    # per-function losses vs IGWO
    for A in ["V1-frozen", "V2-steer25", "V2-steer50", "V2-subset20", "V2-K5"]:
        subs = []
        for f in sorted(df.FunctionID.unique()):
            ra, rb = piv.loc[f, A].dropna(), piv.loc[f, "IGWO-fresh"].dropna()
            c = ra.index.intersection(rb.index)
            subs.append((f, np.median(ra.loc[c] / rb.loc[c])))
        losses = [f"{int(f)}({r:.2f})" for f, r in subs if r > 1.0]
        print(f"{A} vs IGWO losses: {losses}")
    # behaviour
    for A in ["V1-frozen", "V2-steer25", "V2-steer50", "V2-subset20", "V2-K5"]:
        e = df[df.Algorithm == A]
        ep = e["NStagEpisodes"].sum(); rec = e["NRecoveredWindow"].sum() / ep if ep else float("nan")
        print(f"{A:12s} recov {rec:.4f} longStag {e.LongStagShare.mean():.4f} novUse {e.NovelUsefulRate.mean():.5f} sec {e.Seconds.mean():.2f}")

if __name__ == "__main__":
    main()


