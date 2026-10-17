#!/usr/bin/env python3
"""最终七算法主表：复用 seeds 3001:3030 既有结果 + final7 新臂（RL-LGWO/DMSGWO）。"""
import os, sys, glob
import numpy as np, pandas as pd
from scipy import stats
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass
SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
RNG = np.random.default_rng(20261017)
MAIN = {"SPSO-2011":"PSO(SPSO-2011)","CLPSO":"CLPSO","GWO":"GWO","IGWO":"IGWO",
        "S-star":"VAST-GWO(V1)","RL-LGWO(paper)":"RL-LGWO","DMSGWO(recon)":"DMSGWO"}

def holm(p):
    p=np.asarray(p,float); order=np.argsort(p); adj=np.empty_like(p); cur=0.0
    for i,idx in enumerate(order):
        cur=max(cur,p[idx]*(len(p)-i)); adj[idx]=min(cur,1.0)
    return adj

def boot_ci(x,n=10000):
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
    sb=int(sum((qi<0.05) and (di>0) for qi,di in zip(q,ds)))
    sw=int(sum((qi<0.05) and (di<0) for qi,di in zip(q,ds)))
    pooled=(np.log10(piv[B])-np.log10(piv[A])).dropna().values
    lo,hi=boot_ci(pooled)
    return dict(med=float(np.median(list(per.values()))), per=per, w=w, l=l, sb=sb, sw=sw,
                pooled=pooled, ci=(lo,hi), pp=stats.wilcoxon(pooled).pvalue if np.any(pooled!=0) else 1.0)

def main():
    base=pd.read_csv(os.path.join(SQ,"results","final_20261016_215309","merged_runs.csv"))
    base=base[base.Status=="ok"]
    cands=[d for d in sorted(glob.glob(os.path.join(SQ,"results","final7_*"))) if os.path.exists(os.path.join(d,"runs.csv"))]
    if not cands: print("no final7 batch yet"); return
    df=pd.read_csv(os.path.join(cands[-1],"runs.csv")); df=df[df.Status=="ok"]
    print(f"final7 batch: {os.path.basename(cands[-1])}  ok={len(df)}/2610")
    both=pd.concat([base,df],ignore_index=True,sort=False)
    piv=both.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="FinalError",aggfunc="first")
    have=[a for a in MAIN if a in piv.columns]
    print("arms present:", have)
    if "RL-LGWO(paper)" in piv.columns and "RL-LGWO(author)" in piv.columns:
        r=stats_vs(piv,"RL-LGWO(author)","RL-LGWO(paper)")
        print(f"\n敏感性: RL-LGWO(author) vs (paper): med {r['med']:.3f}  W-L {r['w']}-{r['l']}  Holm +{r['sb']}/-{r['sw']}  p={r['pp']:.3g}")
    print("\n=== 七算法主表：对 VAST-GWO(V1) 的配对统计（逐函数 30 种子 + Holm） ===")
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
        print(f"{MAIN[a]:>16}  mean {e.Seconds.mean():.2f}s  median {e.Seconds.median():.2f}s")

if __name__=="__main__":
    main()
