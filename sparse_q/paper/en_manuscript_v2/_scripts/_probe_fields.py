import os, glob, sys, json
import numpy as np, pandas as pd
from scipy import stats
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass

SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
base = pd.read_csv(os.path.join(SQ,"results","final_20261016_215309","merged_runs.csv"), low_memory=False)
base = base[base.Status=="ok"]
print("base arms:", sorted(base.Algorithm.unique()))
print("base functions:", sorted(base.FunctionID.unique()))
parts=[base]
for pat in ["new3_*","pso_*"]:
    cands=[d for d in sorted(glob.glob(os.path.join(SQ,"results",pat))) if os.path.exists(os.path.join(d,"runs.csv"))]
    if cands:
        dd=pd.read_csv(os.path.join(cands[-1],"runs.csv")); dd=dd[dd.Status=="ok"]
        print(pat, os.path.basename(cands[-1]), len(dd), sorted(dd.Algorithm.unique()))
        parts.append(dd)
both=pd.concat(parts,ignore_index=True,sort=False)
both=both[both.Algorithm!="EDGWO"]
piv=both.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="FinalError",aggfunc="first")
print("\ncolumns:", list(piv.columns))
seeds=piv.index.get_level_values(1); print("seeds:", seeds.min(), seeds.max(), len(sorted(set(seeds))))
