#!/usr/bin/env python3
"""Analyze pre-registered CD-VACG P1 and matched A3-Off control."""
from __future__ import annotations
import json, sys
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT=Path(r"D:\111\Desktop\噜噜\拯救G2")
FUNCS=[7,10,13,16,18,22,24,30]
SEEDS=list(range(3131,3141))
FAMILIES={'simple_multimodal':[7,10],'hybrid':[13,16,18],'composition':[22,24,30]}

def latest(pat):
    d=sorted((ROOT/'sparse_q'/'results').glob(pat))
    if not d: raise SystemExit('missing '+pat)
    return d[-1]

def ratio(a,b):
    if b==0: return float('inf') if a>0 else 1.0
    return a/b

def holm(p):
    p=np.asarray(p,float); out=np.full_like(p,np.nan)
    idx=np.where(np.isfinite(p))[0]
    if not len(idx): return out
    order=idx[np.argsort(p[idx])]; prev=0.0; m=len(order)
    for rank,i in enumerate(order):
        v=min(1.0,(m-rank)*p[i]); v=max(v,prev); out[i]=v; prev=v
    return out

def pairwise(df,a,b):
    rows=[]
    for f in FUNCS:
        x=df[(df.Algorithm==a)&(df.FunctionID==f)].sort_values('Seed').FinalError.to_numpy(float)
        y=df[(df.Algorithm==b)&(df.FunctionID==f)].sort_values('Seed').FinalError.to_numpy(float)
        assert len(x)==len(y)==10
        try: stat,p=wilcoxon(x,y,alternative='two-sided',zero_method='wilcox',method='auto')
        except ValueError: stat,p=np.nan,np.nan
        rr=np.array([ratio(u,v) for u,v in zip(x,y)])
        rows.append(dict(comparison=f'{a} vs {b}',FunctionID=f,
                         median_A=float(np.median(x)),median_B=float(np.median(y)),
                         median_ratio=float(np.median(rr)),wins_A=int((rr<1).sum()),
                         losses_A=int((rr>1).sum()),p_raw=float(p) if np.isfinite(p) else np.nan,
                         stat=float(stat) if np.isfinite(stat) else np.nan))
    q=holm([r['p_raw'] for r in rows])
    for r,v in zip(rows,q): r['p_holm']=float(v) if np.isfinite(v) else np.nan
    return rows

def gate(med,a,b):
    rr=np.array([ratio(med.loc[f,a],med.loc[f,b]) for f in FUNCS])
    return dict(A=a,B=b,median_ratio=float(np.median(rr)),wins=int((rr<1).sum()),
                losses=int((rr>1).sum()),catastrophic_gt_1_20=int((rr>1.20).sum()),
                ratios={int(f):float(v) for f,v in zip(FUNCS,rr)})

def main():
    p1=latest('vacg_p1_*'); a3=latest('vacg_a3off_*')
    df=pd.read_csv(p1/'runs.csv'); off=pd.read_csv(a3/'runs.csv')
    rep=ROOT/'reports'/'vacg_p1_analysis'; rep.mkdir(parents=True,exist_ok=True)
    arms=['V1-Frozen','CD-VACG-MAD','CD-VACG-RandomSplit']
    assert sorted(df.FunctionID.unique().tolist())==FUNCS
    assert sorted(df.Seed.unique().tolist())==SEEDS
    assert set(df.Algorithm.unique())==set(arms)
    assert len(df)==240 and (df.Status=='ok').all() and (df.Evaluations==30000).all()
    assert len(off)==80 and (off.Status=='ok').all() and (off.Evaluations==30000).all()
    med=df.pivot_table(index='FunctionID',columns='Algorithm',values='FinalError',aggfunc='median').reindex(FUNCS)
    med.to_csv(rep/'per_function_final_error_median.csv')

    h1=gate(med,'CD-VACG-MAD','V1-Frozen')
    h2=gate(med,'CD-VACG-MAD','CD-VACG-RandomSplit')
    tests=pairwise(df,'CD-VACG-MAD','V1-Frozen')+pairwise(df,'CD-VACG-MAD','CD-VACG-RandomSplit')
    pd.DataFrame(tests).to_csv(rep/'pairwise_wilcoxon_holm.csv',index=False)

    m=df[df.Algorithm=='CD-VACG-MAD'].merge(off,on=['FunctionID','Seed'],suffixes=('_MAD','_A3'))
    run_ratio=m.Seconds_MAD/m.Seconds_A3
    runtime_mean=float(run_ratio.mean()); runtime_med=float(run_ratio.median())
    h1_pass=(h1['median_ratio']<=0.98 and h1['wins']>=6 and h1['catastrophic_gt_1_20']==0 and runtime_mean<=1.15)
    h2_pass=(h2['median_ratio']<=0.98 and h2['wins']>=6 and h2['catastrophic_gt_1_20']==0)

    proc_cols=['VACGGenCount','VACGLineCount','VACGEvalCount','VACGSuccessCount','VACGSuccessRate',
               'VACGArchiveImpCount','VACGImpMagMean','VACGLowFrac','VACGHighFrac','VACGCstarMeanRank']
    proc=df[df.Algorithm.str.startswith('CD-VACG')].groupby('Algorithm')[proc_cols].mean().T
    proc['A3Off_mean']=off[proc_cols].mean()
    proc.to_csv(rep/'process_metrics.csv')

    fam={}
    for name,fs in FAMILIES.items():
        r=np.array([ratio(med.loc[f,'CD-VACG-MAD'],med.loc[f,'V1-Frozen']) for f in fs])
        fam[name]=dict(functions=fs,median_ratio=float(np.median(r)),wins=int((r<1).sum()),losses=int((r>1).sum()))
    (rep/'family_summary.json').write_text(json.dumps(fam,indent=2,ensure_ascii=False),encoding='utf-8')

    summary=dict(results_dir=str(p1),a3off_dir=str(a3),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 H1=h1,H2=h2,runtime_ratio_MAD_over_A3=runtime_mean,
                 runtime_ratio_median=runtime_med,H1_pass=bool(h1_pass),H2_pass=bool(h2_pass),
                 families=fam,
                 verdict=('PROMOTE_VACG_TO_P2' if (h1_pass and h2_pass) else
                          ('GRAFTING_EFFECTIVE_MAD_NOT_PROVEN' if h1_pass else 'STOP_VACG_NEGATIVE')))
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')

    # plot
    fig,ax=plt.subplots(figsize=(9,4.8)); x=np.arange(len(FUNCS)); w=0.36
    ax.bar(x-w/2,[ratio(med.loc[f,'CD-VACG-MAD'],med.loc[f,'V1-Frozen']) for f in FUNCS],w,label='MAD/V1')
    ax.bar(x+w/2,[ratio(med.loc[f,'CD-VACG-MAD'],med.loc[f,'CD-VACG-RandomSplit']) for f in FUNCS],w,label='MAD/RandomSplit')
    ax.axhline(1,color='black',lw=1); ax.axhline(0.98,color='tab:green',ls='--',lw=1,label='0.98 gate')
    ax.axhline(1.20,color='tab:red',ls=':',lw=1,label='1.20 catastrophic')
    ax.set_yscale('log'); ax.set_xticks(x); ax.set_xticklabels([f'F{f}' for f in FUNCS])
    ax.set_ylabel('median final-error ratio (log scale)'); ax.set_title('CD-VACG P1: per-function median ratios')
    ax.legend(); fig.tight_layout(); fig.savefig(rep/'per_function_ratio.png',dpi=180); plt.close(fig)

    lines=['# CD-VACG P1 开发实验结果\n',
           f'- 主结果目录：`{p1}`',f'- A3-Off 目录：`{a3}`',
           '- 240 次主运行（V1、MAD、RandomSplit），80 次 matched A3-Off；失败 0；全部 30,000 真 FE','',
           '## 预注册门槛\n',
           f"- H1 MAD/V1：中位比 {h1['median_ratio']:.6g}，胜/负 {h1['wins']}/{h1['losses']}，>1.20 函数数 {h1['catastrophic_gt_1_20']}，运行时间 MAD/A3 {runtime_mean:.4g} → **{'通过' if h1_pass else '不通过'}**",
           f"- H2 MAD/RandomSplit：中位比 {h2['median_ratio']:.6g}，胜/负 {h2['wins']}/{h2['losses']}，>1.20 函数数 {h2['catastrophic_gt_1_20']} → **{'通过' if h2_pass else '不通过'}**",
           f"- **最终裁定：{summary['verdict']}**",'',
           '| F | V1 | MAD | RandomSplit | MAD/V1 | MAD/RS |','|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        lines.append(f"| {f} | {med.loc[f,'V1-Frozen']:.6g} | {med.loc[f,'CD-VACG-MAD']:.6g} | {med.loc[f,'CD-VACG-RandomSplit']:.6g} | {ratio(med.loc[f,'CD-VACG-MAD'],med.loc[f,'V1-Frozen']):.4g} | {ratio(med.loc[f,'CD-VACG-MAD'],med.loc[f,'CD-VACG-RandomSplit']):.4g} |")
    lines += ['','## 分函数族（MAD/V1 中位比）','']
    for k,v in fam.items(): lines.append(f"- {k}: 中位比 {v['median_ratio']:.4g}，胜/负 {v['wins']}/{v['losses']}")
    lines += ['','## 嫁接过程证据（均值）','',
              f"- MAD：生成 {df[df.Algorithm=='CD-VACG-MAD'].VACGGenCount.mean():.1f}，评价 {df[df.Algorithm=='CD-VACG-MAD'].VACGEvalCount.mean():.1f}，成功率 {df[df.Algorithm=='CD-VACG-MAD'].VACGSuccessRate.mean():.4f}",
              f"- RandomSplit：生成 {df[df.Algorithm=='CD-VACG-RandomSplit'].VACGGenCount.mean():.1f}，评价 {df[df.Algorithm=='CD-VACG-RandomSplit'].VACGEvalCount.mean():.1f}，成功率 {df[df.Algorithm=='CD-VACG-RandomSplit'].VACGSuccessRate.mean():.4f}",
              f"- MAD 档案插入/提升幅度：{df[df.Algorithm=='CD-VACG-MAD'].VACGArchiveImpCount.mean():.1f} / {df[df.Algorithm=='CD-VACG-MAD'].VACGImpMagMean.mean():.4g}",
              '','按预注册规则：H1 不通过则停止；H1 通过、H2 不通过则只能声称坐标嫁接有效。']
    (rep/'vacg_p1_report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)

if __name__=='__main__': main()
