#!/usr/bin/env python3
"""Analyze the passive CAGL P0 leadership-collapse audit (40 runs, 100k FE)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd

ROOT=Path(__file__).resolve().parents[2]
FUNCS=[1,3,4,7,10,13,20,30]
SEEDS=list(range(3251,3256))

def latest(pat):
    ds=sorted((ROOT/'sparse_q'/'results').glob(pat))
    if not ds: raise SystemExit('missing results: '+pat)
    return ds[-1]

def wmean(v,w):
    v=np.asarray(v,float); w=np.asarray(w,float)
    if w.sum()<=0: return float('nan')
    return float(np.sum(v*w)/np.sum(w))

def main():
    p0=latest('cagl_audit_*')
    df=pd.read_csv(p0/'runs.csv')
    rep=ROOT/'reports'/'cagl_p0_audit'; rep.mkdir(parents=True,exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed mismatch'
    assert len(df)==40 and (df.Status=='ok').all(),'incomplete audit'
    assert (df.Evaluations==100000).all(),'FE mismatch'
    rounds=float(df.CaglRounds.sum()); collapse=float(df.CaglCollapseRounds.sum())
    eligible=float(df.CaglEligibleRounds.sum()); direv=float(df.CaglDirectionEvents.sum())
    collapse_rate=collapse/max(rounds,1)
    eligible_share=eligible/max(collapse,1)
    elig_centers=wmean(df.CaglEligibleCentersMean,df.CaglCollapseRounds)
    mean_norm=wmean(df.CaglMeanNormDiff,df.CaglDirectionEvents)
    mean_cos=wmean(df.CaglMeanCos,df.CaglDirectionEvents)
    changed10=float(df.CaglDirChanged10.sum())/max(direv,1)
    per=df.groupby('FunctionID')[['CaglRounds','CaglCollapseRounds','CaglEligibleRounds','CaglEligibleCentersMean','CaglDirectionEvents','CaglDirChanged10']].sum()
    per['collapse_rate']=per.CaglCollapseRounds/per.CaglRounds.replace(0,np.nan)
    per['eligible_share']=per.CaglEligibleRounds/per.CaglCollapseRounds.replace(0,np.nan)
    per['mean_cos']=[wmean(g.CaglMeanCos,g.CaglDirectionEvents) for _,g in df.groupby('FunctionID')]
    per['mean_norm_diff']=[wmean(g.CaglMeanNormDiff,g.CaglDirectionEvents) for _,g in df.groupby('FunctionID')]
    per['changed10_frac']=per.CaglDirChanged10/per.CaglDirectionEvents.replace(0,np.nan)
    per.to_csv(rep/'per_function_audit.csv')
    g1=collapse_rate>=0.10
    g2=eligible_share>=0.50
    g3=(np.isfinite(mean_cos) and mean_cos<=0.99)
    g4=int((per.CaglDirectionEvents>0).sum())>=4
    gate=bool(g1 and g2 and g3 and g4)
    summary=dict(results_dir=str(p0),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 rounds=rounds,collapse_rounds=collapse,eligible_rounds=eligible,
                 collapse_rate=collapse_rate,eligible_share=eligible_share,
                 eligible_centers_mean=elig_centers,direction_events=direv,
                 mean_norm_diff=mean_norm,mean_cos=mean_cos,changed10_fraction=changed10,
                 functions_with_direction_events=int((per.CaglDirectionEvents>0).sum()),
                 gate_collapse_10pct=bool(g1),gate_eligible_50pct=bool(g2),
                 gate_direction_change=bool(g3),gate_multi_family=bool(g4),gate_pass=gate)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    lines=['# CAGL P0 领导塌缩审计结果','',f'- 结果目录：`{p0}`','- 40 次运行，8 函数 × 5 新种子，100k FE，0 失败','- 审计模式与冻结 G1+E 逐位一致（合约测试）','',
           '## 核心事件','',
           f'- 总代数：**{rounds:.0f}**',
           f'- 领导塌缩代：**{collapse:.0f}**（{collapse_rate:.2%}）',
           f'- 塌缩代中存在合格档案中心：**{eligible:.0f}**（{eligible_share:.2%}）',
           f'- 塌缩代平均合格中心数：**{elig_centers:.4g}**',
           f'- 反事实方向事件：**{direv:.0f}**',
           f'- 平均归一化位移差：**{mean_norm:.6g}**' if np.isfinite(mean_norm) else '- 平均归一化位移差：无法计算',
           f'- 平均方向余弦：**{mean_cos:.6f}**' if np.isfinite(mean_cos) else '- 平均方向余弦：无法计算',
           f'- 方向变化 >10° 的比例：**{changed10:.2%}**','',
           '## 分函数事件','',
           '| F | collapse% | eligible% | events | mean cos | mean diff | changed10% |','|---:|---:|---:|---:|---:|---:|---:|']
    for f,row in per.iterrows():
        lines.append(f"| {int(f)} | {row.collapse_rate:.1%} | {row.eligible_share:.1%} | {row.CaglDirectionEvents:.0f} | {row.mean_cos:.4f} | {row.mean_norm_diff:.4g} | {row.changed10_frac:.1%} |")
    lines += ['','## P0 判定','',
              f"- 塌缩触发率 ≥10%：**{'通过' if g1 else '不通过'}**（{collapse_rate:.2%}）",
              f"- 合格档案中心比例 ≥50%：**{'通过' if g2 else '不通过'}**（{eligible_share:.2%}）",
              f"- 平均方向余弦 ≤0.99：**{'通过' if g3 else '不通过'}**（{mean_cos:.6f}）" if np.isfinite(mean_cos) else "- 平均方向余弦 ≤0.99：**不通过**（无方向事件）",
              f"- 至少 4/8 函数出现可用方向事件：**{'通过' if g4 else '不通过'}**（{int((per.CaglDirectionEvents>0).sum())}/8）",'',
              f"**最终判定：{'PROMOTE_CAGL_TO_P1' if gate else 'STOP_CAGL_P0'}**"]
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)

if __name__=='__main__': main()
