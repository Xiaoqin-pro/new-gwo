#!/usr/bin/env python3
"""Analyze the four-arm TSD P1 at 100k true FE."""
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
FUNCS=[1,3,4,7,10,11,13,14,16,18,20,22,24,26,30]
SEEDS=list(range(3261,3271))
ARMS=['A-Frozen','B-VGA','C-TSDbase','D-TSDfull']
FAMILIES={'unimodal':[1,3],'simple_multimodal':[4,7,10,11],'hybrid':[13,14,16,18,20],'composition':[22,24,26,30]}
PAIRS=[('D-TSDfull','A-Frozen'),('C-TSDbase','A-Frozen'),('D-TSDfull','C-TSDbase'),('D-TSDfull','B-VGA'),('C-TSDbase','B-VGA')]

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
def gate(med,a,b):
    rr=np.array([ratio(med.loc[f,a],med.loc[f,b]) for f in FUNCS])
    return dict(A=a,B=b,median_ratio=float(np.median(rr)),wins=int((rr<1).sum()),
                losses=int((rr>1).sum()),catastrophic_gt_1_20=int((rr>1.20).sum()),
                ratios={int(f):float(v) for f,v in zip(FUNCS,rr)})
def main():
    p1=latest('tsd_p1_*'); df=pd.read_csv(p1/'runs.csv')
    rep=ROOT/'reports'/'tsd_p1_analysis'; rep.mkdir(parents=True,exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function set mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed set mismatch'
    assert set(df.Algorithm.unique())==set(ARMS),'arm labels mismatch'
    assert len(df)==600,f'expected 600 runs, got {len(df)}'
    assert (df.Status=='ok').all(),'failed runs present'
    assert (df.Evaluations==100000).all(),'FE mismatch'
    med=df.pivot_table(index='FunctionID',columns='Algorithm',values='FinalError',aggfunc='median').reindex(FUNCS)
    med.to_csv(rep/'per_function_final_error_median.csv')
    gates={f'{a}|{b}':gate(med,a,b) for a,b in PAIRS}
    tests=[]
    for a,b in PAIRS: tests.extend(pairwise(df,a,b))
    pd.DataFrame(tests).to_csv(rep/'pairwise_wilcoxon_holm.csv',index=False)
    rt=df.groupby('Algorithm').Seconds.mean().to_dict()
    runtime={'D/A':rt['D-TSDfull']/rt['A-Frozen'],'C/A':rt['C-TSDbase']/rt['A-Frozen'],
             'D/C':rt['D-TSDfull']/rt['C-TSDbase'],'D/B':rt['D-TSDfull']/rt['B-VGA'],
             'C/B':rt['C-TSDbase']/rt['B-VGA']}
    D_A=gates['D-TSDfull|A-Frozen']; C_A=gates['C-TSDbase|A-Frozen']
    D_C=gates['D-TSDfull|C-TSDbase']; D_B=gates['D-TSDfull|B-VGA']; C_B=gates['C-TSDbase|B-VGA']
    def passg(g,tr): return bool(g['median_ratio']<=0.98 and g['wins']>=11 and g['catastrophic_gt_1_20']==0 and tr<=1.15)
    H1=passg(D_A,runtime['D/A']); H2=passg(C_A,runtime['C/A']); H3=passg(D_C,runtime['D/C']); H4=passg(D_B,runtime['D/B'])
    # comparison-level Wilcoxon on 15 per-function median log ratios, Holm over four primary comparisons
    prim=[('D/A',D_A),('C/A',C_A),('D/C',D_C),('D/B',D_B)]
    comp_p=[]; comp_labels=[]
    for lab,g in prim:
        rr=np.array([abs(np.log(max(v,1e-300))) for v in g['ratios'].values()])
        try: _,pv=wilcoxon(rr,alternative='two-sided',zero_method='wilcox',method='auto')
        except ValueError: pv=np.nan
        comp_p.append(pv); comp_labels.append(lab)
    comp_holm=holm(comp_p)
    proc_cols=[c for c in ['TsdOn','TsdG1Eval','TsdG1Split','TsdStateSplitRate','TsdEEval','TsdECursorOnly',
                           'TsdCursorOnlyRate','TsdProtectUpdates','TsdMeanGapDist','TsdMeanGapFit',
                           'NImprove','ImprovingFERate','RecoveryEventualProb','LongStagShare'] if c in df.columns]
    proc=df.groupby('Algorithm')[proc_cols].mean().T; proc.to_csv(rep/'process_metrics.csv')
    fam={}
    for pname,(a,b) in {'D_vs_A':('D-TSDfull','A-Frozen'),'C_vs_A':('C-TSDbase','A-Frozen'),
                         'D_vs_C':('D-TSDfull','C-TSDbase'),'D_vs_B':('D-TSDfull','B-VGA')}.items():
        fam[pname]={}
        for fname,fs in FAMILIES.items():
            rr=np.array([ratio(med.loc[f,a],med.loc[f,b]) for f in fs])
            fam[pname][fname]=dict(functions=fs,median_ratio=float(np.median(rr)),wins=int((rr<1).sum()),losses=int((rr>1).sum()))
    (rep/'family_summary.json').write_text(json.dumps(fam,indent=2,ensure_ascii=False),encoding='utf-8')
    if H1 and H2 and H3 and H4: verdict='PROMOTE_TSD_FULL_TO_P2'
    elif H1 and H2 and H3 and not H4: verdict='TSD_EFFECTIVE_VGA_BOUNDARY'
    elif H1 and not H2: verdict='FULL_ONLY_EFFECT'
    elif H2 and not H1: verdict='BASE_EFFECT_FULL_OVERFIT'
    else: verdict='STOP_TSD_NEGATIVE'
    summary=dict(results_dir=str(p1),runs=len(df),functions=FUNCS,seeds=SEEDS,gates=gates,
                 runtime_ratio=runtime,H1_D_A=bool(H1),H2_C_A=bool(H2),H3_D_C=bool(H3),H4_D_B=bool(H4),
                 comparison_level_holm={lab:float(v) if np.isfinite(v) else np.nan for lab,v in zip(comp_labels,comp_holm)},
                 verdict=verdict,families=fam)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    fig,ax=plt.subplots(figsize=(11,5)); x=np.arange(len(FUNCS)); w=0.20
    for i,(a,b,lab) in enumerate([('D-TSDfull','A-Frozen','D/A'),('C-TSDbase','A-Frozen','C/A'),
                                   ('D-TSDfull','C-TSDbase','D/C'),('D-TSDfull','B-VGA','D/B')]):
        ax.bar(x+(i-1.5)*w,[ratio(med.loc[f,a],med.loc[f,b]) for f in FUNCS],w,label=lab)
    ax.axhline(1,color='black',lw=1); ax.axhline(0.98,color='tab:green',ls='--',lw=1,label='0.98 gate')
    ax.axhline(1.20,color='tab:red',ls=':',lw=1,label='1.20 boundary')
    ax.set_yscale('log'); ax.set_xticks(x); ax.set_xticklabels([f'F{f}' for f in FUNCS])
    ax.set_ylabel('median final-error ratio (log scale)'); ax.set_title('TSD P1 (100k FE): 15-function ratios')
    ax.legend(ncol=3,fontsize=8); fig.tight_layout(); fig.savefig(rep/'per_function_ratio.png',dpi=180); plt.close(fig)
    lines=['# TSD P1（100k FE）结果\n',f'- 结果目录：`{p1}`','- 600 次运行，4 臂 × 15 函数 × 10 种子，失败 0，全部 100,000 真 FE','','## 预注册门槛\n',
           f"- H1 D/A：中位比 {D_A['median_ratio']:.6g}，胜/负 {D_A['wins']}/{D_A['losses']}，>1.20 {D_A['catastrophic_gt_1_20']}，时间 {runtime['D/A']:.4g} → **{'通过' if H1 else '不通过'}**",
           f"- H2 C/A：中位比 {C_A['median_ratio']:.6g}，胜/负 {C_A['wins']}/{C_A['losses']}，>1.20 {C_A['catastrophic_gt_1_20']}，时间 {runtime['C/A']:.4g} → **{'通过' if H2 else '不通过'}**",
           f"- H3 D/C：中位比 {D_C['median_ratio']:.6g}，胜/负 {D_C['wins']}/{D_C['losses']}，>1.20 {D_C['catastrophic_gt_1_20']} → **{'通过' if H3 else '不通过'}**",
           f"- H4 D/B：中位比 {D_B['median_ratio']:.6g}，胜/负 {D_B['wins']}/{D_B['losses']}，>1.20 {D_B['catastrophic_gt_1_20']} → **{'通过' if H4 else '不通过'}**",
           f"- 辅助 C/B：中位比 {C_B['median_ratio']:.6g}，胜/负 {C_B['wins']}/{C_B['losses']}",
           f"- **最终裁定：{verdict}**",'',
           '| F | A | B | C | D | D/A | C/A | D/C | D/B |','|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        vals=[med.loc[f,a] for a in ARMS]
        lines.append('| '+str(f)+' | '+' | '.join(f'{v:.6g}' for v in vals)+
                     f" | {ratio(med.loc[f,'D-TSDfull'],med.loc[f,'A-Frozen']):.4g}"
                     f" | {ratio(med.loc[f,'C-TSDbase'],med.loc[f,'A-Frozen']):.4g}"
                     f" | {ratio(med.loc[f,'D-TSDfull'],med.loc[f,'C-TSDbase']):.4g}"
                     f" | {ratio(med.loc[f,'D-TSDfull'],med.loc[f,'B-VGA']):.4g} |")
    lines += ['','## 分族结果','']
    for pname in fam:
        s='; '.join(f"{k}:{v['median_ratio']:.3g}({v['wins']}-{v['losses']})" for k,v in fam[pname].items())
        lines.append(f'- {pname}: {s}')
    lines += ['','## TSD 过程证据（均值）','']
    if 'D-TSDfull' in proc.columns:
        b=proc['D-TSDfull']
        lines += [f"- G1 评价/分裂/分裂率：{b.get('TsdG1Eval',float('nan')):.1f} / {b.get('TsdG1Split',float('nan')):.1f} / {b.get('TsdStateSplitRate',float('nan')):.4g}",
                  f"- E 评价/仅轨迹机会/比例：{b.get('TsdEEval',float('nan')):.1f} / {b.get('TsdECursorOnly',float('nan')):.1f} / {b.get('TsdCursorOnlyRate',float('nan')):.4g}",
                  f"- 保护性更新：{b.get('TsdProtectUpdates',float('nan')):.1f}",
                  f"- 平均 P/Z 距离与适应度差：{b.get('TsdMeanGapDist',float('nan')):.6g} / {b.get('TsdMeanGapFit',float('nan')):.6g}"]
    (rep/'tsd_p1_report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)
if __name__=='__main__': main()
