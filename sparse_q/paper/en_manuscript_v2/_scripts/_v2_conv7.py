# -*- coding: utf-8 -*-
"""7-method convergence figure, final version (verified IGWO column map)."""
import os, sys
import numpy as np, pandas as pd, scipy.io as sio
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass

SQ   = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
ROOT = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
CLD  = r"D:\111\Desktop\噜噜\9.29\results\cec\saq_cso_formal_100k_30seed_study_20261013_083541"
IGD  = r"D:\111\Desktop\噜噜\狼群\results\merged_30seed"
OUT  = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\figures"
AN   = r"D:\111\Desktop\噜噜\基础版狼群\文章\_analysis"
plt.rcParams.update({"font.size": 8, "font.family": "DejaVu Sans"})

PANELS=[1,9,8,20,21]
GRID=np.unique(np.round(np.logspace(1,5,240)).astype(int))
def interp_err(fe,tr,f,grid): return np.interp(grid, fe, tr-100.0*f)
curves={}
src={os.path.join(SQ,"results","final_20261016_215309"):["S-star"],
     os.path.join(SQ,"results","new3_20261017_100728"):["HAGWO","AOGWO"],
     os.path.join(SQ,"results","pso_20261017_211024"):["PSO(classic)"],
     os.path.join(ROOT,"results","formal_20261016_140254"):["GWO"]}
for bdir,labels in src.items():
    meta=pd.read_csv(os.path.join(bdir,"runs.csv"))
    sel=meta[(meta.Algorithm.isin(labels))&(meta.FunctionID.isin(PANELS))&(meta.Status=="ok")]
    for _,row in sel.iterrows():
        f=int(row.FunctionID); lab=str(row.Algorithm)
        m=sio.loadmat(os.path.join(bdir,"runs","run_%05d.mat"%int(row.RunID)),squeeze_me=True,struct_as_record=False)
        res=m["record"].result
        curves.setdefault((f,lab),[]).append(interp_err(np.asarray(res.TraceFE).ravel(),np.asarray(res.Trace).ravel(),f,GRID))
# IGWO with verified column map
cm=np.load(os.path.join(AN,"_igwo_colmap_full.npy"))
colmap={(int(f),int(s)):int(c) for f,s,c in cm}
mm=sio.loadmat(os.path.join(IGD,"traces.mat"), squeeze_me=True, struct_as_record=False)
Tr=mm["Traces"]; feI=np.asarray(mm["traceFE"]).ravel()
runs=pd.read_csv(os.path.join(IGD,"runs.csv"))
for f in PANELS:
    for s in range(3001,3031):
        c=colmap[(f,s)]
        curves.setdefault((f,"IGWO"),[]).append(interp_err(feI,Tr[:,c],f,GRID))
# CLPSO from author-source suite
mani=pd.read_csv(os.path.join(CLD,"job_manifest.csv"))
sel=mani[(mani.Condition=="CLPSO-AuthorSource")&(mani.FunctionID.isin(PANELS))&(mani.Budget==100000)]
for _,row in sel.iterrows():
    f=int(row.FunctionID)
    m=sio.loadmat(os.path.join(CLD,"runs","job_%04d.mat"%int(row.JobID)),squeeze_me=True,struct_as_record=False)
    T=np.asarray(m["T"]).ravel()
    curves.setdefault((f,"CLPSO"),[]).append(interp_err(np.arange(1,len(T)+1),T,f,GRID))

tab={"F1":(1.241e6,1.033e7),"F9":(2.433,581.2),"F8":(86.14,126.1),"F20":(466.0,645.8),"F21":(280.7,326.5)}
print("final-median checks (figure vs frozen table):")
for f in PANELS:
    sv=np.median([c[-1] for c in curves[(f,"S-star")]]); iv=np.median([c[-1] for c in curves[(f,"IGWO")]])
    tv,ti=tab["F%d"%f]
    print(f"  F{f:<2d} VAST {sv:10.4g} vs {tv:10.4g}   IGWO {iv:10.4g} vs {ti:10.4g}")
    assert np.isclose(sv,tv,rtol=1e-3), f
    assert np.isclose(iv,ti,rtol=1e-3), f

order=["S-star","IGWO","HAGWO","PSO(classic)","CLPSO","AOGWO","GWO"]
cmap={"S-star":("#c0392b",2.0,"-"),"IGWO":("#e67e22",1.3,"-"),"HAGWO":("#8e44ad",1.4,"-"),
      "PSO(classic)":("#2980b9",1.4,"-"),"CLPSO":("#16a085",1.4,"-"),
      "AOGWO":("#d35400",1.2,"-."),"GWO":("#7f8c8d",1.3,"--")}
label={"S-star":"VAST-GWO","PSO(classic)":"PSO"}
fig,axes=plt.subplots(2,3,figsize=(7.4,4.5))
for ax,f in zip(axes.ravel(),PANELS+[None]):
    if f is None:
        ax.axis("off")
        h=[plt.Line2D([],[],color=cmap[k][0],lw=cmap[k][1],ls=cmap[k][2],label=label.get(k,k)) for k in order]
        ax.legend(handles=h,loc="center",fontsize=8,frameon=False,title="median of 30 runs",title_fontsize=8)
        continue
    for k in order:
        M=np.vstack(curves[(f,k)]); c,lw,ls=cmap[k]
        ax.plot(GRID,np.maximum(np.median(M,axis=0),1e-12),color=c,lw=lw,ls=ls)
    ax.set_xscale("log"); ax.set_yscale("log"); ax.set_title("F%d"%f,fontsize=8)
    ax.set_xlabel("true FE",fontsize=7); ax.set_ylabel("best-so-far error",fontsize=7)
    ax.tick_params(labelsize=6); ax.grid(alpha=0.3)
fig.tight_layout(); fig.savefig(os.path.join(OUT,"fig_convergence.png"),dpi=300); plt.close(fig)
print("saved", os.path.join(OUT,"fig_convergence.png"))
