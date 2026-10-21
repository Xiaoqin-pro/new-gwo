#!/usr/bin/env python3
"""Analyze the 5-arm AMC factorial P1 (archive credit x adaptive move control)."""
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
SEEDS=list(range(3176,3186))
ARMS=['A-Identity','B-ENAC','C-Identity-AMC','D-ENAC-AMC','E-V1']
FAMILIES={'unimodal':[1,3],'simple_multimodal':[4,7,10,11],'hybrid':[13,14,16,18,20],'composition':[22,24,26,30]}
PAIRS=[('C-Identity-AMC','A-Identity'),('D-ENAC-AMC','B-ENAC'),('B-ENAC','A-Identity'),('D-ENAC-AMC','C-Identity-AMC'),('C-Identity-AMC','E-V1'),('D-ENAC-AMC','E-V1')]

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
    cand=sorted((ROOT/'sparse_q'/'results').glob('amc_p1c_*'))
    p1=cand[-1] if cand else latest('amc_p1_*')
    df=pd.read_csv(p1/'runs.csv')
    rep=ROOT/'reports'/'amc_p1_analysis'; rep.mkdir(parents=True,exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist())==FUNCS
    assert sorted(df.Seed.unique().tolist())==SEEDS
    assert set(df.Algorithm.unique())==set(ARMS)
    assert len(df)==750 and (df.Status=='ok').all() and (df.Evaluations==30000).all()
    med=df.pivot_table(index='FunctionID',columns='Algorithm',values='FinalError',aggfunc='median').reindex(FUNCS)
    med.to_csv(rep/'per_function_final_error_median.csv')

    gates={f'{a}|{b}':gate(med,a,b) for a,b in PAIRS}
    tests=[]
    for a,b in PAIRS: tests.extend(pairwise(df,a,b))
    pd.DataFrame(tests).to_csv(rep/'pairwise_wilcoxon_holm.csv',index=False)

    # runtime: C/A, D/B and ENAC B/A same scaffold
    rt=df.groupby('Algorithm').Seconds.mean().to_dict()
    runtime={'C/A':rt['C-Identity-AMC']/rt['A-Identity'],'D/B':rt['D-ENAC-AMC']/rt['B-ENAC'],'B/A':rt['B-ENAC']/rt['A-Identity']}

    def passed(g,rkey):
        return (g['median_ratio']<=0.98 and g['wins']>=11 and g['catastrophic_gt_1_20']==0 and runtime[rkey]<=1.15)
    C_A=gates['C-Identity-AMC|A-Identity']; D_B=gates['D-ENAC-AMC|B-ENAC']; B_A=gates['B-ENAC|A-Identity']; D_C=gates['D-ENAC-AMC|C-Identity-AMC']
    C_A_pass=passed(C_A,'C/A'); D_B_pass=passed(D_B,'D/B'); B_A_pass=passed(B_A,'B/A'); D_C_pass=(D_C['median_ratio']<=0.98 and D_C['wins']>=11 and D_C['catastrophic_gt_1_20']==0)

    proc_cols=['AMCEndGamma','AMCMeanGamma','AMCValidFeedbackRounds','AMCExpandCount','AMCShrinkCount','G1EvalCount','G1SuccessCount','G1SuccessRate','G1ImpPer1000FE','EnacMeanTopRatio','EnacMeanWeightEntropy','EnacCenterEvalTotal','EnacCenterSuccTotal','EnacDroppedFeedback','EnacEImpPer1000FE']
    proc=df.groupby('Algorithm')[proc_cols].mean().T
    proc.to_csv(rep/'process_metrics.csv')

    fam={}
    for pname,(a,b) in {'C_vs_A':('C-Identity-AMC','A-Identity'),'D_vs_B':('D-ENAC-AMC','B-ENAC'),'B_vs_A':('B-ENAC','A-Identity'),'D_vs_C':('D-ENAC-AMC','C-Identity-AMC')}.items():
        fam[pname]={}
        for fname,fs in FAMILIES.items():
            rr=np.array([ratio(med.loc[f,a],med.loc[f,b]) for f in fs])
            fam[pname][fname]=dict(functions=fs,median_ratio=float(np.median(rr)),wins=int((rr<1).sum()),losses=int((rr>1).sum()))
    (rep/'family_summary.json').write_text(json.dumps(fam,indent=2,ensure_ascii=False),encoding='utf-8')

    if C_A_pass and D_B_pass: verdict='PROMOTE_AMC_TO_P2'
    elif C_A_pass and not D_B_pass: verdict='IDENTITY_AMC_ONLY'
    elif D_B_pass and not C_A_pass: verdict='ENAC_AMC_ONLY'
    else: verdict='STOP_AMC_NEGATIVE'
    summary=dict(results_dir=str(p1),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 gates=gates,runtime_ratio=runtime,
                 C_A_pass=bool(C_A_pass),D_B_pass=bool(D_B_pass),B_A_pass=bool(B_A_pass),D_C_pass=bool(D_C_pass),
                 verdict=verdict,families=fam)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')

    fig,ax=plt.subplots(figsize=(11,5)); x=np.arange(len(FUNCS)); w=0.20
    for i,(a,b,lab) in enumerate([('C-Identity-AMC','A-Identity','C/A'),('D-ENAC-AMC','B-ENAC','D/B'),('B-ENAC','A-Identity','B/A'),('D-ENAC-AMC','C-Identity-AMC','D/C')]):
        ax.bar(x+(i-1.5)*w,[ratio(med.loc[f,a],med.loc[f,b]) for f in FUNCS],w,label=lab)
    ax.axhline(1,color='black',lw=1); ax.axhline(0.98,color='tab:green',ls='--',lw=1,label='0.98 gate'); ax.axhline(1.20,color='tab:red',ls=':',lw=1,label='1.20 catastrophic')
    ax.set_yscale('log'); ax.set_xticks(x); ax.set_xticklabels([f'F{f}' for f in FUNCS]); ax.set_ylabel('median final-error ratio (log scale)'); ax.set_title('AMC P1: 15-function factorial ratios'); ax.legend(ncol=3,fontsize=8); fig.tight_layout(); fig.savefig(rep/'per_function_ratio.png',dpi=180); plt.close(fig)

    lines=['# AMC 5臂双因素 P1 结果\n',f'- 结果目录：`{p1}`','- 750 次运行，5 臂 × 15 函数 × 10 种子，失败 0，全部 30,000 真 FE','',
           '## 预注册门槛\n',
           f"- C/A：中位比 {C_A['median_ratio']:.6g}，胜/负 {C_A['wins']}/{C_A['losses']}，>1.20 {C_A['catastrophic_gt_1_20']}，时间 {runtime['C/A']:.4g} → **{'通过' if C_A_pass else '不通过'}**",
           f"- D/B：中位比 {D_B['median_ratio']:.6g}，胜/负 {D_B['wins']}/{D_B['losses']}，>1.20 {D_B['catastrophic_gt_1_20']}，时间 {runtime['D/B']:.4g} → **{'通过' if D_B_pass else '不通过'}**",
           f"- B/A（ENAC 归一化）：中位比 {B_A['median_ratio']:.6g}，胜/负 {B_A['wins']}/{B_A['losses']}，>1.20 {B_A['catastrophic_gt_1_20']} → **{'通过' if B_A_pass else '不通过'}**",
           f"- D/C（交互）：中位比 {D_C['median_ratio']:.6g}，胜/负 {D_C['wins']}/{D_C['losses']}，>1.20 {D_C['catastrophic_gt_1_20']} → **{'通过' if D_C_pass else '不通过'}**",
           f"- **最终裁定：{verdict}**",'',
           '| F | A | B | C | D | E | C/A | D/B | B/A | D/C |','|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        vals=[med.loc[f,a] for a in ARMS]
        lines.append('| '+str(f)+' | '+' | '.join(f'{v:.6g}' for v in vals)+
                     f" | {ratio(med.loc[f,'C-Identity-AMC'],med.loc[f,'A-Identity']):.4g}"
                     f" | {ratio(med.loc[f,'D-ENAC-AMC'],med.loc[f,'B-ENAC']):.4g}"
                     f" | {ratio(med.loc[f,'B-ENAC'],med.loc[f,'A-Identity']):.4g}"
                     f" | {ratio(med.loc[f,'D-ENAC-AMC'],med.loc[f,'C-Identity-AMC']):.4g} |")
    lines += ['','## 分族结果','']
    for pname in fam:
        s='; '.join(f"{k}:{v['median_ratio']:.3g}({v['wins']}-{v['losses']})" for k,v in fam[pname].items())
        lines.append(f'- {pname}: {s}')
    lines += ['','## AMC 过程证据（均值）','',
              f"- C gamma 均值/终点：{df[df.Algorithm=='C-Identity-AMC'].AMCMeanGamma.mean():.4g} / {df[df.Algorithm=='C-Identity-AMC'].AMCEndGamma.mean():.4g}",
              f"- D gamma 均值/终点：{df[df.Algorithm=='D-ENAC-AMC'].AMCMeanGamma.mean():.4g} / {df[df.Algorithm=='D-ENAC-AMC'].AMCEndGamma.mean():.4g}",
              f"- C/D 扩张事件：{df[df.Algorithm=='C-Identity-AMC'].AMCExpandCount.mean():.1f} / {df[df.Algorithm=='D-ENAC-AMC'].AMCExpandCount.mean():.1f}",
              f"- C/D 收缩事件：{df[df.Algorithm=='C-Identity-AMC'].AMCShrinkCount.mean():.1f} / {df[df.Algorithm=='D-ENAC-AMC'].AMCShrinkCount.mean():.1f}",
              f"- C/D G1 成功率：{df[df.Algorithm=='C-Identity-AMC'].G1SuccessRate.mean():.4f} / {df[df.Algorithm=='D-ENAC-AMC'].G1SuccessRate.mean():.4f}",
              '','按预注册规则：C/A 与 D/B 都通过才进入 P2；只有一项通过只支持对应信用基线；均不通过则停止 AMC。']
    (rep/'amc_p1_report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)

if __name__=='__main__': main()
