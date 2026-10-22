#!/usr/bin/env python3
"""Analyze the passive BGR P0 audit (40 runs, 100k FE)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd

ROOT=Path(__file__).resolve().parents[2]
FUNCS=[1,3,4,7,10,13,20,30]
SEEDS=list(range(3296,3301))

def latest(pat):
    ds=sorted((ROOT/'sparse_q'/'results').glob(pat))
    if not ds: raise SystemExit('missing results: '+pat)
    return ds[-1]
def main():
    p=latest('bgr_audit_*'); df=pd.read_csv(p/'runs.csv')
    rep=ROOT/'reports'/'bgr_p0_audit'; rep.mkdir(parents=True,exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed mismatch'
    assert len(df)==40 and (df.Status=='ok').all(),'incomplete audit'
    assert (df.Evaluations==100000).all(),'FE mismatch'
    per=df.groupby('FunctionID')[['BgrG1Cand','BgrOutCand','BgrOutCoord','BgrTotalCoord']].sum()
    per['out_cand_rate']=per.BgrOutCand/per.BgrG1Cand.replace(0,np.nan)
    per['out_coord_rate']=per.BgrOutCoord/per.BgrTotalCoord.replace(0,np.nan)
    per['median_clip_dist']=df.groupby('FunctionID').BgrClipDistMedian.median()
    per['mean_clip_dist']=df.groupby('FunctionID').BgrClipDistMean.mean()
    per['p90_clip_dist']=df.groupby('FunctionID').BgrClipDistP90.mean()
    per['seeds_ge20']=df.assign(hit=df.BgrOutCandRate>=0.20).groupby('FunctionID').hit.sum()
    per['early_rate']=df.groupby('FunctionID').BgrEarlyRate.mean()
    per['mid_rate']=df.groupby('FunctionID').BgrMidRate.mean()
    per['late_rate']=df.groupby('FunctionID').BgrLateRate.mean()
    per.to_csv(rep/'per_function_audit.csv')
    f1=int((per.seeds_ge20>=4).sum())>=6
    f2=int((per.median_clip_dist>0.01).sum())>=6
    phase_rates=np.array([per.early_rate.mean(),per.mid_rate.mean(),per.late_rate.mean()])
    f3=bool(np.min(phase_rates)>0.05)
    gate=bool(f1 and f2 and f3)
    summary=dict(results_dir=str(p),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 total_g1=int(df.BgrG1Cand.sum()),total_out_cand=int(df.BgrOutCand.sum()),
                 total_out_coord=int(df.BgrOutCoord.sum()),total_coord=int(df.BgrTotalCoord.sum()),
                 global_out_cand_rate=float(df.BgrOutCand.sum()/max(df.BgrG1Cand.sum(),1)),
                 global_out_coord_rate=float(df.BgrOutCoord.sum()/max(df.BgrTotalCoord.sum(),1)),
                 functions_seed_gate=int((per.seeds_ge20>=4).sum()),
                 functions_distance_gate=int((per.median_clip_dist>0.01).sum()),
                 mean_phase_rates={k:float(v) for k,v in zip(['early','mid','late'],phase_rates)},
                 gate_candidate_rate=bool(f1),gate_distance=bool(f2),gate_phase=bool(f3),gate_pass=gate)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    lines=['# BGR P0 被动边界审计结果','',f'- 结果目录：`{p}`','- 40 次运行，8 函数 × 5 新种子，100k FE，0 失败','- 审计模式与冻结 G1+E 逐位一致（合约测试）','',
           '## 边界失真机会','',
           f'- G1 候选：**{summary["total_g1"]}**',
           f'- 越界候选：**{summary["total_out_cand"]}**（{summary["global_out_cand_rate"]:.2%}）',
           f'- 越界坐标：**{summary["total_out_coord"]} / {summary["total_coord"]}**（{summary["global_out_coord_rate"]:.2%}）',
           f'- 早/中/后期越界率均值：**{phase_rates[0]:.2%} / {phase_rates[1]:.2%} / {phase_rates[2]:.2%}**','',
           '## 分函数结果','',
           '| F | out candidate% | out coord% | median clip dist | seeds ≥20% | early/mid/late |','|---:|---:|---:|---:|---:|---:|']
    for f,row in per.iterrows():
        lines.append(f"| {int(f)} | {row.out_cand_rate:.1%} | {row.out_coord_rate:.2%} | {row.median_clip_dist:.4g} | {int(row.seeds_ge20)}/5 | {row.early_rate:.1%}/{row.mid_rate:.1%}/{row.late_rate:.1%} |")
    lines += ['','## P0 判定','',
              f"- 至少 6/8 函数在 ≥4/5 种子上越界率 ≥20%：**{'通过' if f1 else '不通过'}**（{summary['functions_seed_gate']}/8）",
              f"- 至少 6/8 函数截断位移中位数 >0.01：**{'通过' if f2 else '不通过'}**（{summary['functions_distance_gate']}/8）",
              f"- 早/中/后期均有现象：**{'通过' if f3 else '不通过'}**（{phase_rates[0]:.2%}/{phase_rates[1]:.2%}/{phase_rates[2]:.2%}）",'',
              f"**最终判定：{'PROMOTE_BGR_TO_CONFIRMATION' if gate else 'STOP_BGR_P0'}**"]
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)
if __name__=='__main__': main()
