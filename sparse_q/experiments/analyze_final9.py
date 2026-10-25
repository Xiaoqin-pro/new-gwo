#!/usr/bin/env python3
"""Final nine-arm paper table: SVAD-GWO vs 8 baselines.

Arms (display order):
  SVAD-GWO, GWO, IGWO, MENGWO, IAGWO, CLPSO, AOGWO, HCLPSO, HAGWO

Protocol: CEC2017, D=50, 100k true FE, N=50, seeds 3001-3030 (30 runs),
29 functions (F1, F3-F30). Statistic: Wilcoxon rank-sum (Mann-Whitney U,
two-sided), no multiple-comparison correction; win/tie/loss per function.

CLPSO note: two reproductions exist -- the archived main-table version
(CLPSO-AuthorSource, per registry USER-DECISION-CLPSO) and a strict N=50
rebuild. They are statistically indistinguishable (per-function median ratio
1.013, max per-run relative difference 38x but median 11%), so the archived
version is reported and the N=50 rebuild is kept as a sensitivity check.

Outputs (sparse_q/reports/final9/):
  per_function_stats.csv   mean/std/median per arm per function
  wlt_vs_svad.csv          win/tie/loss + p per arm per function
  summary.csv              one row per arm
  table_main.tex           main results table
  table_wlt.tex            win/tie/loss summary table
"""
import sys, json
from pathlib import Path
import numpy as np, pandas as pd
from scipy.stats import mannwhitneyu, friedmanchisquare

SQ = Path(__file__).resolve().parents[1]
OUT = SQ/'reports'/'final9'
MASTER = SQ/'reports'/'integrated_3001'/'master_3001.csv'
ALPHA = 0.05

ARMS = [
    ('D-SVAD-GWO',            'SVAD-GWO', 'proposed'),
    ('GWO',                   'GWO',      '2014'),
    ('IGWO',                  'IGWO',     '2021'),
    ('B-MENGWO',              'MENGWO',   '2025'),
    ('C-IAGWO',               'IAGWO',    '2024'),
    ('CLPSO-AuthorSource',    'CLPSO',    '2006'),
    ('AOGWO',                 'AOGWO',    '2026'),
    ('HCLPSO-AuthorSource',   'HCLPSO',   '2015'),
    ('HAGWO',                 'HAGWO',    '2026'),
]
PROPOSED = 'D-SVAD-GWO'

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    m = pd.read_csv(MASTER, index_col=[0,1])
    cols = [a for a,_ ,_ in ARMS]
    missing = [c for c in cols if c not in m.columns]
    assert not missing, missing
    d = m[cols]
    fns = sorted(d.index.get_level_values(0).unique())
    assert len(fns)==29 and d.index.get_level_values(1).nunique()==30

    # ---- per-function mean / std / median ----
    rows=[]
    for fn in fns:
        for src,label,_ in ARMS:
            v=d.loc[fn,src].to_numpy(float)
            rows.append(dict(fn=fn, arm=label, mean=v.mean(), std=v.std(ddof=1),
                             median=float(np.median(v))))
    pf=pd.DataFrame(rows)
    pf.to_csv(OUT/'per_function_stats.csv', index=False)

    # ---- win/tie/loss vs proposed ----
    wrows=[]
    for src,label,_ in ARMS:
        if src==PROPOSED: continue
        for fn in fns:
            x=d.loc[fn,PROPOSED].to_numpy(float)
            y=d.loc[fn,src].to_numpy(float)
            mx,my=float(np.median(x)),float(np.median(y))
            try: p=float(mannwhitneyu(x,y,alternative='two-sided').pvalue)
            except Exception: p=1.0
            if p<ALPHA and mx<my:   tag='W'
            elif p<ALPHA and mx>my: tag='L'
            else:                   tag='T'
            wrows.append(dict(fn=fn, arm=label, med_svad=mx, med_arm=my,
                              ratio=my/mx if mx else np.nan, p=p, tag=tag))
    wl=pd.DataFrame(wrows)
    wl.to_csv(OUT/'wlt_vs_svad.csv', index=False)

    # ---- summary ----
    ranks=d.rank(axis=1, method='average').mean()
    stat,pf_test=friedmanchisquare(*[d[c].to_numpy(float) for c in cols])
    srows=[]
    for src,label,yr in ARMS:
        v=d[src]
        r=dict(arm=label, source=src, year=yr, rank=float(ranks[src]),
               median=float(v.median()), mean=float(v.mean()),
               gmean=float(np.exp(np.log(v+1e-8).mean())))
        if src!=PROPOSED:
            g=wl[wl.arm==label]
            r.update(W=int((g.tag=='W').sum()), T=int((g.tag=='T').sum()),
                     L=int((g.tag=='L').sum()),
                     med_ratio=float(g.ratio.median()))
        srows.append(r)
    summ=pd.DataFrame(srows).sort_values('rank')
    summ.to_csv(OUT/'summary.csv', index=False)

    print('Friedman chi2=%.2f p=%.3g (9 arms)'%(stat,pf_test))
    print(summ.to_string(index=False, float_format=lambda v:'%.4g'%v))
    print()
    print('W/T/L of SVAD-GWO against each baseline (29 functions):')
    for _,r in summ.iterrows():
        if r['arm']=='SVAD-GWO': continue
        print('  vs %-8s W=%2d T=%2d L=%2d  median ratio=%.3f'%(
            r['arm'], int(r['W']), int(r['T']), int(r['L']), float(r['med_ratio'])))

    # ---- LaTeX: main table (median per function, bold best) ----
    piv=d.groupby(level=0).median()
    labels=[l for _,l,_ in ARMS]
    def fmt(v):
        if v==0: return '0'
        if abs(v)>=1e4 or abs(v)<1e-2:
            e=int(np.floor(np.log10(abs(v))))
            mant=v/10**e
            return r'%.3f$\times10^{%d}$'%(mant,e)
        return '%.3f'%v
    lines=[]
    lines.append(r'\begin{table*}[t]')
    lines.append(r'\centering')
    lines.append(r'\caption{Median final error over 30 independent runs (CEC2017, $D=50$, $10^5$ FE). Best per function in bold.}')
    lines.append(r'\label{tab:main}')
    lines.append(r'\begin{tabular}{c'+'c'*len(ARMS)+'}')
    lines.append(r'\hline')
    lines.append('F & '+' & '.join(labels)+r' \\')
    lines.append(r'\hline')
    for fn in fns:
        vals=[piv.loc[fn,a] for a in cols]
        best=min(vals)
        cells=[]
        for v in vals:
            t=fmt(v)
            cells.append(r'\textbf{'+t+'}' if v==best else t)
        lines.append('F%d & '%fn+' & '.join(cells)+r' \\')
    lines.append(r'\hline')
    lines.append(r'\end{tabular}')
    lines.append(r'\end{table*}')
    (OUT/'table_main.tex').write_text('\n'.join(lines), encoding='utf-8')

    # ---- LaTeX: W/T/L summary ----
    lines=[r'\begin{table}[t]', r'\centering',
           r'\caption{Wilcoxon rank-sum test of SVAD-GWO against each baseline over 29 functions (30 runs each, $\alpha=0.05$, no multiple-comparison correction).}',
           r'\label{tab:wlt}',
           r'\begin{tabular}{lcccc}', r'\hline',
           r'Algorithm & Win & Tie & Loss & Median ratio \\', r'\hline']
    order=list(summ[summ['arm']=='SVAD-GWO'].index)+\
          list(summ[summ['arm']!='SVAD-GWO'].sort_values('med_ratio',ascending=False).index)
    for i in order:
        r=summ.loc[i]
        if r['arm']=='SVAD-GWO':
            lines.append(r'\textbf{SVAD-GWO} & -- & -- & -- & 1.000 \\')
        else:
            lines.append('%s & %d & %d & %d & %.3f \\\\'%(
                r['arm'], int(r['W']), int(r['T']), int(r['L']), float(r['med_ratio'])))
    lines += [r'\hline', r'\end{tabular}', r'\end{table}']
    (OUT/'table_wlt.tex').write_text('\n'.join(lines), encoding='utf-8')
    # ---- LaTeX: mean +- std table ----
    means=d.groupby(level=0).mean(); stds=d.groupby(level=0).std(ddof=1)
    lines=[r'\begin{table*}[t]', r'\centering',
           r'\caption{Mean $\pm$ standard deviation of the final error over 30 runs (CEC2017, $D=50$, $10^5$ FE). Best mean per function in bold.}',
           r'\label{tab:meanstd}',
           r'\begin{tabular}{c'+'c'*len(ARMS)+'}', r'\hline',
           'F & '+' & '.join(labels)+r' \\', r'\hline']
    for fn in fns:
        vals=[means.loc[fn,a] for a in cols]
        best=min(vals); cells=[]
        for a,v in zip(cols,vals):
            t=r'%.3e$\pm$%.1e'%(v,stds.loc[fn,a])
            cells.append(r'\textbf{'+t+'}' if v==best else t)
        lines.append('F%d & '%fn+' & '.join(cells)+r' \\')
    lines += [r'\hline', r'\end{tabular}', r'\end{table*}']
    (OUT/'table_meanstd.tex').write_text('\n'.join(lines), encoding='utf-8')

    # ---- per-function best counts ----
    pivm=d.groupby(level=0).median()
    win_counts={l:0 for _,l,_ in ARMS}
    for fn in fns:
        vals=[pivm.loc[fn,a] for a in cols]
        win_counts[ARMS[int(np.argmin(vals))][1]] += 1
    print('\nfunctions where each arm has the best median (of %d):'%len(fns))
    for k,v in sorted(win_counts.items(), key=lambda x:-x[1]):
        print('  %-9s %d'%(k,v))
    json.dump(win_counts, open(OUT/'best_counts.json','w'), indent=1)

    print('\nwrote tables:', ', '.join(p.name for p in sorted(OUT.glob('table_*.tex'))))

if __name__=='__main__':
    main()
