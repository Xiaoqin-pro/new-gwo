# -*- coding: utf-8 -*-
"""UAV 应用正式档分析（900 次：6 算法 x 5 图 x 30 种子 x 30k FE）。
三层指标：可行性 -> 路径质量 -> 配对统计；输出可复算报告。"""
import os, io, sys
import numpy as np, pandas as pd
from scipy import stats
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass

SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
CSV = os.path.join(SQ, "results", "uav_formal_N50_30k", "raw_runs.csv")
OUT = os.path.join(SQ, "results", "uav_formal_N50_30k", "analysis_report.txt")
d = pd.read_csv(CSV, low_memory=False)
ALGS = ["VAST-GWO","GWO","IGWO","HAGWO","PSO","CLPSO"]
BASE = [a for a in ALGS if a != "VAST-GWO"]
CK = [2000,5000,10000,20000,30000]
lines = []
def out(s=""):
    print(s); lines.append(s)

def holm(p):
    p = np.asarray(p, float); o = np.argsort(p); adj = np.empty_like(p); cur = 0.0
    for i, ix in enumerate(o):
        cur = max(cur, p[ix]*(len(p)-i)); adj[ix] = min(cur, 1.0)
    return adj

out("="*84)
out("UAV 应用正式档分析  benchmark-v1 | 6 算法 x 5 图 x 30 种子 x 30,000 真实 FE")
out("数据: results/uav_formal_N50_30k/raw_runs.csv (900/900 ok, 0 failed)")
out("="*84)

# ---------- A1. 逐算法总览 ----------
out("\n[A1] 逐算法总览（每算法 150 次 = 5 图 x 30 种子）")
out(f"{'算法':<10}{'可行率':>8}{'30k未可行':>9}{'首次可行FE中位':>13}{'可行Cost中位':>12}{'无条件罚项Cost中位*':>18}{'运行秒中位':>10}")
rowsA=[]
for a in ALGS:
    e = d[d.Algorithm==a]
    feas = e.Feasible.mean()
    nf = int((e.Feasible==0).sum())
    ff = e.loc[e.Feasible==1, "FirstFeasibleEvaluation"]
    ck = e.loc[e.Feasible==1, "CkptBestFeasCost_5"]
    pen = e["CkptBestPenalized_5"]
    rowsA.append(dict(alg=a, feas=feas, nf=nf, ff_med=np.nanmedian(ff) if len(ff) else np.nan,
                      cost_med=np.nanmedian(ck), pen_med=np.nanmedian(pen),
                      sec=np.nanmedian(e.SearchSeconds)))
    out(f"{a:<10}{feas*100:>7.1f}%{nf:>9d}{rowsA[-1]['ff_med']:>13.0f}{rowsA[-1]['cost_med']:>12.1f}{rowsA[-1]['pen_med']:>18.1f}{rowsA[-1]['sec']:>10.1f}")
out("*无条件罚项Cost = 含不可行罚项的最优值，对所有运行取中位（不剔除失败）")

# ---------- A2. 检查点累计可行率 ----------
out("\n[A2] FE 检查点累计可行率（%，同一次 30k 运行内的早期待观测）")
hdr = f"{'算法':<10}" + "".join(f"{f'{c//1000}k':>8}" for c in CK)
out(hdr)
cum = {}
for a in ALGS:
    e = d[d.Algorithm==a]
    vals = [e[f"CkptHadFeasible_{i+1}"].mean()*100 for i in range(5)]
    cum[a]=vals
    out(f"{a:<10}" + "".join(f"{v:>8.1f}" for v in vals))

# ---------- A3. 分地图可行率 ----------
out("\n[A3] 分地图可行率（%，每格 30 次运行）")
maps = sorted(d.Terrain.unique())
out(f"{'算法':<10}" + "".join(f"{m[:8]:>10}" for m in maps))
for a in ALGS:
    line = f"{a:<10}"
    for m in maps:
        e = d[(d.Algorithm==a)&(d.Terrain==m)]
        line += f"{e.Feasible.mean()*100:>10.1f}"
    out(line)

# ---------- B. 配对统计（同地图同种子） ----------
piv_f  = d.pivot_table(index=["Terrain","Run"], columns="Algorithm", values="Feasible")
piv_c  = d.pivot_table(index=["Terrain","Run"], columns="Algorithm", values="CkptBestFeasCost_5")
piv_p  = d.pivot_table(index=["Terrain","Run"], columns="Algorithm", values="CkptBestPenalized_5")
piv_ff = d.pivot_table(index=["Terrain","Run"], columns="Algorithm", values="FirstFeasibleEvaluation")

out("\n[B] 对 VAST-GWO 的配对统计（150 对 = 5 图 x 30 种子）")
out("  McNemar: 最终可行性;  Cost: 双方可行对的逐对比值;  罚项: 全部 150 对")
out(f"{'基线':<9}{'McNemar p':>10}{'VAST独可行':>10}{'对照独可行':>10}{'双方可行n':>9}{'Cost中位比':>10}{'Cost p':>9}{'罚项中位比':>10}{'罚项 p':>9}")
mc_p=[]; cost_p=[]; pen_p=[]
res={}
for b in BASE:
    f1 = piv_f["VAST-GWO"].values; f2 = piv_f[b].values
    b01 = int(((f1==1)&(f2==0)).sum()); c10 = int(((f1==0)&(f2==1)).sum())
    if b01+c10>0:
        pm = stats.binomtest(b01, b01+c10, 0.5).pvalue
    else:
        pm = 1.0
    both = (piv_c["VAST-GWO"].notna())&(piv_c[b].notna())
    nboth = int(both.sum())
    if nboth>=8:
        r = piv_c.loc[both,"VAST-GWO"]/piv_c.loc[both,b]
        medr = float(np.median(r))
        dd = np.log10(piv_c.loc[both,b])-np.log10(piv_c.loc[both,"VAST-GWO"])
        pc = stats.wilcoxon(dd).pvalue if np.any(dd!=0) else 1.0
    else:
        medr=np.nan; pc=np.nan
    rp = piv_p["VAST-GWO"]/piv_p[b]
    medrp = float(np.median(rp))
    dp = np.log10(piv_p[b])-np.log10(piv_p["VAST-GWO"])
    pp = stats.wilcoxon(dp).pvalue if np.any(dp!=0) else 1.0
    mc_p.append(pm); cost_p.append(pc); pen_p.append(pp)
    res[b]=dict(mc=pm,b01=b01,c10=c10,nboth=nboth,medr=medr,pc=pc,medrp=medrp,pp=pp)
qmc=holm(mc_p); qc=holm(cost_p); qpp=holm(pen_p)
for b,q1,q2,q3 in zip(BASE,qmc,qc,qpp):
    r=res[b]
    out(f"{b:<9}{r['mc']:>10.3g}{r['b01']:>10d}{r['c10']:>10d}{r['nboth']:>9d}{r['medr']:>10.3f}{r['pc']:>9.3g}{r['medrp']:>10.3f}{r['pp']:>9.3g}")
out("  Holm 校正后 p（跨 5 个基线）:")
out("    McNemar: " + ", ".join(f"{b}={p:.3g}" for b,p in zip(BASE,qmc)))
out("    Cost(双方可行): " + ", ".join(f"{b}={p:.3g}" for b,p in zip(BASE,qc)))
out("    罚项(全部对): " + ", ".join(f"{b}={p:.3g}" for b,p in zip(BASE,qpp)))

# ---------- B2. 首次可行 FE 配对（双方都成功的对） ----------
out("\n[B2] 首次可行 FE：仅统计双方均成功的配对（截尾未成功的对已排除，n 见上表）")
for b in BASE:
    m = (piv_ff["VAST-GWO"].notna())&(piv_ff[b].notna())
    n=int(m.sum())
    if n>=8:
        dd = piv_ff.loc[m,"VAST-GWO"]-piv_ff.loc[m,b]
        p = stats.wilcoxon(dd).pvalue if np.any(dd!=0) else 1.0
        out(f"  VAST vs {b:<8} n={n:<4} 中位差值(V-X)={np.median(dd):>8.0f} FE  p={p:.3g}  VAST更早占比={ (dd<0).mean()*100:.0f}%")
    else:
        out(f"  VAST vs {b:<8} n={n:<4} 样本不足")

# ---------- B3. 分地图 Cost 比值 ----------
out("\n[B3] 分地图 可行 Cost 中位比（VAST/基线，<1 = VAST 更好；仅双方可行对）")
out(f"{'基线':<9}" + "".join(f"{m[:8]:>10}" for m in maps) + f"{'胜图数':>8}")
for b in BASE:
    line=f"{b:<9}"; wins=0
    for m in maps:
        msk=(piv_c.index.get_level_values(0)==m)
        a1=piv_c.loc[msk,"VAST-GWO"]; a2=piv_c.loc[msk,b]
        ok=a1.notna()&a2.notna()
        if ok.sum()>=5:
            r=float(np.median(a1[ok]/a2[ok])); wins += r<1
            line+=f"{r:>10.3f}"
        else:
            line+=f"{'--':>10}"
    out(line+f"{wins:>8d}")

out("\n[说明] ①20k/10k/5k/2k 为 30k 协议内的检查点，不等价于独立短预算运行；")
out("       ②首次可行 FE 仅在双方成功对间比较；可行性差异由 McNemar 报告；")
out("       ③不可行运行不进入 Cost 比较，但进入无条件的罚项比较。")

io.open(OUT,"w",encoding="utf-8").write("\n".join(lines))
print("\n[report saved]", OUT)
