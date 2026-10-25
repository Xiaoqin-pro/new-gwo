#!/usr/bin/env python3
"""Three new external baselines vs SVAD-GWO and GWO: paired per-function Wilcoxon + Holm."""
import sys, json
from pathlib import Path
import numpy as np, pandas as pd
from scipy.stats import wilcoxon

def holm(ps, names, dl):
    ps=np.asarray(ps,float); order=np.argsort(ps); m=len(ps)
    adj=np.empty(m); run=0.0
    for i in range(m):
        v=ps[order[i]]*(m-i); run=max(run,v); adj[i]=run
    better=[]; worse=[]
    for i in range(m):
        fn=names[order[i]]
        if adj[i]<0.05:
            (better if dl[fn]<0 else worse).append((int(fn), float(adj[i])))
    return better, worse

def load(d, alg):
    df=pd.read_csv(Path(d)/'runs.csv')
    return df[df.Algorithm==alg][['FunctionID','Seed','FinalError']]

def compare(bdir, adir, aalg, bdir2, balg, out):
    b=load(bdir2,balg).rename(columns={'FinalError':'eb'})
    a=load(adir,aalg).rename(columns={'FinalError':'ea'})
    j=b.merge(a,on=['FunctionID','Seed'],validate='one_to_one')
    j['r']=(j.eb+1e-8)/(j.ea+1e-8)
    j['dl']=np.log10(j.r)
    med=j.groupby('FunctionID').r.median()
    dl={int(k):float(v) for k,v in j.groupby('FunctionID').dl.median().items()}
    piv=j.pivot_table(index='Seed',columns='FunctionID',values='dl')
    fns=[int(c) for c in sorted(piv.columns)]
    ps=[];names=[]
    for fn in fns:
        dd=piv[fn].to_numpy(float)
        try: p=float(wilcoxon(dd).pvalue)
        except Exception: p=1.0
        ps.append(p); names.append(fn)
    better,worse=holm(ps,names,dl)
    overall=float(np.median(np.array([dl[f] for f in fns])))
    try: pcmp=float(wilcoxon(np.array([dl[f] for f in fns])).pvalue)
    except Exception: pcmp=1.0
    res=dict(label=balg, vs=aalg, nFunc=len(fns), nSeed=int(j.Seed.nunique()),
             medRatio=float(np.median(med.values)),
             wins=int((med<1).sum()), losses=int((med>1).sum()),
             cats=int((med>1.2).sum()), holmBetter=[x[0] for x in better],
             holmWorse=[x[0] for x in worse], compP=pcmp,
             perFunc={int(k):float(v) for k,v in med.items()},
             logMed=overall)
    out.append(res)
    return res

def main():
    bdir=sys.argv[1]                      # baseline3_confirm30 batch
    svad='sparse_q/results/svadgwo_confirm30_20261025_000001'
    out=[]
    for balg in ['MENGWO','DE-Elim GWO','CorrGWO-c2','CorrGWO-c1']:
        compare(None,svad,'SVAD-GWO',bdir,balg,out)
    print('%-14s %-11s %7s %6s %6s %6s %7s  %s'%('arm','vs','medR','wins','loss','cat','p','Holm'))
    for r in out:
        print('%-14s %-11s %7.4f %3d/%d %6d %6d %7.4g  better=%d %s worse=%d %s'%(
            r['label'],r['vs'],r['medRatio'],r['wins'],r['nFunc'],r['losses'],r['cats'],
            r['compP'],len(r['holmBetter']),r['holmBetter'],len(r['holmWorse']),r['holmWorse']))
    Path('sparse_q/reports/baseline3_confirm30_analysis').mkdir(parents=True,exist_ok=True)
    json.dump(out,open('sparse_q/reports/baseline3_confirm30_analysis/summary.json','w'),indent=1)
    print()
    print('per-function median ratio (arm / SVAD-GWO):')
    fns=sorted(out[0]['perFunc'])
    hdr='Fn   '+''.join('%13s'%r['label'] for r in out); print(hdr)
    for fn in fns:
        print('F%-3d '%fn+''.join('%13.3f'%r['perFunc'][fn] for r in out))

if __name__=='__main__':
    main()
