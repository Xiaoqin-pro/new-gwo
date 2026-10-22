#!/usr/bin/env python3
"""Analyze the passive DSE-premise audit (dual stagnation: alpha AND archive stagnant >= tau)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 13, 20, 30]
SEEDS = list(range(3399, 3404))
TAU = 2000
BUDGET = 100000


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def main():
    p = latest('dse_audit_*')
    df = pd.read_csv(p / 'runs.csv')
    rep = ROOT / 'reports' / 'dse_audit'
    rep.mkdir(parents=True, exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS, 'function mismatch'
    assert sorted(df.Seed.unique().tolist()) == SEEDS, 'seed mismatch'
    assert len(df) == len(FUNCS) * len(SEEDS) and (df.Status == 'ok').all(), 'audit incomplete'
    assert (df.Evaluations == BUDGET).all(), 'FE mismatch'
    df = df.copy()
    df['trigger_ok'] = (df.DaFirstDualFE > 0) & (df.DaFirstDualFE <= 0.9 * BUDGET)
    df['arc_ever_stagnant'] = df.DaArcGapMax >= TAU
    per_run = df[['FunctionID', 'Seed', 'DaArcImpCnt', 'DaArcGapMax', 'DaDualFE', 'DaFirstDualFE', 'trigger_ok']]
    per_run.to_csv(rep / 'per_run_audit.csv', index=False)
    per = df.groupby('FunctionID').agg(arc_imp_median=('DaArcImpCnt', 'median'),
                                       arc_gap_max_median=('DaArcGapMax', 'median'),
                                       arc_gap_max_max=('DaArcGapMax', 'max'),
                                       dual_fe_median=('DaDualFE', 'median'),
                                       seeds_with_trigger=('trigger_ok', 'sum'),
                                       runs=('trigger_ok', 'size')).reindex(FUNCS)
    per.to_csv(rep / 'per_function_audit.csv')
    gate_funcs = int((per.seeds_with_trigger >= 3).sum())
    gate = bool(gate_funcs >= 6)
    summary = dict(results_dir=str(p), runs=len(df), tau=TAU,
                   runs_with_trigger=int(df.trigger_ok.sum()),
                   functions_with_3of5_triggers=gate_funcs,
                   arc_gap_max_overall=int(df.DaArcGapMax.max()),
                   arc_gap_max_median=int(df.DaArcGapMax.median()),
                   arc_imp_median=float(df.DaArcImpCnt.median()),
                   gate_required_functions=6, gate_pass=gate,
                   verdict='PROMOTE_DSE_TO_P1' if gate else 'STOP_DSE_P0')
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# DSE 前提被动审计结果（双停滞门控机会）', '',
             f'- 结果目录：`{p}`', f'- {len(df)} 次运行（8 函数 × 5 种子 × 100k FE），行为与冻结 G1+E 逐位一致（合约测试）',
             f'- 触发定义：全局最优停滞 ≥{TAU} FE **且** 档案改善停滞 ≥{TAU} FE', '',
             '## 关键数字', '',
             f"- 档案改善次数（中位/runs）：**{summary['arc_imp_median']:.0f}** 次（平均间隔 ≈ {BUDGET/max(summary['arc_imp_median'],1):.0f} FE）",
             f"- 单次运行内『档案最长无改善间隔』：中位 **{summary['arc_gap_max_median']} FE**，最大 {summary['arc_gap_max_overall']} FE（阈值 {TAU}）",
             f"- 出现『双停滞且剩余预算 ≥10%』的运行数：**{summary['runs_with_trigger']}/{len(df)}**",
             f"- 满足『≥3/5 种子有触发机会』的函数数：**{gate_funcs}/8**（要求 ≥6）", '',
             f"**判定：{summary['verdict']}**", '',
             '| F | 档案改善次数(中位) | 最长间隔(中位) | 最长间隔(max) | 双停滞FE(中位) | 触发的种子数 |', '|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        r = per.loc[f]
        lines.append(f"| {f} | {r.arc_imp_median:.0f} | {r.arc_gap_max_median:.0f} | {r.arc_gap_max_max:.0f} | "
                     f"{r.dual_fe_median:.0f} | {int(r.seeds_with_trigger)}/{int(r.runs)} |")
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
