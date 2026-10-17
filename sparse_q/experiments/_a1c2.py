import pandas as pd, numpy as np, glob, os
from scipy import stats
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
b = sorted(glob.glob(root + r"\results\sq1c_*"))[-1]
df = pd.read_csv(b + r"\runs.csv"); df=df[df.Status=="ok"]
piv = df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
for A,B in [("P-prop25-rand","S1-sparse-random"),("P-prop25-rot","P-prop25-rand")]:
    d = np.log10(piv[B]) - np.log10(piv[A])
    p = stats.wilcoxon(d).pvalue if np.any(d!=0) else 1.0
    print(f"{A} vs {B}: pooled p={p:.4g}, median logdiff={np.median(d):.3f}, mean ratio={np.mean(piv[A]/piv[B]):.3f}")
