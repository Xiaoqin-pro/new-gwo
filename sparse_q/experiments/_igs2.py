import pandas as pd, numpy as np, glob
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
sq = root + r"\sparse_q"
d6 = pd.read_csv(sorted(glob.glob(sq + r"\results\sq6_*"))[-1] + r"\runs.csv")
diag = pd.read_csv(sorted(glob.glob(root + r"\results\diag1_*"))[-1] + r"\runs.csv")
p6 = d6.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
pg = diag.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
sel = {"Sstar-K10": p6["T-S1-p38-K10"], "S1-K50": p6["T-S1-p38"]}
for a in ["IGWO","HIDMS-PSO","HCLPSO","DMS-PSO","SAQ-CSO","GWO"]:
    sel[a] = pg[a]
m = pd.DataFrame(sel)
print("rows:", len(m), "| per-function medians (seeds 3001:3005):")
print(f"{'F':>4} {'S*/GWO':>9} {'IGWO/GWO':>10} {'S*/IGWO':>9} {'S*/SAQ':>9} {'S1/GWO':>9}")
for f in sorted(m.index.get_level_values(0).unique()):
    g = m.loc[f]
    def r(a,b): 
        v = (g[a]/g[b]).replace([np.inf,-np.inf],np.nan).dropna()
        return v.median()
    print(f"{int(f):>4} {r('Sstar-K10','GWO'):9.3f} {r('IGWO','GWO'):10.3f} {r('Sstar-K10','IGWO'):9.3f} {r('Sstar-K10','SAQ-CSO'):9.3f} {r('S1-K50','GWO'):9.3f}")
