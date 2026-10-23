#!/usr/bin/env python3
"""PAIR P0-Value: does centre quality rank predict the value of interpolation candidates? (docs/88)"""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 13, 20, 30]
SEEDS = list(range(3614, 3619))


def main():
    ds = sorted((ROOT / 'sparse_q' / 'results').glob('pair_p0_*'))
    if not ds:
        raise SystemExit('missing pair_p0_* results')
    p = ds[-1]
    df = pd.read_csv(p / 'runs.csv')
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all() and len(df) == 40
    ev = df[['PairEvalC_1', 'PairEvalC_2', 'PairEvalC_3']].to_numpy(float)
    gb = df[['PairGBC_1', 'PairGBC_2', 'PairGBC_3']].to_numpy(float)
    ar = df[['PairArcC_1', 'PairArcC_2', 'PairArcC_3']].to_numpy(float)
    df['gb_rate_1'] = gb[:, 0] / np.maximum(ev[:, 0], 1)
    df['gb_rate_3'] = gb[:, 2] / np.maximum(ev[:, 2], 1)
    df['arc_rate_1'] = ar[:, 0] / np.maximum(ev[:, 0], 1)
    df['arc_rate_3'] = ar[:, 2] / np.maximum(ev[:, 2], 1)
    per = df.groupby('FunctionID').agg(ev1=('PairEvalC_1', 'median'), ev2=('PairEvalC_2', 'median'),
                                       ev3=('PairEvalC_3', 'median'), gb1=('PairGBC_1', 'median'),
                                       gb3=('PairGBC_3', 'median'),
                                       gb_ratio=('gb_rate_1', lambda s: np.nan), ).reindex(FUNCS)
    per['gb_rate_1'] = df.groupby('FunctionID').gb_rate_1.median().reindex(FUNCS)
    per['gb_rate_3'] = df.groupby('FunctionID').gb_rate_3.median().reindex(FUNCS)
    per['arc_rate_1'] = df.groupby('FunctionID').arc_rate_1.median().reindex(FUNCS)
    per['arc_rate_3'] = df.groupby('FunctionID').arc_rate_3.median().reindex(FUNCS)
    per['gb_ratio'] = (per.gb_rate_1 + 1e-3) / (per.gb_rate_3 + 1e-3)
    per['arc_ratio'] = (per.arc_rate_1 + 1e-3) / (per.arc_rate_3 + 1e-3)
    per['ok'] = (per.gb1 >= 10) & ((per.gb_ratio >= 1.5) | (per.arc_ratio >= 1.5))
    npass = int(per.ok.sum())
    verdict = 'PROMOTE_PAIR_TO_CONFIRM' if npass >= 6 else 'STOP_PAIR_P0'
    rep = ROOT / 'reports' / 'pair_p0_audit'; rep.mkdir(parents=True, exist_ok=True)
    per.to_csv(rep / 'per_function_audit.csv')
    summary = dict(results_dir=str(p), runs=len(df), functions=FUNCS, seeds=SEEDS,
                   functions_pass=npass, verdict=verdict,
                   totals=dict(ev=ev.sum(axis=0).tolist(), gb=gb.sum(axis=0).tolist(), arc=ar.sum(axis=0).tolist()))
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# PAIR P0-Value（质量排名是否预测插值候选价值）', '',
             f'- 结果目录：`{p}`（{len(df)} 次运行，0 失败）',
             '- 分档：bin1 = 较优中心 rank≤3；bin2 = 4–6；bin3 = >6', '',
             '| F | 评价数 1/2/3 | GB 数 1/3 | GB 率 1 vs 3 | GB 比 | 接纳率 1 vs 3 | 接纳比 | 通过 |',
             '|---:|---:|---:|---:|---:|---:|---:|:--:|']
    for f in FUNCS:
        r = per.loc[f]
        lines.append(f"| {f} | {r.ev1:.0f}/{r.ev2:.0f}/{r.ev3:.0f} | {r.gb1:.0f}/{r.gb3:.0f} | "
                     f"{r.gb_rate_1*100:.2f}% vs {r.gb_rate_3*100:.2f}% | {r.gb_ratio:.2f} | "
                     f"{r.arc_rate_1*100:.1f}% vs {r.arc_rate_3*100:.1f}% | {r.arc_ratio:.2f} | {'是' if r.ok else '否'} |")
    lines += ['', f"- 汇总：bin1 评价 {int(ev[:,0].sum())} / GB {int(gb[:,0].sum())}；"
                  f"bin2 {int(ev[:,1].sum())} / {int(gb[:,1].sum())}；bin3 {int(ev[:,2].sum())} / {int(gb[:,2].sum())}",
              f'- 通过函数数：**{npass}/8**（门槛 ≥6）', '', f'**判定：{verdict}**', '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
