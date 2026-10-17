#!/usr/bin/env python3
"""Final v2 decision table: merge freshv2 (6 arms) + combo2 and report
Holm vs IGWO plus vs-V1 comparisons for every candidate."""
import os, sys, glob
import numpy as np, pandas as pd
from scipy import stats
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass
SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"

def holm(p):
    p = np.asarray(p, float); o = np.argsort(p); a = np.empty_like(p); c = 0.0
    for i, ix in enumerate(o):
        c = max(c, p[ix] * (len(p) - i)); a[ix] = min(c, 1.0)
    return a

def cmp(piv, A, B):
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
    sb = sum((x < 0.05) and (y > 0) for x, y in zip(q, ds))
    sw = sum((x < 0.05) and (y < 0) for x, y in zip(q, ds))
    return float(np.median(rs)), w, l, sb, sw, per

def main():
    parts = []
    b = sorted(glob.glob(os.path.join(SQ, "results", "freshv2_*")))[-1]
    parts.append(pd.read_csv(os.path.join(b, "runs.csv")))
    cb = sorted(glob.glob(os.path.join(SQ, "results", "combo2_*")))
    if cb:
        parts.append(pd.read_csv(os.path.join(cb[-1], "runs.csv")))
    df = pd.concat(parts, ignore_index=True, sort=False)
    df = df[df.Status == "ok"]
    piv = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
    print("=== v2 decision (fresh seeds 3031:3060, D=50, 29fn) ===")
    cands = [a for a in ["V1-frozen", "V2-steer25", "V2-steer50", "V2-subset20", "V2-K5", "V2-steer50-g20"] if a in piv.columns]
    print(f"{'arm':18s} {'vs IGWO ratio':>14s} {'W-L':>8s} {'Holm':>9s} | {'vs V1 ratio':>12s} {'W-L':>8s} {'Holm':>9s}")
    for a in cands:
        r1, w1, l1, sb1, sw1, _ = cmp(piv, a, "IGWO-fresh")
        if a == "V1-frozen":
            print(f"{a:18s} {r1:14.3f} {str(w1)+'-'+str(l1):>8s} {'+%d/-%d' % (sb1, sw1):>9s} |")
            continue
        r2, w2, l2, sb2, sw2, _ = cmp(piv, a, "V1-frozen")
        print(f"{a:18s} {r1:14.3f} {str(w1)+'-'+str(l1):>8s} {'+%d/-%d' % (sb1, sw1):>9s} | {r2:12.3f} {str(w2)+'-'+str(l2):>8s} {'+%d/-%d' % (sb2, sw2):>9s}")
    rank = piv.groupby(level=0).median().rank(axis=1).mean(axis=0).sort_values()
    print("\nmean ranks:", {k: round(v, 2) for k, v in rank.items()})
    for a in cands:
        e = df[df.Algorithm == a]
        ep = e["NStagEpisodes"].sum(); rec = e["NRecoveredWindow"].sum() / ep if ep else float("nan")
        print(f"{a:18s} recov {rec:.4f} longStag {e.LongStagShare.mean():.4f} novUse {e.NovelUsefulRate.mean():.5f} sec {e.Seconds.mean():.2f}")

if __name__ == "__main__":
    main()
