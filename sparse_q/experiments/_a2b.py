import pandas as pd, numpy as np, glob, sys
sys.path.insert(0, r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\experiments")
from gates_sparse_q import ratio_stats
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
b = sorted(glob.glob(root + r"\results\sq2_*"))[-1]
df = pd.read_csv(b + r"\runs.csv"); df=df[df.Status=="ok"]
cp = {c: df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values=c, aggfunc="first") for c in ["CheckT10","CheckT20","CheckT50"]}
print("checkpoint ratios vs S1-pool38 (lower=better):")
for a in ["W-q25","W-q50","W-q75","S-q25-p38"]:
    row=[]
    for c in ["CheckT10","CheckT20","CheckT50"]:
        r,w,_ = ratio_stats(cp[c], a, "S1-pool38", offset_by_fid=True)
        row.append(f"{c[-2:]}k:{r:.3f}({w[0]}/{w[2]})")
    print(f"  {a:10s} " + "  ".join(row))
