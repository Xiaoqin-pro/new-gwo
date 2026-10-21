#!/usr/bin/env python3
"""Analyze the three-arm TSD-base confirmation on seeds 3071-3100."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT=Path(__file__).resolve().parents[2]
FUNCS=[1]+list(range(3,31))
SEEDS=list(range(3071,3101))
ARMS=['A-Frozen','B-VGA','C-TSDbase']
FAMILIES={'unimodal':[1,3],'simple_multimodal':[4,5,6,7,8,9,10],
          'hybrid':[11,12,13,14,15,16,17,18,19,20],
          'composition':[21,22,23,24,25,26,27,28,29,30]}

def latest(pat):
    ds=sorted((ROOT/'sparse_q'/'results').glob(pat))
    if not ds: raise SystemExit('missing results: '+pat)
    return ds[-1]
def ratio(a,b):
    if b==0: return float('inf') if a>0 else 1.0
    return float(a/b)
def holm(p):
    p=np.asarray(p,float); out=np.full_like(p,np.nan); idx=np.where(np.isfinite(p))[0]
    if not len(idx): return out
    order=idx[np.argsort(p[idx])]; prev=0.0
    for rank,i in enumerate(order):
        v=min(1.0,(len(order)-rank)*p[i]); v=max(v,prev); out[i]=v; prev=v
    return out
def bootstrap_ci(values,B=10000,seed=20261021):
    rng=np.random.default_rng(seed); v=np.asarray(values,float); n=len(v)
    meds=np.empty(B)
    for b in range(B):
        idx=rng.integers(0,n,n); meds[b]=np.median(v[idx])
    return float(np.percentile(meds,2.5)),float(np.percentile(meds,97.5))
def pairwise(df,a,b):
    rows=[]
    for f in FUNCS:
        x=df[(df.Algorithm==a)&(df.FunctionID==f)].sort_values('Seed').FinalError.to_numpy(float)
        y=df[(df.Algorithm==b)&(df.FunctionID==f)].sort_values('Seed').FinalError.to_numpy(float)
        if len(x)!=len(y) or len(x)==0: continue
        try: stat,p=wilcoxon(x,y,alternative='two-sided',zero_method='wilcox',method='auto')
        except ValueError: stat,p=np.nan,np.nan
        rr=np.array([ratio(u,v) for u,v in zip(x,y)])
        rows.append(dict(comparison=f'{a} vs {b}',FunctionID=f,median_A=float(np.median(x)),
                         median_B=float(np.median(y)),median_ratio=float(np.median(rr)),
                         wins_A=int((rr<1).sum()),losses_A=int((rr>1).sum()),
                         p_raw=float(p) if np.isfinite(p) else np.nan,
                         stat=float(stat) if np.isfinite(stat) else np.nan))
    q=holm([r['p_raw'] for r in rows])
    for r,v in zip(rows,q): r['p_holm']=float(v) if np.isfinite(v) else np.nan
    return rows
def main():
    p=latest('tsd_confirm_bc_2026*')
    bc=pd.read_csv(p/'runs.csv')
    a2_path=ROOT/'sparse_q'/'results'/'ablcore_20261017_062209'/'runs.csv'
    assert a2_path.exists(),'missing reused A2-G1E source'
    a2=pd.read_csv(a2_path)
    a2=a2[a2.Algorithm=='A2-G1E'].copy()
    a2['Algorithm']='A-Frozen'
    df=pd.concat([a2,bc],ignore_index=True,sort=False)
    rep=ROOT/'reports'/'tsd_confirm_analysis'; rep.mkdir(parents=True,exist_ok=True)
    assert len(a2)==870,'expected 870 reused A2-G1E runs'
    assert len(bc)==1740,'expected 1740 new B/C runs'
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed mismatch'
    assert set(df.Algorithm.unique())==set(ARMS),'arm mismatch'
    assert len(df)==2610,f'expected 2610 runs, got {len(df)}'
    assert (df.Status=='ok').all(),'failed runs'
    assert (df.Evaluations==100000).all(),'FE mismatch'
    med=df.pivot_table(index='FunctionID',columns='Algorithm',values='FinalError',aggfunc='median').reindex(FUNCS)
    med.to_csv(rep/'per_function_final_error_median.csv')
    # per-function paired median ratios
    pf={}
    for f in FUNCS:
        ca=[]; cb=[]
        for s in SEEDS:
            a=df[(df.Algorithm=='A-Frozen')&(df.FunctionID==f)&(df.Seed==s)].FinalError.iloc[0]
            b=df[(df.Algorithm=='B-VGA')&(df.FunctionID==f)&(df.Seed==s)].FinalError.iloc[0]
            c=df[(df.Algorithm=='C-TSDbase')&(df.FunctionID==f)&(df.Seed==s)].FinalError.iloc[0]
            ca.append(ratio(c,a)); cb.append(ratio(c,b))
        pf[f]=dict(CA=float(np.median(ca)),CB=float(np.median(cb)))
    ratios=pd.DataFrame.from_dict(pf,orient='index').reindex(FUNCS)
    ratios.to_csv(rep/'per_function_ratio.csv')
    ca_vals=ratios.CA.to_numpy(); cb_vals=ratios.CB.to_numpy()
    ca_ci=bootstrap_ci(ca_vals); cb_ci=bootstrap_ci(cb_vals)
    pooled_ca=float(np.median([ratio(df[(df.Algorithm=='C-TSDbase')&(df.FunctionID==f)&(df.Seed==s)].FinalError.iloc[0],
                                     df[(df.Algorithm=='A-Frozen')&(df.FunctionID==f)&(df.Seed==s)].FinalError.iloc[0])
                                for f in FUNCS for s in SEEDS]))
    pooled_cb=float(np.median([ratio(df[(df.Algorithm=='C-TSDbase')&(df.FunctionID==f)&(df.Seed==s)].FinalError.iloc[0],
                                     df[(df.Algorithm=='B-VGA')&(df.FunctionID==f)&(df.Seed==s)].FinalError.iloc[0])
                                for f in FUNCS for s in SEEDS]))
    wins_ca=int((ca_vals<1).sum()); wins_cb=int((cb_vals<1).sum())
    cat_ca=int((ca_vals>1.20).sum()); cat_cb=int((cb_vals>1.20).sum())
    max_ca=float(np.max(ca_vals)); max_cb=float(np.max(cb_vals))
    rt=df.groupby('Algorithm').Seconds.mean().to_dict()
    r_ca=rt['C-TSDbase']/rt['A-Frozen']; r_cb=rt['C-TSDbase']/rt['B-VGA']
    H1=bool(ca_ci[1]<1.05 and cat_ca<=2 and max_ca<=1.35 and r_ca<=1.15)
    H2=bool(float(np.median(cb_vals))<=0.98 and wins_cb>=20 and cat_cb==0 and r_cb<=1.15)
    proc_cols=[c for c in ['TsdG1Eval','TsdG1Split','TsdStateSplitRate','TsdEEval','TsdECursorOnly',
                           'TsdCursorOnlyRate','TsdProtectUpdates','TsdMeanGapDist','TsdMeanGapFit',
                           'NImprove','ImprovingFERate','RecoveryEventualProb','LongStagShare'] if c in df.columns]
    proc=df[df.Algorithm=='C-TSDbase'][proc_cols].mean() if proc_cols else pd.Series(dtype=float)
    proc.to_csv(rep/'process_metrics_C.csv')
    proc_all_cols=[c for c in ['CheckT20','CheckT50','CheckT80','NImprove','ImprovingFERate',
                               'RecoveryEventualProb','LongStagShare','NovelUsefulRate','NovelStrictImprove',
                               'TsdG1Eval','TsdG1Split','TsdStateSplitRate','TsdEEval','TsdECursorOnly',
                               'TsdCursorOnlyRate','TsdProtectUpdates','TsdMeanGapDist','TsdMeanGapFit']
                   if c in df.columns]
    proc_all=df.groupby('Algorithm')[proc_all_cols].mean().T if proc_all_cols else pd.DataFrame()
    proc_all.to_csv(rep/'process_metrics_all.csv')
    # per-function Wilcoxon and comparison-level tests
    tests=[]
    tests+=pairwise(df,'C-TSDbase','A-Frozen')
    tests+=pairwise(df,'C-TSDbase','B-VGA')
    pd.DataFrame(tests).to_csv(rep/'pairwise_wilcoxon_holm.csv',index=False)
    comp_p=[]; comp_lab=[]
    for lab,v in [('C/A',np.log(ca_vals)),('C/B',np.log(cb_vals))]:
        try: _,pv=wilcoxon(v,alternative='two-sided',zero_method='wilcox',method='auto')
        except ValueError: pv=np.nan
        comp_p.append(pv); comp_lab.append(lab)
    comp_holm=holm(comp_p)
    if H1 and H2: verdict='CONFIRM_TSD_BASE_TWO_CONTRIBUTION'
    elif H1 and not H2: verdict='TSD_BASE_NONINFERIOR_ONLY'
    elif H2 and not H1: verdict='TSD_BASE_GAIN_OVER_VGA_BUT_LOSS_VS_G1E'
    else: verdict='STOP_TSD_BASE_CONFIRMATION'
    proc_summary={}
    for k in ['CheckT20','CheckT50','NImprove','ImprovingFERate','RecoveryEventualProb','LongStagShare','TsdStateSplitRate','TsdMeanGapDist','TsdProtectUpdates']:
        if k in proc_all.index:
            proc_summary[k]={a:(float(proc_all.loc[k,a]) if np.isfinite(proc_all.loc[k,a]) else None) for a in ARMS}
    summary=dict(results_dir=str(p),a2_source=str(a2_path),bc_source=str(p),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 median_ratio_CA_function_level=float(np.median(ca_vals)),median_ratio_CB_function_level=float(np.median(cb_vals)),
                 pooled_median_ratio_CA=pooled_ca,pooled_median_ratio_CB=pooled_cb,
                 CI95_CA=ca_ci,CI95_CB=cb_ci,wins_CA=wins_ca,wins_CB=wins_cb,
                 catastrophic_CA=cat_ca,catastrophic_CB=cat_cb,max_CA=max_ca,max_CB=max_cb,
                 runtime_C_A=r_ca,runtime_C_B=r_cb,H1_non_inferior=H1,H2_improve_over_VGA=H2,
                 comparison_level_holm={lab:float(v) if np.isfinite(v) else np.nan for lab,v in zip(comp_lab,comp_holm)},
                 process_summary=proc_summary,verdict=verdict)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    # plot
    x=np.arange(len(FUNCS)); w=0.35
    fig,ax=plt.subplots(figsize=(12,5))
    ax.bar(x-w/2,ca_vals,w,label='C/A (TSDbase/Frozen)')
    ax.bar(x+w/2,cb_vals,w,label='C/B (TSDbase/VGA)')
    ax.axhline(1,color='k',lw=1); ax.axhline(1.05,color='tab:orange',ls='--',lw=1,label='non-inferiority 1.05')
    ax.axhline(0.98,color='tab:green',ls='--',lw=1,label='improvement 0.98'); ax.axhline(1.20,color='tab:red',ls=':',lw=1,label='1.20 boundary')
    ax.set_yscale('log'); ax.set_xticks(x); ax.set_xticklabels([f'F{f}' for f in FUNCS]); ax.set_ylabel('per-function median error ratio')
    ax.set_title('TSD base confirmation: 29 functions, 30 seeds, 100k FE'); ax.legend(ncol=2,fontsize=8)
    fig.tight_layout(); fig.savefig(rep/'per_function_ratio.png',dpi=180); plt.close(fig)
    lines=['# TSD 基础版确认结果（29 函数 × 30 种子 × 100k FE）','',f'- 结果目录：`{p}`','- 2610 次运行，3 臂，失败 0，全部 100,000 FE','- 种子 3071–3100；A 臂复用 `ablcore_20261017_062209` 的 A2-G1E，B/C 为同种子新跑','',
           '## 预注册判定','',
           f"- H1 C/A 非劣效：函数级中位比 {np.median(ca_vals):.6g}，95% CI [{ca_ci[0]:.4g}, {ca_ci[1]:.4g}]，胜/负 {wins_ca}/{len(FUNCS)-wins_ca}，>1.20 {cat_ca}，最大 {max_ca:.4g}，时间 {r_ca:.4g} → **{'通过' if H1 else '不通过'}**",
           f"- H2 C/B 优于 VGA：函数级中位比 {np.median(cb_vals):.6g}，95% CI [{cb_ci[0]:.4g}, {cb_ci[1]:.4g}]，胜/负 {wins_cb}/{len(FUNCS)-wins_cb}，>1.20 {cat_cb}，最大 {max_cb:.4g}，时间 {r_cb:.4g} → **{'通过' if H2 else '不通过'}**",
           f"- 最终裁定：**{verdict}**",'',
           '| F | A | B | C | C/A | C/B |','|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        lines.append(f"| {f} | {med.loc[f,'A-Frozen']:.6g} | {med.loc[f,'B-VGA']:.6g} | {med.loc[f,'C-TSDbase']:.6g} | {ratios.loc[f,'CA']:.4g} | {ratios.loc[f,'CB']:.4g} |")
    lines += ['','## 过程证据（A/B/C 均值）','']
    for k in ['CheckT20','CheckT50','NImprove','ImprovingFERate','RecoveryEventualProb','LongStagShare']:
        if k in proc_all.index:
            vals=' / '.join(f"{a}={proc_all.loc[k,a]:.6g}" if np.isfinite(proc_all.loc[k,a]) else f'{a}=NA' for a in ARMS)
            lines.append(f'- {k}: {vals}')
    lines += ['','## TSD 机制过程（C 均值）','']
    for k in ['TsdG1Eval','TsdG1Split','TsdStateSplitRate','TsdEEval','TsdECursorOnly','TsdCursorOnlyRate','TsdProtectUpdates','TsdMeanGapDist','TsdMeanGapFit']:
        if k in proc.index:
            lines.append(f'- {k}: {proc[k]:.6g}')
    lines += ['','## 函数族结果','']
    for fname,fs in FAMILIES.items():
        ca=np.array([ratios.loc[f,'CA'] for f in fs]); cb=np.array([ratios.loc[f,'CB'] for f in fs])
        lines.append(f"- {fname}: C/A median {np.median(ca):.4g}, C/B median {np.median(cb):.4g}, C/B wins {(cb<1).sum()}/{len(cb)}")
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)
if __name__=='__main__': main()
