# -*- coding: utf-8 -*-
"""comparison_d50_d100.md: dimension-generalisation contrast (D=50 vs D=100)."""
import os, sys
import numpy as np, pandas as pd, glob
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass
SQ = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(SQ, "results", "d100_analysis")
ALGS = ["VAST-GWO","GWO","IGWO","HAGWO","PSO","CLPSO","AOGWO"]

def d50_pivot():
    b = pd.read_csv(os.path.join(SQ,"results","final_20261016_215309","merged_runs.csv"), low_memory=False)
    b = b[b.Status=="ok"]
    parts=[b]
    for pat,mp in [("new3_*",{"HAGWO":"HAGWO","AOGWO":"AOGWO"}),("pso_*",{"PSO(classic)":"PSO"})]:
        c=[d for d in sorted(glob.glob(os.path.join(SQ,"results",pat))) if os.path.exists(os.path.join(d,"runs.csv"))]
        if c:
            d=pd.read_csv(os.path.join(c[-1],"runs.csv")); d=d[d.Status=="ok"]
            d["Algorithm"]=d.Algorithm.replace(mp); parts.append(d)
    df=pd.concat(parts,ignore_index=True,sort=False)
    df=df[df.Algorithm.isin(ALGS+["S-star"])].copy()
    df["Algorithm"]=df.Algorithm.replace({"S-star":"VAST-GWO"})
    return df.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="FinalError",aggfunc="first")

def d100_pivot():
    df=pd.read_csv(os.path.join(OUT,"raw_runs.csv"),low_memory=False)
    df=df[df.Status=="ok"]
    return df.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="FinalError",aggfunc="first")

def ranks(piv):
    med=piv.groupby(level=0).median()
    return med[ALGS].rank(axis=1).mean(axis=0)

def ratio(piv,b):
    r=piv["VAST-GWO"]; x=piv[b]; c=r.notna()&x.notna()&(x!=0)
    per=r[c]/x[c]
    fn=per.groupby(level=0).median()
    return float(np.median(fn)), int((fn<1).sum()), int((fn>1).sum())

PAPER50 = {
    "rank": {"VAST-GWO":2.24,"IGWO":2.28,"HAGWO":3.41,"PSO":4.41,"CLPSO":4.48,"AOGWO":5.07,"GWO":6.10},
    "ratio": {"GWO":0.525,"IGWO":0.938,"HAGWO":0.806,"PSO":0.652,"CLPSO":0.668,"AOGWO":0.586},
    # W-L is recomputed below with the same aggregation as D=100; the paper
    # table's W-L column is vs GWO, not vs VAST-GWO, so it is not reused here.
}

def main():
    p50=d50_pivot(); p100=d100_pivot()
    r50=ranks(p50); r100=ranks(p100)
    lines=[]
    lines.append("# D=50 vs D=100：维度泛化对照\n")
    lines.append("> 两套结果均为 CEC2017、29 函数、100,000 真实 FE、种子 3001:3030、N=50、同初始池协议。\n")
    lines.append("> D=50 为论文主表结果；D=100 为本补充实验。比值 = VAST-GWO ÷ 基线，<1 表示 VAST-GWO 更好。\n")
    lines.append("\n## 1. 平均排名\n")
    lines.append("| 算法 | D=50 平均排名 | D=100 平均排名 | 变化 |\n|---|---:|---:|---:|\n")
    for a in ALGS:
        d=r100[a]-PAPER50["rank"][a]
        lines.append(f"| {a} | {PAPER50['rank'][a]:.2f} | {r100[a]:.2f} | {d:+.2f} |\n")
    lines.append("\n## 2. VAST-GWO 相对各基线的中位误差比与胜负\n")
    lines.append("| 基线 | D=50 中位比 | D=50 胜-负 | D=100 中位比 | D=100 胜-负 | 比值变化 |\n|---|---:|---:|---:|---:|---:|\n")
    for b in ALGS[1:]:
        m100,w100,l100=ratio(p100,b)
        m50r,w50,l50=ratio(p50,b)
        lines.append(f"| {b} | {m50r:.3f} | {w50}-{l50} | {m100:.3f} | {w100}-{l100} | {m100/m50r:.2f}× |\n")
    # runtime
    d100=pd.read_csv(os.path.join(OUT,"raw_runs.csv"),low_memory=False)
    d100=d100[(d100.Status=="ok")&(d100.Seed>=3011)]
    lines.append("\n## 3. 运行时间（D=100 仅用新跑种子 3011:3030）\n")
    lines.append("| 算法 | 中位秒 | IQR | 相对 GWO |\n|---|---:|---:|---:|\n")
    g=d100[d100.Algorithm=="GWO"].Seconds.median()
    for a in ALGS:
        s=d100[d100.Algorithm==a].Seconds
        lines.append(f"| {a} | {s.median():.2f} | {s.quantile(.75)-s.quantile(.25):.2f} | {s.median()/g:.2f}× |\n")
    lines.append("\n> D=50 的排名列取论文主表 `paper/tables/table_main.tex`；误差比与胜-负列用与本补充实验**完全相同**的"
                 "聚合代码从 D=50 合并结果重算（论文主表的 W-L 列是“对 GWO”，不是“对 VAST-GWO”，不能直接挪用）。"
                 "个别函数并列会使胜-负与本报告文字中的旧口径相差 ±1。\n")
    lines.append("\n## 4. 读法与纪律\n")
    lines.append("- 排名变化与比值变化是**描述性**对照；D=50 与 D=100 不是同一批运行，不做跨维度显著性检验。\n")
    lines.append("- D=100 的推断统计（逐函数 Wilcoxon + Holm）见 `table_d100_holm.csv` 与 `analysis_report.md`。\n")
    lines.append("- 若 VAST-GWO 在 D=100 的优势缩小或个别函数退步，按原始结果如实呈现，不据此改动算法或统计口径。\n")
    lines.append("- **口径差异**：D=50 的 CLPSO 行沿用论文主表的冻结套件归档数据（与严格 N=50 复现统计上不可区分，"
                 "中位比 1.017、p=0.085）；D=100 的 CLPSO 行为 TEC2006 原版代码 N=50 严格复现。"
                 "因此 CLPSO 的跨维度比值变化含约 1.7% 的口径差异，应视为描述性。\n")
    lines.append("- D=50 的 VAST-GWO 与 D=100 复用段来自同一次冻结实现；D=100 归档段已做 290/290 逐位复现。\n")
    txt="".join(lines)
    open(os.path.join(OUT,"comparison_d50_d100.md"),"w",encoding="utf-8",newline="\n").write(txt)
    print(txt)

if __name__=="__main__": main()
