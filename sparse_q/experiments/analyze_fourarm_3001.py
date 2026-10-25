#!/usr/bin/env python3
"""Four-arm 29x30 (seeds 3001-3030): GWO / MENGWO / IAGWO / SVAD-GWO.

Reports per-arm medians, paired per-function Wilcoxon + Holm vs SVAD-GWO and vs GWO,
Friedman mean rank, and cross-checks the GWO arm against the audited reference CSV.
"""
import sys, json
from pathlib import Path
import numpy as np, pandas as pd
from scipy.stats import wilcoxon, friedmanchisquare

ARMS=['A-GWO','B-MENGWO','C-IAGWO','D-SVAD-GWO']
SHORT={'A-GWO':'GWO','B-MENGWO':'MENGWO','C-IAGWO':'IAGWO','D-SVAD-GWO':'SVAD'}

def load(batch):
    df=pd.read_csv(Path(batch)/'runs.csv')
    df=df[df.Status=='ok']
    return df

def holm(ps, names, dl):
    ps=np.asarray(ps,float); order=np.argsort(ps); m=len(ps)
    adj=np.empty(m); run=0.0
    for i in range(m):
        v=ps[order[i]]*(m-i); run=max(run,v); adj[i]=run
    better=[];worse=[]
    for i in range(m):
        fn=names[order[i]]
        if adj[i]<0.05:
            (better if dl[fn]<0 else worse).append(int(fn))
    return better,worse,adj,order

def paired(df, a, b, out=None):
    x=df[df.Algorithm==a][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'})
    y=df[df.Algorithm==b][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'})
    j=x.merge(y,on=['FunctionID','Seed'],validate='one_to_one')
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
    better,worse,adj,order=holm(ps,names,dl)
    try: pcmp=float(wilcoxon(np.array([dl[f] for f in fns])).pvalue)
    except Exception: pcmp=1.0
    res=dict(num=b, den=a, nFunc=len(fns), nSeed=int(j.Seed.nunique()),
             medRatio=float(np.median(med.values)), wins=int((med<1).sum()),
             losses=int((med>1).sum()), cats=int((med>1.2).sum()),
             holmBetter=better, holmWorse=worse, compP=pcmp,
             perFunc={int(k):float(v) for k,v in med.items()})
    if out is not None: out.append(res)
    return res

def main():
    batch=sys.argv[1]
    df=load(batch)
    print('batch',batch)
    print(df.groupby('Algorithm').agg(n=('FinalError','size'),fn=('FunctionID','nunique'),
          sd=('Seed','nunique'),sec=('Seconds','mean')).to_string())
    # rank table
    piv=df.pivot_table(index=['FunctionID','Seed'],columns='Algorithm',values='FinalError')
    piv=piv[[a for a in ARMS if a in piv.columns]]
    ranks=piv.rank(axis=1,method='average')
    mr=ranks.mean()
    print('\nFriedman mean rank (1=best):')
    for a in mr.index: print('  %-12s %.3f'%(a,mr[a]))
    stat,pf=friedmanchisquare(*[piv[a].to_numpy(float) for a in piv.columns])
    print('  Friedman chi2=%.1f p=%.3g'%(stat,pf))
    out=[]
    print('\n=== paired vs D-SVAD-GWO ===')
    for a in ['A-GWO','B-MENGWO','C-IAGWO']:
        r=paired(df,'D-SVAD-GWO',a,out)
        print('%-10s medR=%.4f wins=%2d/%d losses=%2d cats=%2d p=%.4g Holm better=%d %s worse=%d %s'%(
            a,r['medRatio'],r['wins'],r['nFunc'],r['losses'],r['cats'],r['compP'],
            len(r['holmBetter']),r['holmBetter'],len(r['holmWorse']),r['holmWorse']))
    print('\n=== paired vs A-GWO ===')
    for a in ['B-MENGWO','C-IAGWO','D-SVAD-GWO']:
        r=paired(df,'A-GWO',a,out)
        print('%-10s medR=%.4f wins=%2d/%d losses=%2d cats=%2d p=%.4g Holm better=%d %s worse=%d %s'%(
            a,r['medRatio'],r['wins'],r['nFunc'],r['losses'],r['cats'],r['compP'],
            len(r['holmBetter']),r['holmBetter'],len(r['holmWorse']),r['holmWorse']))
    print('\nper-function median ratio (arm / D-SVAD-GWO):')
    fns=sorted(out[0]['perFunc'])
    print('Fn   '+''.join('%11s'%SHORT[a] for a in ['A-GWO','B-MENGWO','C-IAGWO']))
    for fn in fns:
        print('F%-3d '%fn+''.join('%11.3f'%out[i]['perFunc'][fn] for i in range(3)))
    # cross-check GWO arm vs audited reference
    ref=Path('data/reference/audited_10algo_30seed.csv')
    if ref.exists():
        rd=pd.read_csv(ref); rd=rd[rd.Algorithm=='GWO'][['FunctionID','Seed','FinalError']]
        g=df[df.Algorithm=='A-GWO'][['FunctionID','Seed','FinalError']]
        m=rd.merge(g,on=['FunctionID','Seed'],suffixes=('_ref','_new'))
        if len(m):
            d=np.abs(m.FinalError_ref-m.FinalError_new)/np.maximum(1,np.abs(m.FinalError_ref))
            print('\nGWO cross-check vs audited reference: n=%d  max rel diff=%.3g  median=%.3g'%(
                len(m), d.max(), d.median()))
    d=Path('sparse_q/reports/fourarm_3001_analysis'); d.mkdir(parents=True,exist_ok=True)
    json.dump(out,open(d/'summary.json','w'),indent=1)
    print('\nwrote',d/'summary.json')

if __name__=='__main__':
    main()
