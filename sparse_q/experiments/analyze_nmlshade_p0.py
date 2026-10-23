#!/usr/bin/env python3
"""NMLSHADE P0: plateau migration with matched periodic/random controls."""
from pathlib import Path
import json, numpy as np, pandas as pd
from scipy.stats import wilcoxon
ROOT=Path(__file__).resolve().parents[2]
ARMS=['A-LS-Off','B-PeriodicNiche','C-PlateauRandom','D-PlateauNiche']
FUNCS=[1,4,7,10,13,20,24,30]

def paired(df,a,b):
    x=df[df.Algorithm==a][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'})
    y=df[df.Algorithm==b][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'})
    j=x.merge(y,on=['FunctionID','Seed'],validate='one_to_one')
    assert len(j)==40
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
    p=sorted((ROOT/'sparse_q'/'results').glob('nmlshade_p0_*'))[-1]
    df=pd.read_csv(p/'runs.csv')
    assert len(df)==160, len(df)
    assert set(df.Algorithm.unique())==set(ARMS)
    assert (df.Status=='ok').all() and (df.Evaluations==100000).all()
    assert set(df.FunctionID.unique())==set(FUNCS)
    out={}; pf=pd.DataFrame(index=FUNCS)
    for name,a,b in [('D_A','D-PlateauNiche','A-LS-Off'),
                     ('D_B','D-PlateauNiche','B-PeriodicNiche'),
                     ('D_C','D-PlateauNiche','C-PlateauRandom'),
                     ('B_A','B-PeriodicNiche','A-LS-Off'),
                     ('C_A','C-PlateauRandom','A-LS-Off')]:
        s,r=paired(df,a,b); out[name]=s; pf[name+'_ratio']=r
    sec=df.groupby('Algorithm').Seconds.mean(); rt=float(sec['D-PlateauNiche']/sec['A-LS-Off'])
    gate=bool(out['D_A']['median']<=0.98 and out['D_A']['wins']>=6 and out['D_A']['cats']<=1
              and out['D_B']['median']<=0.99 and out['D_C']['median']<=0.99 and rt<=1.20)
    verdict='PROMOTE_NMLSHADE_TO_P1' if gate else 'STOP_NMLSHADE_P0'
    diag={}
    for a in ARMS:
        g=df[df.Algorithm==a]
        diag[a]=dict(seconds_mean=float(g.Seconds.mean()), trig_mean=float(g.MigTriggers.mean()),
                     rounds_mean=float(g.MigRounds.mean()), migrants_mean=float(g.MigMigrants.mean()),
                     better_mean=float(g.MigBetter.mean()), bank_mean=float(g.MigBankSize.mean()),
                     hist_mean=float(g.MigHistSize.mean()))
    rep=ROOT/'reports'/'nmlshade_p0_analysis'; rep.mkdir(parents=True,exist_ok=True)
    obj=dict(results_dir=str(p),comparisons=out,runtime_D_over_A=rt,gate=gate,verdict=verdict,diagnostics=diag)
    (rep/'summary.json').write_text(json.dumps(obj,indent=2,ensure_ascii=False),encoding='utf-8')
    pf.to_csv(rep/'per_function_ratio.csv')
    lines=['# Niche-Migration L-SHADE P0（8 函数 × 5 新种子 3824–3828，100k FE）','',
           f'- 结果目录：`{p}`（160 次运行，0 失败）','',
           '| 对比 | median | wins/8 | >1.20 | max | worst | p | 95% CI |',
           '|---|---:|---:|---:|---:|---:|---:|---:|']
    for name,label in [('D_A','D/A 完整/原始'),('D_B','D/B 完整/周期迁移'),
                       ('D_C','D/C 完整/随机历史'),('B_A','B/A 周期迁移/原始'),
                       ('C_A','C/A 随机历史/原始')]:
        s=out[name]
        lines.append(f"| {label} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max']:.3f} | F{s['worst_f']} | {s['p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] |")
    lines += ['',f'- D/A 时间比：{rt:.3f}','','## 迁移过程量（均值）','',
              '| 臂 | triggers | rounds | migrants | better | bank | hist |',
              '|---|---:|---:|---:|---:|---:|---:|']
    for a in ARMS:
        d=diag[a]
        lines.append(f"| {a} | {d['trig_mean']:.2f} | {d['rounds_mean']:.2f} | {d['migrants_mean']:.2f} | {d['better_mean']:.2f} | {d['bank_mean']:.1f} | {d['hist_mean']:.1f} |")
    lines += ['',f'**判定：{verdict}**','']
    (rep/'report.md').write_text('\n'.join(lines),encoding='utf-8')
    print('\n'.join(lines))

if __name__=='__main__': main()
