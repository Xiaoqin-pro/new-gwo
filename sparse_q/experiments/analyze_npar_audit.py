#!/usr/bin/env python3
"""Analyze the passive NPAR P0 audit (40 runs, 100k FE)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd

ROOT=Path(__file__).resolve().parents[2]
FUNCS=[1,3,4,7,10,13,20,30]
SEEDS=list(range(3246,3251))

def latest(pat):
    ds=sorted((ROOT/'sparse_q'/'results').glob(pat))
    if not ds: raise SystemExit('missing results: '+pat)
    return ds[-1]

def main():
    p0=latest('npar_audit_*')
    df=pd.read_csv(p0/'runs.csv')
    rep=ROOT/'reports'/'npar_p0_audit'; rep.mkdir(parents=True,exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed mismatch'
    assert len(df)==40 and (df.Status=='ok').all(),'incomplete audit'
    assert (df.Evaluations==100000).all(),'FE mismatch'

    far=float(df.NparFarEvents.sum())
    changed=float(df.NparChangedTarget.sum())
    eligible=float(df.NparEligibleEvents.sum())
    fallback=float(df.NparFallbackEvents.sum())
    nne=float(df.NparNNEvents.sum())
    nnb=float((df.NparMeanNNBefore*df.NparNNEvents).sum())/max(nne,1)
    nng=float((df.NparMeanNNGlobal*df.NparNNEvents).sum())/max(nne,1)
    nnp=float((df.NparMeanNNPair*df.NparNNEvents).sum())/max(nne,1)
    changed_frac=changed/max(far,1)
    eligible_frac=eligible/max(far,1)
    fallback_frac=fallback/max(far,1)
    delta=(nng-nnp)/nng if nng>0 else float('nan')
    ev=df[df.NparNNEvents>0].copy()
    run_delta=(ev.NparMeanNNGlobal-ev.NparMeanNNPair)/ev.NparMeanNNGlobal.replace(0,np.nan)
    positive_runs=int((run_delta>0).sum()); run_total=int(run_delta.notna().sum())
    per_func=df.groupby('FunctionID')[['NparFullBetter','NparFarEvents','NparChangedTarget','NparEligibleEvents','NparFallbackEvents','NparNNEvents']].sum()
    per_func['changed_frac']=per_func.NparChangedTarget/per_func.NparFarEvents.replace(0,np.nan)
    per_func['eligible_frac']=per_func.NparEligibleEvents/per_func.NparFarEvents.replace(0,np.nan)
    per_func.to_csv(rep/'per_function_audit.csv')
    gate_changed=changed_frac>=0.20
    gate_nn=(np.isfinite(delta) and delta>0 and positive_runs>=max(1,int(np.ceil(0.60*run_total)))) if run_total else False
    gate_spread=int((per_func.NparFarEvents>0).sum())>=4
    gate=bool(gate_changed and gate_nn and gate_spread)
    summary=dict(results_dir=str(p0),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 far_events=far,changed_target=changed,eligible_events=eligible,fallback_events=fallback,
                 changed_fraction=changed_frac,eligible_fraction=eligible_frac,fallback_fraction=fallback_frac,
                 nn_events=nne,nn_before_mean=nnb,nn_global_mean=nng,nn_pair_mean=nnp,
                 nn_relative_improvement=delta,positive_nn_runs=positive_runs,nn_runs=run_total,
                 gate_changed_20pct=bool(gate_changed),gate_nn_improvement=bool(gate_nn),
                 gate_multi_family=bool(gate_spread),gate_pass=gate)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')

    lines=['# NPAR P0 被动审计结果','',f'- 结果目录：`{p0}`','- 40 次运行，8 函数 × 5 新种子，100k FE，0 失败','- 审计模式与冻结 G1+E 逐位一致（合约测试）','',
           '## 核心事件','',
           f'- 满载且候选优于全局最差的远距离插入事件：**{far:.0f}**',
           f'- NPAR 会改变删除对象：**{changed:.0f}**（{changed_frac:.2%}）',
           f'- NPAR 条件满足、可实际替换拥挤中心：**{eligible:.0f}**（{eligible_frac:.2%}）',
           f'- NPAR 条件不满足、回退全局最差：**{fallback:.0f}**（{fallback_frac:.2%}）','',
           '## 反事实覆盖','',
           f'- 平均最近邻距离（事件加权）：全局最差替换 **{nng:.6g}**，NPAR 替换 **{nnp:.6g}**',
           f'- NPAR 相对全局最差替换的覆盖改善：**{delta:.4%}**' if np.isfinite(delta) else '- NPAR 覆盖改善：无法计算',
           f'- 有事件运行中，NPAR 覆盖更好的运行：**{positive_runs}/{run_total}**','',
           '## 分函数事件','',
           '| F | far | changed | eligible | fallback | changed% | eligible% |','|---:|---:|---:|---:|---:|---:|---:|']
    for f,row in per_func.iterrows():
        lines.append(f"| {int(f)} | {row.NparFarEvents:.0f} | {row.NparChangedTarget:.0f} | {row.NparEligibleEvents:.0f} | {row.NparFallbackEvents:.0f} | {row.changed_frac:.1%} | {row.eligible_frac:.1%} |")
    lines += ['','## P0 判定','',
              f"- 改变删除对象比例 ≥20%：**{'通过' if gate_changed else '不通过'}**（{changed_frac:.2%}）",
              f"- NPAR 反事实覆盖改善：**{'通过' if gate_nn else '不通过'}**（改善 {delta:.4%}，正改善运行 {positive_runs}/{run_total}）" if np.isfinite(delta) else "- NPAR 反事实覆盖改善：**不通过**（无有效事件）",
              f"- 多函数出现事件：**{'通过' if gate_spread else '不通过'}**（{int((per_func.NparFarEvents>0).sum())}/8）",'',
              f"**最终判定：{'PROMOTE_NPAR_TO_P1' if gate else 'STOP_NPAR_P0'}**"]
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)

if __name__=='__main__': main()
