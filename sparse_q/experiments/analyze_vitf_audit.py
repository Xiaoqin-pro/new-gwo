#!/usr/bin/env python3
"""Analyze the passive VITF P0 audit (40 runs, 100k FE)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd

ROOT=Path(__file__).resolve().parents[2]
FUNCS=[1,3,4,7,10,13,20,30]
SEEDS=list(range(3271,3276))

def latest(pat):
    ds=sorted((ROOT/'sparse_q'/'results').glob(pat))
    if not ds: raise SystemExit('missing results: '+pat)
    return ds[-1]
def wmean(v,w):
    v=np.asarray(v,float); w=np.asarray(w,float)
    if w.sum()<=0: return float('nan')
    return float(np.sum(v*w)/np.sum(w))

def main():
    p=latest('vitf_audit_*'); df=pd.read_csv(p/'runs.csv')
    rep=ROOT/'reports'/'vitf_p0_audit'; rep.mkdir(parents=True,exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed mismatch'
    assert len(df)==40 and (df.Status=='ok').all(),'incomplete audit'
    assert (df.Evaluations==100000).all(),'FE mismatch'
    opp=float(df.VitfG1Opp.sum()); events=float(df.VitfEvents.sum())
    arc=float(df.VitfArcEvents.sum()); angles=float(df.VitfAngleCount.sum())
    act_rate=events/max(opp,1)
    useful=wmean(df.VitfUsefulIndependentRate,df.VitfArcEvents)
    indep=wmean(df.VitfIndependentRate,df.VitfArcEvents)
    angle10=wmean(df.VitfAngle10Rate,df.VitfAngleCount)
    angle30=wmean(df.VitfAngle30Rate,df.VitfAngleCount)
    mean_angle=wmean(df.VitfMeanAngle,df.VitfAngleCount)
    mean_arc=wmean(df.VitfMeanArcDist,df.VitfArcEvents)
    pmed=wmean(df.VitfPBetterArcMedianRate,df.VitfArcEvents)
    pbest=wmean(df.VitfPBetterArcBestRate,df.VitfArcEvents)
    per=df.groupby('FunctionID')[['VitfG1Opp','VitfEvents','VitfArcEvents','VitfAngleCount']].sum()
    per['activation']=per.VitfEvents/per.VitfG1Opp.replace(0,np.nan)
    per['useful_independent']=[wmean(g.VitfUsefulIndependentRate,g.VitfArcEvents) for _,g in df.groupby('FunctionID')]
    per['independent']=[wmean(g.VitfIndependentRate,g.VitfArcEvents) for _,g in df.groupby('FunctionID')]
    per['mean_angle']=[wmean(g.VitfMeanAngle,g.VitfAngleCount) for _,g in df.groupby('FunctionID')]
    per['angle10_rate']=[wmean(g.VitfAngle10Rate,g.VitfAngleCount) for _,g in df.groupby('FunctionID')]
    per['mean_arc_dist']=[wmean(g.VitfMeanArcDist,g.VitfArcEvents) for _,g in df.groupby('FunctionID')]
    per['p_better_median']=[wmean(g.VitfPBetterArcMedianRate,g.VitfArcEvents) for _,g in df.groupby('FunctionID')]
    per.to_csv(rep/'per_function_audit.csv')
    g1=act_rate>=0.20
    g2=np.isfinite(useful) and useful>=0.20
    g3=np.isfinite(angle10) and angle10>=0.20
    g4=int(((per.VitfArcEvents>0)&(per.VitfAngleCount>0)).sum())>=4
    gate=bool(g1 and g2 and g3 and g4)
    summary=dict(results_dir=str(p),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 g1_opportunities=opp,vitf_events=events,activation_rate=act_rate,
                 angle_count=angles,mean_angle=mean_angle,angle10_rate=angle10,angle30_rate=angle30,
                 arc_events=arc,mean_arc_distance=mean_arc,independent_rate=indep,useful_independent_rate=useful,
                 p_better_arc_median_rate=pmed,p_better_arc_best_rate=pbest,
                 functions_with_events=int(((per.VitfArcEvents>0)&(per.VitfAngleCount>0)).sum()),
                 gate_activation=bool(g1),gate_useful_independent=bool(g2),gate_angle=bool(g3),
                 gate_multi_family=bool(g4),gate_pass=gate)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    lines=['# VITF P0 被动审计结果','',f'- 结果目录：`{p}`','- 40 次运行，8 函数 × 5 新种子，100k FE，0 失败','- 审计模式与冻结 G1+E 逐位一致（合约测试）','',
           '## 核心指标','',
           f'- G1 审计机会：**{opp:.0f}**；VITF 激活：**{events:.0f}**（{act_rate:.2%}）',
           f'- 可计算档案距离的激活事件：**{arc:.0f}**；P 独立于 E 的比例：**{indep:.2%}**',
           f'- 独立且优于档案中位质量的比例：**{useful:.2%}**',
           f'- 可计算夹角事件：**{angles:.0f}**；平均夹角：**{mean_angle:.4f}°**；>10° 比例：**{angle10:.2%}**；>30° 比例：**{angle30:.2%}**',
           f'- P 到 E 的平均归一化最近距离：**{mean_arc:.6g}**',
           f'- P 优于档案中位质量的比例：**{pmed:.2%}**；优于档案最优的比例：**{pbest:.2%}**','',
           '## 分函数结果','',
           '| F | activation% | independent% | useful-indep% | mean angle | angle>10% | arc events |','|---:|---:|---:|---:|---:|---:|---:|']
    for f,row in per.iterrows():
        lines.append(f"| {int(f)} | {row.activation:.1%} | {row.independent:.1%} | {row.useful_independent:.1%} | {row.mean_angle:.3f} | {row.angle10_rate:.1%} | {row.VitfArcEvents:.0f} |")
    lines += ['','## P0 判定','',
              f"- 激活率 ≥20%：**{'通过' if g1 else '不通过'}**（{act_rate:.2%}）",
              f"- 独立有用率 ≥20%：**{'通过' if g2 else '不通过'}**（{useful:.2%}）",
              f"- 夹角 >10° 比例 ≥20%：**{'通过' if g3 else '不通过'}**（{angle10:.2%}）",
              f"- 至少 4/8 函数出现事件：**{'通过' if g4 else '不通过'}**（{int(((per.VitfEvents>0)&(per.VitfAngleCount>0)).sum())}/8）",'',
              f"**最终判定：{'PROMOTE_VITF_TO_DEVELOPMENT' if gate else 'STOP_VITF_P0'}**"]
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)

if __name__=='__main__': main()
