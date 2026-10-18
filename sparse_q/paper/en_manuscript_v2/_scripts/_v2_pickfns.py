# -*- coding: utf-8 -*-
import os, glob, sys
import numpy as np, pandas as pd
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass
SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
base = pd.read_csv(os.path.join(SQ,"results","final_20261016_215309","merged_runs.csv"), low_memory=False)
base = base[base.Status=="ok"]
parts=[base]
for pat in ["new3_*","pso_*"]:
    cands=[d for d in sorted(glob.glob(os.path.join(SQ,"results",pat))) if os.path.exists(os.path.join(d,"runs.csv"))]
    dd=pd.read_csv(os.path.join(cands[-1],"runs.csv")); dd=dd[dd.Status=="ok"]; parts.append(dd)
both=pd.concat(parts,ignore_index=True,sort=False); both=both[both.Algorithm!="EDGWO"]
alg7=["S-star","IGWO","HAGWO","PSO(classic)","CLPSO","AOGWO","GWO"]
piv=both.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="FinalError",aggfunc="first")
med=piv.groupby(level=0).median()[alg7]
fam=lambda f: "U" if f in (1,3) else ("SM" if 4<=f<=10 else ("H" if 11<=f<=20 else "C"))
rows=[]
for f in med.index:
    row=med.loc[f]
    s=row["S-star"]; others=row.drop("S-star")
    best_other=others.min(); who=others.idxmin()
    rank=(row.rank()["S-star"])
    rows.append((f,fam(f),rank,s,best_other,who,best_other/s,row))
rows.sort(key=lambda t:t[6], reverse=True)
print(f"{'Fn':>3} {'fam':>3} {'rank':>4} {'VAST':>12} {'best other':>12} {'who':>12} {'ratio':>9}")
for f,fm,rk,s,bo,who,ratio,row in rows:
    print(f"F{f:<2d} {fm:>3} {rk:>4.0f} {s:12.4g} {bo:12.4g} {who:>12} {ratio:9.2f}")
