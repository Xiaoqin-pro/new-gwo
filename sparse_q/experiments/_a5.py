import pandas as pd, numpy as np, glob, sys
from scipy import stats
sys.path.insert(0, r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\experiments")
from gates_sparse_q import ratio_stats
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
b = sorted(glob.glob(root + r"\results\sq5_*"))[-1]
df = pd.read_csv(b + r"\runs.csv"); df=df[df.Status=="ok"]
piv = df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
print("=== SCREEN5 (10 seeds): gates and standings ===")
for A,B in [("S5p-q","S3p-q25"),("S5p-q","S4p-random"),("S3p-q25","S4p-random")]:
    r,w,per = ratio_stats(piv, A, B)
    d = np.log10(piv[B]) - np.log10(piv[A])
    p = stats.wilcoxon(d).pvalue if np.any(d!=0) else 1.0
    print(f"{A:9s} vs {B:11s}: ratio {r:.3f} W/T/L {w[0]}/{w[1]}/{w[2]} p={p:.3g}")
for a in ["GWO","B0-ANGWO","B1-dense-sync","S1-pool38","S3p-q25","S4p-random","S5p-q"]:
    r,w,_ = ratio_stats(piv, a, "GWO")
    e = df[df.Algorithm==a]
    ep=e["NStagEpisodes"].sum(); rec=e["NRecoveredWindow"].sum()/ep if ep else np.nan
    print(f"{a:13s} vs GWO {r:6.3f}  W/L {w[0]}/{w[2]}  sec {e.Seconds.mean():.3f}  recov {rec:.4f}  longStag {e.LongStagShare.mean():.4f}  novUse {e.NovelUsefulRate.mean():.4f}  Q4 {e.ImprovRateQ4.mean():.4f}")
# early checkpoints vs GWO and vs B0
for c in ["CheckT10","CheckT20"]:
    cp = df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values=c, aggfunc="first")
    r1,w1,_ = ratio_stats(cp,"S5p-q","GWO",offset_by_fid=True)
    r2,w2,_ = ratio_stats(cp,"S5p-q","B0-ANGWO",offset_by_fid=True)
    r3,w3,_ = ratio_stats(cp,"S3p-q25","GWO",offset_by_fid=True)
    print(f"{c}: S5p vs GWO {r1:.3f}({w1[0]}/{w1[2]}) | S5p vs B0 {r2:.3f}({w2[0]}/{w2[2]}) | S3p vs GWO {r3:.3f}({w3[0]}/{w3[2]})")
# simple multimodal subset (F4,F6,F9) ratio vs GWO for S5p / S3p
for a in ["S5p-q","S3p-q25","S1-pool38"]:
    r,w,per = ratio_stats(piv,a,"GWO")
    sub = [per[f] for f in (4,6,9) if f in per]
    print(f"{a} simple-multimodal ratios {[round(x,3) for x in sub]} (median {np.median(sub):.3f})")
# Q diagnostics
e = df[df.Algorithm=="S5p-q"]
print(f"Q actions: {e.QAct1.mean():.1f}/{e.QAct2.mean():.1f}/{e.QAct3.mean():.1f}; shares {e.QuotaAct1Pct.mean():.2f}/{e.QuotaAct2Pct.mean():.2f}/{e.QuotaAct3Pct.mean():.2f}; rew {e.RewardMean.mean():.4f}; gbWin {e.GBWindowPct.mean():.3f}")
