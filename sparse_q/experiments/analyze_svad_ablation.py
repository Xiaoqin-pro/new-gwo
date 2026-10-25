#!/usr/bin/env python3
"""SVAD-GWO ablation analysis: Wilcoxon rank-sum + win/tie/loss.

Arms
  A-Full       reused from fourarm_3001 (D-SVAD-GWO, same seeds, verified
               reproducible point-by-point on the current code)
  B-Base       no archive, no differential
  C-Eonly      archive on, differential off
  D-Diffonly   differential on (wolves only), no archive
  E-NoSteer    STEER off, RNG draw schedule unchanged
  F-FixedDiff  F(t) fixed at 1.0

Protocol: CEC2017, D=50, 100k FE, N=50, seeds 3001-3030, 29 functions.
Primary statistic: Mann-Whitney U (two-sided, alpha=0.05), no correction,
win/tie/loss by median.  Paired signed-rank is reported as a sensitivity
check because both arms share the same initial population per seed.
"""
import sys, json
from pathlib import Path
import numpy as np, pandas as pd
from scipy.stats import mannwhitneyu, wilcoxon

SQ = Path(__file__).resolve().parents[1]
OUT = SQ/'reports'/'svad_ablation'
FULL = SQ/'results'/'fourarm_3001_20261025_010843'/'runs.csv'
ABL  = SQ/'results'/'svad_ablation_factorial_20261025_042121'/'runs.csv'
ALPHA = 0.05
LABELS = {'A-Full':'Full','B-Base':'NoE+NoDiff','C-Eonly':'E only',
          'D-Diffonly':'DiffA only','E-NoSteer':'NoSteer','F-FixedDiff':'FixedDiff'}

def load():
    f=pd.read_csv(FULL, low_memory=False)
    f=f[f.Algorithm=='D-SVAD-GWO'][['FunctionID','Seed','FinalError']].copy()
    f['Arm']='A-Full'
    a=pd.read_csv(ABL, low_memory=False)
    a=a[['FunctionID','Seed','FinalError','Algorithm']].rename(columns={'Algorithm':'Arm'})
    d=pd.concat([f,a],ignore_index=True)
    d=d.pivot_table(index=['FunctionID','Seed'],columns='Arm',values='FinalError')
    return d

def compare(d, arm, ref='A-Full'):
    rows=[]
    for fn in sorted(d.index.get_level_values(0).unique()):
        x=d.loc[fn,ref].to_numpy(float); y=d.loc[fn,arm].to_numpy(float)
        mx,my=float(np.median(x)),float(np.median(y))
        p=float(mannwhitneyu(x,y,alternative='two-sided').pvalue)
        try: pr=float(wilcoxon(x,y).pvalue)
        except Exception: pr=1.0
        tag='W' if (p<ALPHA and my>mx) else ('L' if (p<ALPHA and my<mx) else 'T')
        rows.append(dict(fn=fn, med_full=mx, med_arm=my, ratio=my/mx if mx else np.nan,
                         p=p, p_paired=pr, tag=tag))
    return pd.DataFrame(rows)

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    d=load()
    arms=[c for c in d.columns if c!='A-Full']
    print('matrix: %d (fn,seed) x %d arms'%(len(d),len(d.columns)))
    res=[]
    for arm in arms:
        t=compare(d,arm)
        # W/L are from the ARM's perspective: W means the ablated arm is WORSE
        # (removing the mechanism hurt), which is what we want to demonstrate.
        W=int((t.tag=='W').sum()); L=int((t.tag=='L').sum()); T=int((t.tag=='T').sum())
        r=dict(arm=arm, label=LABELS.get(arm,arm), W=W, T=T, L=L,
               med_ratio=float(t.ratio.median()),
               paired_W=int(((t.p_paired<ALPHA)&(t.ratio>1)).sum()),
               paired_L=int(((t.p_paired<ALPHA)&(t.ratio<1)).sum()),
               paired_T=int((t.p_paired>=ALPHA).sum()))
        res.append(r)
        t.insert(0,'arm',arm)
        t.to_csv(OUT/('per_function_%s.csv'%arm),index=False)
    summ=pd.DataFrame(res)
    summ.to_csv(OUT/'ablation_summary.csv',index=False)
    print()
    print('%-14s %-12s %4s %4s %4s %9s   paired(W/L/T)'%('arm','label','W','T','L','medR'))
    print('-'*72)
    for _,r in summ.iterrows():
        print('%-14s %-12s %4d %4d %4d %9.3f   %d/%d/%d'%(
            r['arm'],r['label'],r['W'],r['T'],r['L'],r['med_ratio'],
            r['paired_W'],r['paired_L'],r['paired_T']))
    print('\nW/T/L is from the ABLATED arm versus Full:')
    print('  W = ablated arm significantly worse  (the removed mechanism was contributing)')
    print('  L = ablated arm significantly better (the mechanism was not helping)')
    print('  T = no significant difference')

if __name__=='__main__':
    main()
