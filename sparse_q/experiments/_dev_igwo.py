import pandas as pd, numpy as np, glob
from scipy import stats
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
sq = root + r"\sparse_q"
d10 = pd.read_csv(sorted(glob.glob(sq + r"\results\sq10_*"))[-1] + r"\runs.csv")
d11 = pd.read_csv(sorted(glob.glob(sq + r"\results\sq11_*"))[-1] + r"\runs.csv")
diag = pd.read_csv(sorted(glob.glob(root + r"\results\diag1_*"))[-1] + r"\runs.csv")
p10 = d10.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
p11 = d11.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
pg = diag.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
sel = {"P4-ref": p10["P4-ref"], "P4-steer25": p10["P4-steer25"], "P4-subset20": p10["P4-subset20"],
       "P4-steer50": p10["P4-steer50"], "P4-s25g20": p11["P4-s25g20"], "IGWO": pg["IGWO"], "GWO": pg["GWO"]}
m = pd.DataFrame(sel)
print("rows:", len(m), "(8 fn x 5 seeds, shared pairs)")
for A in ["P4-ref","P4-steer25","P4-subset20","P4-steer50","P4-s25g20"]:
    sub = m[[A,"IGWO"]].dropna()
    w = l = 0
    detail = {}
    for f in sorted(set(sub.index.get_level_values(0))):
        g = sub.loc[f]
        r = (g[A]/g["IGWO"]).median()
        detail[int(f)] = round(r,3)
        w += r < 1; l += r > 1
    print(f"{A:12s} vs IGWO (5 seeds): W-L {w}-{l}  per-fn {detail}")
print("\nIGWO vs GWO on same pairs:", round(np.median([np.median((m.loc[f,'IGWO']/m.loc[f,'GWO'])) for f in sorted(set(m.index.get_level_values(0)))]),3))
