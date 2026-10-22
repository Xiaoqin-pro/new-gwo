#!/usr/bin/env python3
"""Analyze the three-arm RGI confirmation at 100k FE."""
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
ARMS=['A-Frozen','B-RGI','C-StallRestart']
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
def boot_ci(v,B=10000,seed=20261022):
    rng=np.random.default_rng(seed); v=np.asarray(v,float); n=len(v); out=np.empty(B)
    for b in range(B): out[b]=np.median(v[rng.integers(0,n,n)])
    return float(np.percentile(out,2.5)),float(np.percentile(out,97.5))
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
    p=latest('rgi_confirm_2026*'); bc=pd.read_csv(p/'runs.csv')
    a=pd.read_csv(ROOT/'sparse_q'/'results'/'ablcore_20261017_062209'/'runs.csv')
    a=a[a.Algorithm=='A2-G1E'].copy(); a['Algorithm']='A-Frozen'
    df=pd.concat([a,bc],ignore_index=True,sort=False)
    rep=ROOT/'reports'/'rgi_confirm_analysis'; rep.mkdir(parents=True,exist_ok=True)
    assert len(a)==870 and len(bc)==1740,'arm size mismatch'
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed mismatch'
    assert set(df.Algorithm.unique())==set(ARMS),'arm mismatch'
    assert len(df)==2610 and (df.Status=='ok').all(),'run table mismatch'
    assert (df.Evaluations==100000).all(),'FE mismatch'
    med=df.pivot_table(index='FunctionID',columns='Algorithm',values='FinalError',aggfunc='median').reindex(FUNCS)
    med.to_csv(rep/'per_function_final_error_median.csv')
    pf={}
    for f in FUNCS:
        ba=[]; bc2=[]
        for s in SEEDS:
            av=df[(df.Algorithm=='A-Frozen')&(df.FunctionID==f)&(df.Seed==s)].FinalError.iloc[0]
            bv=df[(df.Algorithm=='B-RGI')&(df.FunctionID==f)&(df.Seed==s)].FinalError.iloc[0]
            cv=df[(df.Algorithm=='C-StallRestart')&(df.FunctionID==f)&(df.Seed==s)].FinalError.iloc[0]
            ba.append(ratio(bv,av)); bc2.append(ratio(bv,cv))
        pf[f]=dict(BA=float(np.median(ba)),BC=float(np.median(bc2)))
    ratios=pd.DataFrame.from_dict(pf,orient='index').reindex(FUNCS); ratios.to_csv(rep/'per_function_ratio.csv')
    ba=ratios.BA.to_numpy(); bc=ratios.BC.to_numpy(); ba_ci=boot_ci(ba); bc_ci=boot_ci(bc)
    wins_ba=int((ba<1).sum()); wins_bc=int((bc<1).sum()); cat_ba=int((ba>1.20).sum()); cat_bc=int((bc>1.20).sum())
    max_ba=float(np.max(ba)); max_bc=float(np.max(bc))
    rt=df.groupby('Algorithm').Seconds.mean().to_dict()
    r_ba=rt['B-RGI']/rt['A-Frozen']; r_bc=rt['B-RGI']/rt['C-StallRestart']
    H1=bool(np.median(ba)<=0.98 and ba_ci[1]<1.00 and wins_ba>=18 and cat_ba==0 and r_ba<=1.15)
    H2=bool(np.median(bc)<=0.98 and wins_bc>=18 and cat_bc==0)
    fam={}
    for fname,fs in FAMILIES.items():
        fam[fname]=dict(BA=float(np.median([ratios.loc[f,'BA'] for f in fs])),
                        BC=float(np.median([ratios.loc[f,'BC'] for f in fs])))
    tests=pairwise(df,'B-RGI','A-Frozen')+pairwise(df,'B-RGI','C-StallRestart')
    pd.DataFrame(tests).to_csv(rep/'pairwise_wilcoxon_holm.csv',index=False)
    comp_p=[]; comp_lab=[]
    for lab,v in [('B/A',np.log(ba)),('B/C',np.log(bc))]:
        try: _,pv=wilcoxon(v,alternative='two-sided',zero_method='wilcox',method='auto')
        except ValueError: pv=np.nan
        comp_p.append(pv); comp_lab.append(lab)
    comp_holm=holm(comp_p)
    if H1 and H2: verdict='CONFIRM_RGI_RANK_GATED'
    elif H1 and not H2: verdict='RGI_EFFECTIVE_RANK_NOT_NEEDED'
    elif H2 and not H1: verdict='RANK_GATING_EFFECT_BUT_NO_NET_GAIN'
    else: verdict='STOP_RGI_CONFIRMATION'
    proc_cols=[x for x in ['RgiRestarts','RgiEvaluatedRestarts','RgiRestartRate','NImprove','ImprovingFERate','RecoveryEventualProb','LongStagShare'] if x in df.columns]
    proc=df[df.Algorithm.isin(['B-RGI','C-StallRestart'])].groupby('Algorithm')[proc_cols].mean().T if proc_cols else pd.DataFrame()
    proc.to_csv(rep/'process_metrics.csv')
    summary=dict(results_dir=str(p),a2_source=str(ROOT/'sparse_q'/'results'/'ablcore_20261017_062209'/'runs.csv'),runs=len(df),
                 median_BA=float(np.median(ba)),CI_BA=ba_ci,wins_BA=wins_ba,cat_BA=cat_ba,max_BA=max_ba,
                 median_BC=float(np.median(bc)),CI_BC=bc_ci,wins_BC=wins_bc,cat_BC=cat_bc,max_BC=max_bc,
                 runtime_B_A=r_ba,runtime_B_C=r_bc,families=fam,H1_B_A=H1,H2_B_C=H2,
                 comparison_level_holm={lab:(float(v) if np.isfinite(v) else None) for lab,v in zip(comp_lab,comp_holm)},verdict=verdict)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    fig,ax=plt.subplots(figsize=(12,5)); x=np.arange(len(FUNCS)); w=0.35
    ax.bar(x-w/2,ba,w,label='B/A'); ax.bar(x+w/2,bc,w,label='B/C')
    ax.axhline(1,color='k',lw=1); ax.axhline(0.98,color='tab:green',ls='--',lw=1,label='0.98'); ax.axhline(1.20,color='tab:red',ls=':',lw=1,label='1.20')
    ax.set_yscale('log'); ax.set_xticks(x); ax.set_xticklabels([f'F{f}' for f in FUNCS]); ax.set_ylabel('per-function median ratio')
    ax.set_title('RGI confirmation: 29 functions, 30 seeds, 100k FE'); ax.legend(ncol=2,fontsize=8)
    fig.tight_layout(); fig.savefig(rep/'per_function_ratio.png',dpi=180); plt.close(fig)
    lines=['# RGI 三臂确认结果','',f'- 结果目录：`{p}`','- 2610 次配对运行（A 复用，B/C 新跑），0 失败，全部 100,000 FE','',
           '## 预注册判定','',
           f"- H1 B/A：中位比 {np.median(ba):.6g}，95% CI [{ba_ci[0]:.4g}, {ba_ci[1]:.4g}]，胜/负 {wins_ba}/{29-wins_ba}，>1.20 {cat_ba}，最大 {max_ba:.4g}，时间 {r_ba:.4g} → **{'通过' if H1 else '不通过'}**",
           f"- H2 B/C：中位比 {np.median(bc):.6g}，95% CI [{bc_ci[0]:.4g}, {bc_ci[1]:.4g}]，胜/负 {wins_bc}/{29-wins_bc}，>1.20 {cat_bc}，最大 {max_bc:.4g}，时间 {r_bc:.4g} → **{'通过' if H2 else '不通过'}**",
           f"- 最终裁定：**{verdict}**",'',
           '| F | A | B | C | B/A | B/C |','|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        lines.append(f"| {f} | {med.loc[f,'A-Frozen']:.6g} | {med.loc[f,'B-RGI']:.6g} | {med.loc[f,'C-StallRestart']:.6g} | {ratios.loc[f,'BA']:.4g} | {ratios.loc[f,'BC']:.4g} |")
    lines += ['','## 函数族结果','']
    for k,v in fam.items(): lines.append(f"- {k}: B/A {v['BA']:.4g}, B/C {v['BC']:.4g}")
    lines += ['','## 过程指标','']
    for k in proc.index:
        vals=' / '.join(f"{a}={proc.loc[k,a]:.6g}" for a in proc.columns)
        lines.append(f'- {k}: {vals}')
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)
if __name__=='__main__': main()
