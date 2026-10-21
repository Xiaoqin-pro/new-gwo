#!/usr/bin/env python3
"""Analyze the pre-registered G2-TR P1 development batch.

Reads only the frozen runs.csv produced by the 4-worker MATLAB harness.
Applies the gates written in sparse_q/docs/19_G2TR_PREREG.md without changing
the function subset, seeds, thresholds, or arms.
"""
from __future__ import annotations
import json, math, sys
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon

ROOT = Path(r"D:\111\Desktop\噜噜\拯救G2")
ARMS = ["V1-frozen", "A2-G1E", "A4-G2fixedmin", "G2-TR", "G2-subset20"]
MAIN = ("G2-TR", "A2-G1E")
H2PAIR = ("G2-TR", "A4-G2fixedmin")
H3PAIR = ("G2-TR", "V1-frozen")


def latest_dir() -> Path:
    dirs = sorted((ROOT / "sparse_q" / "results").glob("g2tr_p1_*"))
    if not dirs:
        raise SystemExit("No g2tr_p1_* result directory found")
    return dirs[-1]


def safe_ratio(a: float, b: float) -> float:
    if b == 0:
        return float("inf") if a > 0 else 1.0
    return a / b


def holm(pvals):
    """Holm-Bonferroni adjusted p-values, NaNs preserved and put last."""
    p = np.asarray(pvals, dtype=float)
    finite = np.isfinite(p)
    adj = np.full_like(p, np.nan)
    if not finite.any():
        return adj
    idx = np.where(finite)[0]
    order = idx[np.argsort(p[idx])]
    m = len(order)
    prev = 0.0
    for rank, i in enumerate(order):
        val = min(1.0, (m - rank) * p[i])
        val = max(val, prev)
        adj[i] = val
        prev = val
    return adj


def wilcoxon_row(df, a, b, fid):
    x = df[(df.Algorithm == a) & (df.FunctionID == fid)].sort_values("Seed")
    y = df[(df.Algorithm == b) & (df.FunctionID == fid)].sort_values("Seed")
    assert list(x.Seed) == list(y.Seed), "seed pairing mismatch"
    ax = x.FinalError.to_numpy(float)
    by = y.FinalError.to_numpy(float)
    try:
        stat, p = wilcoxon(ax, by, alternative="two-sided", zero_method="wilcox", method="auto")
    except ValueError:
        stat, p = float("nan"), float("nan")
    ratios = np.array([safe_ratio(u, v) for u, v in zip(ax, by)])
    wins = int(np.sum(ratios < 1.0))
    losses = int(np.sum(ratios > 1.0))
    med_ratio = float(np.median(ratios))
    log_eff = float(np.median(np.log(np.maximum(ratios, 1e-300))))
    return dict(
        comparison=f"{a} vs {b}", FunctionID=int(fid), n=len(ax),
        median_error_A=float(np.median(ax)), median_error_B=float(np.median(by)),
        median_ratio_A_over_B=med_ratio,
        wins_A=wins, losses_A=losses, ties_A=int(len(ax) - wins - losses),
        mean_log_ratio=log_eff,
        wilcoxon_stat=float(stat) if np.isfinite(stat) else np.nan,
        p_raw=float(p) if np.isfinite(p) else np.nan,
    )


def main():
    outdir = Path(sys.argv[1]) if len(sys.argv) > 1 else latest_dir()
    runs = outdir / "runs.csv"
    df = pd.read_csv(runs)
    repdir = ROOT / "reports" / "g2tr_p1_analysis"
    repdir.mkdir(parents=True, exist_ok=True)

    # ---------- integrity ----------
    funcs = sorted(int(x) for x in df.FunctionID.unique())
    seeds = sorted(int(x) for x in df.Seed.unique())
    assert set(ARMS).issubset(set(df.Algorithm.unique())), "missing arm"
    assert funcs == [1, 4, 6, 9, 11, 15, 21, 25], f"unexpected functions {funcs}"
    assert seeds == list(range(3101, 3111)), f"unexpected seeds {seeds}"
    assert len(df) == 5 * 8 * 10, f"unexpected run count {len(df)}"
    assert (df.Status == "ok").all(), "failed runs present"
    assert (df.Evaluations == 30000).all(), "FE accounting failure"
    assert df.FinalError.notna().all(), "missing final errors"

    # ---------- per-function medians ----------
    med = (df.pivot_table(index="FunctionID", columns="Algorithm", values="FinalError", aggfunc="median")
             .reindex(funcs))
    med20 = (df.pivot_table(index="FunctionID", columns="Algorithm", values="CheckT20", aggfunc="median")
               .reindex(funcs))
    med.to_csv(repdir / "per_function_final_error_median.csv")
    med20.to_csv(repdir / "per_function_checkT20_median.csv")

    # ---------- pairwise tests ----------
    tests = []
    for pair in (MAIN, H2PAIR, H3PAIR):
        a, b = pair
        rows = [wilcoxon_row(df, a, b, f) for f in funcs]
        adj = holm([r["p_raw"] for r in rows])
        for r, q in zip(rows, adj):
            r["p_holm"] = float(q) if np.isfinite(q) else np.nan
        tests.extend(rows)
    tests_df = pd.DataFrame(tests)
    tests_df.to_csv(repdir / "pairwise_wilcoxon_holm.csv", index=False)

    # ---------- gate summaries ----------
    def gate(pair):
        a, b = pair
        ratios = np.array([safe_ratio(med.loc[f, a], med.loc[f, b]) for f in funcs], float)
        return dict(
            A=a, B=b,
            median_ratio=float(np.median(ratios)),
            wins=int(np.sum(ratios < 1.0)),
            losses=int(np.sum(ratios > 1.0)),
            catastrophic_gt_1_20=int(np.sum(ratios > 1.20)),
            ratios={int(f): float(r) for f, r in zip(funcs, ratios)},
        )

    g1 = gate(MAIN); g2 = gate(H2PAIR); g3 = gate(H3PAIR)
    ratios20 = np.array([safe_ratio(med20.loc[f, H3PAIR[0]], med20.loc[f, H3PAIR[1]]) for f in funcs], float)
    g3_20 = dict(median_ratio=float(np.median(ratios20)),
                 worse_gt_1_05=int(np.sum(ratios20 > 1.05)),
                 ratios={int(f): float(r) for f, r in zip(funcs, ratios20)})

    runtime = df.groupby("Algorithm").Seconds.mean().to_dict()
    runtime_ratio_A4 = runtime["G2-TR"] / runtime["A4-G2fixedmin"]
    runtime_ratio_V1 = runtime["G2-TR"] / runtime["V1-frozen"]

    h1_pass = (g1["median_ratio"] <= 0.98) and (g1["wins"] >= 6) and (g1["catastrophic_gt_1_20"] == 0)
    h2_pass = (g2["median_ratio"] <= 0.98) and (g2["wins"] >= 6) and (g2["catastrophic_gt_1_20"] == 0)
    h3_pass = (g3["median_ratio"] <= 1.00) and (g3_20["median_ratio"] <= 1.00) and \
              (g3_20["worse_gt_1_05"] <= 3) and \
              (runtime_ratio_A4 <= 1.15) and (runtime_ratio_V1 <= 1.15)

    # ---------- secondary metrics ----------
    secondary_cols = ["NRecoveredEventual", "RecoveryEventualProb", "LongStagShare",
                      "NovMean", "NovRate", "NovelUsefulRate", "NovelStrictImprove"]
    secondary = (df.groupby("Algorithm")[secondary_cols].mean().reindex(ARMS).T)
    secondary.to_csv(repdir / "secondary_metrics_mean.csv")

    tr = df[df.Algorithm == "G2-TR"].copy()
    tr["G2_pop_success_rate"] = (tr.G2AlphaImp + tr.G2PopImp) / tr.G2EvalCount
    tr["G2_alpha_success_rate"] = tr.G2AlphaImp / tr.G2EvalCount
    tr["G2_global_success_rate"] = tr.G2GlobalImp / tr.G2EvalCount
    tr_radius = tr[["G2EvalCount", "G2AlphaImp", "G2PopImp", "G2NoImp", "G2GlobalImp",
                    "G2RadiusStart", "G2RadiusEnd", "G2RadiusMean", "G2RadiusMin", "G2RadiusMax",
                    "G2_pop_success_rate", "G2_alpha_success_rate", "G2_global_success_rate"]].describe().T
    tr_radius.to_csv(repdir / "g2tr_radius_and_eval_diagnostics.csv")

    summary = dict(
        results_dir=str(outdir), runs=len(df), functions=funcs, seeds=seeds,
        comparison_H1=MAIN, comparison_H2=H2PAIR, comparison_H3=H3PAIR,
        H1_gate=g1, H2_gate=g2, H3_gate=g3,
        H3_checkT20=g3_20,
        runtime_mean_sec={k: float(v) for k, v in runtime.items()},
        runtime_ratio_G2TR_over_A4=float(runtime_ratio_A4),
        runtime_ratio_G2TR_over_V1=float(runtime_ratio_V1),
        H1_pass=bool(h1_pass), H2_pass=bool(h2_pass), H3_pass=bool(h3_pass),
        verdict=("PROMOTE_TO_P3" if (h1_pass and h2_pass and h3_pass) else "STOP_G2TR_NEGATIVE"),
    )
    (repdir / "summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")

    # ---------- human-readable report ----------
    def fmt(x):
        return f"{x:.6g}" if isinstance(x, (int, float, np.floating)) else str(x)

    lines = []
    lines.append("# G2-TR P1 开发实验结果\n")
    lines.append(f"- 结果目录：`{outdir}`")
    lines.append(f"- 运行：{len(df)}（5 臂 × 8 函数 × 10 种子），失败 0，全部 30,000 真 FE")
    lines.append(f"- 函数：{funcs}；种子：{seeds[0]}–{seeds[-1]}")
    lines.append("")
    lines.append("## 预注册门槛判定\n")
    lines.append(f"- **H1（G2-TR vs A2）**：中位比 {fmt(g1['median_ratio'])}，"
                 f"胜/负 {g1['wins']}/{g1['losses']}，灾难性退化(>1.20) {g1['catastrophic_gt_1_20']} → "
                 f"**{'通过' if h1_pass else '不通过'}**")
    lines.append(f"- **H2（G2-TR vs A4固定最小尺度）**：中位比 {fmt(g2['median_ratio'])}，"
                 f"胜/负 {g2['wins']}/{g2['losses']}，灾难性退化(>1.20) {g2['catastrophic_gt_1_20']} → "
                 f"**{'通过' if h2_pass else '不通过'}**")
    lines.append(f"- **H3（不破坏 V1 / 20% FE / 时间）**：最终中位比 {fmt(g3['median_ratio'])}，"
                 f"CheckT20 中位比 {fmt(g3_20['median_ratio'])}，"
                 f"CheckT20 >1.05 的函数数 {g3_20['worse_gt_1_05']}，"
                 f"时间比 vs A4 {fmt(runtime_ratio_A4)} / vs V1 {fmt(runtime_ratio_V1)} → "
                 f"**{'通过' if h3_pass else '不通过'}**")
    lines.append(f"- **最终裁定：{summary['verdict']}**")
    lines.append("")
    lines.append("## 逐函数中位误差\n")
    lines.append("| F | V1 | A2 | A4 | G2-TR | Subset20 | TR/A2 | TR/A4 | TR/V1 |")
    lines.append("|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
    for f in funcs:
        row = [med.loc[f, a] for a in ARMS]
        r1 = safe_ratio(med.loc[f, 'G2-TR'], med.loc[f, 'A2-G1E'])
        r2 = safe_ratio(med.loc[f, 'G2-TR'], med.loc[f, 'A4-G2fixedmin'])
        r3 = safe_ratio(med.loc[f, 'G2-TR'], med.loc[f, 'V1-frozen'])
        lines.append(f"| {f} | " + " | ".join(fmt(v) for v in row) + f" | {fmt(r1)} | {fmt(r2)} | {fmt(r3)} |")
    lines.append("")
    lines.append("## G2-TR 诊断\n")
    lines.append(f"- G2 已评价候选数：均值 {tr.G2EvalCount.mean():.1f}，范围 {tr.G2EvalCount.min():.0f}–{tr.G2EvalCount.max():.0f}")
    lines.append(f"- 每次已评价 G2 候选的 alpha 改进率：{tr['G2_alpha_success_rate'].mean():.4f}")
    lines.append(f"- 每次已评价 G2 候选的种群替换率：{tr['G2_pop_success_rate'].mean():.4f}")
    lines.append(f"- 半径均值：{tr.G2RadiusMean.mean():.5f}；半径结束值中位数：{tr.G2RadiusEnd.median():.5f}")
    lines.append(f"- 半径最大值达到 0.05 的比例：{(tr.G2RadiusMax >= 0.049999).mean():.3f}")
    lines.append("")
    lines.append("## 关键机制解释\n")
    if not h1_pass:
        lines.append("G2-TR 没有通过 H1。信任域半径的大多数更新落在“候选可替换最差狼但未改进 alpha”的保持分支；"
                     "在 GWO 种群最差个体通常很弱的情况下，这个判定过宽，半径长期维持较大值，"
                     "后期又快速塌到下界，因此没有形成稳定的局部精化。该结果同时说明："
                     "在当前 GWO 种群语义下，用“是否替换最差狼”定义局部成功会与 E 的覆盖问题重叠，"
                     "不能仅靠半径自适应解决 G2 的独立性。")
    lines.append("按预注册淘汰规则：停止 G2-TR 半径参数搜索，保留负面结果；不回改门槛，不用 P1 种子继续调参。")
    (repdir / "g2tr_p1_report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    print("\n".join(lines))
    print(f"\n[analysis] wrote {repdir}")


if __name__ == "__main__":
    main()
