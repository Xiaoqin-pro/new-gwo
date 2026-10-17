import pandas as pd, numpy as np, sys
from scipy import stats
sys.path.insert(0, r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\experiments")
from gates_sparse_q import ratio_stats
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
b = sorted(__import__("glob").glob(root + r"\results\sq1c_*"))[-1]
df = pd.read_csv(b + r"\runs.csv"); df = df[df.Status=="ok"]
piv = df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
cp = {c: df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values=c, aggfunc="first") for c in ["CheckT10","CheckT20","CheckT50"]}
S1 = "S1-sparse-random"
print("=== SCREEN1C: strat variants vs S1 ===")
for a in [x for x in piv.columns if x != S1]:
    r,w,per = ratio_stats(piv, a, S1)
    gate = (r <= 0.98) or (w[0] >= 6 and r <= 1.00)
    print(f"{a:16s} vs S1: ratio {r:.3f}, W/T/L {w[0]}/{w[1]}/{w[2]}, gate {'PASS' if gate else 'FAIL'}")
    print("   per-fn:", {int(k): round(v,3) for k,v in per.items()})
r20, w20, per20 = ratio_stats(cp["CheckT20"], "P-prop25-rand", S1, offset_by_fid=True)
print(f"\nP-prop25-rand vs S1 @FE20k: ratio {r20:.3f}, W/T/L {w20}")
for a in [S1,"P-prop25-rot","P-prop25-rand","P-prop50-rand","P-prop75-rand"]:
    e = df[df.Algorithm==a]
    ep = e["NStagEpisodes"].sum(); rec = e["NRecoveredWindow"].sum()/ep if ep else np.nan
    print(f"{a:16s} sec {e.Seconds.mean():.3f}  recov {rec:.4f}  longStag {e.LongStagShare.mean():.4f}  novUseful {e.NovelUsefulRate.mean():.4f}  Q4impr {e.ImprovRateQ4.mean():.4f}")
