#!/usr/bin/env python3
"""SCREEN14 方向归因审计的门槛判定（docs/12_SDIR_AUDIT.md 预注册）。"""
import os, sys, glob
import numpy as np, pandas as pd
from scipy import stats
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass
SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"

def holm(p):
    p=np.asarray(p,float); order=np.argsort(p); adj=np.empty_like(p); cur=0.0
    for i,idx in enumerate(order):
        cur=max(cur,p[idx]*(len(p)-i)); adj[idx]=min(cur,1.0)
    return adj

def stats_vs(piv,A,B):
    funcs=sorted(set(piv.index.get_level_values(0)))
    w=l=0; rs=[]; ps=[]; ds=[]; per={}
    for f in funcs:
        ra,rb=piv.loc[f,A].dropna(),piv.loc[f,B].dropna()
        c=ra.index.intersection(rb.index)
        if len(c)==0: continue
        ra,rb=ra.loc[c],rb.loc[c]
        rr=float(np.median(ra/rb)); rs.append(rr); per[int(f)]=rr
        w+=ra.mean()<rb.mean(); l+=ra.mean()>rb.mean()
        d=np.log10(rb)-np.log10(ra)
        ps.append(stats.wilcoxon(d).pvalue if np.any(d!=0) else 1.0); ds.append(np.median(d))
    q=holm(ps)
    sb=sum((qi<0.05) and (di>0) for qi,di in zip(q,ds))
    sw=sum((qi<0.05) and (di<0) for qi,di in zip(q,ds))
    return float(np.median(rs)), w, l, sb, sw, per

def gate(med, w, l, n):
    ok_ratio = med <= 0.98
    ok_wl = w >= int(np.ceil(6/8*n))
    return ok_ratio, ok_wl, (ok_ratio or ok_wl)

def main():
    cands=[]
    for d in sorted(glob.glob(os.path.join(SQ,"results","sq14_*"))):
        try:
            df=pd.read_csv(os.path.join(d,"runs.csv"))
            if df.Seed.nunique()==10 and len(df)>=400: cands.append((d,df))
        except Exception: pass
    if not cands:
        print("no complete sq14 batch (10 seeds) yet"); return
    d,df=cands[-1]; df=df[df.Status=="ok"]
    print("batch:", os.path.basename(d), "| ok runs:", len(df))
    piv=df.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="FinalError",aggfunc="first")
    arms=["S14-ref","S14-mix","S14-g1","S14-g2e","S14-rand"]
    print(f"\n{'pair':>18} {'medRatio':>9} {'W-L':>6} {'Holm(+/-)':>10}   per-fn ratios")
    res={}
    for A in ["S14-mix","S14-g1","S14-g2e","S14-rand"]:
        med,w,l,sb,sw,per=stats_vs(piv,A,"S14-ref")
        res[A]=dict(med=med,w=w,l=l,sb=sb,sw=sw,per=per)
        print(f"{A+' vs ref':>18} {med:9.3f} {w:>3}-{l:<2} {sb:>5}/{sw:<4}   { {k:round(v,2) for k,v in per.items()} }")
    print()
    for A in ["S14-g1","S14-g2e","S14-rand"]:
        med,w,l,sb,sw,per=stats_vs(piv,A,"S14-mix")
        res[A+"_vmix"]=dict(med=med,w=w,l=l)
        print(f"{A+' vs mix':>18} {med:9.3f} {w:>3}-{l:<2} {sb:>5}/{sw:<4}")
    print()
    n=8
    print("=== gates (docs/12) ===")
    best=None
    for A in ["S14-mix","S14-g1","S14-g2e"]:
        r=res[A]; okr,okw,ok=gate(r["med"],r["w"],r["l"],n)
        print(f"G14a {A:8s} vs ref: med={r['med']:.3f} (<=0.98: {okr}), W-L={r['w']}-{r['l']} (>=6: {okw}) -> {'PASS' if ok else 'FAIL'}")
        if ok and best is None: best=A
    if best:
        r=res[best]
        print(f"best arm = {best}")
        r2=res["S14-rand"] if best!="S14-rand" else None
        # best vs rand
        if best=="S14-mix": med,w,l=res["S14-rand"]["med"],res["S14-rand"]["w"],res["S14-rand"]["l"]; varm="S14-rand vs ref"
        else:
            med,w,l=res[best+"_vmix"]["med"],res[best+"_vmix"]["w"],res[best+"_vmix"]["l"]
        okr,okw,ok=gate(med,w,l,n)
        print(f"G14b {best} vs S14-rand: med={med:.3f} (<=0.98: {okr}), W-L={w}-{l} (>=6: {okw}) -> {'PASS' if ok else 'FAIL'}")
        if best in ("S14-g1",):
            r3=res["S14-g1_vmix"]; okr3,okw3,ok3=gate(r3["med"],r3["w"],r3["l"],n)
            print(f"G14c g1 vs mix: med={r3['med']:.3f} W-L={r3['w']}-{r3['l']} -> {'g1' if ok3 else 'mix'} for E2")
        else:
            print("G14c: best is mix -> E2 uses mix")
    else:
        print("no arm passed G14a -> E2 不启动（steer50 在 dev 上未复现增益）")

if __name__=="__main__":
    main()
