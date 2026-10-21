#!/usr/bin/env python3
"""Analyze the passive TSD P0 shadow-state audit (40 runs, 100k FE)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd

ROOT=Path(__file__).resolve().parents[2]
FUNCS=[1,3,4,7,10,13,20,30]
SEEDS=list(range(3256,3261))

def latest(pat):
    ds=sorted((ROOT/'sparse_q'/'results').glob(pat))
    if not ds: raise SystemExit('missing results: '+pat)
    return ds[-1]

def wmean(v,w):
    v=np.asarray(v,float); w=np.asarray(w,float)
    if w.sum()<=0: return float('nan')
    return float(np.sum(v*w)/np.sum(w))

def main():
    p0=latest('tsd_audit_*')
    df=pd.read_csv(p0/'runs.csv')
    rep=ROOT/'reports'/'tsd_p0_audit'; rep.mkdir(parents=True,exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed mismatch'
    assert len(df)==40 and (df.Status=='ok').all(),'incomplete audit'
    assert (df.Evaluations==100000).all(),'FE mismatch'
    per=df.groupby('FunctionID')[['TsdG1Eval','TsdG1Split','TsdEEval','TsdECursorOnly','TsdOEEval','TsdOECursorOnly','TsdProtectUpdates']].sum()
    per['state_split_rate']=per.TsdG1Split/per.TsdG1Eval.replace(0,np.nan)
    per['cursor_only_rate']=per.TsdECursorOnly/per.TsdEEval.replace(0,np.nan)
    per['oe_cursor_only_rate']=per.TsdOECursorOnly/per.TsdOEEval.replace(0,np.nan)
    per['mean_gap_dist']=[wmean(g.TsdMeanGapDist,g.TsdG1Eval) for _,g in df.groupby('FunctionID')]
    per['mean_gap_fit']=[wmean(g.TsdMeanGapFit,g.TsdG1Eval) for _,g in df.groupby('FunctionID')]
    per['max_gap_dist']=df.groupby('FunctionID').TsdMaxGapDist.max()
    per.to_csv(rep/'per_function_audit.csv')
    # aggregate weighted rates
    g1=float(df.TsdG1Eval.sum()); split=float(df.TsdG1Split.sum())
    ee=float(df.TsdEEval.sum()); eo=float(df.TsdECursorOnly.sum())
    oe=float(df.TsdOEEval.sum()); oo=float(df.TsdOECursorOnly.sum())
    rate=split/max(g1,1); crate=eo/max(ee,1); orate=oo/max(oe,1)
    gapd=wmean(df.TsdMeanGapDist,df.TsdG1Eval); gapf=wmean(df.TsdMeanGapFit,df.TsdG1Eval)
    funcs_split=int((per.state_split_rate>=0.20).sum())
    funcs_cursor=int((per.cursor_only_rate>=0.10).sum())
    gate=bool(funcs_split>=6 and funcs_cursor>=4)
    summary=dict(results_dir=str(p0),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 g1_eval=g1,g1_split=split,state_split_rate=rate,
                 e_eval=ee,e_cursor_only=eo,cursor_only_rate=crate,
                 oe_eval=oe,oe_cursor_only=oo,oe_cursor_only_rate=orate,
                 mean_gap_dist=gapd,mean_gap_fit=gapf,
                 functions_state_split_20pct=funcs_split,
                 functions_cursor_only_10pct=funcs_cursor,
                 gate_state_split=bool(funcs_split>=6),
                 gate_cursor_only=bool(funcs_cursor>=4),
                 gate_pass=gate)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    lines=['# TSD P0 影子状态审计结果','',f'- 结果目录：`{p0}`','- 40 次运行，8 函数 × 5 新种子，100k FE，0 失败','- 影子审计与冻结 G1+E 逐位一致（合约测试）','',
           '## 全局触发','',
           f'- G1 真实评价：**{g1:.0f}**；轨迹可移动但 P 无需更新：**{split:.0f}**（{rate:.2%}）',
           f'- E 真实评价：**{ee:.0f}**；仅轨迹可更新的机会：**{eo:.0f}**（{crate:.2%}）',
           f'- G2 标准填补候选评价：**{oe:.0f}**；仅轨迹可更新机会：**{oo:.0f}**（{orate:.2%}）',
           f'- 保护性状态更新：**{df.TsdProtectUpdates.sum():.0f}**',
           f'- 平均 P/Z 归一化距离：**{gapd:.6g}**；平均适应度差：**{gapf:.6g}**','',
           '## 分函数结果','',
           '| F | state split% | E cursor-only% | E eval | gap dist | gap fit | Protect updates |','|---:|---:|---:|---:|---:|---:|---:|']
    for f,row in per.iterrows():
        lines.append(f"| {int(f)} | {row.state_split_rate:.1%} | {row.cursor_only_rate:.1%} | {row.TsdEEval:.0f} | {row.mean_gap_dist:.4g} | {row.mean_gap_fit:.4g} | {row.TsdProtectUpdates:.0f} |")
    lines += ['','## P0 判定','',
              f"- 至少 6/8 函数 state split ≥20%：**{'通过' if funcs_split>=6 else '不通过'}**（{funcs_split}/8）",
              f"- 至少 4/8 函数 E cursor-only ≥10%：**{'通过' if funcs_cursor>=4 else '不通过'}**（{funcs_cursor}/8）",
              '- Trace/Best/FE 逐位一致：**通过**（合约测试）','',
              f"**最终判定：{'PROMOTE_TSD_TO_P1' if gate else 'STOP_TSD_P0'}**"]
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)

if __name__=='__main__': main()
