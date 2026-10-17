#!/usr/bin/env python3
"""SCREEN18 候选来源消融分析（docs/13_ABLATION.md 预注册报告项）。"""
import os, sys, glob
import numpy as np, pandas as pd
from scipy import stats
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass
SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
RNG = np.random.default_rng(20261017)
ARMS = ["A0-GWOonly","A1-G1G2","A2-G1E","A3-V1full","A5-NoArchive"]

def holm(p):
    p=np.asarray(p,float); order=np.argsort(p); adj=np.empty_like(p); cur=0.0
    for i,idx in enumerate(order):
        cur=max(cur,p[idx]*(len(p)-i)); adj[idx]=min(cur,1.0)
    return adj

def boot_ci(x,n=10000):
    x=np.asarray(x,float); m=[np.median(RNG.choice(x,size=len(x),replace=True)) for _ in range(n)]
    return np.percentile(m,[2.5,97.5])

def stats_vs(piv,A,B,metric=None):
    if metric is not None:
        piv=metric
    funcs=sorted(set(piv.index.get_level_values(0)))
    per={}; ps=[]; ds=[]; w=l=0
    for f in funcs:
        ra,rb=piv.loc[f,A].dropna(),piv.loc[f,B].dropna()
        c=ra.index.intersection(rb.index)
        if len(c)==0: continue
        ra,rb=ra.loc[c],rb.loc[c]
        per[int(f)]=float(np.median(ra/rb))
        w+=ra.mean()<rb.mean(); l+=ra.mean()>rb.mean()
        d=np.log10(rb)-np.log10(ra)
        ps.append(stats.wilcoxon(d).pvalue if np.any(d!=0) else 1.0); ds.append(np.median(d))
    q=holm(ps)
    sb=int(sum((qi<0.05) and (di>0) for qi,di in zip(q,ds)))
    sw=int(sum((qi<0.05) and (di<0) for qi,di in zip(q,ds)))
    pooled=(np.log10(piv[B])-np.log10(piv[A])).dropna().values
    lo,hi=boot_ci(pooled)
    return dict(med=float(np.median(list(per.values()))), per=per, w=w, l=l, sb=sb, sw=sw,
                pooled=pooled, ci=(lo,hi), pp=stats.wilcoxon(pooled).pvalue if np.any(pooled!=0) else 1.0)

def line(A,B,r):
    return (f"{A:13s} vs {B:10s}: med {r['med']:.3f}  W-L {r['w']:>2}-{r['l']:<2}  Holm +{r['sb']}/-{r['sw']}  "
            f"medLog10 {np.median(r['pooled']):+.4f} [{r['ci'][0]:+.4f},{r['ci'][1]:+.4f}]  p={r['pp']:.3g}")

def main():
    cands=[d for d in sorted(glob.glob(os.path.join(SQ,"results","ablcore_*")))
           if os.path.exists(os.path.join(d,"runs.csv"))
           and sum(1 for _ in open(os.path.join(d,"runs.csv"),encoding="utf-8",errors="ignore"))>4000]
    if not cands: print("no complete ablcore batch (>=4000 rows) yet"); return
    d=cands[-1]; df=pd.read_csv(os.path.join(d,"runs.csv")); df=df[df.Status=="ok"]
    print(f"batch {os.path.basename(d)}  ok={len(df)}  seeds={sorted(df.Seed.unique())[:3]}..{sorted(df.Seed.unique())[-1]}")
    piv=df.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="FinalError",aggfunc="first")
    pairs=[("A3-V1full","A0-GWOonly"),("A3-V1full","A1-G1G2"),("A3-V1full","A2-G1E"),
           ("A1-G1G2","A0-GWOonly"),("A2-G1E","A0-GWOonly"),("A5-NoArchive","A3-V1full")]
    print("\n=== 最终误差（配对，逐函数 30 种子） ===")
    res={}
    for A,B in pairs:
        r=stats_vs(piv,A,B); res[(A,B)]=r; print(line(A,B,r))
    print("\n=== 20% FE（CheckT20） ===")
    p20=df.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="CheckT20",aggfunc="first")
    for A,B in pairs:
        r=stats_vs(piv,A,B,metric=p20); print(line(A,B,r))
    print("\n=== 逐函数中位比 vs A3-V1full ===")
    print(f"{'F':>3} {'A0':>7} {'A1':>7} {'A2':>7} {'A5':>7}   (>1 = 比完整版差)")
    for f in sorted(set(piv.index.get_level_values(0))):
        row=f"F{f:<2}"
        for A in ["A0-GWOonly","A1-G1G2","A2-G1E","A5-NoArchive"]:
            ra,rb=piv.loc[f,A].dropna(),piv.loc[f,"A3-V1full"].dropna()
            c=ra.index.intersection(rb.index)
            row+=f" {np.median(ra.loc[c]/rb.loc[c]):7.3f}"
        print(row)
    print("\n=== 函数族分解（中位比 vs A3） ===")
    fams={"F4-F10 简单多峰":range(4,11),"F11-F20 混合":range(11,21),"F21-F30 组合":range(21,31)}
    for fam,fs in fams.items():
        s=f"{fam:14s}"
        for A in ["A0-GWOonly","A1-G1G2","A2-G1E","A5-NoArchive"]:
            vals=[]
            for f in fs:
                if f not in set(piv.index.get_level_values(0)): continue
                ra,rb=piv.loc[f,A].dropna(),piv.loc[f,"A3-V1full"].dropna()
                c=ra.index.intersection(rb.index)
                vals.append(np.median(ra.loc[c]/rb.loc[c]))
            s+=f"  {A.split('-')[0]}={np.median(vals):.3f}"
        print(s)
    rank=piv.groupby(level=0).median().rank(axis=1).mean(axis=0).sort_values()
    print("\n平均排名:", {k: round(float(v),2) for k,v in rank.items()})
    print("\n=== 停滞/恢复（均值） ===")
    for A in ARMS:
        e=df[df.Algorithm==A]
        ep=e.NStagEpisodes.sum(); rec=e.NRecoveredWindow.sum()/ep if ep else float('nan')
        print(f"{A:13s} recov {rec:.4f}  longStag {e.LongStagShare.mean():.4f}  novUse {e.NovelUsefulRate.mean():.5f}")
    print("\n=== 来源级真实改善（每次运行均值） ===")
    for A in ARMS:
        e=df[df.Algorithm==A]
        ic=[e[f"ImpCnt{i}"].mean() for i in range(1,5)]
        im=[e[f"ImpMag{i}"].mean() for i in range(1,5)]
        print(f"{A:13s} ImpCnt=[{ic[0]:6.1f} {ic[1]:6.1f} {ic[2]:6.1f} {ic[3]:6.1f}]  " +
              " ".join(f"Mag{i+1}={im[i]:.3g}" for i in range(4)))
    print("\n=== 运行时间 ===")
    for A in ARMS:
        e=df[df.Algorithm==A]
        print(f"{A:13s} mean {e.Seconds.mean():.2f}s  median {e.Seconds.median():.2f}s")

if __name__=="__main__":
    main()
