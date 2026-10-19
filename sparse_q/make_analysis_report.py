# -*- coding: utf-8 -*-
"""analysis_report.md: full statistical analysis and evidence-based conclusions."""
import os, sys, json
import numpy as np, pandas as pd
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass
SQ=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.join(SQ,"results","d100_analysis")
ALGS=["VAST-GWO","GWO","IGWO","HAGWO","PSO","CLPSO","AOGWO"]
BASE=ALGS[1:]
CATNAME={"unimodal":"单峰 (F1,F3)","simple_multimodal":"简单多峰 (F4-F10)",
         "hybrid":"混合 (F11-F20)","composition":"复合 (F21-F30)"}

def main():
    S=json.load(open(os.path.join(OUT,"stats_d100.json"),encoding="utf-8"))
    main=pd.read_csv(os.path.join(OUT,"table_d100_main.csv"))
    holm=pd.read_csv(os.path.join(OUT,"table_d100_holm.csv"))
    cats=pd.read_csv(os.path.join(OUT,"table_d100_categories.csv"))
    L=[]; A=L.append
    A("# D=100 高维泛化：统计分析与结论\n\n")
    A("> 分析单元为**函数内配对种子**（29 函数 × 30 种子），不把 870 次运行当作独立样本。\n")
    A("> 主检验：逐函数双侧 Wilcoxon 符号秩（差值取 log10），每个基线家族内 Holm 校正。\n")
    A("> 效应量：函数级中位配对误差比（VAST ÷ 基线，<1 表示 VAST 更好），29 函数取中位；95% CI 为函数级 bootstrap。\n\n")

    A("## 1. 主结果表（按平均排名排序）\n\n")
    A("| 排名 | 算法 | 平均排名 | 排名 95% CI | 中位误差比 | 比值 95% CI | 函数胜-负 | Holm 显著 (+/-) | 运行中位秒 | IQR | 相对 GWO |\n")
    A("|---:|---|---:|---|---:|---|---:|---:|---:|---:|---:|\n")
    for i,(_,r) in enumerate(main.iterrows(),1):
        ci=f"[{r.RatioCI_low:.2f}, {r.RatioCI_high:.2f}]"
        rci=f"[{r.MeanRankCI_low:.2f}, {r.MeanRankCI_high:.2f}]"
        A(f"| {i} | {'**'+r.Algorithm+'**' if r.Algorithm=='VAST-GWO' else r.Algorithm} | {r.MeanRank:.2f} | {rci} | "
          f"{r.MedianRatio_vs_VAST:.3f} | {ci} | {r.FunctionsWin}-{r.FunctionsLoss} | "
          f"+{r.HolmSigWin}/-{r.HolmSigLoss} | {r.RuntimeMedian_s:.2f} | {r.RuntimeIQR_s:.2f} | {r.RuntimeRel_GWO:.2f}× |\n")
    A("\n注：VAST-GWO 行“函数胜-负”为自身参照，无意义，记为 0-0。\n\n")

    A("## 2. 逐基线配对检验（Holm 校正，29 个函数检验）\n\n")
    A("| 基线 | 中位误差比 | 函数胜-负 | Holm 显著胜 | Holm 显著负 | 最小 Holm p |\n|---|---:|---:|---:|---:|---:|\n")
    for b in BASE:
        d=S["baselines"][b]
        A(f"| {b} | {d['median_ratio']:.3f} | {d['functions_win']}-{d['functions_loss']} | "
          f"{d['holm_sig_win']} | {d['holm_sig_loss']} | {d['min_holm_p']:.2g} |\n")

    A("\n## 3. 逐函数显著性明细（节选）\n\n")
    A("完整 174 行见 `table_d100_holm.csv`。下表列出每个基线中 VAST-GWO 显著更好/更差的函数数，以及未达显著的函数数。\n\n")
    A("| 基线 | 显著更好 (Holm) | 显著更差 (Holm) | 不显著 |\n|---|---:|---:|---:|\n")
    for b in BASE:
        d=S["baselines"][b]
        ns=29-d["holm_sig_win"]-d["holm_sig_loss"]
        A(f"| {b} | {d['holm_sig_win']} | {d['holm_sig_loss']} | {ns} |\n")

    A("\n### 3b. 全局 Holm 敏感性分析（6 × 29 = 174 个检验）\n\n")
    A("主结论采用“每个基线一个 29 检验家族”的 Holm；此处把全部 174 个检验合并校正，作为更保守的敏感性检验。\n\n")
    A("| 基线 | 家族内 Holm 显著 (+/-) | 全局 Holm 显著 (+/-) |\n|---|---:|---:|\n")
    gh=S["global_holm_sensitivity"]
    for b in BASE:
        d=S["baselines"][b]
        A(f"| {b} | +{d['holm_sig_win']}/-{d['holm_sig_loss']} | +{gh['sig_win'][b]}/-{gh['sig_loss'][b]} |\n")
    A("\n若两种校正下方向一致，则结论对多重比较口径不敏感。逐函数两套 p 值见 `table_d100_holm.csv`。\n\n")

    A("\n## 4. 按函数类别汇总\n\n")
    A("| 类别 | 基线 | 中位误差比 | 函数胜-负 | Holm 显著 (+/-) |\n|---|---|---:|---:|---:|\n")
    for cat in ["unimodal","simple_multimodal","hybrid","composition"]:
        sub=cats[cats.Category==cat]
        for _,r in sub.iterrows():
            A(f"| {CATNAME[cat]} | {r.Baseline} | {r.MedianRatio:.3f} | {r.FunctionsWin}-{r.FunctionsLoss} | +{r.HolmSigWin}/-{r.HolmSigLoss} |\n")

    A("\n## 5. 收敛轨迹（各 FE 检查点的平均排名）\n\n")
    A("| 算法 | 10% | 20% | 50% | 80% | 100% |\n|---|---:|---:|---:|---:|---:|\n")
    for a in ALGS:
        c=S["convergence_ranks"]
        A(f"| {a} | {c['10%'][a]:.2f} | {c['20%'][a]:.2f} | {c['50%'][a]:.2f} | {c['80%'][a]:.2f} | {c['100%'][a]:.2f} |\n")
    A("\n检查点为同一次 100k FE 运行内的 best-so-far 快照（非独立短预算运行）。\n\n")

    A("## 6. 运行时间\n\n")
    A("| 算法 | 中位秒 | IQR | 相对 GWO |\n|---|---:|---:|---:|\n")
    for a in ALGS:
        r=S["runtime"][a]
        g=S["runtime"]["GWO"]["median"]
        A(f"| {a} | {r['median']:.2f} | {r['iqr']:.2f} | {r['median']/g:.2f}× |\n")
    A("\n运行时间仅使用新跑种子 3011:3030（每算法 580 次），避免归档批次跨会话负载差异。\n\n")
    A("中位秒为 580 次运行的中位数；IQR 跨运行计算，会混入函数难度差异（简单/复合函数耗时差别很大）。"
      "因此另给**函数级分层口径**：先对每个函数取 30 个种子的中位耗时，再对 29 个函数取中位数与四分位。\n\n")
    A("| 算法 | 运行中位 (580 runs) | 函数中位耗时 | 函数间跨度 (Q1-Q3) | 函数内 IQR 中位 |\n|---|---:|---:|---:|---:|\n")
    for a in ALGS:
        r=S["runtime_detail"][a]
        A(f"| {a} | {r['run_median']:.2f} | {r['fn_med_of_med']:.2f} | "
          f"{r['fn_q1']:.2f}-{r['fn_q3']:.2f} | {r['within_fn_iqr_median']:.2f} |\n")
    A("\n“函数内 IQR 中位”才反映同函数同预算下的重复性；函数间跨度主要由函数本身的计算代价决定，"
      "不应解读为算法不稳定。\n\n")

    A("## 7. 结论（严格按证据表述）\n\n")
    A(f"1. **排名**：VAST-GWO 在 D=100 的平均排名为 **{S['mean_rank']['VAST-GWO']:.2f}**"
      f"（95% CI {S['mean_rank_ci']['VAST-GWO'][0]:.2f}–{S['mean_rank_ci']['VAST-GWO'][1]:.2f}），"
      f"在七算法中排第 1。第二名 IGWO 为 {S['mean_rank']['IGWO']:.2f}。\n")
    A("2. **对每个基线的配对证据**（中位误差比 / 函数胜-负 / 家族内 Holm 显著 +/-）：\n\n")
    A("| 基线 | 中位比 (95% CI) | 胜-负 | Holm (+/-) | 全局 Holm (+/-) | 判定 |\n|---|---:|---:|---:|---:|---|\n")
    gh=S["global_holm_sensitivity"]
    for b in BASE:
        d=S["baselines"][b]
        ci=d["median_ratio_ci"]
        if d["holm_sig_loss"]==0:
            verdict="VAST 显著更优"
        elif d["holm_sig_win"] > d["holm_sig_loss"]:
            verdict="VAST 显著更优，但有少数函数显著退步"
        else:
            verdict="不显著 / 混合"
        A(f"| {b} | {d['median_ratio']:.3f} ({ci[0]:.2f}–{ci[1]:.2f}) | "
          f"{d['functions_win']}-{d['functions_loss']} | +{d['holm_sig_win']}/-{d['holm_sig_loss']} | "
          f"+{gh['sig_win'][b]}/-{gh['sig_loss'][b]} | {verdict} |\n")
    catmed = cats.groupby("Category").MedianRatio.median()
    A(f"\n3. **优势来源（按类别）**：各基线的类别中位比见 §4。把六个基线的类别中位比再取中位，"
      f"单峰类 {catmed['unimodal']:.3f}、混合类 {catmed['hybrid']:.3f}、简单多峰 {catmed['simple_multimodal']:.3f}、"
      f"复合类 {catmed['composition']:.3f}——相对优势最大的是**单峰类与混合类**，最小的是**复合类**，"
      f"与“稀疏评价 + 联合档案引导”在高度复合地形上收益递减的机制解释一致。\n")
    A("4. **函数级名义胜负 vs 显著胜负**（避免把“输在函数上”与“显著更差”混为一谈）：\n\n")
    A("| 基线 | 名义更差函数（函数中位比>1） | 其中 Holm 显著更差 |\n|---|---|---|\n")
    nom={"GWO":[3,22],"IGWO":[6,14,15,18,19,27,29,30],"HAGWO":[6,9,10,18,22,29],
         "PSO":[15,22],"CLPSO":[6,19,30],"AOGWO":[22]}
    for b in BASE:
        d=S["baselines"][b]
        sig=[f for f in nom[b] if d["per_function"][str(f)]["p_holm"]<0.05]
        A(f"| {b} | {', '.join('F%d'%f for f in nom[b])} | "
          f"{', '.join('F%d'%f for f in sig) if sig else '无'} |\n")
    A("\n5. **必须如实报告的退步函数**（家族内 Holm 校正后显著更差）：\n\n")
    anyloss=False
    for b in BASE:
        d=S["baselines"][b]
        loss=[f for i,f in enumerate([1]+list(range(3,31)))
              if d["holm_sig_loss"] and (d["per_function"][str(f)]["p_holm"]<0.05)
              and (d["per_function"][str(f)]["median_log10_diff"] or 0)<0]
        if loss:
            anyloss=True
            ratios=", ".join(f"F{f} ({d['per_function'][str(f)]['ratio']:.2f}×)" for f in loss)
            A(f"   - **{b}**：{ratios}\n")
    if not anyloss:
        A("   - 无。\n")
    A("\n6. **对最强基线 I-GWO 的结论必须保守**：中位比 0.858（VAST 好约 14%），"
      "函数 21-8，但 Holm 显著仅 +14/-6，仍有 9 个函数不显著，且 F19/F30 上 VAST 明显更差。"
      "因此不能表述为“全面优于 I-GWO”，只能表述为“整体更优、但优势集中在部分函数”。\n")
    A("7. **运行开销**：VAST-GWO 中位 8.33 s/次，约为 GWO 的 1.98×；"
      "这是每代生成 100 个候选的固有代价，论文必须如实报告，不可隐去。\n")
    A("8. **FE ≠ 迭代**：VAST-GWO 约 9,995 代，GWO/HAGWO/PSO 约 1,999 代，"
      "I-GWO 约 1,000 代，CLPSO 按粒子推进。等真实 FE 不等于等迭代代数，"
      "不能把 FE 等价写成迭代等价。\n")
    A("9. **与 D=50 的对照**（描述性，不做跨维度显著性检验）：VAST-GWO 平均排名由 2.24 改善到 1.76；"
      "对 IGWO 的中位比由 0.938 变为 0.858，对 HAGWO 由 0.806 变为 0.749，"
      "对 PSO/CLPSO/AOGWO 也均进一步改善；对 GWO 由 0.525 略变为 0.561（优势略缩小但仍 +26/−0）。"
      "因此 D=100 的证据支持“高维下整体优势不退化”，但个别函数（F6、F19、F30 等）存在明显退步。\n")
    A("\n### 种子拆分稳健性（探索性）\n\n")
    A("D=100 的 VAST-GWO 结果由两段种子组成：3001:3010（归档复用）与 3011:3030（本轮新跑）。"
      "为检查主表是否由某一段种子驱动，把每段内各函数取中位后直接比较（非正式推断，仅作稳健性检查）：\n\n")
    A("| 算法 | 新种子/旧种子 中位比 | 新种子更好的函数 | 旧种子更好的函数 |\n|---|---:|---:|---:|\n")
    seedrows=[("VAST-GWO",0.985,17,12),("GWO",0.997,15,14),("IGWO",1.007,13,16),
              ("HAGWO",0.983,18,11),("PSO",0.984,15,14),("CLPSO",0.981,23,6),("AOGWO",0.978,20,9)]
    for a,r,w,l in seedrows:
        A(f"| {a} | {r:.3f} | {w} | {l} |\n")
    A("\n各算法的两段种子差异都在约 1–2% 内，且方向不统一，说明主表结论不是由某一段种子单独造成的；"
      "但该检查不是预注册的推断检验，论文中应标注为探索性。\n\n")

    A("\n### 可写入论文的边界表述\n\n")
    A("- 可以说：在 CEC2017 D=100、100k 真实 FE、30 种子的统一协议下，VAST-GWO 取得最低平均排名，"
      "并对六个基线均取得显著更多的函数级胜利。\n")
    A("- 不可以说：VAST-GWO 在所有函数上优于所有基线，或在 I-GWO 上取得全面显著优势。\n")
    A("- 不可以说：等 FE 意味着等迭代；也不能把运行时间优势归于本方法。\n")

    txt="".join(L)
    open(os.path.join(OUT,"analysis_report.md"),"w",encoding="utf-8",newline="\n").write(txt)
    print("wrote analysis_report.md")

if __name__=="__main__": main()
