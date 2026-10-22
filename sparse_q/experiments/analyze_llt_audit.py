#!/usr/bin/env python3
"""Analyze the passive LLT P0 audit (40 runs: 8 functions x 5 seeds, 100k FE)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 13, 20, 30]
SEEDS = list(range(3337, 3342))
GATES = dict(local_ne_global=0.50, disp_median=0.01, dup_selected=0.10, min_funcs=6)


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def main():
    p = latest('llt_audit_*')
    df = pd.read_csv(p / 'runs.csv')
    rep = ROOT / 'reports' / 'llt_p0_audit'
    rep.mkdir(parents=True, exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS, 'function mismatch'
    assert sorted(df.Seed.unique().tolist()) == SEEDS, 'seed mismatch'
    assert len(df) == 40 and (df.Status == 'ok').all(), 'incomplete audit'
    assert (df.Evaluations == 100000).all(), 'FE mismatch'
    assert df.LltRounds.notna().all(), 'LLT counters missing'
    per = df.groupby('FunctionID').agg(
        local_ne_global=('LltLocalNeGlobalRate', 'median'),
        disp_median=('LltDispMedian', 'median'),
        disp_p90=('LltDispP90', 'median'),
        dup_selected=('LltDupSelectedRate', 'median'),
        g1_nn=('LltG1NNMedian', 'median'),
        runs=('LltRounds', 'size')).reindex(FUNCS)
    per.to_csv(rep / 'per_function_audit.csv')
    g1 = int((per.local_ne_global >= GATES['local_ne_global']).sum())
    g2 = int((per.disp_median > GATES['disp_median']).sum())
    g3 = int((per.dup_selected >= GATES['dup_selected']).sum())
    gate1 = bool(g1 >= GATES['min_funcs'])
    gate2 = bool(g2 >= GATES['min_funcs'])
    gate3 = bool(g3 >= GATES['min_funcs'])
    gate = bool(gate1 and gate2 and gate3)
    summary = dict(results_dir=str(p), runs=len(df), functions=FUNCS, seeds=SEEDS,
                   functions_local_ne_global=g1, functions_disp_above=g2, functions_dup_above=g3,
                   gate_local_ne_global=gate1, gate_disp=gate2, gate_dup=gate3,
                   gates=GATES, gate_pass=gate,
                   verdict='PROMOTE_LLT_TO_ACTIVE' if gate else 'STOP_LLT_P0')
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# LLT P0 被动审计结果', '',
             f'- 结果目录：`{p}`',
             f'- 40 次运行（8 函数 x 5 新种子），100k FE，0 失败',
             '- 审计模式与冻结 G1+E 逐位一致（合约测试）', '',
             '## 前提指标（分函数中位数）', '',
             '| F | 局部≠全局比例 | 反事实位移 | 位移P90 | 被选重复率 | G1池最近邻 |', '|---:|---:|---:|---:|---:|---:|']
    for f, r in per.iterrows():
        lines.append(f"| {int(f)} | {r.local_ne_global:.3f} | {r.disp_median:.4f} | {r.disp_p90:.4f} | "
                     f"{r.dup_selected:.3f} | {r.g1_nn:.4f} |")
    lines += ['', '## 门槛', '',
              f"- 局部≠全局比例 ≥{GATES['local_ne_global']} 的函数：**{g1}/8**（需 ≥{GATES['min_funcs']}）",
              f"- 反事实位移 >{GATES['disp_median']} 的函数：**{g2}/8**（需 ≥{GATES['min_funcs']}）",
              f"- 被选重复率 ≥{GATES['dup_selected']} 的函数：**{g3}/8**（需 ≥{GATES['min_funcs']}）", '',
              f"**最终判定：{summary['verdict']}**"]
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))
    print('[analysis] wrote', rep)


if __name__ == '__main__':
    main()
