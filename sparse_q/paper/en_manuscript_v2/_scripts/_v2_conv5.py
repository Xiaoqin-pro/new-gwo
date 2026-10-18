# -*- coding: utf-8 -*-
import os, sys
import numpy as np, pandas as pd, scipy.io as sio
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass
SQ   = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
ROOT = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
OUT  = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\figures"
plt.rcParams.update({"font.size": 8, "font.family": "DejaVu Sans"})

targets=[1,4,9,13,24]
src={os.path.join(SQ,"results","final_20261016_215309"):["S-star"],
     os.path.join(ROOT,"results","formal_20261016_140254"):["GWO"],
     os.path.join(SQ,"results","new3_20261017_100728"):["HAGWO","AOGWO"],
     os.path.join(SQ,"results","pso_20261017_211024"):["PSO(classic)"]}
curves={}
for bdir,labels in src.items():
    meta=pd.read_csv(os.path.join(bdir,"runs.csv"))
    sel=meta[(meta.Algorithm.isin(labels))&(meta.FunctionID.isin(targets))&(meta.Status=="ok")]
    for _,row in sel.iterrows():
        f=int(row.FunctionID); lab=str(row.Algorithm)
        fp=os.path.join(bdir,"runs","run_%05d.mat"%int(row.RunID))
        if not os.path.exists(fp): continue
        m=sio.loadmat(fp,squeeze_me=True,struct_as_record=False); res=m["record"].result
        fe=np.asarray(res.TraceFE).ravel(); tr=np.asarray(res.Trace).ravel()-100.0*f
        curves.setdefault((f,lab),[]).append((fe,tr))
        # consistency with that batch's own FinalError
        assert abs(tr[-1]-float(row.FinalError))<1e-4*max(1.0,abs(float(row.FinalError))), (lab,f,row.Seed)
print("trace/final consistency OK for all loaded runs")
for k,v in curves.items(): print(k, len(v))
order=["S-star","GWO","HAGWO","AOGWO","PSO(classic)"]
cmap={"S-star":("#c0392b",1.9,"-"),"GWO":("#7f8c8d",1.3,"--"),"HAGWO":("#8e44ad",1.4,"-"),
      "AOGWO":("#e67e22",1.3,"-."),"PSO(classic)":("#2980b9",1.4,"-")}
fig,axes=plt.subplots(2,3,figsize=(7.4,4.5))
for ax,f in zip(axes.ravel(),targets+[None]):
    if f is None:
        ax.axis("off")
        h=[plt.Line2D([],[],color=cmap[k][0],lw=cmap[k][1],ls=cmap[k][2],
                      label={"S-star":"VAST-GWO","PSO(classic)":"PSO"}.get(k,k)) for k in order]
        ax.legend(handles=h,loc="center",fontsize=8,frameon=False,title="median of 30 runs",title_fontsize=8)
        continue
    for k in order:
        runs=curves.get((f,k))
        if not runs: continue
        fe=runs[0][0]
        errs=np.vstack([np.interp(fe,x,y) for x,y in runs])
        c,lw,ls=cmap[k]
        ax.plot(fe,np.maximum(np.median(errs,axis=0),1e-12),color=c,lw=lw,ls=ls)
    ax.set_xscale("log"); ax.set_yscale("log"); ax.set_title("F%d"%f,fontsize=8)
    ax.set_xlabel("true FE",fontsize=7); ax.set_ylabel("best-so-far error",fontsize=7)
    ax.tick_params(labelsize=6); ax.grid(alpha=0.3)
fig.tight_layout(); fig.savefig(os.path.join(OUT,"fig_convergence7.png"),dpi=300); plt.close(fig)
print("saved")
