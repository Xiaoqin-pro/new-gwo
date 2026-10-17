import pandas as pd, numpy as np, glob, sys
from scipy import stats
sys.path.insert(0, r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\experiments")
from gates_sparse_q import ratio_stats
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
b = sorted(glob.glob(root + r"\results\sq11_*"))[-1]
df = pd.read_csv(b + r"\runs.csv"); df=df[df.Status=="ok"]
piv = df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
ref = "P4-ref"
print("=== SCREEN11: combination (10 seeds) ===")
for a in ["P4-steer25","P4-subset20","P4-s25g20"]:
    r,w,per = ratio_stats(piv,a,ref)
    d = np.log10(piv[ref])-np.log10(piv[a]); p = stats.wilcoxon(d).pvalue if np.any(d!=0) else 1
    gate = (r <= 0.98) or (w[0] >= 6 and r <= 1.00)
    print(f"{a:12s} ratio {r:.3f} W/T/L {w[0]}/{w[1]}/{w[2]} p={p:.3g} gate={'PASS' if gate else 'FAIL'}")
    print("   per-fn:", {int(k): round(v,3) for k,v in per.items()})
for a in ["P4-ref","P4-steer25","P4-subset20","P4-s25g20"]:
    e = df[df.Algorithm==a]
    ep=e["NStagEpisodes"].sum(); rec=e["NRecoveredWindow"].sum()/ep if ep else np.nan
    print(f"{a:12s} sec {e.Seconds.mean():.3f} recov {rec:.4f} longStag {e.LongStagShare.mean():.4f} novUse {e.NovelUsefulRate.mean():.4f} Q4 {e.ImprovRateQ4.mean():.4f}")
# cross-batch audit
b10 = sorted(glob.glob(root + r"\results\sq10_*"))[-1]
d10 = pd.read_csv(b10 + r"\runs.csv")
for lab in ["P4-ref","P4-steer25","P4-subset20"]:
    A = df[df.Algorithm==lab][["FunctionID","Seed","FinalError"]]
    B = d10[d10.Algorithm==lab][["FunctionID","Seed","FinalError"]]
    m = A.merge(B,on=["FunctionID","Seed"],suffixes=("_a","_b"))
    rel = np.abs(m.FinalError_a-m.FinalError_b)/np.maximum(1,np.abs(m.FinalError_b))
    print(f"audit {lab}: overlap {len(m)} bitwise={rel.max()<1e-12}")
