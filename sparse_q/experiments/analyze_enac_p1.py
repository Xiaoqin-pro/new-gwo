#!/usr/bin/env python3
"""Analyze pre-registered ENAC P1 and matched A3-Off control."""
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
SEEDS=list(range(3151,3161))
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
    p1=latest('enac_p1_*')
    a3c=sorted((ROOT/'sparse_q'/'results').glob('enac_a3offc_*'))
    a3=a3c[-1] if a3c else latest('enac_a3off_*')
    df=pd.read_csv(p1/'runs.csv'); off=pd.read_csv(a3/'runs.csv')
    rep=ROOT/'reports'/'enac_p1_analysis'; rep.mkdir(parents=True,exist_ok=True)
    arms=['V1-Frozen','Identity-Credit','ENAC']
    assert sorted(df.FunctionID.unique().tolist())==FUNCS
    assert sorted(df.Seed.unique().tolist())==SEEDS
    assert set(df.Algorithm.unique())==set(arms)
    assert len(df)==240 and (df.Status=='ok').all() and (df.Evaluations==30000).all()
    assert len(off)==80 and (off.Status=='ok').all() and (off.Evaluations==30000).all()
    med=df.pivot_table(index='FunctionID',columns='Algorithm',values='FinalError',aggfunc='median').reindex(FUNCS)
    med.to_csv(rep/'per_function_final_error_median.csv')

    h1=gate(med,'ENAC','V1-Frozen')
    h2=gate(med,'ENAC','Identity-Credit')
    tests=pairwise(df,'ENAC','V1-Frozen')+pairwise(df,'ENAC','Identity-Credit')
    pd.DataFrame(tests).to_csv(rep/'pairwise_wilcoxon_holm.csv',index=False)

    m=df[df.Algorithm=='ENAC'].merge(off,on=['FunctionID','Seed'],suffixes=('_ENAC','_A3'))
    run_ratio=m.Seconds_ENAC/m.Seconds_A3
    runtime_mean=float(run_ratio.mean()); runtime_med=float(run_ratio.median())
    h1_pass=(h1['median_ratio']<=0.98 and h1['wins']>=6 and h1['catastrophic_gt_1_20']==0 and runtime_mean<=1.15)
    h2_pass=(h2['median_ratio']<=0.98 and h2['wins']>=6 and h2['catastrophic_gt_1_20']==0)

    proc_cols=['EnacMeanTopRatio','EnacMeanWeightEntropy','EnacCenterEvalTotal','EnacCenterSuccTotal',
               'EnacCenterSuccessRate','EnacDroppedFeedback','EnacEImpPer1000FE','EnacEEvalCount','EnacEImpCnt']
    proc=df.groupby('Algorithm')[proc_cols].mean().T
    proc['A3Off_mean']=off[proc_cols].mean()
    proc.to_csv(rep/'process_metrics.csv')

    fam={}
    for name,fs in FAMILIES.items():
        r=np.array([ratio(med.loc[f,'ENAC'],med.loc[f,'V1-Frozen']) for f in fs])
        fam[name]=dict(functions=fs,median_ratio=float(np.median(r)),wins=int((r<1).sum()),losses=int((r>1).sum()))
    (rep/'family_summary.json').write_text(json.dumps(fam,indent=2,ensure_ascii=False),encoding='utf-8')

    h_identity=gate(med,'Identity-Credit','V1-Frozen')
    summary=dict(results_dir=str(p1),a3off_dir=str(a3),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 H1=h1,H2=h2,identity_vs_V1=h_identity,runtime_ratio_ENAC_over_A3=runtime_mean,
                 runtime_ratio_median=runtime_med,H1_pass=bool(h1_pass),H2_pass=bool(h2_pass),
                 families=fam,
                 verdict=('PROMOTE_ENAC_TO_P2' if (h1_pass and h2_pass) else
                          ('IDENTITY_EFFECT_ONLY' if h1_pass else 'STOP_ENAC_NEGATIVE')))
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')

    fig,ax=plt.subplots(figsize=(9,4.8)); x=np.arange(len(FUNCS)); w=0.36
    ax.bar(x-w/2,[ratio(med.loc[f,'ENAC'],med.loc[f,'V1-Frozen']) for f in FUNCS],w,label='ENAC/V1')
    ax.bar(x+w/2,[ratio(med.loc[f,'ENAC'],med.loc[f,'Identity-Credit']) for f in FUNCS],w,label='ENAC/Identity')
    ax.axhline(1,color='black',lw=1); ax.axhline(0.98,color='tab:green',ls='--',lw=1,label='0.98 gate')
    ax.axhline(1.20,color='tab:red',ls=':',lw=1,label='1.20 catastrophic')
    ax.set_yscale('log'); ax.set_xticks(x); ax.set_xticklabels([f'F{f}' for f in FUNCS])
    ax.set_ylabel('median final-error ratio (log scale)'); ax.set_title('ENAC P1: per-function median ratios')
    ax.legend(); fig.tight_layout(); fig.savefig(rep/'per_function_ratio.png',dpi=180); plt.close(fig)

    lines=['# ENAC P1 开发实验结果\n',
           f'- 主结果目录：`{p1}`',f'- A3-Off 目录：`{a3}`',
           '- 240 次主运行（V1、Identity-Credit、ENAC），80 次 matched A3-Off；失败 0；全部 30,000 真 FE','',
           '## 预注册门槛\n',
           f"- H1 ENAC/V1：中位比 {h1['median_ratio']:.6g}，胜/负 {h1['wins']}/{h1['losses']}，>1.20 函数数 {h1['catastrophic_gt_1_20']}，运行时间 ENAC/A3 {runtime_mean:.4g} → **{'通过' if h1_pass else '不通过'}**",
           f"- H2 ENAC/Identity：中位比 {h2['median_ratio']:.6g}，胜/负 {h2['wins']}/{h2['losses']}，>1.20 函数数 {h2['catastrophic_gt_1_20']} → **{'通过' if h2_pass else '不通过'}**",
           f"- Identity/V1（次级）：中位比 {h_identity['median_ratio']:.6g}，胜/负 {h_identity['wins']}/{h_identity['losses']}，>1.20 函数数 {h_identity['catastrophic_gt_1_20']}",
           f"- **最终裁定：{summary['verdict']}**",'',
           '| F | V1 | Identity | ENAC | ENAC/V1 | ENAC/Identity |','|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        lines.append(f"| {f} | {med.loc[f,'V1-Frozen']:.6g} | {med.loc[f,'Identity-Credit']:.6g} | {med.loc[f,'ENAC']:.6g} | {ratio(med.loc[f,'ENAC'],med.loc[f,'V1-Frozen']):.4g} | {ratio(med.loc[f,'ENAC'],med.loc[f,'Identity-Credit']):.4g} |")
    lines += ['','## 分函数族（ENAC/V1 中位比）','']
    for k,v in fam.items(): lines.append(f"- {k}: 中位比 {v['median_ratio']:.4g}，胜/负 {v['wins']}/{v['losses']}")
    lines += ['','## 机制过程证据（均值）','',
              f"- V1/A3-Off top ratio：{off.EnacMeanTopRatio.mean():.4g}",
              f"- Identity top ratio：{df[df.Algorithm=='Identity-Credit'].EnacMeanTopRatio.mean():.4g}",
              f"- ENAC top ratio：{df[df.Algorithm=='ENAC'].EnacMeanTopRatio.mean():.4g}",
              f"- Identity/ENAC 权重熵：{df[df.Algorithm=='Identity-Credit'].EnacMeanWeightEntropy.mean():.4g} / {df[df.Algorithm=='ENAC'].EnacMeanWeightEntropy.mean():.4g}",
              f"- Identity/ENAC dropped feedback：{df[df.Algorithm=='Identity-Credit'].EnacDroppedFeedback.mean():.1f} / {df[df.Algorithm=='ENAC'].EnacDroppedFeedback.mean():.1f}",
              f"- ENAC E 改善/1000FE：{df[df.Algorithm=='ENAC'].EnacEImpPer1000FE.mean():.4g}",
              '','按预注册规则：H1 不通过则停止；H1 通过、H2 不通过则只能声称中心身份修正或累计信用有效。']
    (rep/'enac_p1_report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)

if __name__=='__main__': main()
