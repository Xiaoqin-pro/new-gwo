import pandas as pd, numpy as np, glob, sys
from scipy import stats
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
b = sorted(glob.glob(root + r"\results\freshv2_*"))[-1]
df = pd.read_csv(b + r"\runs.csv"); 
ok = df[df.Status=="ok"]
def holm(p):
    p=np.asarray(p,float); o=np.argsort(p); a=np.empty_like(p); c=0.0
    for i,ix in enumerate(o):
        c=max(c,p[ix]*(len(p)-i)); a[ix]=min(c,1.0)
    return a
piv = ok.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
print("=== freshv2 (seeds 3031:3060), arms vs V1-frozen ===")
for A in ["V2-steer25","V2-steer50","V2-subset20","V2-K5"]:
    w=l=0; rs=[]; ps=[]; ds=[]; per={}
    for f in sorted(ok.FunctionID.unique()):
        ra, rb = piv.loc[f,A].dropna(), piv.loc[f,"V1-frozen"].dropna()
        c = ra.index.intersection(rb.index)
        if len(c)==0: continue
        ra, rb = ra.loc[c], rb.loc[c]
        rr = np.median(ra/rb); rs.append(rr); per[int(f)]=rr
        w += ra.mean()<rb.mean(); l += ra.mean()>rb.mean()
        d = np.log10(rb)-np.log10(ra); ps.append(stats.wilcoxon(d).pvalue if np.any(d!=0) else 1.0); ds.append(np.median(d))
    q=holm(ps); sb=sum((x<0.05)and(y>0) for x,y in zip(q,ds)); sw=sum((x<0.05)and(y<0) for x,y in zip(q,ds))
    print(f"{A:12s} vs V1: ratio {np.median(rs):.3f}  W-L {w}-{l}  Holm +{sb}/-{sw}")
    print("   wins:", [f for f,r in per.items() if r<0.95], " losses:", [f for f,r in per.items() if r>1.05])
for a in ["V1-frozen","V2-steer25","V2-steer50","V2-subset20","V2-K5"]:
    e = ok[ok.Algorithm==a]
    ep=e["NStagEpisodes"].sum(); rec=e["NRecoveredWindow"].sum()/ep if ep else np.nan
    print(f"{a:12s} recov {rec:.4f} longStag {e.LongStagShare.mean():.4f} novUse {e.NovelUsefulRate.mean():.5f} sec {e.Seconds.mean():.2f}")
