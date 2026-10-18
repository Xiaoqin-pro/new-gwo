# -*- coding: utf-8 -*-
"""Late-budget improvement events: count vs magnitude for VAST-GWO vs GWO (formal tier)."""
import os, glob, sys
import numpy as np, pandas as pd, scipy.io as sio
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass
SQ   = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
ROOT = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
src={os.path.join(SQ,"results","final_20261016_215309"):["S-star"],
     os.path.join(ROOT,"results","formal_20261016_140254"):["GWO"]}
rows=[]
for bdir,labels in src.items():
    meta=pd.read_csv(os.path.join(bdir,"runs.csv"))
    sel=meta[(meta.Algorithm.isin(labels))&(meta.Status=="ok")]
    for _,row in sel.iterrows():
        fp=os.path.join(bdir,"runs","run_%05d.mat"%int(row.RunID))
        if not os.path.exists(fp): continue
        m=sio.loadmat(fp,squeeze_me=True,struct_as_record=False); res=m["record"].result
        fe=np.asarray(res.TraceFE).ravel(); tr=np.asarray(res.Trace).ravel()
        f=int(res.FunctionID); err=tr-100.0*f
        q=fe>=50000                       # late half of the budget
        e=err[q]
        if len(e)<2: continue
        d=np.diff(e); imp=d[d<0]
        mag=np.log10(np.maximum(e[:-1][d<0],1e-12))-np.log10(np.maximum(e[1:][d<0],1e-12))
        rows.append(dict(Alg=str(res.Algorithm), Fn=f, Seed=int(res.Seed),
                         nImp=len(imp), magMed=float(np.median(mag)) if len(mag) else np.nan,
                         lateLog10=float(np.log10(max(e[0],1e-12))-np.log10(max(e[-1],1e-12)))))
d=pd.DataFrame(rows)
for a,g in d.groupby("Alg"):
    per=g.groupby("Fn").median(numeric_only=True).reset_index()
    print(f"{a:12s} runs={len(g):5d}  median improving events (late half)={per.nImp.median():.0f}  "
          f"median per-event log10 gain={per.magMed.median():.4f}  median late log10 progress={per.lateLog10.median():.3f}")
