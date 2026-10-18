# -*- coding: utf-8 -*-
"""UAV 应用正式档分析 v2（修订版）
修订点（据评审意见）：
  1) 首次可行 FE 采用【截尾】口径：30k 为截尾时点；报告 KM 曲线与 RMST（含未成功运行）
     以及"检查点有序配对检验"（2k<5k<10k<20k<30k<未达成），不剔除失败运行；
  2) 分地图配对统计与效应量（中位比、胜-负、Wilcoxon p、rank-biserial）；
  3) 核对 Cost 与 CkptBestFeasCost_5 字段一致性；
  4) 路径改为相对脚本定位，任意机器可复算。
"""
import os, sys, io
import numpy as np, pandas as pd
from scipy import stats
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass

HERE = os.path.dirname(os.path.abspath(__file__))          # sparse_q/experiments
SQ   = os.path.dirname(HERE)                               # sparse_q
CSV  = os.path.join(SQ, "results", "uav_formal_N50_30k", "raw_runs.csv")
OUT  = os.path.join(SQ, "results", "uav_formal_N50_30k", "analysis_report.txt")
BUDGET = 30000
d = pd.read_csv(CSV, low_memory=False)
ALGS = ["VAST-GWO","GWO","IGWO","HAGWO","PSO","CLPSO"]
BASE = [a for a in ALGS if a != "VAST-GWO"]
CK = [2000,5000,10000,20000,30000]
lines=[]
def out(s=""):
    print(s); lines.append(s)
def holm(p):
    p=np.asarray(p,float); o=np.argsort(p); adj=np.empty_like(p); cur=0.0
    for i,ix in enumerate(o):
        cur=max(cur,p[ix]*(len(p)-i)); adj[ix]=min(cur,1.0)
    return adj
def rank_biserial(diffs):
    # diffs>0 表示 VAST 更优；返回 rank-biserial effect size
    nz=diffs[diffs!=0]
    if len(nz)==0: return 0.0
    r=stats.rankdata(np.abs(nz))
    wp=r[nz>0].sum(); wn=r[nz<0].sum()
    return float((wp-wn)/(wp+wn))
def rmst(ff, feas, tau=BUDGET):
    t=np.where(feas==1, np.minimum(ff,tau), tau)
    return float(np.mean(t))
def boot_rmst_ci(ff, feas, n=2000, seed=7):
    rng=np.random.default_rng(seed); N=len(ff); vals=[]
    for _ in range(n):
        idx=rng.integers(0,N,N)
        vals.append(rmst(ff[idx],feas[idx]))
    return np.percentile(vals,[2.5,97.5])
def ordinal_first_ckpt(row):
    for i,c in enumerate(CK):
        if row[f"CkptHadFeasible_{i+1}"]==1: return i+1
    return 6   # 30k 内未达成（截尾类）

out("="*88)
out("UAV 应用正式档分析 v2（修订：截尾统计/分地图配对/字段核对/相对路径）")
out("benchmark-v1 | 6 算法 x 5 图 x 30 种子 x 30,000 真实 FE | 900/900 ok, 0 failed")
out("="*88)

# ---- 0. 字段核对 ----
f=d[d.Feasible==1]
maxdiff=float((f.Cost-f.CkptBestFeasCost_5).abs().max())
out(f"\n[0] 字段核对: 可行解上 max|Cost - CkptBestFeasCost_5| = {maxdiff:g} "
    f"(n={len(f)}; 不可行时 CkptBestFeasCost_5=NaN) -> 表与图使用同一指标")

# ---- A1. 总览 ----
out("\n[A1] 逐算法总览（每算法 150 次）；RMST = 30k 截尾下首次可行时间的限制均值（越小越好，含失败运行）")
out(f"{'算法':<10}{'可行率':>8}{'30k未可行':>9}{'RMST(FE)':>10}{'RMST 95%CI':>20}{'首次可行FE中位*':>15}{'可行Cost中位':>12}{'罚项中位†':>10}")
rmst_tab={}
for a in ALGS:
    e=d[d.Algorithm==a]
    feas=e.Feasible.values.astype(int); ff=e.FirstFeasibleEvaluation.values
    r=rmst(ff,feas); lo,hi=boot_rmst_ci(ff,feas)
    rmst_tab[a]=(r,lo,hi)
    ffm=np.nanmedian(e.loc[e.Feasible==1,"FirstFeasibleEvaluation"])
    out(f"{a:<10}{e.Feasible.mean()*100:>7.1f}%{int((e.Feasible==0).sum()):>9d}{r:>10.0f}"
        f"{f'[{lo:.0f},{hi:.0f}]':>20}{ffm:>15.0f}"
        f"{np.nanmedian(e.loc[e.Feasible==1,'CkptBestFeasCost_5']):>12.1f}"
        f"{np.median(e['CkptBestPenalized_5']):>10.1f}")
out("*仅成功运行的中位（有条件口径，供对照）；†对全部运行取中位（含罚项），不剔除失败")

# ---- A2. 检查点累计可行率（与 KM 一致；截尾仅发生在 30k） ----
out("\n[A2] FE 检查点累计可行率（%，全部运行的 KM 口径；截尾仅发生在 30k 时点）")
out(f"{'算法':<10}"+"".join(f"{f'{c//1000}k':>8}" for c in CK))
for a in ALGS:
    e=d[d.Algorithm==a]
    out(f"{a:<10}"+"".join(f"{e[f'CkptHadFeasible_{i+1}'].mean()*100:>8.1f}" for i in range(5)))

# ---- A3. 分地图可行率 ----
maps=sorted(d.Terrain.unique())
out("\n[A3] 分地图可行率（%，每格 30 次）")
out(f"{'算法':<10}"+"".join(f"{m[:8]:>10}" for m in maps))
for a in ALGS:
    out(f"{a:<10}"+"".join(f"{d[(d.Algorithm==a)&(d.Terrain==m)].Feasible.mean()*100:>10.1f}" for m in maps))

# ---- 数据透视 ----
d["OrdCkpt"]=d.apply(ordinal_first_ckpt,axis=1)
piv_f=d.pivot_table(index=["Terrain","Run"],columns="Algorithm",values="Feasible")
piv_c=d.pivot_table(index=["Terrain","Run"],columns="Algorithm",values="CkptBestFeasCost_5")
piv_p=d.pivot_table(index=["Terrain","Run"],columns="Algorithm",values="CkptBestPenalized_5")
piv_o=d.pivot_table(index=["Terrain","Run"],columns="Algorithm",values="OrdCkpt")

# ---- B. 汇总配对统计 ----
out("\n[B] 对 VAST-GWO 的汇总配对统计（150 对）")
out("    McNemar=最终可行性；Cost=双方可行对（有条件，报中位比+rank-biserial）；"
    "有序=检查点有序配对（截尾感知，1..5 达成的检查点，6=未达成）")
out(f"{'基线':<9}{'McNemar p':>10}{'V独/对独':>10}{'Cost n':>7}{'Cost中位比':>10}{'Cost p':>10}{'rb':>7}{'有序中位差':>10}{'有序 p':>9}")
mc=[];cp=[];op=[]
res={}
for b in BASE:
    f1=piv_f["VAST-GWO"].values; f2=piv_f[b].values
    b01=int(((f1==1)&(f2==0)).sum()); c10=int(((f1==0)&(f2==1)).sum())
    pm=stats.binomtest(b01,b01+c10,0.5).pvalue if b01+c10>0 else 1.0
    both=piv_c["VAST-GWO"].notna()&piv_c[b].notna(); nb=int(both.sum())
    if nb>=8:
        r=piv_c.loc[both,"VAST-GWO"]/piv_c.loc[both,b]; medr=float(np.median(r))
        dd=np.log10(piv_c.loc[both,b])-np.log10(piv_c.loc[both,"VAST-GWO"])
        pc=stats.wilcoxon(dd).pvalue if np.any(dd!=0) else 1.0; rb=rank_biserial(dd.values)
    else:
        medr=np.nan;pc=np.nan;rb=np.nan
    do=piv_o[b]-piv_o["VAST-GWO"]      # >0：VAST 更早达到可行
    medo=float(np.median(do)); po=stats.wilcoxon(do).pvalue if np.any(do!=0) else 1.0
    mc.append(pm);cp.append(pc);op.append(po)
    res[b]=dict(mc=pm,b01=b01,c10=c10,nb=nb,medr=medr,pc=pc,rb=rb,medo=medo,po=po)
qmc=holm(mc);qc=holm(cp);qo=holm(op)
for b in BASE:
    r=res[b]
    mc_str=f"{r['b01']}/{r['c10']}"
    out(f"{b:<9}{r['mc']:>10.3g}{mc_str:>10}{r['nb']:>7d}{r['medr']:>10.3f}{r['pc']:>10.3g}"
        f"{r['rb']:>7.2f}{r['medo']:>10.2f}{r['po']:>9.3g}")
out("  Holm 校正后 p:")
out("    McNemar: "+", ".join(f"{b}={p:.3g}" for b,p in zip(BASE,qmc)))
out("    Cost:    "+", ".join(f"{b}={p:.3g}" for b,p in zip(BASE,qc)))
out("    有序(截尾): "+", ".join(f"{b}={p:.3g}" for b,p in zip(BASE,qo)))

# ---- B2. 有条件首次可行（保留，标注条件口径） ----
out("\n[B2] 首次可行 FE（有条件：仅双方成功对；仅作对照，不作为主证据）")
piv_ff=d.pivot_table(index=["Terrain","Run"],columns="Algorithm",values="FirstFeasibleEvaluation")
for b in BASE:
    m=(piv_ff["VAST-GWO"].notna())&(piv_ff[b].notna()); n=int(m.sum())
    if n>=8:
        dd=piv_ff.loc[m,"VAST-GWO"]-piv_ff.loc[m,b]
        p=stats.wilcoxon(dd).pvalue if np.any(dd!=0) else 1.0
        out(f"  VAST vs {b:<8} n={n:<4} 中位差={np.median(dd):>8.0f} FE  p={p:.3g}  VAST更早={ (dd<0).mean()*100:.0f}%")
    else:
        out(f"  VAST vs {b:<8} n={n:<4} 样本不足")

# ---- B3. 分地图配对统计 + 效应量 ----
out("\n[B3] 分地图配对统计（Cost，双方可行对）：中位比 / rank-biserial / Wilcoxon p；McNemar p（可行性）")
for b in BASE:
    out(f"  -- VAST vs {b} --")
    out("     " + "".join(f"{m[:8]:>24}" for m in maps))
    row_r="     "; row_p="     "; row_m="     "
    for m in maps:
        msk=(piv_c.index.get_level_values(0)==m)
        a1=piv_c.loc[msk,"VAST-GWO"]; a2=piv_c.loc[msk,b]; ok=a1.notna()&a2.notna()
        if ok.sum()>=5:
            r=float(np.median(a1[ok]/a2[ok]))
            dd=np.log10(a2[ok])-np.log10(a1[ok])
            p=stats.wilcoxon(dd).pvalue if np.any(dd!=0) else 1.0
            rb=rank_biserial(dd.values)
            row_r+=f"{r:>24.3f}"; row_p+=f"{p:>24.3g}"
            f1=piv_f.loc[msk,"VAST-GWO"].values; f2=piv_f.loc[msk,b].values
            b01=int(((f1==1)&(f2==0)).sum()); c10=int(((f1==0)&(f2==1)).sum())
            pm=stats.binomtest(b01,b01+c10,0.5).pvalue if b01+c10>0 else 1.0
            row_m+=f"{pm:>24.3g}"
        else:
            row_r+=f"{'--':>24}"; row_p+=f"{'--':>24}"; row_m+=f"{'--':>24}"
    out(row_r.replace("     ","   中位比 ",1)); out(row_p.replace("     ","   p值   ",1)); out(row_m.replace("     ","  McNemar",1))

out("\n[说明] ①RMST/KM 与有序配对均使用全部 150 次运行（30k 截尾），无选择偏差；")
out("       ②有条件首次可行统计仅作对照；③2k–20k 为 30k 协议内检查点，非独立短预算。")
io.open(OUT,"w",encoding="utf-8").write("\n".join(lines))
print("\n[report saved]",OUT)
