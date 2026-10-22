#!/usr/bin/env python3
"""Analyze the three-arm NEL pilot (120 runs, 100k FE)."""
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
FUNCS=[1,3,4,7,10,13,20,30]; SEEDS=list(range(3301,3306))
ARMS=['A-FrozenFill','B-NEL','C-RandomExemplar']
def latest(pat):
    ds=sorted((ROOT/'sparse_q'/'results').glob(pat))
    if not ds: raise SystemExit('missing results: '+pat)
    return ds[-1]
def ratio(a,b): return float(a/b) if b!=0 else (float('inf') if a>0 else 1.0)
def holm(p):
    p=np.asarray(p,float); out=np.full_like(p,np.nan); idx=np.where(np.isfinite(p))[0]
    if not len(idx): return out
    order=idx[np.argsort(p[idx])]; prev=0.0
    for rank,i in enumerate(order):
        v=min(1.0,(len(order)-rank)*p[i]); v=max(v,prev); out[i]=v; prev=v
    return out
def main():
    p=latest('nel_p1_*'); df=pd.read_csv(p/'runs.csv')
    rep=ROOT/'reports'/'nel_p1_analysis'; rep.mkdir(parents=True,exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed mismatch'
    assert set(df.Algorithm.unique())==set(ARMS),'arm mismatch'
    assert len(df)==120 and (df.Status=='ok').all(),'pilot incomplete'
    assert (df.Evaluations==100000).all(),'FE mismatch'
    med=df.pivot_table(index='FunctionID',columns='Algorithm',values='FinalError',aggfunc='median').reindex(FUNCS)
    med.to_csv(rep/'per_function_final_error_median.csv')
    ratios={}
    tests=[]
    for a,b,lab in [('B-NEL','A-FrozenFill','B/A'),('B-NEL','C-RandomExemplar','B/C')]:
        rr=[]; rows=[]
        for f in FUNCS:
            x=df[(df.Algorithm==a)&(df.FunctionID==f)].sort_values('Seed').FinalError.to_numpy(float)
            y=df[(df.Algorithm==b)&(df.FunctionID==f)].sort_values('Seed').FinalError.to_numpy(float)
            r=np.array([ratio(u,v) for u,v in zip(x,y)]); rr.append(float(np.median(r)))
            try: _,pv=wilcoxon(x,y,alternative='two-sided',zero_method='wilcox',method='auto')
            except ValueError: pv=np.nan
            rows.append(dict(comparison=f'{a} vs {b}',FunctionID=f,median_ratio=float(np.median(r)),
                             wins=int((r<1).sum()),losses=int((r>1).sum()),p_raw=float(pv) if np.isfinite(pv) else np.nan))
        q=holm([r['p_raw'] for r in rows])
        for r,v in zip(rows,q): r['p_holm']=float(v) if np.isfinite(v) else np.nan
        tests+=rows; ratios[lab]=np.array(rr)
    pd.DataFrame(tests).to_csv(rep/'pairwise_wilcoxon_holm.csv',index=False)
    ba=ratios['B/A']; bc=ratios['B/C']
    wins_ba=int((ba<1).sum()); wins_bc=int((bc<1).sum()); cat_ba=int((ba>1.20).sum()); cat_bc=int((bc>1.20).sum())
    rt=df.groupby('Algorithm').Seconds.mean().to_dict(); r_ba=rt['B-NEL']/rt['A-FrozenFill']; r_bc=rt['B-NEL']/rt['C-RandomExemplar']
    H1=bool(np.median(ba)<=0.98 and wins_ba>=6 and cat_ba==0 and r_ba<=1.15)
    H2=bool(np.median(bc)<=0.98 and wins_bc>=6 and cat_bc==0)
    if H1 and H2: verdict='PROMOTE_NEL_TO_CONFIRMATION'
    elif H1 and not H2: verdict='NEL_EFFECTIVE_RANDOM_EXEMPLAR_NOT_RULED_OUT'
    else: verdict='STOP_NEL_PILOT'
    summary=dict(results_dir=str(p),runs=len(df),median_BA=float(np.median(ba)),wins_BA=wins_ba,cat_BA=cat_ba,
                 median_BC=float(np.median(bc)),wins_BC=wins_bc,cat_BC=cat_bc,runtime_BA=r_ba,runtime_BC=r_bc,
                 H1_pass=H1,H2_pass=H2,verdict=verdict)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    fig,ax=plt.subplots(figsize=(10,5)); x=np.arange(len(FUNCS)); w=0.35
    ax.bar(x-w/2,ba,w,label='B/A'); ax.bar(x+w/2,bc,w,label='B/C')
    ax.axhline(1,color='k',lw=1); ax.axhline(0.98,color='tab:green',ls='--',lw=1,label='0.98'); ax.axhline(1.20,color='tab:red',ls=':',lw=1,label='1.20')
    ax.set_yscale('log'); ax.set_xticks(x); ax.set_xticklabels([f'F{f}' for f in FUNCS]); ax.set_ylabel('median ratio')
    ax.set_title('NEL pilot: 8 functions, 5 seeds, 100k FE'); ax.legend(ncol=2,fontsize=8); fig.tight_layout(); fig.savefig(rep/'per_function_ratio.png',dpi=180); plt.close(fig)
    lines=['# NEL P1 预实验（8 函数 × 5 种子 × 100k FE）','',f'- 结果目录：`{p}`','- 120 次运行，0 失败','',
           '## 门槛','',
           f"- H1 B/A：中位比 {np.median(ba):.6g}，胜/负 {wins_ba}/{8-wins_ba}，>1.20 {cat_ba}，时间 {r_ba:.4g} → **{'通过' if H1 else '不通过'}**",
           f"- H2 B/C：中位比 {np.median(bc):.6g}，胜/负 {wins_bc}/{8-wins_bc}，>1.20 {cat_bc}，时间 {r_bc:.4g} → **{'通过' if H2 else '不通过'}**",
           f"- 最终裁定：**{verdict}**",'',
           '| F | A | B | C | B/A | B/C |','|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        lines.append(f"| {f} | {med.loc[f,'A-FrozenFill']:.6g} | {med.loc[f,'B-NEL']:.6g} | {med.loc[f,'C-RandomExemplar']:.6g} | {ratios['B/A'][FUNCS.index(f)]:.4g} | {ratios['B/C'][FUNCS.index(f)]:.4g} |")
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)
if __name__=='__main__': main()
