import pandas as pd, numpy as np, glob, sys
from scipy import stats
sys.path.insert(0, r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\experiments")
from gates_sparse_q import ratio_stats
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
b = sorted(glob.glob(root + r"\results\sq2_*"))[-1]
df = pd.read_csv(b + r"\runs.csv"); df=df[df.Status=="ok"]
piv = df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
for c in ["CheckT10","CheckT20","CheckT50"]:
    pass
cp = {c: df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values=c, aggfunc="first") for c in ["CheckT10","CheckT20","CheckT50"]}
print("=== SCREEN2: quota scan on corrected pool ===")
for a in ["W-q25","W-q50","W-q75","S-q25-p38"]:
    r,w,per = ratio_stats(piv, a, "S1-pool38")
    d = np.log10(piv["S1-pool38"]) - np.log10(piv[a])
    p = stats.wilcoxon(d).pvalue if np.any(d!=0) else 1.0
    print(f"{a:10s} vs S1-pool38: ratio {r:.3f}, W/T/L {w[0]}/{w[1]}/{w[2]}, pooled p={p:.3g}")
    print("   per-fn:", {int(k): round(v,3) for k,v in per.items()})
for a in ["S1-pool38","W-q25","W-q50","W-q75","S-q25-p38"]:
    e = df[df.Algorithm==a]
    ep = e["NStagEpisodes"].sum(); rec = e["NRecoveredWindow"].sum()/ep if ep else np.nan
    print(f"{a:10s} sec {e.Seconds.mean():.3f} recov {rec:.4f} longStag {e.LongStagShare.mean():.4f} novUseful {e.NovelUsefulRate.mean():.4f} Eshare~{e.QuotaAct1Pct.mean() if a.startswith('W') else float('nan'):.2f}")
r20,w20,per20 = ratio_stats(cp["CheckT20"], "W-q25", "S1-pool38", offset_by_fid=True)
print(f"\nW-q25 vs S1 @FE20k: ratio {r20:.3f}, W/T/L {w20}")
