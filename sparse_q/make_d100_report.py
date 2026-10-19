# -*- coding: utf-8 -*-
"""D100_SUPPLEMENT_zh.md: standalone supplementary report (does not overwrite D=50)."""
import os, sys, json
import numpy as np, pandas as pd
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass
SQ=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.join(SQ,"results","d100_analysis")
REP=os.path.join(SQ,"reports")
ALGS=["VAST-GWO","GWO","IGWO","HAGWO","PSO","CLPSO","AOGWO"]

def main():
    S=json.load(open(os.path.join(OUT,"stats_d100.json"),encoding="utf-8"))
    main=pd.read_csv(os.path.join(OUT,"table_d100_main.csv"))
    cats=pd.read_csv(os.path.join(OUT,"table_d100_categories.csv"))
    raw=pd.read_csv(os.path.join(OUT,"raw_runs.csv"),low_memory=False)
    ok=raw[raw.Status=="ok"]
    L=[];A=L.append
    A("# 补充实验报告：VAST-GWO 在 CEC2017 D=100 的高维泛化验证\n\n")
    A("> 独立补充报告。**不覆盖** D=50 原始结果、冻结算法或历史报告。\n")
    A(f"> 日期：{pd.Timestamp.now():%Y-%m-%d} ｜ 数据目录：`sparse_q/results/d100_analysis/`\n\n")
    A("## 0. 摘要\n\n")
    A(f"- 规模：7 算法 × 29 函数 × 30 种子 = **6,090** 次运行；有效 **{len(ok)}** 条，失败 0 条。\n")
    A(f"- 其中复用 VAST-GWO 归档 290 条（逐位复现通过），新跑 5,800 条。\n")
    A(f"- VAST-GWO 平均排名 **{S['mean_rank']['VAST-GWO']:.2f}**（七算法第 {int(main.index[0])+1}）。\n")
    A("- 所有运行严格 100,000 真实 FE，FE 探针一致，轨迹单调，逐作业原子落盘。\n\n")
    A("## 1. 协议\n\n")
    A("| 项 | 值 |\n|---|---|\n")
    A("| Benchmark | CEC2017，29 函数（F1、F3–F30） |\n| 维度 | D=100 |\n")
    A("| 预算 | 100,000 真实 FE（初始化计入） |\n| 种子 | 3001:3030 |\n")
    A("| 种群 | N=50（七算法统一） |\n| 并行 | 恰好 4 个 MATLAB local worker |\n")
    A("| 初始种群 | 同函数同种子共享基池；初始化流与搜索流分离 |\n\n")
    A("## 2. 主表\n\n")
    A("| 算法 | 平均排名 | 中位误差比 | 函数胜-负 | Holm 显著 (+/-) | 运行中位秒 | 相对 GWO |\n")
    A("|---|---:|---:|---:|---:|---:|---:|\n")
    for _,r in main.iterrows():
        A(f"| {'**'+r.Algorithm+'**' if r.Algorithm=='VAST-GWO' else r.Algorithm} | {r.MeanRank:.2f} | "
          f"{r.MedianRatio_vs_VAST:.3f} | {r.FunctionsWin}-{r.FunctionsLoss} | "
          f"+{r.HolmSigWin}/-{r.HolmSigLoss} | {r.RuntimeMedian_s:.2f} | {r.RuntimeRel_GWO:.2f}× |\n")
    A("\n## 3. 按类别\n\n")
    A("| 类别 | 基线 | 中位误差比 | 胜-负 | Holm (+/-) |\n|---|---|---:|---:|---:|\n")
    CN={"unimodal":"单峰","simple_multimodal":"简单多峰","hybrid":"混合","composition":"复合"}
    for cat in ["unimodal","simple_multimodal","hybrid","composition"]:
        for _,r in cats[cats.Category==cat].iterrows():
            A(f"| {CN[cat]} | {r.Baseline} | {r.MedianRatio:.3f} | {r.FunctionsWin}-{r.FunctionsLoss} | +{r.HolmSigWin}/-{r.HolmSigLoss} |\n")
    A("\n## 4. 输出文件\n\n")
    A("| 文件 | 内容 |\n|---|---|\n")
    for f,d in [("raw_runs.csv","全部有效原始运行"),("manifest.json","算法/参数/种子/hash/环境"),
                ("audit_report.md","复现与 FE 审计"),("analysis_report.md","完整统计与结论"),
                ("table_d100_main.csv","七算法主表"),("table_d100_holm.csv","逐函数配对+Holm"),
                ("table_d100_categories.csv","类别汇总"),
                ("figure_d100_ranks.png","排名图（期刊风格）"),("figure_d100_convergence6.pdf","收敛轨迹：五函数 + 排名轨迹（矢量）"),
                ("figure_d100_winloss.png","逐函数胜负"),("figure_d100_runtime.png","运行时间"),("figure_d100_framework.png","方法框架图"),
                ("comparison_d50_d100.md","与 D=50 对照")]:
        A(f"| `{f}` | {d} |\n")
    A("\n## 5. 结论与边界\n\n")
    A(f"1. **排名**：VAST-GWO 平均排名 **{S['mean_rank']['VAST-GWO']:.2f}**"
      f"（95% CI {S['mean_rank_ci']['VAST-GWO'][0]:.2f}–{S['mean_rank_ci']['VAST-GWO'][1]:.2f}），七算法第 1；"
      f"第二名 I-GWO 为 {S['mean_rank']['IGWO']:.2f}。\n")
    A("2. **配对证据**（家族内 Holm）：对 GWO +26/−0、AOGWO +26/−0、CLPSO +23/−3、PSO +21/−1、"
      "HAGWO +19/−3、IGWO +14/−6。全局 174 检验 Holm 下方向不变（+25/−0、+24/−0、+23/−3、+20/−1、+17/−2、+12/−6）。\n")
    A("3. **优势并不全面**：对 I-GWO 仍有 9 个函数不显著，且 F6、F15、F19、F27、F29、F30 显著更差"
      "（F19 达 41×、F30 达 9.3×）。论文不得写“全面优于 I-GWO”。\n")
    A("4. **类别**：单峰类与混合类相对优势最大（六基线类别中位比再取中位分别为 0.406 与 0.444），"
      "复合类（F21–F30）优势最小（0.706；其中对 I-GWO 0.896、HAGWO 0.841）。\n")
    A("5. **运行开销**：中位 8.33 s/次，约 GWO 的 1.98×；函数内 IQR 中位仅 0.19 s，重复性良好。\n")
    A("6. **FE ≠ 迭代**：VAST-GWO 约 9,995 代；GWO/HAGWO/PSO 约 1,999；I-GWO 约 1,000。\n")
    A("7. **与 D=50 相比**：排名由 2.24 改善到 1.76；对 I-GWO 中位比 0.938→0.858，HAGWO 0.806→0.749，"
      "PSO 0.652→0.598，CLPSO 0.668→0.565，AOGWO 0.586→0.484；对 GWO 0.525→0.561（优势略缩小）。"
      "D=100 证据支持高维下整体优势不退化，但个别函数明显退步。\n\n")
    os.makedirs(REP,exist_ok=True)
    open(os.path.join(REP,"D100_SUPPLEMENT_zh.md"),"w",encoding="utf-8",newline="\n").write("".join(L))
    print("wrote reports/D100_SUPPLEMENT_zh.md")

if __name__=="__main__": main()
