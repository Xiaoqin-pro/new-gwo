#!/usr/bin/env python3
"""Analyze the three-arm TSD-R confirmation at 100k FE."""
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
ARMS=['A-Frozen','B-TSDbase','C-TSDR']
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
def boot_ci(v,B=10000,seed=20261021):
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
    p=latest('tsdr_confirm_2026*'); c=pd.read_csv(p/'runs.csv')
    a=pd.read_csv(ROOT/'sparse_q'/'results'/'ablcore_20261017_062209'/'runs.csv')
    a=a[a.Algorithm=='A2-G1E'].copy(); a['Algorithm']='A-Frozen'
    b=pd.read_csv(ROOT/'sparse_q'/'results'/'tsd_confirm_bc_20261021_101017'/'runs.csv')
    b=b[b.Algorithm=='C-TSDbase'].copy(); b['Algorithm']='B-TSDbase'
    c=c[c.Algorithm=='C-TSDR'].copy()
    df=pd.concat([a,b,c],ignore_index=True,sort=False)
    rep=ROOT/'reports'/'tsdr_confirm_analysis'; rep.mkdir(parents=True,exist_ok=True)
    assert len(a)==870 and len(b)==870 and len(c)==870,'arm size mismatch'
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed mismatch'
    assert set(df.Algorithm.unique())==set(ARMS),'arm mismatch'
    assert len(df)==2610 and (df.Status=='ok').all(),'run table mismatch'
    assert (df.Evaluations==100000).all(),'FE mismatch'
    med=df.pivot_table(index='FunctionID',columns='Algorithm',values='FinalError',aggfunc='median').reindex(FUNCS)
    med.to_csv(rep/'per_function_final_error_median.csv')
    pf={}
    for f in FUNCS:
        ca=[]; cb=[]
        for s in SEEDS:
            av=df[(df.Algorithm=='A-Frozen')&(df.FunctionID==f)&(df.Seed==s)].FinalError.iloc[0]
            bv=df[(df.Algorithm=='B-TSDbase')&(df.FunctionID==f)&(df.Seed==s)].FinalError.iloc[0]
            cv=df[(df.Algorithm=='C-TSDR')&(df.FunctionID==f)&(df.Seed==s)].FinalError.iloc[0]
            ca.append(ratio(cv,av)); cb.append(ratio(cv,bv))
        pf[f]=dict(CA=float(np.median(ca)),CB=float(np.median(cb)))
    ratios=pd.DataFrame.from_dict(pf,orient='index').reindex(FUNCS); ratios.to_csv(rep/'per_function_ratio.csv')
    ca=ratios.CA.to_numpy(); cb=ratios.CB.to_numpy()
    ca_ci=boot_ci(ca); cb_ci=boot_ci(cb)
    wins_ca=int((ca<1).sum()); wins_cb=int((cb<1).sum())
    cat_ca=int((ca>1.20).sum()); cat_cb=int((cb>1.20).sum())
    max_ca=float(np.max(ca)); max_cb=float(np.max(cb))
    rt=df.groupby('Algorithm').Seconds.mean().to_dict()
    r_ca=rt['C-TSDR']/rt['A-Frozen']; r_cb=rt['C-TSDR']/rt['B-TSDbase']
    fam={}
    for fname,fs in FAMILIES.items():
        fam[fname]=dict(CA=float(np.median([ratios.loc[f,'CA'] for f in fs])),
                        CB=float(np.median([ratios.loc[f,'CB'] for f in fs])))
    complex_bad=[fam[k]['CB'] for k in ['simple_multimodal','hybrid','composition']]
    H1=bool(ca_ci[1]<1.05 and cat_ca<=2 and max_ca<=1.35 and r_ca<=1.15)
    H2=bool(np.median(cb)<=0.98 and wins_cb>=18 and cat_cb==0 and r_cb<=1.15 and
            sum(v<1.00 for v in complex_bad)>=2 and max(complex_bad)<=1.05)
    tests=pairwise(df,'C-TSDR','A-Frozen')+pairwise(df,'C-TSDR','B-TSDbase')
    pd.DataFrame(tests).to_csv(rep/'pairwise_wilcoxon_holm.csv',index=False)
    comp_p=[]; comp_lab=[]
    for lab,v in [('C/A',np.log(ca)),('C/B',np.log(cb))]:
        try: _,pv=wilcoxon(v,alternative='two-sided',zero_method='wilcox',method='auto')
        except ValueError: pv=np.nan
        comp_p.append(pv); comp_lab.append(lab)
    comp_holm=holm(comp_p)
    if H1 and H2: verdict='CONFIRM_TSDR_SECOND_CONTRIBUTION'
    elif H1 and not H2: verdict='TSDR_NONINFERIOR_ONLY'
    elif H2 and not H1: verdict='TSDR_GAIN_OVER_BASE_ONLY'
    else: verdict='STOP_TSDR_CONFIRMATION'
    proc_cols=[x for x in ['TsdrRecoveries','TsdrTriggers','NImprove','ImprovingFERate','RecoveryEventualProb','LongStagShare'] if x in df.columns]
    proc=df[df.Algorithm=='C-TSDR'][proc_cols].mean() if proc_cols else pd.Series(dtype=float)
    proc.to_csv(rep/'process_metrics_C.csv')
    summary=dict(results_dir=str(p),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 median_CA=float(np.median(ca)),CI_CA=ca_ci,wins_CA=wins_ca,cat_CA=cat_ca,max_CA=max_ca,
                 median_CB=float(np.median(cb)),CI_CB=cb_ci,wins_CB=wins_cb,cat_CB=cat_cb,max_CB=max_cb,
                 runtime_C_A=r_ca,runtime_C_B=r_cb,families=fam,H1_non_inferior=H1,H2_improve_over_base=H2,
                 comparison_level_holm={lab:(float(v) if np.isfinite(v) else None) for lab,v in zip(comp_lab,comp_holm)},
                 verdict=verdict)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    fig,ax=plt.subplots(figsize=(12,5)); x=np.arange(len(FUNCS)); w=0.35
    ax.bar(x-w/2,ca,w,label='C/A'); ax.bar(x+w/2,cb,w,label='C/B')
    ax.axhline(1,color='k',lw=1); ax.axhline(0.98,color='tab:green',ls='--',lw=1,label='0.98'); ax.axhline(1.05,color='tab:orange',ls='--',lw=1,label='1.05'); ax.axhline(1.20,color='tab:red',ls=':',lw=1,label='1.20')
    ax.set_yscale('log'); ax.set_xticks(x); ax.set_xticklabels([f'F{f}' for f in FUNCS]); ax.set_ylabel('per-function median ratio')
    ax.set_title('TSD-R confirmation: 29 functions, 30 seeds, 100k FE'); ax.legend(ncol=2,fontsize=8)
    fig.tight_layout(); fig.savefig(rep/'per_function_ratio.png',dpi=180); plt.close(fig)
    lines=['# TSD-R 三臂确认结果','',f'- 结果目录：`{p}`','- 2610 次配对运行（A/B 复用，C 新跑），0 失败，全部 100,000 FE','',
           '## 预注册判定','',
           f"- H1 C/A 非劣：中位比 {np.median(ca):.6g}，95% CI [{ca_ci[0]:.4g}, {ca_ci[1]:.4g}]，胜/负 {wins_ca}/{29-wins_ca}，>1.20 {cat_ca}，最大 {max_ca:.4g}，时间 {r_ca:.4g} → **{'通过' if H1 else '不通过'}**",
           f"- H2 C/B 改善：中位比 {np.median(cb):.6g}，95% CI [{cb_ci[0]:.4g}, {cb_ci[1]:.4g}]，胜/负 {wins_cb}/{29-wins_cb}，>1.20 {cat_cb}，最大 {max_cb:.4g}，时间 {r_cb:.4g} → **{'通过' if H2 else '不通过'}**",
           f"- 最终裁定：**{verdict}**",'',
           '| F | A | B | C | C/A | C/B |','|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        lines.append(f"| {f} | {med.loc[f,'A-Frozen']:.6g} | {med.loc[f,'B-TSDbase']:.6g} | {med.loc[f,'C-TSDR']:.6g} | {ratios.loc[f,'CA']:.4g} | {ratios.loc[f,'CB']:.4g} |")
    lines += ['','## 函数族结果','']
    for k,v in fam.items(): lines.append(f"- {k}: C/A {v['CA']:.4g}, C/B {v['CB']:.4g}")
    lines += ['','## 过程指标（C 均值）','']
    for k in ['TsdrRecoveries','TsdrTriggers','NImprove','ImprovingFERate','RecoveryEventualProb','LongStagShare']:
        if k in proc.index: lines.append(f'- {k}: {proc[k]:.6g}')
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)
if __name__=='__main__': main()
