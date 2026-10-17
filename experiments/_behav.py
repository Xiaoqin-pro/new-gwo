import pandas as pd, numpy as np
from scipy import stats
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
df = pd.read_csv(root + r"\results\d100_20261016_153544\merged_runs.csv")
df = df[df.Status=="ok"]
piv = df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
A, B = "ANGWO-final", "GWO"
def holm(ps):
    order=np.argsort(ps); adj=np.empty(len(ps)); cur=0
    for i,idx in enumerate(order):
        cur=max(cur, ps[idx]*(len(ps)-i)); adj[idx]=min(cur,1)
    return adj
funcs29 = sorted(df[df.Algorithm.isin([A,B])].FunctionID.unique())
w=l=0; ps=[]; ds=[]; ratios=[]
for f in funcs29:
    ra=piv.loc[f,A].dropna(); rb=piv.loc[f,B].dropna()
    c=ra.index.intersection(rb.index)
    if not len(c): continue
    ratios.append(np.median(ra.loc[c]/rb.loc[c]))
    if ra.loc[c].mean()<rb.loc[c].mean(): w+=1
    else: l+=1
    d=np.log10(rb.loc[c])-np.log10(ra.loc[c]); ds.append(np.median(d))
    ps.append(stats.wilcoxon(d).pvalue if np.any(d!=0) else 1.0)
adj=holm(ps)
print(f"D100 ANGWO-final vs GWO (29 fn, 10 seeds): wins {w}/{l}, median ratio {np.median(ratios):.3f}, Holm sig better {sum((q<0.05)and(d>0) for q,d in zip(adj,ds))}, worse {sum((q<0.05)and(d<0) for q,d in zip(adj,ds))}")
for B2 in ["IGWO","RASE-GWO"]:
    sub = sorted(df[(df.Algorithm==B2)].FunctionID.unique())
    rr=[]; ww=ll=0
    for f in sub:
        ra=piv.loc[f,A].dropna(); rb=piv.loc[f,B2].dropna(); c=ra.index.intersection(rb.index)
        if not len(c): continue
        rr.append(np.median(ra.loc[c]/rb.loc[c]))
        if ra.loc[c].mean()<rb.loc[c].mean(): ww+=1
        else: ll+=1
    print(f"D100 {A} vs {B2} ({len(sub)} fn subset): median ratio {np.median(rr):.3f}, wins {ww}/{ll}")
sec = df.groupby("Algorithm").Seconds.mean()
print("runtime: ANGWO-final %.2fs vs GWO %.2fs (ratio %.2f)" % (sec[A], sec[B], sec[A]/sec[B]))
