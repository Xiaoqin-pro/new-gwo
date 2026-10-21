#!/usr/bin/env python3
"""Analyze the 5-arm TRPS 2x2 P1 at 100k true FE."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1,3,4,7,10,11,13,14,16,18,20,22,24,26,30]
SEEDS = list(range(3206,3216))
ARMS = ['A-Std-G2off','B-TRPS-G2off','C-Std-G2on','D-TRPS-G2on','R-RandomTR-G2off']
FAMILIES = {
    'unimodal':[1,3],
    'simple_multimodal':[4,7,10,11],
    'hybrid':[13,14,16,18,20],
    'composition':[22,24,26,30],
}
PAIRS = [
    ('B-TRPS-G2off','A-Std-G2off'),
    ('B-TRPS-G2off','R-RandomTR-G2off'),
    ('D-TRPS-G2on','C-Std-G2on'),
    ('A-Std-G2off','C-Std-G2on'),
    ('B-TRPS-G2off','D-TRPS-G2on'),
]

def latest(pat: str) -> Path:
    ds = sorted((ROOT/'sparse_q'/'results').glob(pat))
    if not ds:
        raise SystemExit(f'missing results: {pat}')
    return ds[-1]

def ratio(a,b):
    if b == 0:
        return float('inf') if a > 0 else 1.0
    return float(a/b)

def holm(p):
    p=np.asarray(p,float); out=np.full_like(p,np.nan)
    idx=np.where(np.isfinite(p))[0]
    if not len(idx): return out
    order=idx[np.argsort(p[idx])]; prev=0.0
    for rank,i in enumerate(order):
        v=min(1.0,(len(order)-rank)*p[i]); v=max(v,prev); out[i]=v; prev=v
    return out

def pairwise(df,a,b):
    rows=[]
    for f in FUNCS:
        x=df[(df.Algorithm==a)&(df.FunctionID==f)].sort_values('Seed').FinalError.to_numpy(float)
        y=df[(df.Algorithm==b)&(df.FunctionID==f)].sort_values('Seed').FinalError.to_numpy(float)
        if len(x)!=len(y) or len(x)==0: continue
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
    p1=latest('trps_p1_*'); df=pd.read_csv(p1/'runs.csv')
    rep=ROOT/'reports'/'trps_p1_analysis'; rep.mkdir(parents=True,exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function set mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed set mismatch'
    assert set(df.Algorithm.unique())==set(ARMS),'arm labels mismatch'
    assert len(df)==750,f'expected 750 runs, got {len(df)}'
    assert (df.Status=='ok').all(),'failed runs present'
    assert (df.Evaluations==100000).all(),'FE mismatch'

    med=df.pivot_table(index='FunctionID',columns='Algorithm',values='FinalError',aggfunc='median').reindex(FUNCS)
    med.to_csv(rep/'per_function_final_error_median.csv')
    gates={f'{a}|{b}':gate(med,a,b) for a,b in PAIRS}
    tests=[]
    for a,b in PAIRS: tests.extend(pairwise(df,a,b))
    pd.DataFrame(tests).to_csv(rep/'pairwise_wilcoxon_holm.csv',index=False)

    rt=df.groupby('Algorithm').Seconds.mean().to_dict()
    runtime={
        'B/A':rt['B-TRPS-G2off']/rt['A-Std-G2off'],
        'B/R':rt['B-TRPS-G2off']/rt['R-RandomTR-G2off'],
        'D/C':rt['D-TRPS-G2on']/rt['C-Std-G2on'],
        'A/C':rt['A-Std-G2off']/rt['C-Std-G2on'],
    }
    B_A=gates['B-TRPS-G2off|A-Std-G2off']; B_R=gates['B-TRPS-G2off|R-RandomTR-G2off']
    D_C=gates['D-TRPS-G2on|C-Std-G2on']; A_C=gates['A-Std-G2off|C-Std-G2on']
    B_D=gates['B-TRPS-G2off|D-TRPS-G2on']
    H1=(B_A['median_ratio']<=0.98 and B_A['wins']>=11 and B_A['catastrophic_gt_1_20']==0 and runtime['B/A']<=1.15)
    H2=(B_R['median_ratio']<=0.98 and B_R['wins']>=11 and B_R['catastrophic_gt_1_20']==0)
    H3_positive=(D_C['median_ratio']<=0.98 and D_C['wins']>=11 and D_C['catastrophic_gt_1_20']==0)

    proc_cols=[c for c in ['ECPSAction1Pct','ECPSAction2Pct','ECPSAction3Pct','ECPSActionAvgPct',
                           'ECPSEvalCount','ECPSSuccCount','ECPSSuccessRate','ECPSProb1Mean',
                           'ECPSProb2Mean','ECPSProb3Mean','ECPSProbAvgMean','ECPSEntropyMean',
                           'NImprove','ImprovingFERate','RecoveryEventualProb','LongStagShare',
                           'NovelUsefulRate','NovelStrictImprove'] if c in df.columns]
    proc=df.groupby('Algorithm')[proc_cols].mean().T; proc.to_csv(rep/'process_metrics.csv')

    fam={}
    for pname,(a,b) in {'B_vs_A':('B-TRPS-G2off','A-Std-G2off'),
                         'B_vs_R':('B-TRPS-G2off','R-RandomTR-G2off'),
                         'D_vs_C':('D-TRPS-G2on','C-Std-G2on'),
                         'A_vs_C':('A-Std-G2off','C-Std-G2on')}.items():
        fam[pname]={}
        for fname,fs in FAMILIES.items():
            rr=np.array([ratio(med.loc[f,a],med.loc[f,b]) for f in fs])
            fam[pname][fname]=dict(functions=fs,median_ratio=float(np.median(rr)),
                                   wins=int((rr<1).sum()),losses=int((rr>1).sum()))
    (rep/'family_summary.json').write_text(json.dumps(fam,indent=2,ensure_ascii=False),encoding='utf-8')

    if H1 and H2: verdict='PROMOTE_TRPS_G2OFF_TO_P2'
    elif H1 and not H2: verdict='TRPS_NOT_BETTER_THAN_RANDOM_TRUST_REGION'
    elif H3_positive: verdict='G2_INTERACTION_SIGNAL_REQUIRES_NEW_PREREG'
    else: verdict='STOP_TRPS_NEGATIVE'
    summary=dict(results_dir=str(p1),runs=len(df),functions=FUNCS,seeds=SEEDS,gates=gates,
                 runtime_ratio=runtime,H1_pass=bool(H1),H2_pass=bool(H2),
                 H3_positive_interaction=bool(H3_positive),verdict=verdict,families=fam)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')

    fig,ax=plt.subplots(figsize=(11,5)); x=np.arange(len(FUNCS)); w=0.20
    for i,(a,b,lab) in enumerate([('B-TRPS-G2off','A-Std-G2off','B/A'),
                                   ('B-TRPS-G2off','R-RandomTR-G2off','B/R'),
                                   ('D-TRPS-G2on','C-Std-G2on','D/C'),
                                   ('A-Std-G2off','C-Std-G2on','A/C')]):
        ax.bar(x+(i-1.5)*w,[ratio(med.loc[f,a],med.loc[f,b]) for f in FUNCS],w,label=lab)
    ax.axhline(1,color='black',lw=1); ax.axhline(0.98,color='tab:green',ls='--',lw=1,label='0.98 gate')
    ax.axhline(1.20,color='tab:red',ls=':',lw=1,label='1.20 boundary')
    ax.set_yscale('log'); ax.set_xticks(x); ax.set_xticklabels([f'F{f}' for f in FUNCS])
    ax.set_ylabel('median final-error ratio (log scale)')
    ax.set_title('TRPS P1 (100k FE): 15-function ratios')
    ax.legend(ncol=3,fontsize=8); fig.tight_layout(); fig.savefig(rep/'per_function_ratio.png',dpi=180); plt.close(fig)

    lines=['# TRPS P1（100k FE）结果\n',f'- 结果目录：`{p1}`','- 750 次运行，5 臂 × 15 函数 × 10 种子，失败 0，全部 100,000 真 FE','',
           '## 预注册门槛\n',
           f"- H1 B/A：中位比 {B_A['median_ratio']:.6g}，胜/负 {B_A['wins']}/{B_A['losses']}，>1.20 {B_A['catastrophic_gt_1_20']}，时间 {runtime['B/A']:.4g} → **{'通过' if H1 else '不通过'}**",
           f"- H2 B/R：中位比 {B_R['median_ratio']:.6g}，胜/负 {B_R['wins']}/{B_R['losses']}，>1.20 {B_R['catastrophic_gt_1_20']} → **{'通过' if H2 else '不通过'}**",
           f"- H3 D/C：中位比 {D_C['median_ratio']:.6g}，胜/负 {D_C['wins']}/{D_C['losses']}，>1.20 {D_C['catastrophic_gt_1_20']} → **{'正向交互' if H3_positive else '未显示正向交互'}**",
           f"- H4 G2：A/C 中位比 {A_C['median_ratio']:.6g}，A 胜 {A_C['wins']}，>1.20 {A_C['catastrophic_gt_1_20']}；B/D 中位比 {B_D['median_ratio']:.6g}",
           f"- **最终裁定：{verdict}**",'',
           '| F | A | B | C | D | R | B/A | B/R | D/C | A/C |','|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        vals=[med.loc[f,a] for a in ARMS]
        lines.append('| '+str(f)+' | '+' | '.join(f'{v:.6g}' for v in vals)+
                     f" | {ratio(med.loc[f,'B-TRPS-G2off'],med.loc[f,'A-Std-G2off']):.4g}"
                     f" | {ratio(med.loc[f,'B-TRPS-G2off'],med.loc[f,'R-RandomTR-G2off']):.4g}"
                     f" | {ratio(med.loc[f,'D-TRPS-G2on'],med.loc[f,'C-Std-G2on']):.4g}"
                     f" | {ratio(med.loc[f,'A-Std-G2off'],med.loc[f,'C-Std-G2on']):.4g} |")
    lines += ['','## 分族结果','']
    for pname in fam:
        s='; '.join(f"{k}:{v['median_ratio']:.3g}({v['wins']}-{v['losses']})" for k,v in fam[pname].items())
        lines.append(f'- {pname}: {s}')
    lines += ['','## TRPS 过程证据（均值）','']
    if 'B-TRPS-G2off' in proc.columns:
        b=proc['B-TRPS-G2off']
        lines += [f"- 动作生成占比 Avg/α半步/β半步/δ半步：{b.get('ECPSActionAvgPct',float('nan')):.4g} / {b.get('ECPSAction1Pct',float('nan')):.4g} / {b.get('ECPSAction2Pct',float('nan')):.4g} / {b.get('ECPSAction3Pct',float('nan')):.4g}",
                  f"- 动作真实评价/成功/成功率：{b.get('ECPSEvalCount',float('nan')):.1f} / {b.get('ECPSSuccCount',float('nan')):.1f} / {b.get('ECPSSuccessRate',float('nan')):.4g}",
                  f"- 动作概率熵：{b.get('ECPSEntropyMean',float('nan')):.4g}"]
    (rep/'trps_p1_report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)

if __name__=='__main__': main()
