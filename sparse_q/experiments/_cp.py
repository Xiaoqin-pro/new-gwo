import pandas as pd, numpy as np
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
df = pd.read_csv(root + r"\sparse_q\results\final_20261016_215309\merged_runs.csv")
df = df[df.Status=="ok"]
for c in ["CheckT10","CheckT20","CheckT50"]:
    cp = df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values=c, aggfunc="first")
    for B in ["GWO","B0-ANGWO"]:
        if B not in cp.columns: continue
        sub = cp[["S-star",B]].dropna()
        if len(sub)==0: continue
        rs=[]
        for f in sorted(set(sub.index.get_level_values(0))):
            g = sub.loc[f]
            rs.append(np.median((g["S-star"]-100*f)/(g[B]-100*f)))
        print(f"{c}: S-star vs {B}: median-of-fn {np.median(rs):.3f}, wins {sum(r<1 for r in rs)}/29")
