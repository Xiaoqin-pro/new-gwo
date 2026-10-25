#!/usr/bin/env python3
"""DiffA 29x30 Holm analysis: B (new batch) vs A-Final-SteerOn (reused), per-function Holm counts."""
import sys
from pathlib import Path
import numpy as np, pandas as pd
from scipy.stats import wilcoxon
def main(bdir, adir):
    b=pd.read_csv(Path(bdir)/'runs.csv')[['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'})
    a=pd.read_csv(Path(adir)/'runs.csv')
    a=a[a.Algorithm=='A-Final-SteerOn'][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'})
    j=b.merge(a,on=['FunctionID','Seed'],validate='one_to_one')
    j['dl']=np.log10((j.eb+1e-8)/(j.ea+1e-8))
    j['r']=(j.eb+1e-8)/(j.ea+1e-8)
    med=j.groupby('FunctionID').r.median()
    d=j.groupby('FunctionID').apply(lambda g: np.median(np.log10((g.eb+1e-8)/(g.ea+1e-8))),include_groups=False).to_numpy(float)
    stat,p_cmp=wilcoxon(d)
    piv=j.pivot_table(index='Seed',columns='FunctionID',values='dl')
    fns=sorted(piv.columns); ps=[]; names=[]
    for fn in fns:
        dd=piv[fn].to_numpy(float)
        try: p=wilcoxon(dd).pvalue
        except Exception: p=1.0
        ps.append(p); names.append(int(fn))
    ps=np.array(ps); order=np.argsort(ps); m=len(ps)
    adj=np.array([ps[order[i]]*(m-i) for i in range(m)])
    for i in range(1,m): adj[i]=max(adj[i],adj[i-1])
    sig_better=[]; sig_worse=[]
    for i in range(m):
        fn=names[order[i]]; dlv=float(np.median(j[j.FunctionID==fn].dl))
        if adj[i]<0.05:
            (sig_better if dlv<0 else sig_worse).append(fn)
    print('=== DiffA-AnchorBest 29x30 vs A-Final-SteerOn ===')
    print('med=%.4f wins=%d/29 cats=%d comparison-p=%.4g' % (med.median(), int((med<1).sum()), int((med>1.2).sum()), p_cmp))
    print('Holm-sig better (%d): %s' % (len(sig_better), sig_better))
    print('Holm-sig worse  (%d): %s' % (len(sig_worse), sig_worse))
    print()
    print('per-function med ratio:')
    for fn in fns:
        print('  F%d %.3f' % (fn, med[fn]))
if __name__=='__main__':
    main(sys.argv[1], sys.argv[2])
