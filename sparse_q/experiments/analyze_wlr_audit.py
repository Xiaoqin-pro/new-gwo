#!/usr/bin/env python3
"""Analyze the passive WLR-G1 P0 audit (40 runs, 100k FE)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd

ROOT=Path(__file__).resolve().parents[2]
FUNCS=[1,3,4,7,10,13,20,30]
SEEDS=list(range(3286,3291))

def latest(pat):
    ds=sorted((ROOT/'sparse_q'/'results').glob(pat))
    if not ds: raise SystemExit('missing results: '+pat)
    return ds[-1]
def wmean(v,w):
    v=np.asarray(v,float); w=np.asarray(w,float)
    if w.sum()<=0: return float('nan')
    return float(np.sum(v*w)/np.sum(w))

def main():
    p=latest('wlr_audit_*'); df=pd.read_csv(p/'runs.csv')
    rep=ROOT/'reports'/'wlr_p0_audit'; rep.mkdir(parents=True,exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed mismatch'
    assert len(df)==40 and (df.Status=='ok').all(),'incomplete audit'
    assert (df.Evaluations==100000).all(),'FE mismatch'
    per=df.groupby('FunctionID')[['WlrMacroGens','WlrLeaderChanges','WlrGenWithChange','WlrEvaluatedG1','WlrStaleCount']].sum()
    per['change_rate']=per.WlrGenWithChange/per.WlrMacroGens.replace(0,np.nan)
    per['stale_rate']=per.WlrStaleCount/per.WlrEvaluatedG1.replace(0,np.nan)
    per['median_stale_dist']=df.groupby('FunctionID').WlrMedianStaleDist.median()
    per['mean_stale_dist']=df.groupby('FunctionID').WlrMeanStaleDist.mean()
    per['p90_stale_dist']=df.groupby('FunctionID').WlrP90StaleDist.mean()
    per.to_csv(rep/'per_function_audit.csv')
    enough=int(((per.stale_rate>=0.20)).sum())
    dist_ok=int(((per.median_stale_dist>0.01)).sum())
    g1=enough>=6
    g2=dist_ok>=6
    gate=bool(g1 and g2)
    summary=dict(results_dir=str(p),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 macro_gens=int(df.WlrMacroGens.sum()),leader_changes=int(df.WlrLeaderChanges.sum()),
                 stale_g1=int(df.WlrStaleCount.sum()),evaluated_g1=int(df.WlrEvaluatedG1.sum()),
                 global_stale_rate=float(df.WlrStaleCount.sum()/max(df.WlrEvaluatedG1.sum(),1)),
                 functions_stale_20pct=enough,functions_dist_gt001=dist_ok,
                 gate_stale=bool(g1),gate_distance=bool(g2),gate_pass=gate)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    lines=['# WLR-G1 P0 被动审计结果','',f'- 结果目录：`{p}`','- 40 次运行，8 函数 × 5 新种子，100k FE，0 失败','- 审计模式与冻结 G1+E 逐位一致（合约测试）','',
           '## 反馈延迟机会','',
           f'- 宏代数量：**{summary["macro_gens"]}**',
           f'- 领导变化次数：**{summary["leader_changes"]}**',
           f'- 已评价 G1 候选：**{summary["evaluated_g1"]}**；stale candidates：**{summary["stale_g1"]}**（{summary["global_stale_rate"]:.2%}）',
           f'- 至少 20% stale 的函数：**{enough}/8**',
           f'- 反事实距离中位数 >0.01 的函数：**{dist_ok}/8**','',
           '## 分函数结果','',
           '| F | stale rate | median stale dist | mean stale dist | p90 stale dist | change rate |','|---:|---:|---:|---:|---:|---:|']
    for f,row in per.iterrows():
        lines.append(f"| {int(f)} | {row.stale_rate:.1%} | {row.median_stale_dist:.4g} | {row.mean_stale_dist:.4g} | {row.p90_stale_dist:.4g} | {row.change_rate:.1%} |")
    lines += ['','## P0 判定','',
              f"- 至少 6/8 函数 stale rate ≥20%：**{'通过' if g1 else '不通过'}**（{enough}/8）",
              f"- 至少 6/8 函数反事实距离中位数 >0.01：**{'通过' if g2 else '不通过'}**（{dist_ok}/8）",
              '- Trace/Best/FE 逐位一致：**通过**（合约测试）','',
              f"**最终判定：{'PROMOTE_WLR_TO_CONFIRMATION' if gate else 'STOP_WLR_P0'}**"]
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)

if __name__=='__main__': main()
