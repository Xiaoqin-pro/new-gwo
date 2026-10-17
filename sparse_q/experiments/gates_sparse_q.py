#!/usr/bin/env python3
"""Pre-registered gate checks for the sparse_q branch (docs/01_PREREG.md).

Usage:
  python gates_sparse_q.py <batch_dir> --mode screen1|screen2|screen3
Writes GATES.md into the batch directory.
"""
import argparse
import os
import sys
import numpy as np
import pandas as pd
from scipy import stats

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

L = []
def log(s=""):
    L.append(str(s))
    print(s)


def ratio_stats(piv, A, B, col="FinalError", offset_by_fid=False):
    """Return (median paired ratio, W/T/L by function means, per-function ratios)."""
    funcs = sorted(piv.index.get_level_values(0).unique())
    ratios, w, t, l = [], 0, 0, 0
    per_fn = {}
    for f in funcs:
        ra = piv.loc[f, A].dropna()
        rb = piv.loc[f, B].dropna()
        common = ra.index.intersection(rb.index)
        if len(common) == 0:
            continue
        ra, rb = ra.loc[common], rb.loc[common]
        if offset_by_fid:
            ra = ra - 100 * f
            rb = rb - 100 * f
        r = np.median(ra / rb)
        ratios.append(r)
        per_fn[f] = r
        ma, mb = ra.mean(), rb.mean()
        if ma < mb:
            w += 1
        elif ma > mb:
            l += 1
        else:
            t += 1
    return float(np.median(ratios)), (w, t, l), per_fn


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("batch_dir")
    ap.add_argument("--mode", required=True, choices=["screen1", "screen1b", "screen2", "screen3", "screen4"])
    args = ap.parse_args()
    df = pd.read_csv(os.path.join(args.batch_dir, "runs.csv"))
    df = df[df.Status == "ok"].copy()
    piv = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm",
                         values="FinalError", aggfunc="first")
    cp = {}
    for col in ["CheckT10", "CheckT20", "CheckT50", "CheckT80", "CheckT100"]:
        if col in df.columns:
            cp[col] = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm",
                                     values=col, aggfunc="first")
    log(f"# sparse_q 门槛判定 — {args.mode}\n")
    log(f"batch: `{args.batch_dir}` | runs: {len(df)}\n")

    def line(name, val, claim, ok):
        log(f"| {name} | {val} | {claim} | {'PASS' if ok else 'FAIL'} |")

    if args.mode == "screen1":
        A, S1, S2, B0, B1 = "S2-sparse-directed", "S1-sparse-random", "S2-sparse-directed", "B0-ANGWO", "B1-dense-sync"
        log("| 判定项 | 实测 | 门槛 | 结果 |")
        log("|---|---:|---:|---|")
        r1, w1, _ = ratio_stats(piv, "S1-sparse-random", "GWO")
        ok1 = (r1 <= 1.00) and (w1[0] >= 4)
        line("G_S1: S1 vs GWO 中位比值 / 胜负", f"{r1:.3f} / {w1[0]}-{w1[2]}", "≤1.00 且 ≥4/8 胜", ok1)
        r2, w2, _ = ratio_stats(piv, S2, "S1-sparse-random")
        ok2a = (r2 <= 0.98) or (w2[0] >= 6 and r2 <= 1.00)
        line("G_S2a: S2 vs S1 中位比值 / 胜负", f"{r2:.3f} / {w2[0]}-{w2[2]}", "≤0.98 或 (≥6/8 且 ≤1.00)", ok2a)
        r20, _, per20 = ratio_stats(cp["CheckT20"], S2, "S1-sparse-random", offset_by_fid=True)
        simple = [f for f in (4, 6, 9) if f in per20]
        simw = sum(per20[f] < 1 for f in simple)
        ok2b = (r20 <= 0.98) and (simw >= 2)
        line("G_S2b: FE20k 比值 / 简单多峰子集胜", f"{r20:.3f} / {simw}/{len(simple)}", "≤0.98 且 ≥2/3", ok2b)
        overall = ok2a and ok2b
        log(f"\n**SCREEN1 结论：{'晋级 SCREEN2' if overall else '未过门槛'}**"
            f"（G_S1 {'PASS' if ok1 else 'FAIL'}；G_S2a {'PASS' if ok2a else 'FAIL'}；"
            f"G_S2b {'PASS' if ok2b else 'FAIL'}）\n")
        for name in [B0, B1, "GWO", "S1-sparse-random", S2]:
            if name in piv.columns:
                rr, ww, _ = ratio_stats(piv, name, "GWO")
                log(f"- {name}: 对 GWO 中位比值 {rr:.3f}，函数胜负 {ww[0]}-{ww[2]}")
        log("")
        for cpname in ["CheckT10", "CheckT20", "CheckT50"]:
            if cpname in cp:
                r, w, _ = ratio_stats(cp[cpname], S2, S1, offset_by_fid=True)
                log(f"- S2/S1 @ {cpname}: 中位比值 {r:.3f}, 胜负 {w[0]}-{w[2]}")
        log("")
        for m, col in [("有用新颖率", "NovelUsefulRate"), ("长停滞占比", "LongStagShare"),
                       ("恢复窗口概率", None), ("末段改善率", "ImprovRateQ4"), ("运行秒", "Seconds")]:
            row = f"- {m}: "
            for a in [B0, "GWO", S1, S2]:
                if a not in df.Algorithm.unique():
                    continue
                e = df[df.Algorithm == a]
                if col is None:
                    ep = e["NStagEpisodes"].sum()
                    v = e["NRecoveredWindow"].sum() / ep if ep else float("nan")
                else:
                    v = e[col].mean()
                row += f"{a}={v:.4g}  "
            log(row)
        log("")

    if args.mode == "screen1b":
        S1 = "S1-sparse-random"
        log("| 判定项 | 实测 | 门槛 | 结果 |")
        log("|---|---:|---:|---|")
        cands = [a for a in piv.columns if a.startswith("S2v2") or a.startswith("F-stratrand")]
        best, bestr, bestw = None, 9e9, None
        for a in cands:
            r, w, _ = ratio_stats(piv, a, S1)
            log(f"| {a} vs S1 | {r:.3f} / {w[0]}-{w[2]} | ≤0.98 或 (≥6/8 且 ≤1.00) | "
                f"{'PASS' if (r <= 0.98 or (w[0] >= 6 and r <= 1.00)) else 'FAIL'} |")
            if r < bestr:
                best, bestr, bestw = a, r, w
        log(f"\n最优候选：**{best}**（比值 {bestr:.3f}，胜负 {bestw[0]}-{bestw[2]}）\n")
        if "CheckT20" in cp and best is not None:
            r20, w20, per20 = ratio_stats(cp["CheckT20"], best, S1, offset_by_fid=True)
            simple = [f for f in (4, 6, 9) if f in per20]
            simw = sum(per20[f] < 1 for f in simple)
            log(f"- {best} vs S1 @FE20k: 中位比值 {r20:.3f}，简单多峰 {simw}/{len(simple)}，按函数比值 {per20}")
        for a in [S1] + cands:
            if a in df.Algorithm.unique():
                e = df[df.Algorithm == a]
                ep = e["NStagEpisodes"].sum()
                rec = e["NRecoveredWindow"].sum() / ep if ep else float("nan")
                log(f"- {a}: 秒 {e['Seconds'].mean():.3f}, 恢复窗口概率 {rec:.4f}, "
                    f"长停滞 {e['LongStagShare'].mean():.4f}, 有用新颖 {e['NovelUsefulRate'].mean():.4f}, "
                    f"候选/次 {e['NCandidateGenerated'].mean():.0f}")
        log("")
    if args.mode == "screen2":
        variants = [a for a in piv.columns if a.startswith("S3")]
        best, bestr = None, 9e9
        ref = "S2-sparse-directed"
        for a in variants:
            r, w, _ = ratio_stats(piv, a, ref)
            log(f"- {a} vs S2: 中位比值 {r:.3f}，胜负 {w[0]}-{w[2]}")
            if r < bestr:
                best, bestr = a, r
        ok = bestr <= 0.99
        log(f"\n**SCREEN2：最优固定配额 = {best}（比值 {bestr:.3f}）→ {'PASS（采纳）' if ok else 'FAIL（维持 0.5）'}**\n")

    if args.mode == "screen3":
        ref3 = "S3-fixed-best"
        for a in ["S4-random", "S5-q"]:
            if a not in piv.columns:
                continue
            r, w, _ = ratio_stats(piv, a, ref3)
            log(f"- {a} vs {ref3}: 中位比值 {r:.3f}，胜负 {w[0]}-{w[2]}")
        if "S5-q" in piv.columns and "S4-random" in piv.columns:
            r, w, _ = ratio_stats(piv, "S5-q", "S4-random")
            log(f"- S5-q vs S4-random: 中位比值 {r:.3f}，胜负 {w[0]}-{w[2]}")
        if "S5-q" in piv.columns:
            e = df[df.Algorithm == "S5-q"]
            log(f"- S5-q 动作占比: act1={e.QuotaAct1Pct.mean():.2f} act2={e.QuotaAct2Pct.mean():.2f} act3={e.QuotaAct3Pct.mean():.2f}")
            log(f"- S5-q 窗口奖励均值 {e.RewardMean.mean():.4f}；有 gbest 改善的窗口占比 {e.GBWindowPct.mean():.3f}")

    with open(os.path.join(args.batch_dir, "GATES.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(L) + "\n")
    print("report ->", os.path.join(args.batch_dir, "GATES.md"))


if __name__ == "__main__":
    main()

