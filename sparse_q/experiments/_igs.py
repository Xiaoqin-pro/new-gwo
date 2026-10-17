import pandas as pd, numpy as np, glob, sys
from scipy import stats
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
sq = root + r"\sparse_q"
# our sparse arms on dev seeds 3001:3005 (sq6) and 3011:3020 (sq8)
d6 = pd.read_csv(sorted(glob.glob(sq + r"\results\sq6_*"))[-1] + r"\runs.csv")
d8 = pd.read_csv(sorted(glob.glob(sq + r"\results\sq8_*"))[-1] + r"\runs.csv")
diag = pd.read_csv(sorted(glob.glob(root + r"\results\diag1_*"))[-1] + r"\runs.csv")
for d in (d6,d8,diag): pass
def piv_of(df):
    return df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
p6 = piv_of(d6); p8 = piv_of(d8); pg = piv_of(diag)
# build a combined matrix: S*-K10 (from sq6 seeds3001-3005 + sq8 seeds3011-3020), IGWO & strong baselines from diag (seeds 3001-3005)
sel = {}
sel["Sstar-K10"] = pd.concat([p6["T-S1-p38-K10"], p8["S1-p38-K10"]])
sel["S1-K50"] = pd.concat([p6["T-S1-p38"], p8["S1-p38"]])
for a in ["IGWO","HIDMS-PSO","HCLPSO","DMS-PSO","SAQ-CSO","GWO"]:
    if a in pg.columns: sel[a] = pg[a]
mat = pd.DataFrame(sel)
common = mat.dropna()
print("pairwise rows:", len(common), "seeds present:", sorted(set(common.index.get_level_values(1))))
def ratio(A,B,df):
    sub = df[[A,B]].dropna()
    r = sub.groupby(level=0).apply(lambda g: np.median(g[A]/g[B]), include_groups=False)
    return np.median(r), (r<1).sum(), len(r)
print("\n=== Dev head-to-head (identical fn/seed pairs) ===")
for B in ["GWO","IGWO","HIDMS-PSO","HCLPSO","DMS-PSO","SAQ-CSO"]:
    if B not in mat.columns: continue
    sub = mat[["Sstar-K10",B]].dropna()
    if len(sub)==0: continue
    r, w, n = ratio("Sstar-K10",B,mat)
    d = np.log10(sub[B]) - np.log10(sub["Sstar-K10"])
    p = stats.wilcoxon(d).pvalue if np.any(d!=0) else 1.0
    print(f"S*-K10 vs {B:10s}: median ratio {r:.3f} ({w}/{n} fn-mean wins)  pooled p={p:.3g}  pairs={len(sub)}")
# and where IGWO itself stands vs GWO on the same pairs
r, w, n = ratio("IGWO","GWO",mat)
print(f"\nIGWO vs GWO (same pairs): median ratio {r:.3f} ({w}/{n} wins)")
r, w, n = ratio("Sstar-K10","GWO",mat)
print(f"S*-K10 vs GWO (same pairs): median ratio {r:.3f} ({w}/{n} wins)")
