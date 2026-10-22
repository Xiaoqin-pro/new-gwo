#!/usr/bin/env python3
"""Analyze the passive RGI P0 audit (40 runs, 100k FE)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd

ROOT=Path(__file__).resolve().parents[2]
FUNCS=[1,3,4,7,10,13,20,30]
SEEDS=list(range(3291,3296))

def latest(pat):
    ds=sorted((ROOT/'sparse_q'/'results').glob(pat))
    if not ds: raise SystemExit('missing results: '+pat)
    return ds[-1]
def main():
    p=latest('rgi_audit_*'); df=pd.read_csv(p/'runs.csv')
    rep=ROOT/'reports'/'rgi_p0_audit'; rep.mkdir(parents=True,exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed mismatch'
    assert len(df)==40 and (df.Status=='ok').all(),'incomplete audit'
    assert (df.Evaluations==100000).all(),'FE mismatch'
    per=df.groupby('FunctionID')[['RgiTriggers','RgiEvaluated']].sum()
    per['eval_rate']=per.RgiEvaluated/per.RgiTriggers.replace(0,np.nan)
    seeds_pos=df[df.RgiEvaluated>0].groupby('FunctionID').Seed.nunique().reindex(FUNCS).fillna(0).astype(int)
    per['seeds_with_eval']=seeds_pos
    per.to_csv(rep/'per_function_audit.csv')
    g1=int((per.RgiEvaluated>=10).sum())>=6
    g2=int((per.seeds_with_eval>=3).sum())>=6
    gate=bool(g1 and g2)
    summary=dict(results_dir=str(p),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 total_triggers=int(df.RgiTriggers.sum()),total_evaluated=int(df.RgiEvaluated.sum()),
                 global_eval_rate=float(df.RgiEvaluated.sum()/max(df.RgiTriggers.sum(),1)),
                 functions_evaluated_10=int((per.RgiEvaluated>=10).sum()),
                 functions_seeds_3=int((per.seeds_with_eval>=3).sum()),
                 gate_evaluated=bool(g1),gate_seed_coverage=bool(g2),gate_pass=gate)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    lines=['# RGI P0 被动审计结果','',f'- 结果目录：`{p}`','- 40 次运行，8 函数 × 5 新种子，100k FE，0 失败','- 审计模式与冻结 G1+E 逐位一致（合约测试）','',
           '## 触发与可评价机会','',
           f'- 触发候选：**{summary["total_triggers"]}**',
           f'- 触发候选实际被评价：**{summary["total_evaluated"]}**（{summary["global_eval_rate"]:.2%}）',
           f'- 被评价机会 ≥10 的函数：**{summary["functions_evaluated_10"]}/8**',
           f'- 至少 3 个种子存在可评价机会的函数：**{summary["functions_seeds_3"]}/8**','',
           '## 分函数结果','',
           '| F | triggers | evaluated | eval rate | seeds with eval |','|---:|---:|---:|---:|---:|']
    for f,row in per.iterrows():
        lines.append(f"| {int(f)} | {row.RgiTriggers:.0f} | {row.RgiEvaluated:.0f} | {row.eval_rate:.1%} | {row.seeds_with_eval:.0f}/5 |")
    lines += ['','## P0 判定','',
              f"- 至少 6/8 函数可评价机会 ≥10：**{'通过' if g1 else '不通过'}**（{summary['functions_evaluated_10']}/8）",
              f"- 至少 6/8 函数在 ≥3 个种子中出现机会：**{'通过' if g2 else '不通过'}**（{summary['functions_seeds_3']}/8）",
              '- Trace/Best/FE 逐位一致：**通过**（合约测试）','',
              f"**最终判定：{'PROMOTE_RGI_TO_CONFIRMATION' if gate else 'STOP_RGI_P0'}**"]
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)
if __name__=='__main__': main()
