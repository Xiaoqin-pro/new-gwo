# -*- coding: utf-8 -*-
"""v2 figures: function-level ratio heatmap + 7-method convergence panels."""
import os, sys, glob, json
import numpy as np, pandas as pd
import scipy.io as sio
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import TwoSlopeNorm

try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass

SQ  = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
OUT = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\figures"
os.makedirs(OUT, exist_ok=True)
plt.rcParams.update({"font.size": 8, "font.family": "DejaVu Sans"})

MAIN7 = [("S-star","VAST-GWO"),("IGWO","I-GWO"),("HAGWO","HAGWO"),
         ("PSO(classic)","PSO"),("CLPSO","CLPSO"),("AOGWO","AOGWO"),("GWO","GWO")]
COLS  = ["I-GWO","HAGWO","PSO","CLPSO","AOGWO","GWO"]

def load_main7():
    base = pd.read_csv(os.path.join(SQ,"results","final_20261016_215309","merged_runs.csv"), low_memory=False)
    base = base[base.Status=="ok"]
    parts=[base]
    for pat in ["new3_*","pso_*"]:
        cands=[d for d in sorted(glob.glob(os.path.join(SQ,"results",pat))) if os.path.exists(os.path.join(d,"runs.csv"))]
        dd=pd.read_csv(os.path.join(cands[-1],"runs.csv")); dd=dd[dd.Status=="ok"]
        parts.append(dd)
    both=pd.concat(parts,ignore_index=True,sort=False)
    both=both[both.Algorithm!="EDGWO"]
    return both

def heatmap(both):
    piv=both.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="FinalError",aggfunc="first")
    med=piv.groupby(level=0).median()
    funcs=sorted(set(piv.index.get_level_values(0)))
    M=np.zeros((len(funcs),len(COLS)))
    for i,f in enumerate(funcs):
        for j,lab in enumerate(COLS):
            b=[a for a,l in MAIN7 if l==lab][0]
            M[i,j]=np.log10(med.loc[f,"S-star"]/med.loc[f,b])
    M=np.clip(M,-2,2)
    fig,ax=plt.subplots(figsize=(3.6,6.2))
    norm=TwoSlopeNorm(vmin=-2,vcenter=0,vmax=2)
    im=ax.imshow(M,cmap="RdBu_r",norm=norm,aspect="auto")
    ax.set_xticks(range(len(COLS))); ax.set_xticklabels(COLS,rotation=45,ha="right",fontsize=7)
    ax.set_yticks(range(len(funcs))); ax.set_yticklabels([f"F{f}" for f in funcs],fontsize=6)
    bounds=[1.5,10.5,20.5]
    for b in bounds: ax.axhline(b,color="k",lw=0.8)
    ax.set_title(r"$\log_{10}$(VAST-GWO / baseline),  median error",fontsize=7)
    cb=fig.colorbar(im,ax=ax,fraction=0.05,pad=0.03)
    cb.set_label("negative = VAST-GWO better",fontsize=6); cb.ax.tick_params(labelsize=6)
    fig.tight_layout(); fig.savefig(os.path.join(OUT,"fig_heatmap.png"),dpi=300); plt.close(fig)
    print("heatmap ok")

def convergence():
    targets=[1,4,9,13,24]
    src={"final_20261016_215309":["S-star","GWO","IGWO","CLPSO"],
         "new3_20261017_100728":["HAGWO","AOGWO"],
         "pso_20261017_211024":["PSO(classic)"]}
    curves={}
    for batch,labels in src.items():
        bdir=os.path.join(SQ,"results",batch)
        meta=pd.read_csv(os.path.join(bdir,"runs.csv"))
        sel=meta[(meta.Algorithm.isin(labels))&(meta.FunctionID.isin(targets))&(meta.Status=="ok")]
        for _,row in sel.iterrows():
            f=int(row.FunctionID); lab=str(row.Algorithm)
            fp=os.path.join(bdir,"runs",f"run_{int(row.RunID):05d}.mat")
            if not os.path.exists(fp): continue
            m=sio.loadmat(fp,squeeze_me=True,struct_as_record=False)
            res=m["record"].result
            fe=np.asarray(res.TraceFE).ravel(); tr=np.asarray(res.Trace).ravel()
            curves.setdefault((f,lab),[]).append((fe,tr-100.0*f))
    order=[a for a,_ in MAIN7]
    cmap={"S-star":("#c0392b",1.8,"-"),"IGWO":("#e67e22",1.2,"-"),"HAGWO":("#8e44ad",1.3,"-"),
          "PSO(classic)":("#2980b9",1.2,"-"),"CLPSO":("#16a085",1.2,"-"),
          "AOGWO":("#d35400",1.1,"--"),"GWO":("#7f8c8d",1.2,"--")}
    fig,axes=plt.subplots(2,3,figsize=(7.4,4.4))
    for ax,f in zip(axes.ravel(),targets+[None]):
        if f is None: ax.axis("off"); continue
        for lab in order:
            runs=curves.get((f,lab))
            if not runs: continue
            fe=runs[0][0]
            errs=np.vstack([np.interp(fe,x,y) for x,y in runs])
            c,lw,ls=cmap[lab]
            ax.plot(fe,np.maximum(np.median(errs,axis=0),1e-12),color=c,lw=lw,ls=ls,
                    label={"S-star":"VAST-GWO","PSO(classic)":"PSO"}.get(lab,lab))
        ax.set_xscale("log"); ax.set_yscale("log"); ax.set_title(f"F{f}")
        ax.set_xlabel("true FE",fontsize=7); ax.set_ylabel("best-so-far error",fontsize=7)
        ax.tick_params(labelsize=6); ax.grid(alpha=0.3)
        if f==targets[0]: ax.legend(fontsize=5.4,ncol=2,frameon=False)
    fig.tight_layout(); fig.savefig(os.path.join(OUT,"fig_convergence7.png"),dpi=300); plt.close(fig)
    print("convergence ok")

if __name__=="__main__":
    both=load_main7()
    heatmap(both)
    convergence()
