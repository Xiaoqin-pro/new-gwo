import pandas as pd, numpy as np, glob
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
parts=[pd.read_csv(sorted(glob.glob(root + r"\results\freshv2_*"))[-1] + r"\runs.csv"),
       pd.read_csv(sorted(glob.glob(root + r"\results\combo2_*"))[-1] + r"\runs.csv")]
df=pd.concat(parts, ignore_index=True, sort=False); df=df[df.Status=="ok"]
piv=df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
A="V2-steer50-g20"
print(f"{A} vs IGWO per-function medians:")
for f in sorted(df.FunctionID.unique()):
    ra, rb = piv.loc[f,A].dropna(), piv.loc[f,"IGWO-fresh"].dropna()
    c = ra.index.intersection(rb.index)
    r = np.median(ra.loc[c]/rb.loc[c])
    mark = "LOSS" if r>1.05 else ("WIN " if r<0.95 else "    ")
    print(f"  F{int(f):>2} {r:8.3f} {mark}")
