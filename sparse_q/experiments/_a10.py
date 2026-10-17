import pandas as pd, numpy as np, glob, sys
from scipy import stats
sys.path.insert(0, r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\experiments")
from gates_sparse_q import ratio_stats
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
b = sorted(glob.glob(root + r"\results\sq10_*"))[-1]
df = pd.read_csv(b + r"\runs.csv"); df=df[df.Status=="ok"]
piv = df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
ref = "P4-ref"
print("=== SCREEN10 (Phase-4 enhancements, 10 seeds) vs ref ===")
for a in ["P4-boost3","P4-steer25","P4-steer50","P4-subset20","P4-both"]:
    r,w,per = ratio_stats(piv,a,ref)
    d = np.log10(piv[ref])-np.log10(piv[a]); p = stats.wilcoxon(d).pvalue if np.any(d!=0) else 1
    gate = (r <= 0.98) or (w[0] >= 6 and r <= 1.00)
    print(f"{a:12s} ratio {r:.3f} W/T/L {w[0]}/{w[1]}/{w[2]} p={p:.3g} gate={'PASS' if gate else 'FAIL'}")
    print("   per-fn:", {int(k): round(v,3) for k,v in per.items()})
for a in ["P4-ref","P4-boost3","P4-steer25","P4-subset20","P4-both"]:
    e = df[df.Algorithm==a]
    ep=e["NStagEpisodes"].sum(); rec=e["NRecoveredWindow"].sum()/ep if ep else np.nan
    print(f"{a:12s} sec {e.Seconds.mean():.3f} recov {rec:.4f} longStag {e.LongStagShare.mean():.4f} novUse {e.NovelUsefulRate.mean():.4f} Q4 {e.ImprovRateQ4.mean():.4f}")
# cross-batch audit P4-ref vs sq6 T-S1-p38-K10
b6 = sorted(glob.glob(root + r"\results\sq6_*"))[-1]
d6 = pd.read_csv(b6 + r"\runs.csv")
A = df[df.Algorithm=="P4-ref"][["FunctionID","Seed","FinalError"]]
B = d6[d6.Algorithm=="T-S1-p38-K10"][["FunctionID","Seed","FinalError"]]
m = A.merge(B,on=["FunctionID","Seed"],suffixes=("_a","_b"))
rel = np.abs(m.FinalError_a-m.FinalError_b)/np.maximum(1,np.abs(m.FinalError_b))
print(f"\nP4-ref vs sq6 K10: overlap {len(m)} bitwise={rel.max()<1e-12} maxrel={rel.max():.2e}")
