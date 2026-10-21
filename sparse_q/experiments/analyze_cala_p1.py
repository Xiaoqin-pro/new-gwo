#!/usr/bin/env python3
"""Analyze the 4-arm CALA P1 at 100k true FE."""
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
FUNCS=[1,3,4,7,10,11,13,14,16,18,20,22,24,26,30]
SEEDS=list(range(3186,3196))
ARMS=['A-TwoRoute','B-CALA','C-RandomLeader','D-V1']
FAMILIES={'unimodal':[1,3],'simple_multimodal':[4,7,10,11],'hybrid':[13,14,16,18,20],'composition':[22,24,26,30]}
PAIRS=[('B-CALA','A-TwoRoute'),('B-CALA','C-RandomLeader'),('A-TwoRoute','D-V1'),('B-CALA','D-V1'),('C-RandomLeader','D-V1')]

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
    p1=latest('cala_p1_*'); df=pd.read_csv(p1/'runs.csv')
    rep=ROOT/'reports'/'cala_p1_analysis'; rep.mkdir(parents=True,exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist())==FUNCS
    assert sorted(df.Seed.unique().tolist())==SEEDS
    assert set(df.Algorithm.unique())==set(ARMS)
    assert len(df)==600 and (df.Status=='ok').all() and (df.Evaluations==100000).all()
    med=df.pivot_table(index='FunctionID',columns='Algorithm',values='FinalError',aggfunc='median').reindex(FUNCS)
    med.to_csv(rep/'per_function_final_error_median.csv')

    gates={f'{a}|{b}':gate(med,a,b) for a,b in PAIRS}
    tests=[]
    for a,b in PAIRS: tests.extend(pairwise(df,a,b))
    pd.DataFrame(tests).to_csv(rep/'pairwise_wilcoxon_holm.csv',index=False)

    rt=df.groupby('Algorithm').Seconds.mean().to_dict()
    runtime={'B/A':rt['B-CALA']/rt['A-TwoRoute'],'C/A':rt['C-RandomLeader']/rt['A-TwoRoute'],'A/D':rt['A-TwoRoute']/rt['D-V1'],'B/D':rt['B-CALA']/rt['D-V1']}
    B_A=gates['B-CALA|A-TwoRoute']; B_C=gates['B-CALA|C-RandomLeader']; A_D=gates['A-TwoRoute|D-V1']; B_D=gates['B-CALA|D-V1']
    H1=(B_A['median_ratio']<=0.98 and B_A['wins']>=11 and B_A['catastrophic_gt_1_20']==0 and runtime['B/A']<=1.15)
    H2=(B_C['median_ratio']<=0.98 and B_C['wins']>=11 and B_C['catastrophic_gt_1_20']==0)
    H3=(A_D['median_ratio']<=1.05 and A_D['catastrophic_gt_1_20']==0 and B_D['median_ratio']<=1.05 and B_D['catastrophic_gt_1_20']==0)

    proc_cols=['CALARhoMean','CALARhoMax','CALARhoEnd','CALADMean','CALARandomLeaderCount','CALAUseCount','NImprove','NRecoveredEventual','RecoveryEventualProb','LongStagShare','NovMean','NovelUsefulRate','NovelStrictImprove']
    proc=df.groupby('Algorithm')[proc_cols].mean().T
    proc.to_csv(rep/'process_metrics.csv')

    fam={}
    for pname,(a,b) in {'B_vs_A':('B-CALA','A-TwoRoute'),'B_vs_C':('B-CALA','C-RandomLeader'),'A_vs_D':('A-TwoRoute','D-V1'),'B_vs_D':('B-CALA','D-V1')}.items():
        fam[pname]={}
        for fname,fs in FAMILIES.items():
            rr=np.array([ratio(med.loc[f,a],med.loc[f,b]) for f in fs])
            fam[pname][fname]=dict(functions=fs,median_ratio=float(np.median(rr)),wins=int((rr<1).sum()),losses=int((rr>1).sum()))
    (rep/'family_summary.json').write_text(json.dumps(fam,indent=2,ensure_ascii=False),encoding='utf-8')

    if H1 and H2 and H3: verdict='PROMOTE_CALA_TO_P2'
    elif H1 and H2 and not H3: verdict='CALA_EFFECTIVE_G2_REMOVAL_UNSAFE'
    elif H1 and not H2: verdict='LEADER_BIAS_ONLY'
    else: verdict='STOP_CALA_NEGATIVE'
    summary=dict(results_dir=str(p1),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 gates=gates,runtime_ratio=runtime,
                 H1_pass=bool(H1),H2_pass=bool(H2),H3_pass=bool(H3),verdict=verdict,families=fam)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')

    fig,ax=plt.subplots(figsize=(11,5)); x=np.arange(len(FUNCS)); w=0.20
    for i,(a,b,lab) in enumerate([('B-CALA','A-TwoRoute','B/A'),('B-CALA','C-RandomLeader','B/C'),('A-TwoRoute','D-V1','A/D'),('B-CALA','D-V1','B/D')]):
        ax.bar(x+(i-1.5)*w,[ratio(med.loc[f,a],med.loc[f,b]) for f in FUNCS],w,label=lab)
    ax.axhline(1,color='black',lw=1); ax.axhline(0.98,color='tab:green',ls='--',lw=1,label='0.98 gate'); ax.axhline(1.20,color='tab:red',ls=':',lw=1,label='1.20 catastrophic')
    ax.set_yscale('log'); ax.set_xticks(x); ax.set_xticklabels([f'F{f}' for f in FUNCS]); ax.set_ylabel('median final-error ratio (log scale)'); ax.set_title('CALA P1 (100k FE): 15-function ratios'); ax.legend(ncol=3,fontsize=8); fig.tight_layout(); fig.savefig(rep/'per_function_ratio.png',dpi=180); plt.close(fig)

    lines=['# CALA P1（100k FE）结果\n',f'- 结果目录：`{p1}`','- 600 次运行，4 臂 × 15 函数 × 10 种子，失败 0，全部 100,000 真 FE','',
           '## 预注册门槛\n',
           f"- H1 B/A：中位比 {B_A['median_ratio']:.6g}，胜/负 {B_A['wins']}/{B_A['losses']}，>1.20 {B_A['catastrophic_gt_1_20']}，时间 {runtime['B/A']:.4g} → **{'通过' if H1 else '不通过'}**",
           f"- H2 B/C：中位比 {B_C['median_ratio']:.6g}，胜/负 {B_C['wins']}/{B_C['losses']}，>1.20 {B_C['catastrophic_gt_1_20']} → **{'通过' if H2 else '不通过'}**",
           f"- H3 A/D、B/D：A/D 中位比 {A_D['median_ratio']:.6g}，B/D 中位比 {B_D['median_ratio']:.6g}，>1.20 A/D {A_D['catastrophic_gt_1_20']}、B/D {B_D['catastrophic_gt_1_20']} → **{'通过' if H3 else '不通过'}**",
           f"- **最终裁定：{verdict}**",'',
           '| F | A | B | C | D | B/A | B/C | A/D | B/D |','|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        vals=[med.loc[f,a] for a in ARMS]
        lines.append('| '+str(f)+' | '+' | '.join(f'{v:.6g}' for v in vals)+
                     f" | {ratio(med.loc[f,'B-CALA'],med.loc[f,'A-TwoRoute']):.4g}"
                     f" | {ratio(med.loc[f,'B-CALA'],med.loc[f,'C-RandomLeader']):.4g}"
                     f" | {ratio(med.loc[f,'A-TwoRoute'],med.loc[f,'D-V1']):.4g}"
                     f" | {ratio(med.loc[f,'B-CALA'],med.loc[f,'D-V1']):.4g} |")
    lines += ['','## 分族结果','']
    for pname in fam:
        s='; '.join(f"{k}:{v['median_ratio']:.3g}({v['wins']}-{v['losses']})" for k,v in fam[pname].items())
        lines.append(f'- {pname}: {s}')
    lines += ['','## CALA 过程证据（均值）','',
              f"- CALA rho 均值/最大/终点：{df[df.Algorithm=='B-CALA'].CALARhoMean.mean():.4g} / {df[df.Algorithm=='B-CALA'].CALARhoMax.mean():.4g} / {df[df.Algorithm=='B-CALA'].CALARhoEnd.mean():.4g}",
              f"- CALA D 均值：{df[df.Algorithm=='B-CALA'].CALADMean.mean():.4g}",
              f"- CALA 使用次数：{df[df.Algorithm=='B-CALA'].CALAUseCount.mean():.1f}",
              f"- RandomLeader 抽取次数：{df[df.Algorithm=='C-RandomLeader'].CALARandomLeaderCount.mean():.1f}",
              '','按预注册规则：H1、H2、H3 全部通过才进入 P2；H1 不通过则停止。']
    (rep/'cala_p1_report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)

if __name__=='__main__': main()
