#!/usr/bin/env python3
"""E2: steer50 变体在正式种子 3001:3030 的验证（与 17 基线主表同种子）。"""
import os, sys, glob
import numpy as np, pandas as pd
from scipy import stats
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass
SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
ARM = sys.argv[1] if len(sys.argv)>1 else None

def holm(p):
    p=np.asarray(p,float); order=np.argsort(p); adj=np.empty_like(p); cur=0.0
    for i,idx in enumerate(order):
        cur=max(cur,p[idx]*(len(p)-i)); adj[idx]=min(cur,1.0)
    return adj

def stats_vs(piv,A,B):
    funcs=sorted(set(piv.index.get_level_values(0)))
    w=l=0; rs=[]; ps=[]; ds=[]; per={}
    for f in funcs:
        if A not in piv.columns or B not in piv.columns: continue
        ra,rb=piv.loc[f,A].dropna(),piv.loc[f,B].dropna()
        c=ra.index.intersection(rb.index)
        if len(c)==0: continue
        ra,rb=ra.loc[c],rb.loc[c]
        per[int(f)]=float(np.median(ra/rb)); rs.append(per[int(f)])
        w+=ra.mean()<rb.mean(); l+=ra.mean()>rb.mean()
        d=np.log10(rb)-np.log10(ra)
        ps.append(stats.wilcoxon(d).pvalue if np.any(d!=0) else 1.0); ds.append(np.median(d))
    q=holm(ps)
    sb=sum((qi<0.05) and (di>0) for qi,di in zip(q,ds))
    sw=sum((qi<0.05) and (di<0) for qi,di in zip(q,ds))
    return float(np.median(rs)), w, l, sb, sw, per

def main():
    cands=[d for d in sorted(glob.glob(os.path.join(SQ,"results","st50f_*")))
           if os.path.exists(os.path.join(d,"runs.csv"))]
    if not cands: print("no st50f batch yet"); return
    d=cands[-1]; df=pd.read_csv(os.path.join(d,"runs.csv")); df=df[df.Status=="ok"]
    arm=ARM if ARM else sorted(df.Algorithm.unique())[0]
    m=pd.read_csv(os.path.join(SQ,"results","final_20261016_215309","merged_runs.csv"))
    m=m[m.Status=="ok"]
    both=pd.concat([m,df[df.Algorithm==arm]],ignore_index=True,sort=False)
    piv=both.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="FinalError",aggfunc="first")
    print(f"batch {os.path.basename(d)} arm={arm}; merged arms={both.Algorithm.nunique()}; pairs ok")
    d0=(np.log10(piv["IGWO"])-np.log10(piv[arm])).dropna()
    print(f"\npooled vs IGWO: median log10 gain {np.median(d0):+.4f}  p={stats.wilcoxon(d0).pvalue:.3g}  raw W-L {int((d0>0).sum())}-{int((d0<0).sum())}")
    print(f"\n{'baseline':>12} {'medRatio':>9} {'W-L':>7} {'Holm(+/-)':>10}")
    for B in ["IGWO","S-star","GWO","RASE-GWO","SAQ-CSO","HCLPSO","HIDMS-PSO"]:
        if B not in piv.columns: continue
        med,w,l,sb,sw,per=stats_vs(piv,arm,B)
        print(f"{B:>12} {med:9.3f} {w:>4}-{l:<3} {sb:>5}/{sw:<4}")
    rank=piv.groupby(level=0).median().rank(axis=1).mean(axis=0).sort_values()
    print("\nmean ranks:", {k: round(float(v),2) for k,v in rank.items()})
    print("\ncheckpoints vs S-star (formal seeds replication):")
    for ck in ["CheckT10","CheckT20","CheckT50","CheckT80","CheckT100"]:
        if ck not in both.columns: continue
        p2=both.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values=ck,aggfunc="first")
        dd=(np.log10(p2["S-star"])-np.log10(p2[arm])).dropna()
        print(f"  {ck}: medRatio {np.median(p2[arm]/p2['S-star']):.3f}  W-L {int((dd>0).sum())}-{int((dd<0).sum())}  p={stats.wilcoxon(dd).pvalue:.3g}")
    med,w,l,sb,sw,per=stats_vs(piv,arm,"IGWO")
    print("\nvs IGWO sig wins:", sorted([f for f,v in per.items()]+[]))
    med2,w2,l2,sb2,sw2,per2=stats_vs(piv,arm,"S-star")
    print("vs S-star losses>1.05:", {f:round(v,2) for f,v in per2.items() if v>1.05})

if __name__=="__main__":
    main()
