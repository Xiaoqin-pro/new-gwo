import pandas as pd, numpy as np, glob, sys
from scipy import stats
sys.path.insert(0, r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\experiments")
from gates_sparse_q import ratio_stats
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
b7 = sorted(glob.glob(root + r"\results\sq7_*"))[-1]
b8 = sorted(glob.glob(root + r"\results\sq8_*"))[-1]
d7 = pd.read_csv(b7 + r"\runs.csv"); d7=d7[d7.Status=="ok"]
d8 = pd.read_csv(b8 + r"\runs.csv"); d8=d8[d8.Status=="ok"]
print("=== SQ7: Q-v3 (prior init, fast eps) on dev 3001:3010 ===")
p7 = d7.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
for A,B in [("Q-v3-prior","S3p-q25"),("Q-v3-prior","S4p-random")]:
    r,w,per = ratio_stats(p7,A,B)
    dd = np.log10(p7[B])-np.log10(p7[A]); pp = stats.wilcoxon(dd).pvalue if np.any(dd!=0) else 1
    print(f"  {A} vs {B}: ratio {r:.3f} W/T/L {w[0]}/{w[1]}/{w[2]} p={pp:.3g}")
e = d7[d7.Algorithm=="Q-v3-prior"]
print(f"  Q-v3 actions {e.QAct1.mean():.1f}/{e.QAct2.mean():.1f}/{e.QAct3.mean():.1f}; shares {e.QuotaAct1Pct.mean():.2f}/{e.QuotaAct2Pct.mean():.2f}/{e.QuotaAct3Pct.mean():.2f}; rew {e.RewardMean.mean():.4f}")
print("\n=== SQ8: fresh-dev seeds 3011:3020, S* selection ===")
p8 = d8.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
ref = "S1-p38"
for a in ["S1-p38-K10","S1-E50","S3p-q25"]:
    r,w,per = ratio_stats(p8,a,ref)
    dd = np.log10(p8[ref])-np.log10(p8[a]); pp = stats.wilcoxon(dd).pvalue if np.any(dd!=0) else 1
    print(f"  {a:12s} vs S1-p38: ratio {r:.3f} W/T/L {w[0]}/{w[1]}/{w[2]} p={pp:.3g}")
    print("     per-fn:", {int(k): round(v,3) for k,v in per.items()})
for c in ["CheckT10","CheckT20"]:
    cp = d8.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values=c, aggfunc="first")
    for a in ["S1-p38-K10","S1-E50","S3p-q25"]:
        r,w,_ = ratio_stats(cp,a,ref,offset_by_fid=True)
        print(f"  {c} {a} vs S1: {r:.3f} ({w[0]}/{w[2]})")
for a in ["S1-p38","S1-p38-K10","S1-E50","S3p-q25"]:
    e = d8[d8.Algorithm==a]
    ep=e["NStagEpisodes"].sum(); rec=e["NRecoveredWindow"].sum()/ep if ep else np.nan
    print(f"  {a:12s} sec {e.Seconds.mean():.3f} recov {rec:.4f} longStag {e.LongStagShare.mean():.4f} novUse {e.NovelUsefulRate.mean():.4f} Q4 {e.ImprovRateQ4.mean():.4f}")
