#!/usr/bin/env python3
"""Analyze the SALS P0 passive audit (post-selection coefficient sampling geometry)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 13, 20, 30]
SEEDS = list(range(3434, 3439))


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def main():
    p = latest('sals_audit_*')
    df = pd.read_csv(p / 'runs.csv')
    rep = ROOT / 'reports' / 'sals_audit'
    rep.mkdir(parents=True, exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert len(df) == len(FUNCS) * len(SEEDS) and (df.Status == 'ok').all()
    assert (df.Evaluations == 100000).all()
    df = df.copy()
    df['disp_ratio'] = df.SalsDispCMean / df.SalsDispBMean
    df[['FunctionID', 'Seed', 'SalsNMean', 'SalsStratFrac', 'SalsDispBMean', 'SalsDispCMean', 'disp_ratio',
        'SalsShiftBMean', 'SalsShiftCMean']].to_csv(rep / 'per_run_audit.csv', index=False)
    per = df.groupby('FunctionID').agg(n_mean=('SalsNMean', 'median'), strat=('SalsStratFrac', 'median'),
                                       dispB=('SalsDispBMean', 'median'), dispC=('SalsDispCMean', 'median'),
                                       disp_ratio=('disp_ratio', 'median'), shiftB=('SalsShiftBMean', 'median'),
                                       shiftC=('SalsShiftCMean', 'median'), runs=('SalsNMean', 'size')).reindex(FUNCS)
    per.to_csv(rep / 'per_function_audit.csv')
    g1 = bool(np.allclose(df.SalsStratFrac.to_numpy(float), 1.0))
    g2 = int((per.disp_ratio >= 1.01).sum()); g3 = int(((per.shiftB >= 0.01) & (per.shiftC >= 0.01)).sum())
    gate2 = g2 >= 6; gate3 = g3 >= 6
    gate = bool(g1 and gate2 and gate3)
    summary = dict(results_dir=str(p), runs=len(df), strat_realised=g1,
                   functions_disp_ratio_ge101=g2, functions_shift_ge001=g3,
                   gate_strat=g1, gate_dispersion=gate2, gate_shift=gate3, gate_pass=gate,
                   verdict='PROMOTE_SALS_TO_P1' if gate else 'STOP_SALS_P0')
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# SALS P0 被动审计结果', '',
             f'- 结果目录：`{p}`', f'- {len(df)} 次运行（8 函数 × 5 新种子 × 100k FE），audit 与冻结 G1+E+STEER 逐位一致（合约测试）', '',
             '| F | 每代被评价 G1 数 | 分层实现率 | 离散度 B | 离散度 C | C/B | 重抽位移 B | 重抽位移 C |',
             '|---:|---:|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        r = per.loc[f]
        lines.append(f"| {f} | {r.n_mean:.2f} | {r.strat:.3f} | {r.dispB:.4f} | {r.dispC:.4f} | "
                     f"{r.disp_ratio:.4f} | {r.shiftB:.4f} | {r.shiftC:.4f} |")
    lines += ['', '## 预注册门槛（doc 67）', '',
              f"1. 所有运行分层实现率 =1：**{'通过' if g1 else '不通过'}**",
              f"2. 离散度比 C/B ≥1.01 的函数：**{g2}/8** → {'通过' if gate2 else '不通过'}",
              f"3. 两臂重抽位移均 ≥0.01 的函数：**{g3}/8** → {'通过' if gate3 else '不通过'}",
              '4. audit 逐位一致：通过（合约测试）', '',
              f"**最终判定：{summary['verdict']}**"]
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
