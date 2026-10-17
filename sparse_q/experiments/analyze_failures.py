#!/usr/bin/env python3
"""Phase-4 failure analysis: where does the frozen method lose, and why?

Reads the merged final-tier CSV and writes a Chinese markdown report:
per-function ratios vs each key baseline, family aggregation, and the
behaviour diagnostics (novelty-vs-improvement, stagnation, recovery).
"""
import os
import sys
import numpy as np
import pandas as pd

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"


def fam(f):
    if f in (1, 3):
        return "unimodal"
    if 4 <= f <= 10:
        return "simple"
    if 11 <= f <= 20:
        return "hybrid"
    return "composition"


def main():
    batch = sorted([d for d in os.listdir(os.path.join(SQ, "results")) if d.startswith("final_")])[-1]
    path = os.path.join(SQ, "results", batch, "merged_runs.csv")
    df = pd.read_csv(path)
    df = df[df.Status == "ok"]
    A = "S-star"
    refs = [r for r in ["GWO", "B0-ANGWO", "S1-pool38", "IGWO", "HIDMS-PSO",
                        "HCLPSO", "DMS-PSO", "SAQ-CSO", "RASE-GWO", "SPSO-2011"]
            if r in df.Algorithm.unique()]
    piv = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm",
                         values="FinalError", aggfunc="first")
    out = ["# Phase-4 失败函数分析（自动生成）\n",
           f"批次：`{batch}`；主方法：S-star（frozen）\n"]
    # per-function ratios
    out.append("## 1. 逐函数中位误差比（S*/基线）\n")
    out.append("| F | family | " + " | ".join(refs) + " |")
    out.append("|---|---|" + "|".join(["---:"] * len(refs)) + "|")
    per = {}
    for f in sorted(df.FunctionID.unique()):
        row = [f"{int(f)}", fam(f)]
        for r in refs:
            v = (piv.loc[f, A] / piv.loc[f, r]).replace([np.inf, -np.inf], np.nan).dropna()
            per[(f, r)] = v.median()
            row.append(f"{v.median():.3f}")
        out.append("| " + " | ".join(row) + " |")
    out.append("")
    # family aggregation
    out.append("## 2. 函数族汇总（族内函数中位比的中位）\n")
    out.append("| family | " + " | ".join(refs) + " |")
    out.append("|---|" + "|".join(["---:"] * len(refs)) + "|")
    for fm in ["unimodal", "simple", "hybrid", "composition"]:
        fs = [f for f in sorted(df.FunctionID.unique()) if fam(f) == fm]
        row = [fm]
        for r in refs:
            vals = [per[(f, r)] for f in fs]
            row.append(f"{np.median(vals):.3f}")
        out.append("| " + " | ".join(row) + " |")
    out.append("")
    # losses list
    out.append("## 3. 对关键基线的失败函数（比值>1.05）\n")
    for r in ["IGWO", "HIDMS-PSO", "HCLPSO", "DMS-PSO", "SAQ-CSO"]:
        if r not in refs:
            continue
        lose = [f for f in sorted(df.FunctionID.unique()) if per[(f, r)] > 1.05]
        win = [f for f in sorted(df.FunctionID.unique()) if per[(f, r)] < 0.95]
        out.append(f"- vs {r}: 失败 {lose if lose else '无'}；胜出 {win if len(win) < 12 else str(win[:12]) + '...'}")
    out.append("")
    # behaviour diagnostics
    out.append("## 4. 行为诊断（有探针数据的变体）\n")
    out.append("| method | NovelRate | UsefulNov | ImprovFE | LongStag | Recovery | FinalStagLen |")
    out.append("|---|---:|---:|---:|---:|---:|---:|")
    for a in [A, "B0-ANGWO", "GWO", "S1-pool38", "S3p-q25", "S5p-q"]:
        if a not in df.Algorithm.unique():
            continue
        e = df[df.Algorithm == a]
        if "NStagEpisodes" not in e:
            continue
        ep = e["NStagEpisodes"].sum()
        rec = e["NRecoveredWindow"].sum() / ep if ep else float("nan")
        out.append(f"| {a} | {e.NovRate.mean():.3f} | {e.NovelUsefulRate.mean():.5f} | "
                   f"{e.ImprovingFERate.mean():.5f} | {e.LongStagShare.mean():.4f} | {rec:.4f} | "
                   f"{e.FinalStagLen.median():.1f} |")
    out.append("")
    out.append("## 5. 结论提示（人工填写）\n")
    out.append("- 新颖度高但改善率低的函数：")
    out.append("- 长期围绕同一 α 的函数（长停滞占比高 + 恢复低）：")
    out.append("- Q 是否退化：")
    out.append("")
    with open(os.path.join(SQ, "reports", "FAILURE_ANALYSIS_zh.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(out))
    print("\n".join(out[:40]))
    print("... written to sparse_q/reports/FAILURE_ANALYSIS_zh.md")


if __name__ == "__main__":
    main()
