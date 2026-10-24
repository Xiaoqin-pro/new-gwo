#!/usr/bin/env python3
"""Diff-GWO P1/P1b analysis: B-DiffAll and C-Mix60 vs A-Standard."""
from pathlib import Path
import json, sys, numpy as np, pandas as pd
from scipy.stats import wilcoxon
ROOT=Path(__file__).resolve().parents[2]
FUNCS15=[1,3,4,7,10,11,13,14,16,18,20,22,24,26,30]
def ratio(a,b):
    a=np.asarray(a,float); b=np.asarray(b,float); return (a+1e-8)/(b+1e-8)
def analyze(p,outdir,tag):
    df=pd.read_csv(p/'runs.csv')
    assert (df.Status=='ok').all() and (df.Evaluations==100000).all()
    res={}
    for name,a,b in [('B_A','B-DiffAll','A-Standard'),('C_A','C-Mix60','A-Standard'),('B_C','B-DiffAll','C-Mix60')]:
        x=df[df.Algorithm==a][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'})
        y=df[df.Algorithm==b][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'})
        j=x.merge(y,on=['FunctionID','Seed'])
        r=j.groupby('FunctionID').apply(lambda g: np.median(ratio(g.ea,g.eb)),include_groups=False)
        d=j.groupby('FunctionID').apply(lambda g: np.median(np.log10(ratio(g.ea,g.eb))),include_groups=False).to_numpy(float)
        try: pv=float(wilcoxon(d).pvalue)
        except ValueError: pv=float('nan')
        res[name]=dict(median=float(np.median(r)),wins=int((r<1).sum()),n=len(r),cats=int((r>1.2).sum()),max=float(r.max()),p=pv,per={int(k):float(v) for k,v in r.items()})
    (outdir/'summary.json').write_text(json.dumps(res,indent=2,ensure_ascii=False),encoding='utf-8')
    print(f'=== {tag} ===')
    for k,v in res.items():
        print(f'{k}: med={v["median"]:.4f} wins={v["wins"]}/{v["n"]} cats={v["cats"]} max={v["max"]:.3g} p={v["p"]:.4f}')
    return res
if __name__=='__main__':
    p=Path(sys.argv[1]); out=Path(sys.argv[2]); out.mkdir(parents=True,exist_ok=True)
    analyze(p,out,p.name)
