#!/usr/bin/env python3
"""Final-tier analysis for the sparse_q branch.

Merges: our frozen final batch (S-star / S1 / S3p / S5p / B1) with the
read-only reused rows (B0 = frozen ANGWO and GWO from the frozen formal
batch; audited strong baselines from the reference CSVs), then reports:
ranks, pairwise vs references (Wilcoxon+Holm), early checkpoints, behaviour
metrics and the dual-axis gates from docs/01.
"""
import os
import sys
import numpy as np
import pandas as pd
from scipy import stats

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

ROOT = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
SQ = os.path.join(ROOT, "sparse_q")


def holm(p):
    p = np.asarray(p, float)
    order = np.argsort(p)
    adj = np.empty_like(p)
    cur = 0.0
    for i, idx in enumerate(order):
        cur = max(cur, p[idx] * (len(p) - i))
        adj[idx] = min(cur, 1.0)
    return adj


def load_final(batch_dir):
    ours = pd.read_csv(os.path.join(batch_dir, "runs.csv"))
    ours = ours[ours.Status == "ok"].copy()
    ours["Source"] = "new"
    frozen = pd.read_csv(os.path.join(ROOT, "results", "formal_20261016_140254", "runs.csv"))
    frozen = frozen[frozen.Status == "ok"]
    b0 = frozen[frozen.Algorithm == "ANGWO-final"].copy()
    b0["Algorithm"] = "B0-ANGWO"; b0["Source"] = "frozen-reuse"
    gwo = frozen[frozen.Algorithm == "GWO"].copy()
    gwo["Source"] = "frozen-reuse"
    ref10 = pd.read_csv(os.path.join(ROOT, "data", "reference", "audited_10algo_30seed.csv"))
    ref15 = pd.read_csv(os.path.join(ROOT, "data", "reference", "audited_15algo_30seed.csv"))
    ref10 = ref10[ref10.Status == "ok"]; ref15 = ref15[ref15.Status == "ok"]
    mapping = {
        "IGWO": "IGWO", "RASE-GWO": "Over1000-90q3",
        "HIDMS-PSO": "HIDMS-PSO-IndexCorrected", "HCLPSO": "HCLPSO-AuthorSource",
        "DMS-PSO": "DMS-PSO-SIS2005", "SAQ-CSO": "SAQ-CSO",
        "SPSO-2011": "SPSO-2011-OfficialC", "HPSO-TVAC": "HPSO-TVAC-CEC",
        "CLPSO": "CLPSO-AuthorSource", "Original-CSO": "Original-CSO-MR02",
    }
    parts = [ours, b0, gwo]
    for new, old in mapping.items():
        src = ref10 if old in ("IGWO", "Over1000-90q3") else ref15
        sel = src[src.Algorithm == old].copy()
        if len(sel) == 0:
            raise SystemExit("missing audited rows for " + old)
        sel["Algorithm"] = new; sel["Source"] = "audited"
        parts.append(sel)
    df = pd.concat(parts, ignore_index=True, sort=False)
    # integrity: our GWO-equivalent mode (none here) and B0 rows verified elsewhere
    return df


def ratio_stats(piv, A, B, col="FinalError", off=False):
    funcs = sorted(piv.index.get_level_values(0).unique())
    ratios, w, t, l = [], 0, 0, 0
    per = {}
    for f in funcs:
        ra = piv.loc[f, A].dropna(); rb = piv.loc[f, B].dropna()
        c = ra.index.intersection(rb.index)
        if len(c) == 0:
            continue
        ra, rb = ra.loc[c], rb.loc[c]
        if off:
            ra, rb = ra - 100 * f, rb - 100 * f
        r = np.median(ra / rb); ratios.append(r); per[f] = r
        ma, mb = ra.mean(), rb.mean()
        if ma < mb: w += 1
        elif ma > mb: l += 1
        else: t += 1
    return float(np.median(ratios)), (w, t, l), per


def main():
    b = sorted([d for d in os.listdir(os.path.join(SQ, "results")) if d.startswith("final_")])[-1]
    batch = os.path.join(SQ, "results", b)
    df = load_final(batch)
    df.to_csv(os.path.join(batch, "merged_runs.csv"), index=False)
    ok = df[df.Status == "ok"]
    piv = ok.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm",
                         values="FinalError", aggfunc="first")
    ranks = piv.groupby(level=0).median().rank(axis=1).mean(axis=0).sort_values()
    print("=== FINAL D=50 (29 fn x 30 seeds, 100k FE) ===")
    print("mean ranks:", {k: round(v, 2) for k, v in ranks.items()})
    A = "S-star"
    for B in ["GWO", "B0-ANGWO", "S1-pool38", "S3p-q25", "S5p-q", "IGWO",
              "HIDMS-PSO", "HCLPSO", "DMS-PSO", "SAQ-CSO", "RASE-GWO", "SPSO-2011",
              "HPSO-TVAC", "CLPSO", "Original-CSO"]:
        if B not in piv.columns or B == A:
            continue
        r, w, per = ratio_stats(piv, A, B)
        d = np.log10(piv[B]) - np.log10(piv[A])
        d = d[np.isfinite(d)]
        p = stats.wilcoxon(d).pvalue if np.any(d != 0) else 1.0
        # Holm across functions
        ps, ds = [], []
        for f in sorted(ok.FunctionID.unique()):
            ra = piv.loc[f, A].dropna(); rb = piv.loc[f, B].dropna()
            c = ra.index.intersection(rb.index)
            if len(c) < 6: continue
            dd = np.log10(rb.loc[c]) - np.log10(ra.loc[c])
            ps.append(stats.wilcoxon(dd).pvalue if np.any(dd != 0) else 1.0)
            ds.append(np.median(dd))
        sb = sw = 0
        if ps:
            q = holm(ps)
            for qi, di in zip(q, ds):
                if qi < 0.05:
                    sb += di > 0; sw += di < 0
        print(f"{A} vs {B:14s}: ratio {r:.3f}  W/T/L {w[0]}/{w[1]}/{w[2]}  pooled p={p:.3g}  Holm +{sb}/-{sw}")
    # dual-axis gates vs B0
    print("\n=== Dual-axis gates (vs B0) ===")
    for c, off in [("CheckT10", True), ("CheckT20", True)]:
        cp = ok.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm", values=c, aggfunc="first")
        r, w, _ = ratio_stats(cp, A, "B0-ANGWO", off=True)
        print(f"  {c}: S* vs B0 ratio {r:.3f} W/T/L {w[0]}/{w[1]}/{w[2]}")
    d20 = ok.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm", values="CheckT20", aggfunc="first")
    r20, w20, per20 = ratio_stats(d20, A, "B0-ANGWO", off=True)
    simple = [f for f in range(4, 11) if f in per20]
    sm = np.median([per20[f] for f in simple])
    print(f"  FE20 ratio {r20:.3f} (gate <=0.98 {'PASS' if r20 <= 0.98 else 'FAIL'}); simple multimodal (F4-F10) median {sm:.3f} {'PASS' if sm <= 0.98 else 'FAIL'}")
    for a in [A, "B0-ANGWO", "GWO", "S1-pool38", "S3p-q25", "S5p-q"]:
        e = ok[ok.Algorithm == a]
        if "NStagEpisodes" not in e: continue
        ep = e["NStagEpisodes"].sum(); rec = e["NRecoveredWindow"].sum() / ep if ep else np.nan
        print(f"  {a:13s} recov {rec:.4f} longStag {e.LongStagShare.mean():.4f} "
              f"novUse {e.NovelUsefulRate.mean():.5f} NovoQ4 {e.NovRateQ4.mean():.3f} "
              f"imprQ4 {e.ImprovRateQ4.mean():.5f} sec {e.Seconds.mean():.2f}")
    e = ok[ok.Algorithm == A]; b0 = ok[ok.Algorithm == "B0-ANGWO"]
    epa, epb = e["NStagEpisodes"].sum(), b0["NStagEpisodes"].sum()
    ra, rb = e["NRecoveredWindow"].sum()/epa, b0["NRecoveredWindow"].sum()/epb
    print(f"\n  B-axis gate: recov {ra:.4f} vs B0 {rb:.4f} (+{ra-rb:.4f}; gate +0.05 {'PASS' if ra-rb>=0.05 else 'FAIL'}); "
          f"longStag {e.LongStagShare.mean():.4f} vs B0 {b0.LongStagShare.mean():.4f} "
          f"(gate <= B0-0.03 {'PASS' if e.LongStagShare.mean() <= b0.LongStagShare.mean()-0.03 else 'FAIL'})")
    print(f"  A-axis gate: useful novelty {e.NovelUsefulRate.mean():.5f} vs B0 {b0.NovelUsefulRate.mean():.5f} "
          f"{'PASS' if e.NovelUsefulRate.mean() >= b0.NovelUsefulRate.mean() else 'FAIL'}")


if __name__ == "__main__":
    main()
