# -*- coding: utf-8 -*-
"""UAV 应用正式档图（v2，相对路径；与 analyze_uav_formal.py 同口径）：
  1) feasibility_curve.png  检查点累计可行率（KM 口径，含全部运行）
  2) rmst_bar.png           RMST(30k 截尾) 带 bootstrap 95% CI（越小越好）
  3) final_cost_box.png     可行解 Cost 箱线（= CkptBestFeasCost_5，已核对逐位一致）
  4) first_feasible_ecdf.png 有条件 ECDF（仅成功运行，作补充图，标题标注 conditional）
"""
import os, numpy as np, pandas as pd
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE=os.path.dirname(os.path.abspath(__file__)); SQ=os.path.dirname(HERE)
d=pd.read_csv(os.path.join(SQ,"results","uav_formal_N50_30k","raw_runs.csv"), low_memory=False)
figdir=os.path.join(SQ,"results","uav_formal_N50_30k","figures"); os.makedirs(figdir,exist_ok=True)
ALGS=["VAST-GWO","HAGWO","PSO","IGWO","GWO","CLPSO"]; CK=[2000,5000,10000,20000,30000]; TAU=30000
colors={"VAST-GWO":"#d62728","HAGWO":"#1f77b4","PSO":"#2ca02c","IGWO":"#ff7f0e","GWO":"#9467bd","CLPSO":"#8c564b"}
marks={"VAST-GWO":"o","HAGWO":"s","PSO":"^","IGWO":"v","GWO":"D","CLPSO":"x"}
plt.rcParams.update({"font.size":10,"axes.grid":True,"grid.alpha":0.3})

plt.figure(figsize=(6.2,4.2))
for a in ALGS:
    e=d[d.Algorithm==a]
    y=[e[f"CkptHadFeasible_{i+1}"].mean()*100 for i in range(5)]
    plt.plot(CK,y,marker=marks[a],color=colors[a],lw=2,ms=6,label=a)
plt.xscale("log"); plt.xticks(CK,["2k","5k","10k","20k","30k"])
plt.xlabel("Real fitness evaluations"); plt.ylabel("Cumulative feasible runs (%)")
plt.ylim(-2,102); plt.legend(frameon=False,fontsize=9); plt.tight_layout()
plt.savefig(os.path.join(figdir,"feasibility_curve.png"),dpi=220); plt.close()

def rmst_ci(ff,feas,n=2000,seed=7):
    rng=np.random.default_rng(seed); N=len(ff); vals=[]
    for _ in range(n):
        i=rng.integers(0,N,N)
        t=np.where(feas[i]==1,np.minimum(ff[i],TAU),TAU); vals.append(t.mean())
    return float(np.mean(np.where(feas==1,np.minimum(ff,TAU),TAU))),np.percentile(vals,[2.5,97.5])
plt.figure(figsize=(6.2,4.2))
mean_ci=[rmst_ci(d[d.Algorithm==a].FirstFeasibleEvaluation.values.astype(float),
                 d[d.Algorithm==a].Feasible.values.astype(int)) for a in ALGS]
ypos=np.arange(len(ALGS))[::-1]
plt.barh(ypos,[m for m,_ in mean_ci],xerr=[[m-lo for m,(lo,hi) in mean_ci],[hi-m for m,(lo,hi) in mean_ci]],
         color=[colors[a] for a in ALGS],alpha=0.65,capsize=3)
for y,(m,(lo,hi)),a in zip(ypos,mean_ci,ALGS):
    plt.text(m+150,y,f"{m:.0f} [{lo:.0f},{hi:.0f}]",va="center",fontsize=8)
plt.yticks(ypos,ALGS); plt.xlabel("RMST of first-feasible FE (30k censoring; lower is better)")
plt.tight_layout(); plt.savefig(os.path.join(figdir,"rmst_bar.png"),dpi=220); plt.close()

plt.figure(figsize=(6.2,4.2))
data=[d[(d.Algorithm==a)&(d.Feasible==1)]["CkptBestFeasCost_5"].values for a in ALGS]
bp=plt.boxplot(data,tick_labels=ALGS,showfliers=False,patch_artist=True,widths=0.6)
for patch,a in zip(bp["boxes"],ALGS): patch.set_facecolor(colors[a]); patch.set_alpha(0.35)
ymax=max(np.max(c) for c in data)
for i,a in enumerate(ALGS):
    nf=int((d[d.Algorithm==a].Feasible==0).sum())
    plt.text(i+1,ymax*1.02,f"censored: {nf}/150",ha="center",va="bottom",fontsize=8,color="#444")
plt.ylim(0,ymax*1.12)
plt.ylabel("Final penalized cost (feasible runs; = CkptBestFeasCost_5)"); plt.tight_layout()
plt.savefig(os.path.join(figdir,"final_cost_box.png"),dpi=220); plt.close()

plt.figure(figsize=(6.2,4.2))
for a in ALGS:
    ff=np.sort(d[(d.Algorithm==a)&(d.Feasible==1)]["FirstFeasibleEvaluation"].values)
    if len(ff)==0: continue
    plt.step(ff,np.arange(1,len(ff)+1)/len(ff)*100,where="post",color=colors[a],lw=2,label=f"{a} (n={len(ff)})")
plt.xscale("log"); plt.xticks(CK,["2k","5k","10k","20k","30k"])
plt.xlabel("First-feasible real FE"); plt.ylabel("ECDF, successful runs only (%)")
plt.title("Conditional on successful runs (supplement; primary evidence = RMST & cumulative feasibility)",fontsize=9)
plt.legend(frameon=False,fontsize=8); plt.tight_layout()
plt.savefig(os.path.join(figdir,"first_feasible_ecdf.png"),dpi=220); plt.close()
print("figures regenerated:",sorted(os.listdir(figdir)))
