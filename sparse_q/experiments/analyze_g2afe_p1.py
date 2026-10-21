#!/usr/bin/env python3
"""Analyze the pre-registered G2-AFE P1 development batch."""
from __future__ import annotations
import json, sys
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(r"D:\111\Desktop\噜噜\拯救G2")
ARMS = ["V1-frozen", "A2-G1E", "G2-AFE-Trigger", "G2-AFE-RandomDir", "G2-AFE-Always"]
FUNCS = [3, 5, 8, 12, 17, 20, 23, 30]
SEEDS = list(range(3111, 3121))
PAIRS = [("G2-AFE-Trigger", "A2-G1E"), ("G2-AFE-Trigger", "G2-AFE-RandomDir"),
         ("G2-AFE-Trigger", "V1-frozen"), ("G2-AFE-Always", "A2-G1E"),
         ("G2-AFE-RandomDir", "A2-G1E")]


def latest_dir() -> Path:
    dirs = sorted((ROOT / "sparse_q" / "results").glob("g2afe_p1_*"))
    if not dirs:
        raise SystemExit("No g2afe_p1_* result directory found")
    return dirs[-1]


def ratio(a, b):
    if b == 0:
        return float("inf") if a > 0 else 1.0
    return a / b


def holm(p):
    p = np.asarray(p, float)
    out = np.full_like(p, np.nan)
    idx = np.where(np.isfinite(p))[0]
    if not len(idx):
        return out
    order = idx[np.argsort(p[idx])]
    prev = 0.0
    m = len(order)
    for rank, i in enumerate(order):
        v = min(1.0, (m - rank) * p[i]); v = max(v, prev)
        out[i] = v; prev = v
    return out


def pairwise(df, a, b):
    rows = []
    for f in FUNCS:
        x = df[(df.Algorithm == a) & (df.FunctionID == f)].sort_values("Seed")
        y = df[(df.Algorithm == b) & (df.FunctionID == f)].sort_values("Seed")
        assert list(x.Seed) == list(y.Seed)
        ax, by = x.FinalError.to_numpy(float), y.FinalError.to_numpy(float)
        try:
            stat, p = wilcoxon(ax, by, alternative="two-sided", zero_method="wilcox", method="auto")
        except ValueError:
            stat, p = np.nan, np.nan
        rr = np.array([ratio(u, v) for u, v in zip(ax, by)])
        rows.append(dict(comparison=f"{a} vs {b}", FunctionID=f,
                         median_A=float(np.median(ax)), median_B=float(np.median(by)),
                         median_ratio=float(np.median(rr)),
                         wins_A=int((rr < 1).sum()), losses_A=int((rr > 1).sum()),
                         p_raw=float(p) if np.isfinite(p) else np.nan,
                         stat=float(stat) if np.isfinite(stat) else np.nan))
    q = holm([r["p_raw"] for r in rows])
    for r, v in zip(rows, q):
        r["p_holm"] = float(v) if np.isfinite(v) else np.nan
    return rows


def gate(med, a, b):
    rr = np.array([ratio(med.loc[f, a], med.loc[f, b]) for f in FUNCS])
    return dict(A=a, B=b, median_ratio=float(np.median(rr)),
                wins=int((rr < 1).sum()), losses=int((rr > 1).sum()),
                catastrophic_gt_1_20=int((rr > 1.20).sum()),
                ratios={int(f): float(v) for f, v in zip(FUNCS, rr)})


def main():
    outdir = Path(sys.argv[1]) if len(sys.argv) > 1 else latest_dir()
    df = pd.read_csv(outdir / "runs.csv")
    rep = ROOT / "reports" / "g2afe_p1_analysis"; rep.mkdir(parents=True, exist_ok=True)

    assert sorted(df.FunctionID.unique().tolist()) == FUNCS, "unexpected function set"
    assert sorted(df.Seed.unique().tolist()) == SEEDS, "unexpected seeds"
    assert set(ARMS).issubset(set(df.Algorithm.unique())), "missing arm"
    assert len(df) == 5 * 8 * 10, f"unexpected runs {len(df)}"
    assert (df.Status == "ok").all(), "failed run"
    assert (df.Evaluations == 30000).all(), "bad FE"

    med = df.pivot_table(index="FunctionID", columns="Algorithm", values="FinalError", aggfunc="median").reindex(FUNCS)
    med20 = df.pivot_table(index="FunctionID", columns="Algorithm", values="CheckT20", aggfunc="median").reindex(FUNCS)
    med.to_csv(rep / "per_function_final_error_median.csv")
    med20.to_csv(rep / "per_function_checkT20_median.csv")

    tests = []
    for a, b in PAIRS:
        tests.extend(pairwise(df, a, b))
    tests_df = pd.DataFrame(tests)
    tests_df.to_csv(rep / "pairwise_wilcoxon_holm.csv", index=False)

    g1 = gate(med, "G2-AFE-Trigger", "A2-G1E")
    g2 = gate(med, "G2-AFE-Trigger", "G2-AFE-RandomDir")
    g3 = gate(med, "G2-AFE-Trigger", "V1-frozen")
    rr20 = np.array([ratio(med20.loc[f, "G2-AFE-Trigger"], med20.loc[f, "V1-frozen"]) for f in FUNCS])
    h1 = g1["median_ratio"] <= 0.98 and g1["wins"] >= 6 and g1["catastrophic_gt_1_20"] == 0
    h2 = g2["median_ratio"] <= 0.98 and g2["wins"] >= 6 and g2["catastrophic_gt_1_20"] == 0
    rt = df.groupby("Algorithm").Seconds.mean().to_dict()
    runtime_ratio = rt["G2-AFE-Trigger"] / rt["A2-G1E"]
    h3 = (g3["median_ratio"] <= 1.00 and float(np.median(rr20)) <= 1.00
          and int((rr20 > 1.05).sum()) <= 3 and runtime_ratio <= 1.15)

    sec_cols = ["NRecoveredEventual", "RecoveryEventualProb", "LongStagShare",
                "NovMean", "NovRate", "NovelUsefulRate", "NovelStrictImprove",
                "G2AFEActiveRounds", "G2AFEPairValidRounds", "G2AFECandidates",
                "G2AFEFallbackCandidates", "G2AFEStepMean", "G2AFEGlobalImp",
                "G2AFEArchiveImp", "G2AFEAccept", "G2EvalCount"]
    sec = df.groupby("Algorithm")[sec_cols].mean().reindex(ARMS).T
    sec.to_csv(rep / "secondary_metrics_mean.csv")

    # AFE diagnostics by arm and per function
    afe = df[df.Algorithm.str.startswith("G2-AFE")].copy()
    afe["G2EvalSuccess"] = afe.G2AFEAccept / afe.G2EvalCount.replace(0, np.nan)
    afe["G2GlobalRate"] = afe.G2AFEGlobalImp / afe.G2EvalCount.replace(0, np.nan)
    afe["G2ArchiveRate"] = afe.G2AFEArchiveImp / afe.G2EvalCount.replace(0, np.nan)
    afe.groupby("Algorithm")[["G2EvalCount", "G2AFEActiveRounds", "G2AFEPairValidRounds",
                              "G2AFECandidates", "G2AFEFallbackCandidates", "G2AFEStepMean",
                              "G2EvalSuccess", "G2GlobalRate", "G2ArchiveRate"]].mean().to_csv(
        rep / "afe_diagnostics_by_arm.csv")

    summary = dict(results_dir=str(outdir), runs=len(df), functions=FUNCS, seeds=SEEDS,
                   H1=g1, H2=g2, H3_final=g3,
                   H3_checkT20=dict(median_ratio=float(np.median(rr20)),
                                    worse_gt_1_05=int((rr20 > 1.05).sum()),
                                    ratios={int(f): float(v) for f, v in zip(FUNCS, rr20)}),
                   runtime_mean_sec={k: float(v) for k, v in rt.items()},
                   runtime_ratio_trigger_over_A2=float(runtime_ratio),
                   H1_pass=bool(h1), H2_pass=bool(h2), H3_pass=bool(h3),
                   verdict=("PROMOTE_TO_P2" if (h1 and h2 and h3) else "STOP_G2AFE_NEGATIVE"))
    (rep / "summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")

    # plot
    rr = {c: (med["G2-AFE-Trigger"] / med[c]).to_numpy() for c in ["A2-G1E", "G2-AFE-RandomDir", "V1-frozen"]}
    fig, ax = plt.subplots(figsize=(9, 4.8)); x = np.arange(len(FUNCS)); w = 0.26
    for i, (k, v) in enumerate(rr.items()):
        ax.bar(x + (i - 1) * w, v, w, label=f"Trigger/{k}")
    ax.axhline(1, color="black", lw=1); ax.axhline(0.98, color="tab:green", ls="--", lw=1, label="0.98 gate")
    ax.axhline(1.20, color="tab:red", ls=":", lw=1, label="1.20 catastrophic")
    ax.set_yscale("log"); ax.set_xticks(x); ax.set_xticklabels([f"F{f}" for f in FUNCS])
    ax.set_ylabel("median final-error ratio (log scale)")
    ax.set_title("G2-AFE P1: per-function median final-error ratios")
    ax.legend(ncol=2, fontsize=8); fig.tight_layout(); fig.savefig(rep / "per_function_ratio.png", dpi=180); plt.close(fig)

    lines = ["# G2-AFE P1 开发实验结果\n",
             f"- 结果目录：`{outdir}`", f"- 400 次运行，5 臂 × 8 函数 × 10 种子，失败 0，全部 30,000 真 FE", "",
             "## 预注册门槛\n",
             f"- **H1（AFE-Trigger vs A2）**：中位比 {g1['median_ratio']:.6g}，胜/负 {g1['wins']}/{g1['losses']}，>1.20 的函数 {g1['catastrophic_gt_1_20']} → **{'通过' if h1 else '不通过'}**",
             f"- **H2（AFE-Trigger vs RandomDir）**：中位比 {g2['median_ratio']:.6g}，胜/负 {g2['wins']}/{g2['losses']}，>1.20 的函数 {g2['catastrophic_gt_1_20']} → **{'通过' if h2 else '不通过'}**",
             f"- **H3（vs V1 / 20% FE / 时间）**：最终比 {g3['median_ratio']:.6g}，CheckT20 比 {np.median(rr20):.6g}，>1.05 函数数 {int((rr20>1.05).sum())}，时间比 {runtime_ratio:.4g} → **{'通过' if h3 else '不通过'}**",
             f"- **最终裁定：{summary['verdict']}**", "",
             "## 逐函数中位误差\n", "| F | V1 | A2 | AFE-T | AFE-R | AFE-A | T/A2 | T/R | T/V1 |",
             "|---:|---:|---:|---:|---:|---:|---:|---:|---:|"]
    for f in FUNCS:
        row = [med.loc[f, a] for a in ARMS]
        lines.append(f"| {f} | " + " | ".join(f"{v:.6g}" for v in row) +
                     f" | {ratio(med.loc[f,'G2-AFE-Trigger'],med.loc[f,'A2-G1E']):.4g}"
                     f" | {ratio(med.loc[f,'G2-AFE-Trigger'],med.loc[f,'G2-AFE-RandomDir']):.4g}"
                     f" | {ratio(med.loc[f,'G2-AFE-Trigger'],med.loc[f,'V1-frozen']):.4g} |")
    lines += ["", "## AFE 过程诊断\n",
              f"- Trigger 平均 G2 评价数：{df[df.Algorithm=='G2-AFE-Trigger'].G2EvalCount.mean():.1f}",
              f"- Trigger 平均 AFE 候选数：{df[df.Algorithm=='G2-AFE-Trigger'].G2AFECandidates.mean():.1f}",
              f"- Trigger 平均激活轮数：{df[df.Algorithm=='G2-AFE-Trigger'].G2AFEActiveRounds.mean():.1f}",
              f"- Trigger 平均点对有效轮数：{df[df.Algorithm=='G2-AFE-Trigger'].G2AFEPairValidRounds.mean():.1f}",
              f"- Trigger 平均步长：{df[df.Algorithm=='G2-AFE-Trigger'].G2AFEStepMean.mean():.4g}",
              f"- Trigger 每次评价的全局改进率：{(df[df.Algorithm=='G2-AFE-Trigger'].G2AFEGlobalImp.sum()/df[df.Algorithm=='G2-AFE-Trigger'].G2EvalCount.sum()):.5f}",
              f"- Trigger 每次评价的档案插入率：{(df[df.Algorithm=='G2-AFE-Trigger'].G2AFEArchiveImp.sum()/df[df.Algorithm=='G2-AFE-Trigger'].G2EvalCount.sum()):.5f}",
              "", "按预注册淘汰规则处理；如果 H1/H2 不通过，将停止 G2-AFE，不做参数扫描。"]
    (rep / "g2afe_p1_report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines)); print("[analysis] wrote", rep)


if __name__ == "__main__":
    main()
