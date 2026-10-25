#!/usr/bin/env python3
"""Final algorithm 29x30 ablation: new arms (A-Final/B-NoDiff/C-NoE/D-NoSteer)
paired with reused A0-GWOonly / A2-G1E from ablcore, same seeds 3071-3100."""
import sys
from pathlib import Path
import numpy as np, pandas as pd
from scipy.stats import wilcoxon

def ratio(a,b): return (np.asarray(a,float)+1e-8)/(np.asarray(b,float)+1e-8)

def paired_cmp(dfa, armA, dfb, armB, fns):
    a=dfa[dfa.Algorithm==armA][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'})
    b=dfb[dfb.Algorithm==armB][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'})
    j=a.merge(b,on=['FunctionID','Seed'])
    j=j[j.FunctionID.isin(fns)]
    j['r']=ratio(j.eb,j.ea)
    r=j.groupby('FunctionID').r.median()
    d=j.groupby('FunctionID').apply(lambda g: np.median(np.log10(ratio(g.eb,g.ea))),include_groups=False).to_numpy(float)
    try: pv=float(wilcoxon(d).pvalue)
    except ValueError: pv=float('nan')
    return dict(med=float(r.median()),wins=int((r<1).sum()),n=len(r),cats=int((r>1.2).sum()),p=pv)

def main(newdir, abldir, outdir):
    fns=[1]+list(range(3,31))
    dfn=pd.read_csv(Path(newdir)/'runs.csv')
    dfa=pd.read_csv(Path(abldir)/'runs.csv')
    rows={}
    # reuse: GWOonly = A0-GWOonly, G1E = A2-G1E (both 29x30 seeds 3071-3100)
    rows['A-Final vs GWOonly'] = paired_cmp(dfa,'A0-GWOonly', dfn,'A-Final', fns)
    rows['A-Final vs G1E']    = paired_cmp(dfa,'A2-G1E',    dfn,'A-Final', fns)
    rows['A-Final vs NoDiff']  = paired_cmp(dfn,'B-NoDiff',  dfn,'A-Final', fns)
    rows['A-Final vs NoE']     = paired_cmp(dfn,'C-NoE',     dfn,'A-Final', fns)
    rows['A-Final vs NoSteer'] = paired_cmp(dfn,'D-NoSteer', dfn,'A-Final', fns)
    Path(outdir).mkdir(parents=True,exist_ok=True)
    lines=['# 最终算法 29×30 消融（seeds 3071–3100，100k FE）','',
           f'- 新臂：`{newdir}`（{len(dfn)} 次）',
           f'- 复用对照：`{abldir}`（A0-GWOonly / A2-G1E，同种子）','',
           '| 对比 | median | wins/29 | >1.20 | p |','|---|---:|---:|---:|---:|']
    for k,v in rows.items():
        lines.append(f'| {k} | {v["med"]:.4f} | {v["wins"]}/{v["n"]} | {v["cats"]} | {v["p"]:.4f} |')
        print(f'{k}: med={v["med"]:.4f} wins={v["wins"]}/{v["n"]} cats={v["cats"]} p={v["p"]:.4f}')
    (Path(outdir)/'report.md').write_text('\n'.join(lines),encoding='utf-8')
    print('written', outdir)
if __name__=='__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3])
