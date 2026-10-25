#!/usr/bin/env python3
"""Integrated 3001-3030 comparison: Wilcoxon rank-sum + win/tie/loss.

Protocol: CEC2017, D=50, 100k true FE, N=50, seeds 3001-3030 (30 runs/arm),
29 functions (F1, F3-F30). All arms share the initial population and EvalProbe
accounting, so the comparison is like-for-like.

No multiple-comparison correction (user decision 2026-10-25). Two W/T/L
definitions are reported:

  SIG   (primary)  win  = p < 0.05 and median_A < median_B
                   loss = p < 0.05 and median_A > median_B
                   tie  = p >= 0.05
  MED   (secondary) ordinal comparison of medians, relative tolerance 1e-3

Outputs:
  master_3001.csv       870 x 45 matrix of final errors
  pairwise_raw.csv      all 990 ordered pairs, SIG counts + median ratio
  svad_vs_all.csv       SVAD-GWO against each of the other 44 arms
  friedman.csv          mean rank per arm
  per_function_svad.csv per-function medians and p for the main comparison set
"""
import sys, json, itertools
from pathlib import Path
import numpy as np, pandas as pd
from scipy.stats import mannwhitneyu, friedmanchisquare

ROOT = Path('sparse_q/reports/integrated_3001')
MASTER = ROOT/'master_3001.csv'
TOL = 1e-3
ALPHA = 0.05

def load():
    m = pd.read_csv(MASTER, index_col=[0,1])
    return m

def per_function(m, a, b):
    rows=[]
    for fn in sorted(m.index.get_level_values(0).unique()):
        x=m.loc[fn,a].to_numpy(float); y=m.loc[fn,b].to_numpy(float)
        mx,my=float(np.median(x)),float(np.median(y))
        try: p=float(mannwhitneyu(x,y,alternative='two-sided').pvalue)
        except Exception: p=1.0
        if p<ALPHA and mx<my:   tag='win'
        elif p<ALPHA and mx>my: tag='loss'
        else:                   tag='tie'
        scale=max(min(abs(mx),abs(my)),1e-12)
        med_tag='tie' if abs((my-mx)/scale)<=TOL else ('win' if my<mx else 'loss')
        rows.append(dict(fn=fn, med_a=mx, med_b=my, ratio=my/mx if mx else np.nan,
                         p=p, tag=tag, med_tag=med_tag))
    return pd.DataFrame(rows)

def counts(d):
    return dict(win=int((d.tag=='win').sum()), tie=int((d.tag=='tie').sum()),
                loss=int((d.tag=='loss').sum()),
                med_win=int((d.med_tag=='win').sum()),
                med_tie=int((d.med_tag=='tie').sum()),
                med_loss=int((d.med_tag=='loss').sum()),
                med_ratio=float(d.ratio.median()))

def main():
    m=load()
    algs=list(m.columns)
    fns=sorted(m.index.get_level_values(0).unique())
    print('master: %d runs x %d arms, %d functions, %d seeds'%(
        m.shape[0], len(algs), len(fns), m.index.get_level_values(1).nunique()))

    # ---- Friedman mean rank over all arms ----
    ranks=m.rank(axis=1,method='average').mean().sort_values()
    stat,pf=friedmanchisquare(*[m[a].to_numpy(float) for a in algs])
    fr=pd.DataFrame({'arm':ranks.index,'mean_rank':ranks.values})
    fr.to_csv(ROOT/'friedman.csv',index=False)
    print('\nFriedman chi2=%.1f p=%.3g'%(stat,pf))

    # ---- all ordered pairs ----
    rows=[]
    for a,b in itertools.combinations(algs,2):
        d=per_function(m,a,b); c=counts(d)
        rows.append(dict(A=a,B=b,**c))
        d2=per_function(m,b,a); c2=counts(d2)
        rows.append(dict(A=b,B=a,**c2))
    pr=pd.DataFrame(rows)
    pr.to_csv(ROOT/'pairwise_raw.csv',index=False)
    print('%d ordered pairs written'%len(pr))

    # ---- SVAD vs all (SVAD is A, so win = SVAD better) ----
    sv=pr[pr.A=='D-SVAD-GWO'].sort_values('med_ratio')
    sv.to_csv(ROOT/'svad_vs_all.csv',index=False)
    print('\nSVAD-GWO vs %d arms: total SIG win %d / tie %d / loss %d (of %d)'%(
        len(sv), sv.win.sum(), sv.tie.sum(), sv.loss.sum(), len(sv)*29))

    # ---- per-function detail for the main comparison set ----
    main_set=['GWO','IGWO','B-MENGWO','C-IAGWO','HAGWO','AOGWO','EDGWO',
              'PSO(classic)','CLPSO(2006)','SAQ-CSO','SPSO-2011-OfficialC',
              'HIDMS-PSO-IndexCorrected','DMS-PSO-SIS2005','HCLPSO-AuthorSource']
    main_set=[a for a in main_set if a in algs]
    det=[]
    for a in main_set:
        d=per_function(m,'D-SVAD-GWO',a); d.insert(0,'arm',a); det.append(d)
    pd.concat(det).to_csv(ROOT/'per_function_svad.csv',index=False)
    print('\nper-function detail for %d main-set arms written'%len(main_set))
    print('\nFriedman top-15:')
    print(fr.head(15).to_string(index=False,float_format=lambda v:'%.3f'%v))

if __name__=='__main__':
    main()
