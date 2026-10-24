#!/usr/bin/env python3
"""Diff-GWO 29x30 confirmation: B-DiffAll (new batch) vs A-Final-SteerOn (reused steer_robust)."""
from pathlib import Path
import json, sys, numpy as np, pandas as pd
from scipy.stats import wilcoxon
ROOT=Path(__file__).resolve().parents[2]
def ratio(a,b):
    a=np.asarray(a,float); b=np.asarray(b,float); return (a+1e-8)/(b+1e-8)
def main(bdir, adir, outdir):
    dfb=pd.read_csv(bdir/'runs.csv')
    dfa=pd.read_csv(adir/'runs.csv')
    assert (dfb.Status=='ok').all() and (dfb.Evaluations==100000).all()
    a=dfa[dfa.Algorithm=='A-Final-SteerOn'][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'})
    b=dfb[['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'})
    j=b.merge(a,on=['FunctionID','Seed'],validate='one_to_one')
    assert len(j)==len(dfb), f'merge mismatch: {len(j)} vs {len(dfb)}'
    j['r']=ratio(j.eb,j.ea)
    r=j.groupby('FunctionID').r.median()
    d=j.groupby('FunctionID').apply(lambda g: np.median(np.log10(ratio(g.eb,g.ea))),include_groups=False).to_numpy(float)
    try: pv=float(wilcoxon(d).pvalue)
    except ValueError: pv=float('nan')
    res=dict(median=float(r.median()),wins=int((r<1).sum()),n=len(r),cats=int((r>1.2).sum()),p=pv,
             per={int(k):float(v) for k,v in r.items()},worst_f=int(r.idxmax()),best_f=int(r.idxmin()))
    outdir.mkdir(parents=True,exist_ok=True)
    (outdir/'summary.json').write_text(json.dumps(res,indent=2,ensure_ascii=False),encoding='utf-8')
    lines=['# Diff-GWO 29×30 确认（B-DiffAll vs 复用 A-Final-SteerOn，seeds 3459–3488，100k FE）','',
           f'- B 批：`{bdir}`（{len(dfb)} 次，0 失败）',
           f'- A 臂复用：`{adir}` steer_robust A-Final-SteerOn（同种子）',
           '',f'| 指标 | 值 |','|---|---:|',
           f'| B/A 函数级中位比 | {res["median"]:.4f} |',
           f'| 胜/29 | {res["wins"]}/{res["n"]} |',
           f'| \\>1.20 | {res["cats"]} |',
           f'| worst | F{res["worst_f"]} ({r[res["worst_f"]]:.2f}) |',
           f'| best | F{res["best_f"]} ({r[res["best_f"]]:.4f}) |',
           f'| Wilcoxon p | {res["p"]:.4f} |','']
    (outdir/'report.md').write_text('\n'.join(lines),encoding='utf-8')
    print(f'B/A: med={res["median"]:.4f} wins={res["wins"]}/29 cats={res["cats"]} p={res["p"]:.4f} worst=F{res["worst_f"]}({r[res["worst_f"]]:.2f})')
    for fn in [1,3,18,24,26,30]:
        print(f'  F{fn}: {r[fn]:.4f}')
if __name__=='__main__':
    main(Path(sys.argv[1]),Path(sys.argv[2]),Path(sys.argv[3]))
