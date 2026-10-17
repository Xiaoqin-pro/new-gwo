import pandas as pd, numpy as np, glob, sys
from scipy import stats
sys.path.insert(0, r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\experiments")
from gates_sparse_q import ratio_stats
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
b6 = sorted(glob.glob(root + r"\results\sq6_*"))[-1]
b5 = sorted(glob.glob(root + r"\results\sq5_*"))[-1]
df6 = pd.read_csv(b6 + r"\runs.csv"); df6=df6[df6.Status=="ok"]
df5 = pd.read_csv(b5 + r"\runs.csv"); df5=df5[df5.Status=="ok"]
df = pd.concat([df6, df5[~df5.Algorithm.isin(df6.Algorithm.unique())]], ignore_index=True)
piv = df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
S1 = "T-S1-p38"
print("=== SQ6 tuning (10 seeds), ref = T-S1-p38 ===")
rank = {}
for a in ["T-S1-p25","T-S1-p38-K25","T-S1-p38-K10","T-S1-E50","T-Q-v2","S3p-q25","S4p-random","S5p-q","S1-pool38"]:
    if a not in piv.columns: continue
    r,w,per = ratio_stats(piv, a, S1)
    d = np.log10(piv[S1]) - np.log10(piv[a])
    p = stats.wilcoxon(d).pvalue if np.any(d!=0) else 1.0
    e = df[df.Algorithm==a]
    ep=e["NStagEpisodes"].sum(); rec=e["NRecoveredWindow"].sum()/ep if ep else np.nan
    rank[a]=r
    print(f"{a:14s} ratio {r:.3f}  W/T/L {w[0]}/{w[1]}/{w[2]}  p={p:.3g}  sec {e.Seconds.mean():.3f} recov {rec:.4f} longStag {e.LongStagShare.mean():.4f}")
    print("   per-fn:", {int(k): round(v,3) for k,v in per.items()})
# cross-batch audit for T-S1-p38 vs sq5 S1-pool38 (bitwise?)
A = df6[df6.Algorithm=="T-S1-p38"][["FunctionID","Seed","FinalError"]]
B = df5[df5.Algorithm=="S1-pool38"][["FunctionID","Seed","FinalError"]]
m = A.merge(B, on=["FunctionID","Seed"], suffixes=("_a","_b"))
rel = np.abs(m.FinalError_a-m.FinalError_b)/np.maximum(1,np.abs(m.FinalError_b))
print(f"\nT-S1-p38 vs sq5 S1-pool38: overlap {len(m)}, bitwise={rel.max()<1e-12}, max rel {rel.max():.2e}")
for c in ["CheckT10","CheckT20"]:
    cp = df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values=c, aggfunc="first")
    for a in ["T-S1-p38-K25","T-S1-p38-K10","T-S1-p25","T-S1-E50"]:
        r,w,_ = ratio_stats(cp,a,S1,offset_by_fid=True)
        print(f"{c} {a} vs S1: {r:.3f} ({w[0]}/{w[2]})")
