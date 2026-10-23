#!/usr/bin/env python3
"""Sparse L-SHADE P0: dense/random/near/dual screening."""
from pathlib import Path
import json, numpy as np, pandas as pd
from scipy.stats import wilcoxon
ROOT=Path(__file__).resolve().parents[2]
ARMS=['A-Dense','B-RandomK','C-NearK','D-DualK']
FUNCS=[1,4,7,10,13,20,24,30]

def paired(df,a,b):
    x=df[df.Algorithm==a][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'})
    y=df[df.Algorithm==b][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'})
    j=x.merge(y,on=['FunctionID','Seed'],validate='one_to_one'); assert len(j)==40
    j['r']=j.ea/j.eb
    j['dl']=np.log10(np.maximum(j.ea,1e-12))-np.log10(np.maximum(j.eb,1e-12))
    pf=j.groupby('FunctionID').r.median(); d=j.groupby('FunctionID').dl.median().to_numpy(float)
    try: p=float(wilcoxon(d).pvalue)
    except ValueError: p=float('nan')
    r=pf.to_numpy(float); rng=np.random.default_rng(20261023)
    boot=np.array([np.median(rng.choice(r,len(r),replace=True)) for _ in range(5000)])
    return dict(median=float(np.median(r)),wins=int((r<1).sum()),cats=int((r>1.2).sum()),
                max=float(r.max()),worst_f=int(pf.index[int(np.argmax(r))]),p=p,
                ci95=[float(np.percentile(boot,2.5)),float(np.percentile(boot,97.5))]),pf

def main():
    p=sorted((ROOT/'sparse_q'/'results').glob('slshade_p0_*'))[-1]
    df=pd.read_csv(p/'runs.csv')
    assert len(df)==160, len(df)
    assert set(df.Algorithm.unique())==set(ARMS)
    assert (df.Status=='ok').all() and (df.Evaluations==100000).all()
    assert set(df.FunctionID.unique())==set(FUNCS)
    out={}; pf=pd.DataFrame(index=FUNCS)
    for name,a,b in [('D_A','D-DualK','A-Dense'),('D_B','D-DualK','B-RandomK'),
                     ('D_C','D-DualK','C-NearK'),('B_A','B-RandomK','A-Dense'),
                     ('C_A','C-NearK','A-Dense')]:
        s,r=paired(df,a,b); out[name]=s; pf[name+'_ratio']=r
    sec=df.groupby('Algorithm').Seconds.mean(); rt=float(sec['D-DualK']/sec['A-Dense'])
    gate=bool(out['D_A']['median']<=0.98 and out['D_A']['wins']>=6 and out['D_A']['cats']<=1
              and out['D_B']['median']<=0.99 and out['D_C']['median']<=0.99 and rt<=1.60)
    verdict='PROMOTE_SLSHADE_TO_P1' if gate else 'STOP_SLSHADE_P0'
    diag={}
    for a in ARMS:
        g=df[df.Algorithm==a]
        diag[a]=dict(seconds_mean=float(g.Seconds.mean()), rounds_mean=float(g.Rounds.mean()),
                     generated_mean=float(g.TrialsGenerated.mean()), selected_mean=float(g.TrialsSelected.mean()),
                     near_mean=float(g.NearSelected.mean()), far_mean=float(g.FarSelected.mean()))
    rep=ROOT/'reports'/'slshade_p0_analysis'; rep.mkdir(parents=True,exist_ok=True)
    obj=dict(results_dir=str(p),comparisons=out,runtime_D_over_A=rt,gate=gate,verdict=verdict,diagnostics=diag)
    (rep/'summary.json').write_text(json.dumps(obj,indent=2,ensure_ascii=False),encoding='utf-8')
    pf.to_csv(rep/'per_function_ratio.csv')
    lines=['# Sparse L-SHADE P0（8 函数 × 5 新种子 3839–3843，100k FE）','',
           f'- 结果目录：`{p}`（160 次运行，0 失败）','',
           '| 对比 | median | wins/8 | >1.20 | max | worst | p | 95% CI |',
           '|---|---:|---:|---:|---:|---:|---:|---:|']
    for name,label in [('D_A','D/A 两势/稠密'),('D_B','D/B 两势/随机K'),
                       ('D_C','D/C 两势/近端K'),('B_A','B/A 随机K/稠密'),
                       ('C_A','C/A 近端K/稠密')]:
        s=out[name]
        lines.append(f"| {label} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max']:.3f} | F{s['worst_f']} | {s['p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] |")
    lines += ['',f'- D/A 时间比：{rt:.3f}','','## 筛选过程量（均值）','',
              '| 臂 | seconds | rounds | trials | selected | near | far |',
              '|---|---:|---:|---:|---:|---:|---:|']
    for a in ARMS:
        d=diag[a]
        lines.append(f"| {a} | {d['seconds_mean']:.3f} | {d['rounds_mean']:.1f} | {d['generated_mean']:.1f} | {d['selected_mean']:.1f} | {d['near_mean']:.1f} | {d['far_mean']:.1f} |")
    lines += ['',f'**判定：{verdict}**','']
    (rep/'report.md').write_text('\n'.join(lines),encoding='utf-8')
    print('\n'.join(lines))

if __name__=='__main__': main()
