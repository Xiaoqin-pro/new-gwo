#!/usr/bin/env python3
"""Analyze the pre-registered SFAC P1 batch and matched A3-off control."""
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
FUNCS=[7,10,13,14,16,18,22,24]
SEEDS=list(range(3121,3131))

def latest(pat):
    d=sorted((ROOT/'sparse_q'/'results').glob(pat))
    if not d: raise SystemExit(f'missing {pat}')
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

def main():
    p1=latest('sfac_p1_*'); a3=latest('sfac_a3off2_*')
    df=pd.read_csv(p1/'runs.csv'); off=pd.read_csv(a3/'runs.csv')
    rep=ROOT/'reports'/'sfac_p1_analysis'; rep.mkdir(parents=True,exist_ok=True)

    assert sorted(df.FunctionID.unique().tolist())==FUNCS
    assert sorted(df.Seed.unique().tolist())==SEEDS
    assert set(df.Algorithm.unique())=={'V1-Frozen','V1-SFAC'}
    assert len(df)==160 and (df.Status=='ok').all() and (df.Evaluations==30000).all()
    assert len(off)==80 and (off.Status=='ok').all() and (off.Evaluations==30000).all()
    assert sorted(off.FunctionID.unique().tolist())==FUNCS
    assert sorted(off.Seed.unique().tolist())==SEEDS

    med=df.pivot_table(index='FunctionID',columns='Algorithm',values='FinalError',aggfunc='median').reindex(FUNCS)
    med.to_csv(rep/'per_function_final_error_median.csv')
    rr=med['V1-SFAC']/med['V1-Frozen']
    h1_ratio=float(rr.median()); wins=int((rr<1).sum()); losses=int((rr>1).sum())
    catastrophic=int((rr>1.20).sum())

    # pairwise Wilcoxon + Holm
    rows=[]
    for f in FUNCS:
        x=df[(df.Algorithm=='V1-SFAC')&(df.FunctionID==f)].sort_values('Seed').FinalError.to_numpy(float)
        y=df[(df.Algorithm=='V1-Frozen')&(df.FunctionID==f)].sort_values('Seed').FinalError.to_numpy(float)
        try: stat,p=wilcoxon(x,y,alternative='two-sided',zero_method='wilcox',method='auto')
        except ValueError: stat,p=np.nan,np.nan
        rr_s=np.array([ratio(u,v) for u,v in zip(x,y)])
        rows.append(dict(FunctionID=f,median_SFAC=float(np.median(x)),median_V1=float(np.median(y)),
                         median_ratio=float(np.median(rr_s)),wins=int((rr_s<1).sum()),
                         losses=int((rr_s>1).sum()),p_raw=float(p) if np.isfinite(p) else np.nan,
                         stat=float(stat) if np.isfinite(stat) else np.nan))
    q=holm([r['p_raw'] for r in rows])
    for r,v in zip(rows,q): r['p_holm']=float(v) if np.isfinite(v) else np.nan
    pd.DataFrame(rows).to_csv(rep/'pairwise_wilcoxon_holm.csv',index=False)

    # runtime: pair SFAC and A3-off by function/seed
    m=df[df.Algorithm=='V1-SFAC'].merge(off,on=['FunctionID','Seed'],suffixes=('_SFAC','_A3'))
    run_ratio=m.Seconds_SFAC/m.Seconds_A3
    runtime_ratio=float(run_ratio.mean()); runtime_median=float(run_ratio.median())
    H1_pass=(h1_ratio<=0.98 and wins>=6 and catastrophic==0 and runtime_ratio<=1.15)

    # process metrics
    proc_cols=['ArcCredSum','ArcCredMax','ArcCredNonzero','ArcCredZeroFrac',
               'ArcGenCountTotal','ArcGenTopShare','ArcGenEntropy',
               'ArcEvalCountTotal','ArcEvalTopShare','ArcEvalEntropy','ArcEvalSuccessRate',
               'ArcStaleFeedback','ArcReplacementCount','SFACBoostCount','SFACDecayCount']
    sfac=df[df.Algorithm=='V1-SFAC']; 
    proc=pd.DataFrame({'SFAC_mean':sfac[proc_cols].mean(),'A3Off_mean':off[proc_cols].mean(),
                       'SFAC_median':sfac[proc_cols].median(),'A3Off_median':off[proc_cols].median()})
    proc.to_csv(rep/'process_metrics.csv')

    summary=dict(results_dir=str(p1),a3off_dir=str(a3),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 median_ratio=h1_ratio,wins=wins,losses=losses,catastrophic_gt_1_20=catastrophic,
                 runtime_ratio_SFAC_over_A3=runtime_ratio,runtime_ratio_median=runtime_median,
                 H1_pass=bool(H1_pass),verdict=('PROMOTE_SFAC_TO_P2' if H1_pass else 'STOP_SFAC_NEGATIVE'))
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')

    # plot
    fig,ax=plt.subplots(figsize=(8.5,4.5)); x=np.arange(len(FUNCS))
    ax.bar(x,rr.to_numpy(),0.55,label='SFAC / V1')
    ax.axhline(1,color='black',lw=1); ax.axhline(0.98,color='tab:green',ls='--',lw=1,label='0.98 gate')
    ax.axhline(1.20,color='tab:red',ls=':',lw=1,label='1.20 catastrophic')
    ax.set_xticks(x); ax.set_xticklabels([f'F{f}' for f in FUNCS]); ax.set_yscale('log')
    ax.set_ylabel('median final-error ratio (log scale)'); ax.set_title('SFAC P1: per-function median final-error ratio')
    ax.legend(); fig.tight_layout(); fig.savefig(rep/'per_function_ratio.png',dpi=180); plt.close(fig)

    lines=['# SFAC P1 开发实验结果\n',
           f'- 主结果目录：`{p1}`',
           f'- A3-Off 对照目录：`{a3}`',
           '- 160 次主运行（V1-Frozen、V1-SFAC），80 次 matched-scaffold A3-Off；失败 0；全部 30,000 真 FE','',
           '## 预注册门槛\n',
           f'- 最终误差中位比 SFAC/V1：{h1_ratio:.6g}',
           f'- 逐函数胜/负：{wins}/{losses}；>1.20 的函数数：{catastrophic}',
           f'- 运行时间 SFAC/A3-Off：均值 {runtime_ratio:.4g}，中位 {runtime_median:.4g}',
           f'- **H1 判定：{"通过" if H1_pass else "不通过"}**','',
           '| F | V1 median | SFAC median | SFAC/V1 |',
           '|---:|---:|---:|---:|']
    for f in FUNCS:
        lines.append(f'| {f} | {med.loc[f,"V1-Frozen"]:.6g} | {med.loc[f,"V1-SFAC"]:.6g} | {ratio(med.loc[f,"V1-SFAC"],med.loc[f,"V1-Frozen"]):.4g} |')
    lines += ['','## 机制行为（均值）','',
              f'- ArcCredZeroFrac：SFAC {sfac.ArcCredZeroFrac.mean():.4g} vs A3-Off {off.ArcCredZeroFrac.mean():.4g}',
              f'- ArcGenTopShare：SFAC {sfac.ArcGenTopShare.mean():.4g} vs A3-Off {off.ArcGenTopShare.mean():.4g}',
              f'- ArcGenEntropy：SFAC {sfac.ArcGenEntropy.mean():.4g} vs A3-Off {off.ArcGenEntropy.mean():.4g}',
              f'- ArcEvalTopShare：SFAC {sfac.ArcEvalTopShare.mean():.4g} vs A3-Off {off.ArcEvalTopShare.mean():.4g}',
              f'- ArcEvalSuccessRate：SFAC {sfac.ArcEvalSuccessRate.mean():.4g} vs A3-Off {off.ArcEvalSuccessRate.mean():.4g}',
              f'- SFAC boost/decay 事件：{sfac.SFACBoostCount.mean():.1f} / {sfac.SFACDecayCount.mean():.1f}',
              f'- ArcStaleFeedback：SFAC {sfac.ArcStaleFeedback.mean():.1f} vs A3-Off {off.ArcStaleFeedback.mean():.1f}','',
              '按预注册规则：H1 不通过则停止 SFAC，不扫描信用参数；H1 通过才进入正式确认。']
    (rep/'sfac_p1_report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)

if __name__=='__main__': main()
