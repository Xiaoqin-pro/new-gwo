#!/usr/bin/env python3
"""Cross-arm (V2-steer50 + g2Subset=0.2) full analysis: freshv2 + combo2 merged."""
import os, sys, glob
import numpy as np, pandas as pd
from scipy import stats
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass
SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
A_COMBO = "V2-steer50-g20"

def holm(p):
    p = np.asarray(p, float); order = np.argsort(p); adj = np.empty_like(p); cur = 0.0
    for i, idx in enumerate(order):
        cur = max(cur, p[idx] * (len(p) - i)); adj[idx] = min(cur, 1.0)
    return adj

def stats_vs(piv, A, B):
    funcs = sorted(set(piv.index.get_level_values(0)))
    w = l = 0; rs = []; ps = []; ds = []; per = {}
    for f in funcs:
        if A not in piv.columns or B not in piv.columns: continue
        if f not in piv.index.get_level_values(0): continue
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
    return float(np.median(rs)), w, l, sb, sw, per, list(zip([f for f in funcs], ps, q))

def main():
    f2 = sorted(glob.glob(os.path.join(SQ, "results", "freshv2_*")))[-1]
    c2 = sorted(glob.glob(os.path.join(SQ, "results", "combo2_*")))[-1]
    df = pd.concat([pd.read_csv(os.path.join(f2, "runs.csv")), pd.read_csv(os.path.join(c2, "runs.csv"))],
                   ignore_index=True, sort=False)
    df = df[df.Status == "ok"]
    print(f"batches: {os.path.basename(f2)} + {os.path.basename(c2)}   ok runs: {len(df)}")
    piv = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
    print("arms:", sorted(piv.columns))
    print("\n=== vs IGWO-fresh (same seeds 3031:3060) ===")
    for A in ["V1-frozen", "V2-steer25", "V2-steer50", "V2-subset20", "V2-K5", A_COMBO]:
        if A not in piv.columns: continue
        r, w, l, sb, sw, per, pq = stats_vs(piv, A, "IGWO-fresh")
        print(f"{A:16s} ratio {r:.3f}  W-L {w}-{l}  Holm +{sb}/-{sw}  (sig:&)", )
    print("\n=== cross-arm vs V1-frozen / vs V2-steer50 ===")
    for B in ["V1-frozen", "V2-steer50"]:
        r, w, l, sb, sw, per, pq = stats_vs(piv, A_COMBO, B)
        print(f"{A_COMBO} vs {B:11s}: ratio {r:.3f}  W-L {w}-{l}  Holm +{sb}/-{sw}")
    print("\n=== mean ranks (avg over functions of median-rank among arms) ===")
    rank = piv.groupby(level=0).median().rank(axis=1).mean(axis=0).sort_values()
    for k, v in rank.items(): print(f"  {k:16s} {v:.2f}")
    print("\n=== per-function vs IGWO-fresh (cross-arm) ===")
    r, w, l, sb, sw, per, pq = stats_vs(piv, A_COMBO, "IGWO-fresh")
    wins = {f: round(v,2) for f, v in sorted(per.items()) if v < 0.95}
    losses = {f: round(v,2) for f, v in sorted(per.items()) if v > 1.05}
    near = {f: round(v,2) for f, v in sorted(per.items()) if 0.95 <= v <= 1.05}
    print("  wins  (<0.95):", wins)
    print("  near  (0.95-1.05):", near)
    print("  losses(>1.05):", losses)
    print("\n=== behaviour (recovery / stagnation) ===")
    for A in ["V1-frozen", "V2-steer50", "V2-subset20", A_COMBO]:
        if A not in set(df.Algorithm): continue
        e = df[df.Algorithm == A]
        ep = e["NStagEpisodes"].sum(); rec = e["NRecoveredWindow"].sum() / ep if ep else float("nan")
        print(f"  {A:16s} recov {rec:.4f}  longStag {e.LongStagShare.mean():.4f}  novUse {e.NovelUsefulRate.mean():.5f}  sec {e.Seconds.mean():.2f}")

if __name__ == "__main__":
    main()
