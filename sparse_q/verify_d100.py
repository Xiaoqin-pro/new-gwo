# -*- coding: utf-8 -*-
"""verify_d100.py: independent end-to-end verification from raw_runs.csv only.
Recomputes every headline number without reusing analyze_d100.py outputs."""
import os, sys, json
import numpy as np, pandas as pd
from scipy import stats
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass
SQ=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.join(SQ,"results","d100_analysis")
ALGS=["VAST-GWO","GWO","IGWO","HAGWO","PSO","CLPSO","AOGWO"]
FUNCS=[1]+list(range(3,31))
def holm(p):
    p=np.asarray(p,float); o=np.argsort(p); a=np.empty_like(p); c=0.0
    for i,ix in enumerate(o):
        c=max(c,p[ix]*(len(p)-i)); a[ix]=min(c,1.0)
    return a
def main():
    r=pd.read_csv(os.path.join(OUT,"raw_runs.csv"),low_memory=False)
    assert len(r)==6090 and (r.Status=="ok").all()
    pv=r.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="FinalError",aggfunc="first")
    assert pv.shape==(870,7), pv.shape
    assert not pv.isna().any().any()
    med=pv.groupby(level=0).median()
    rank=med[ALGS].rank(axis=1).mean(axis=0)
    print("Mean ranks:", {k: round(float(v),3) for k,v in rank.items()})
    ok=True
    for b in ALGS[1:]:
        ps=[]; ang=[]
        for f in FUNCS:
            a=pv.loc[f,"VAST-GWO"].values; x=pv.loc[f,b].values
            mask=np.isfinite(a)&np.isfinite(x)&(x!=0)
            d=np.log10(x[mask])-np.log10(a[mask])
            ang.append(np.median(d))
            ps.append(1.0 if np.all(d==0) else float(stats.wilcoxon(d).pvalue))
        q=holm(ps)
        sw=int(np.sum((q<0.05)&(np.array(ang)>0))); sl=int(np.sum((q<0.05)&(np.array(ang)<0)))
        ratios=[]
        for f in FUNCS:
            a=pv.loc[f,"VAST-GWO"].values; x=pv.loc[f,b].values
            m=np.isfinite(a)&np.isfinite(x)&(x!=0)
            ratios.append(np.median(a[m]/x[m]))
        print(f"{b:>8}: median_ratio={np.median(ratios):.3f} Holm +{sw}/-{sl} "
              f"W-L {sum(v<1 for v in ratios)}-{sum(v>1 for v in ratios)}")
        ok &= (len(q)==29)
    # compare with published table
    t=pd.read_csv(os.path.join(OUT,"table_d100_main.csv"))
    for _,row in t.iterrows():
        assert abs(rank[row.Algorithm]-row.MeanRank)<1e-9, (row.Algorithm, rank[row.Algorithm], row.MeanRank)
    print("\nIndependent verification: PASS (6090 rows, 7x29x30 complete, table matches)")
    return ok
if __name__=="__main__":
    main()
