#!/usr/bin/env python3
"""OBL initialization P1 replication."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np, pandas as pd
from scipy.stats import wilcoxon
ROOT=Path(__file__).resolve().parents[2]
FUNCS=[1,3,4,7,10,11,13,14,16,18,20,22,24,26,30]
SEEDS=list(range(3624,3634)); A_ARM,B_ARM='A-RandomInit','B-OBLInit'
def main():
    ds=sorted((ROOT/'sparse_q'/'results').glob('last_p1_*'))
    if not ds: raise SystemExit('missing last_p1_*')
    p=ds[-1]; df=pd.read_csv(p/'runs.csv')
    assert len(df)==300 and set(df.Algorithm.unique())=={A_ARM,B_ARM}
    assert sorted(df.FunctionID.unique().tolist())==FUNCS and sorted(df.Seed.unique().tolist())==SEEDS
    assert (df.Status=='ok').all() and (df.Evaluations==100000).all()
    x=df[df.Algorithm==A_ARM][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'})
    y=df[df.Algorithm==B_ARM][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'})
    j=x.merge(y,on=['FunctionID','Seed']); j['r']=j.ea/j.eb
    j['dl']=np.log10(np.maximum(j.ea,1e-12))-np.log10(np.maximum(j.eb,1e-12))
    pf=j.groupby('FunctionID').r.median(); r=pf.to_numpy(float)
    d=j.groupby('FunctionID').dl.median().to_numpy(float)
    try: pv=float(wilcoxon(d).pvalue)
    except ValueError: pv=float('nan')
    rng=np.random.default_rng(20261023)
    boot=np.array([np.median(rng.choice(r,len(r),replace=True)) for _ in range(5000)])
    s=dict(median=float(np.median(r)),wins=int((r<1).sum()),cats=int((r>1.2).sum()),max_ratio=float(r.max()),
           worst_f=int(pf.index[int(np.argmax(r))]),p=pv,ci95=[float(np.percentile(boot,2.5)),float(np.percentile(boot,97.5))])
    sec=df.groupby('Algorithm').Seconds.mean(); rt=float(sec[B_ARM]/sec[A_ARM])
    gate=bool(s['median']<=.98 and s['wins']>=11 and s['cats']==0 and rt<=1.15)
    verdict='PROMOTE_LAST_TO_CONFIRM' if gate else 'STOP_LAST_P1'
    rep=ROOT/'reports'/'last_p1_analysis'; rep.mkdir(parents=True,exist_ok=True)
    out=dict(results_dir=str(p),**s,runtime=rt,gate=gate,verdict=verdict)
    (rep/'summary.json').write_text(json.dumps(out,indent=2,ensure_ascii=False),encoding='utf-8')
    pd.DataFrame({'B/A':pf}).to_csv(rep/'per_function_ratio.csv')
    lines=['# OBL 初始化 P1（15 函数 × 10 新种子 3624–3633，100k FE）','',
           f'- 结果目录：`{p}`（300 次运行，0 失败）','',
           '| 对比 | 中位比 | 胜/15 | >1.20 | 最大 | 最差函数 | p | 95% CI | 时间比 |',
           '|---|---:|---:|---:|---:|---:|---:|---:|---:|',
           f"| B OBL / A random | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max_ratio']:.3f} | F{s['worst_f']} | {s['p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] | {rt:.3f} |",
           '',f'**判定：{verdict}**','']
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines))
if __name__=='__main__': main()
