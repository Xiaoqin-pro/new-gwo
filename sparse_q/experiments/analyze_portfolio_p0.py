#!/usr/bin/env python3
"""Dual-core portfolio P0 analysis."""
from pathlib import Path
import json, numpy as np, pandas as pd
from scipy.stats import wilcoxon
ROOT=Path(__file__).resolve().parents[2]
ARMS=['A-LSHADE','B-CMAES','C-Portfolio50']
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
    p=sorted((ROOT/'sparse_q'/'results').glob('portfolio_p0_*'))[-1]
    df=pd.read_csv(p/'runs.csv')
    assert len(df)==120 and set(df.Algorithm.unique())==set(ARMS)
    assert (df.Status=='ok').all() and (df.Evaluations==100000).all()
    out={}; pf=pd.DataFrame(index=FUNCS)
    for name,a,b in [('C_A','C-Portfolio50','A-LSHADE'),('C_B','C-Portfolio50','B-CMAES'),
                     ('B_A','B-CMAES','A-LSHADE')]:
        s,r=paired(df,a,b); out[name]=s; pf[name+'_ratio']=r
    med=df.pivot_table(index='FunctionID',columns='Algorithm',values='FinalError',aggfunc='median')
    best_single=np.minimum(med['A-LSHADE'],med['B-CMAES'])
    rbest=med['C-Portfolio50']/best_single
    sbest=dict(median=float(np.median(rbest)),wins=int((rbest<=1.05).sum()),worst_f=int(rbest.index[int(np.argmax(rbest))]),max=float(rbest.max()))
    sec=df.groupby('Algorithm').Seconds.mean(); rt=float(sec['C-Portfolio50']/sec['A-LSHADE'])
    gate=bool(out['C_A']['median']<=0.90 and out['C_A']['wins']>=6 and out['C_A']['cats']<=1
              and out['C_B']['median']<=1.00 and out['C_B']['wins']>=5
              and sbest['wins']>=5 and rt<=1.30)
    verdict='PROMOTE_PORTFOLIO_TO_P1' if gate else 'STOP_PORTFOLIO_P0'
    rep=ROOT/'reports'/'portfolio_p0_analysis'; rep.mkdir(parents=True,exist_ok=True)
    obj=dict(results_dir=str(p),comparisons=out,vs_best_single=sbest,runtime_C_over_A=rt,gate=gate,verdict=verdict,
             seconds=sec.to_dict())
    (rep/'summary.json').write_text(json.dumps(obj,indent=2,ensure_ascii=False),encoding='utf-8')
    pf['C_vs_best_single']=rbest
    pf.to_csv(rep/'per_function_ratio.csv')
    lines=['# Dual-Core Portfolio P0（8 函数 × 5 新种子 3879–3883，100k FE）','',
           f'- 结果目录：`{p}`（120 次运行，0 失败）','',
           '| 对比 | median | wins/8 | >1.20 | max | worst | p | 95% CI |',
           '|---|---:|---:|---:|---:|---:|---:|---:|']
    for name,label in [('C_A','C/A Portfolio/LSHADE'),('C_B','C/B Portfolio/CMA'),
                       ('B_A','B/A CMA/LSHADE')]:
        s=out[name]
        lines.append(f"| {label} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max']:.3f} | F{s['worst_f']} | {s['p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] |")
    lines += ['',f"- C 相对单核最好结果：median={sbest['median']:.4f}, <=1.05 wins={sbest['wins']}/8, max={sbest['max']:.3f}",
              f'- C/A 时间比：{rt:.3f}','',f'**判定：{verdict}**','']
    (rep/'report.md').write_text('\n'.join(lines),encoding='utf-8')
    print('\n'.join(lines))
if __name__=='__main__': main()
