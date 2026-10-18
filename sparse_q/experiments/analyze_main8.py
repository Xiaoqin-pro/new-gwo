#!/usr/bin/env python3
"""主对比表（8 算法）：VAST-GWO + GWO/IGWO/PSO/CLPSO + 新增 HAGWO/AOGWO/EDGWO。
RL-LGWO/DMSGWO 按用户决定移出对比集（归档保留，不参与分析）。"""
import os, sys, glob
import numpy as np, pandas as pd
from scipy import stats
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass
SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
RNG = np.random.default_rng(20261017)
MAIN = {"PSO(classic)":"PSO","CLPSO":"CLPSO","GWO":"GWO","IGWO":"IGWO",
        "S-star":"VAST-GWO(V1)","HAGWO":"HAGWO(2026)","AOGWO":"AOGWO(2026)"}

def holm(p):
    p=np.asarray(p,float); o=np.argsort(p); adj=np.empty_like(p); cur=0.0
    for i,ix in enumerate(o): cur=max(cur,p[ix]*(len(p)-i)); adj[ix]=min(cur,1.0)
    return adj

def boot_ci(x,n=8000):
    x=np.asarray(x,float); m=[np.median(RNG.choice(x,size=len(x),replace=True)) for _ in range(n)]
    return np.percentile(m,[2.5,97.5])

def stats_vs(piv,A,B):
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
    sb=int(sum((x<0.05 and d>0) for x,d in zip(q,ds))); sw=int(sum((x<0.05 and d<0) for x,d in zip(q,ds)))
    pooled=(np.log10(piv[B])-np.log10(piv[A])).dropna().values
    lo,hi=boot_ci(pooled)
    return dict(med=float(np.median(list(per.values()))), per=per, w=w, l=l, sb=sb, sw=sw,
                pooled=pooled, ci=(lo,hi), pp=stats.wilcoxon(pooled).pvalue if np.any(pooled!=0) else 1.0)

def main():
    base=pd.read_csv(os.path.join(SQ,"results","final_20261016_215309","merged_runs.csv"), low_memory=False)
    base=base[base.Status=="ok"]
    parts=[]
    for pat,n in [("new3_*",2610),("pso_*",870),("clpso_*",870)]:
        cands=[d for d in sorted(glob.glob(os.path.join(SQ,"results",pat))) if os.path.exists(os.path.join(d,"runs.csv"))]
        if cands:
            dd=pd.read_csv(os.path.join(cands[-1],"runs.csv")); dd=dd[dd.Status=="ok"]
            print(f"{pat}: {os.path.basename(cands[-1])} ok={len(dd)}/{n}")
            parts.append(dd)
    if not parts: print("no new batches yet"); return
    df=pd.concat(parts,ignore_index=True,sort=False)
    df=df[df.Algorithm!="EDGWO"]
    both=pd.concat([base,df],ignore_index=True,sort=False)
    piv=both.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="FinalError",aggfunc="first")
    have=[a for a in MAIN if a in piv.columns]
    print("arms present:", have)
    print("\n=== 八算法主表：对 VAST-GWO(V1) 的配对统计（逐函数 30 种子 + Holm）===")
    print(f"{'baseline':>16} {'medRatio':>9} {'W-L':>7} {'Holm(+/-)':>10} {'medLog10 [CI]':>26} {'pooled p':>9}")
    for a in have:
        if a=="S-star": continue
        r=stats_vs(piv,"S-star",a)
        print(f"{MAIN[a]:>16} {r['med']:9.3f} {r['w']:>2}-{r['l']:<3} {r['sb']:>4}/{r['sw']:<4} "
              f"{np.median(r['pooled']):+.4f} [{r['ci'][0]:+.4f},{r['ci'][1]:+.4f}]  {r['pp']:9.3g}")
    rank=piv[have].groupby(level=0).median().rank(axis=1).mean(axis=0).sort_values()
    print("\n平均排名:", {MAIN[k]: round(float(v),2) for k,v in rank.items()})
    for a in have:
        e=both[both.Algorithm==a]
        print(f"{MAIN[a]:>16} mean {e.Seconds.mean():.2f}s median {e.Seconds.median():.2f}s rounds {e.Rounds.mean() if 'Rounds' in e else float('nan'):.0f}")

if __name__=="__main__":
    main()
