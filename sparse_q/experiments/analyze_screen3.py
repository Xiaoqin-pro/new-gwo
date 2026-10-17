#!/usr/bin/env python3
"""SCREEN3 analysis: Q-learning vs best fixed vs random quota (both arms)."""
import glob
import os
import sys
import numpy as np
import pandas as pd
from scipy import stats

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gates_sparse_q import ratio_stats

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

ROOT = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"


def analyse(batch_dir, fixed_label, rand_label, q_label, arm_name):
    df = pd.read_csv(os.path.join(batch_dir, "runs.csv"))
    df = df[df.Status == "ok"]
    piv = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm",
                         values="FinalError", aggfunc="first")
    print(f"\n=== {arm_name}: {os.path.basename(batch_dir)} ===")
    res = {}
    for ref in [fixed_label, rand_label]:
        r, w, per = ratio_stats(piv, q_label, ref)
        d = np.log10(piv[ref]) - np.log10(piv[q_label])
        p = stats.wilcoxon(d).pvalue if np.any(d != 0) else 1.0
        gate = (r <= 0.99) or (w[0] >= 6 and r <= 1.00)
        res[ref] = gate
        print(f"  {q_label} vs {ref}: ratio {r:.3f}, W/T/L {w[0]}/{w[1]}/{w[2]}, p={p:.3g}, gate={'PASS' if gate else 'FAIL'}")
        print("     per-fn:", {int(k): round(v, 3) for k, v in per.items()})
    for a in [fixed_label, rand_label, q_label]:
        e = df[df.Algorithm == a]
        ep = e["NStagEpisodes"].sum()
        rec = e["NRecoveredWindow"].sum() / ep if ep else np.nan
        print(f"  {a:12s} sec {e.Seconds.mean():.3f}  recov {rec:.4f}  longStag {e.LongStagShare.mean():.4f} "
              f" novUseful {e.NovelUsefulRate.mean():.4f}  Q4impr {e.ImprovRateQ4.mean():.4f}")
    e = df[df.Algorithm == q_label]
    if "QAct1" in e.columns and not e["QAct1"].isna().all():
        print(f"  Q action counts (mean/run): {e.QAct1.mean():.1f} / {e.QAct2.mean():.1f} / {e.QAct3.mean():.1f}")
        print(f"  Q action share: {e.QuotaAct1Pct.mean():.2f} / {e.QuotaAct2Pct.mean():.2f} / {e.QuotaAct3Pct.mean():.2f}")
        print(f"  window reward mean {e.RewardMean.mean():.4f}; windows with gbest improvement {e.GBWindowPct.mean():.3f}")
        sv = e[["QState1", "QState2", "QState3", "QState4", "QState5", "QState6"]].mean()
        print(f"  state visits (mean/run): {sv.round(1).tolist()}")
    return res


def main():
    a = sorted(glob.glob(os.path.join(ROOT, "results", "sq3a_*")))[-1]
    b = sorted(glob.glob(os.path.join(ROOT, "results", "sq3b_*")))[-1]
    ra = analyse(a, "S3p-q25", "S4p-random", "S5p-q", "arm A (pinned strat)")
    rb = analyse(b, "S3w-q25", "S4w-random", "S5w-q", "arm B (weighted)")
    print("\nGate summary: arm A", ra, "| arm B", rb)


if __name__ == "__main__":
    main()
