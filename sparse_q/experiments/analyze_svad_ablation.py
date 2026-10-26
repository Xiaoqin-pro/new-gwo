#!/usr/bin/env python3
"""SVAD-GWO ablation: rank-sum + win/tie/loss, across filler definitions.

Compares each ablated arm against Full (reused from fourarm_3001) using
Mann-Whitney U, alpha=0.05, no correction, direction by median.

Two filler definitions are reported side by side:
  Alpha-shell filler : 'B-Base' / 'C-Eonly'   (screen299 batch)
  GWO filler         : 'B-BaseG' / 'C-EonlyG' (screen301 batch)

W/T/L is counted from the ABLATED arm: W = ablated arm significantly worse,
i.e. the removed mechanism was contributing.
"""
import sys
from pathlib import Path
import numpy as np, pandas as pd
from scipy.stats import mannwhitneyu, wilcoxon

SQ = Path(__file__).resolve().parents[1]
OUT = SQ/'reports'/'svad_ablation'
FULL = SQ/'results'/'fourarm_3001_20261025_010843'/'runs.csv'
S299 = SQ/'results'/'svad_ablation_factorial_20261025_042121'/'runs.csv'
S301 = next(SQ.glob('results/uniform_filler_factorial_*/runs.csv'), None)
ALPHA = 0.05

def full_arm():
    f=pd.read_csv(FULL, low_memory=False)
    f=f[f.Algorithm=='D-SVAD-GWO'][['FunctionID','Seed','FinalError']]
    return f.rename(columns={'FinalError':'Full'}).set_index(['FunctionID','Seed'])['Full']

def batch(p):
    a=pd.read_csv(p, low_memory=False)
    return a.pivot_table(index=['FunctionID','Seed'],columns='Algorithm',values='FinalError')

def compare(full, arm_series):
    rows=[]
    for fn in sorted(full.index.get_level_values(0).unique()):
        x=full.loc[fn].to_numpy(float); y=arm_series.loc[fn].to_numpy(float)
        mx,my=float(np.median(x)),float(np.median(y))
        p=float(mannwhitneyu(x,y,alternative='two-sided').pvalue)
        try: pr=float(wilcoxon(x,y).pvalue)
        except Exception: pr=1.0
        tag='W' if (p<ALPHA and my>mx) else ('L' if (p<ALPHA and my<mx) else 'T')
        rows.append(dict(fn=fn, med_full=mx, med_arm=my,
                         ratio=my/mx if mx else np.nan, p=p, p_paired=pr, tag=tag))
    return pd.DataFrame(rows)

def summarize(t, label):
    return dict(arm=label, W=int((t.tag=='W').sum()), T=int((t.tag=='T').sum()),
                L=int((t.tag=='L').sum()), med_ratio=float(t.ratio.median()),
                pW=int(((t.p_paired<ALPHA)&(t.ratio>1)).sum()),
                pL=int(((t.p_paired<ALPHA)&(t.ratio<1)).sum()),
                pT=int((t.p_paired>=ALPHA).sum()))

def main():
    full=full_arm()
    arms=[]
    s299=batch(S299)
    for c,lab in [('B-Base','Base [alpha-shell filler]'),
                  ('C-Eonly','E-only [alpha-shell filler]'),
                  ('D-Diffonly','DiffA-only'),
                  ('E-NoSteer','NoSteer'),
                  ('F-FixedDiff','FixedDiff')]:
        if c in s299.columns: arms.append((c,lab,s299[c]))
    if S301 is not None:
        s301=batch(S301)
        for c,lab in [('B-BaseG','Base [GWO filler]'),
                      ('C-EonlyG','E-only [GWO filler]')]:
            if c in s301.columns: arms.append((c,lab,s301[c]))
    res=[]; print('%-26s %-28s %3s %3s %3s %8s  paired W/L/T'%('arm','label','W','T','L','medR'))
    print('-'*86)
    for c,lab,s in arms:
        j=full.to_frame('Full').join(s.rename('Arm'),how='inner')
        t=compare(j['Full'], j['Arm'])
        t.insert(0,'arm',c)
        t.to_csv(OUT/('per_function_%s.csv'%c),index=False)
        r=summarize(t,lab); r['col']=c; res.append(r)
        print('%-26s %-28s %3d %3d %3d %8.3f  %d/%d/%d'%(
            c,lab,r['W'],r['T'],r['L'],r['med_ratio'],r['pW'],r['pL'],r['pT']))
    pd.DataFrame(res).to_csv(OUT/'ablation_summary_all.csv',index=False)
    print('\nW = ablated arm significantly worse (mechanism was contributing)')
    print('L = ablated arm significantly better')

if __name__=='__main__':
    main()
