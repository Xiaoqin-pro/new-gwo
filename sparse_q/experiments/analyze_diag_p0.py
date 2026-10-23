#!/usr/bin/env python3
"""Allocation-structure P0 (docs/79): strict per-class value, archive coverage, time trend."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 13, 20, 30]
SEEDS = list(range(3569, 3574))
CLASSES = ['G1', 'filler', 'E-shell', 'E-2c']


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def mat3(df, col):
    # MATLAB struct2table flattens a 10x4 matrix column-major: (row r, col c) -> element (c-1)*10+r
    cols = [f'{col}_{(c - 1) * 10 + r}' for c in range(1, 5) for r in range(1, 11)]
    return df[cols].to_numpy(float).reshape(len(df), 4, 10).transpose(0, 2, 1)


def main():
    p = latest('diag_p0_*')
    df = pd.read_csv(p / 'runs.csv')
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all() and len(df) == 40
    E, GB, AR, PO = (mat3(df, c) for c in ['DiagEval', 'DiagGB', 'DiagArc', 'DiagPop'])
    df['gb_2c'] = GB[:, :, 3].sum(axis=1)
    df['gb_sh'] = GB[:, :, 2].sum(axis=1)
    df['rate_2c'] = df.gb_2c / np.maximum(E[:, :, 3].sum(axis=1), 1)
    df['rate_sh'] = df.gb_sh / np.maximum(E[:, :, 2].sum(axis=1), 1)
    df['zero_share'] = df.DiagZeroEval / np.maximum(df.DiagLifeN, 1)
    df['evals_per_life'] = df.DiagEvalSum / np.maximum(df.DiagLifeN, 1)
    df['gb_first3'] = GB[:, :3, :].sum(axis=(1, 2))
    df['gb_last3'] = GB[:, 7:, :].sum(axis=(1, 2))
    per = df.groupby('FunctionID').agg(
        gb_2c=('gb_2c', 'median'), gb_sh=('gb_sh', 'median'),
        rate_2c=('rate_2c', 'median'), rate_sh=('rate_sh', 'median'),
        zero_share=('zero_share', 'median'), evals_per_life=('evals_per_life', 'median'),
        life_n=('DiagLifeN', 'median')).reindex(FUNCS)
    per['asym_ok'] = (per.rate_2c >= 2 * per.rate_sh) & (per.gb_2c >= 2)
    per['cover_ok'] = per.zero_share >= 0.30
    g_c = int(per.asym_ok.sum()); g_b = int(per.cover_ok.sum())
    rep = ROOT / 'reports' / 'diag_p0_audit'; rep.mkdir(parents=True, exist_ok=True)
    per.to_csv(rep / 'per_function_audit.csv')
    cls = {c: dict(evals=float(E[:, :, i].sum()), gb=float(GB[:, :, i].sum()), arc=float(AR[:, :, i].sum()),
                   pop=float(PO[:, :, i].sum()),
                   gb_rate=float(GB[:, :, i].sum() / max(E[:, :, i].sum(), 1)),
                   arc_rate=float(AR[:, :, i].sum() / max(E[:, :, i].sum(), 1))) for i, c in enumerate(CLASSES)}
    trend = dict(gb_first3=float(df.gb_first3.median()), gb_last3=float(df.gb_last3.median()),
                 qual_first3=float(np.nanmedian(df[['DiagQual_1', 'DiagQual_2', 'DiagQual_3']].to_numpy(float))),
                 qual_last3=float(np.nanmedian(df[['DiagQual_8', 'DiagQual_9', 'DiagQual_10']].to_numpy(float))))
    verdict = ('PROMOTE_ALLOC_MIX_TO_P1' if g_c >= 6 else
               ('COVERAGE_PREMISE_ONLY' if g_b >= 6 else 'STOP_ALLOC_DIAG'))
    summary = dict(results_dir=str(p), runs=len(df), classes=cls, per_function_gates=dict(asym=g_c, cover=g_b),
                   trend=trend, verdict=verdict)
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# 分配结构 P0 诊断（8 函数 × 5 新种子 3569–3573 × 100k FE，被动、逐位一致）', '',
             f'- 结果目录：`{p}`（{len(df)} 次运行，0 失败）', '',
             '## 类别严格价值（全部函数汇总）', '',
             '| 类别 | 评价数 | 全局最优改进 | GB 率 | 入库/刷新 | ARC 率 | 种群替换 |', '|---|---:|---:|---:|---:|---:|---:|']
    for c in CLASSES:
        d = cls[c]
        lines.append(f"| {c} | {d['evals']:.0f} | {d['gb']:.0f} | {d['gb_rate']*100:.3f}% | {d['arc']:.0f} | {d['arc_rate']*100:.2f}% | {d['pop']:.0f} |")
    lines += ['', '## 逐函数前提', '',
              '| F | E-2c GB | E-shell GB | 率比 2c/sh | 零评价生命周期比例 | 评价/生命周期 | 前提c′ | 前提b′ |',
              '|---:|---:|---:|---:|---:|---:|:--:|:--:|']
    for f in FUNCS:
        r = per.loc[f]
        lines.append(f"| {f} | {r.gb_2c:.0f} | {r.gb_sh:.0f} | {r.rate_2c/max(r.rate_sh,1e-9):.2f} | {r.zero_share:.3f} | "
                     f"{r.evals_per_life:.2f} | {'是' if r.asym_ok else '否'} | {'是' if r.cover_ok else '否'} |")
    lines += ['', f"- G-c′（内部分支价值不对称）：**{g_c}/8**（门槛 ≥6）",
              f"- G-b′（覆盖不足）：**{g_b}/8**（门槛 ≥6）",
              f"- 时间趋势（报告）：前三个十分位 GB 中位 {trend['gb_first3']:.1f} vs 后三个 {trend['gb_last3']:.1f}；"
              f"档案相对质量 {trend['qual_first3']:.4f} → {trend['qual_last3']:.4f}", '',
              f'**判定：{verdict}**', '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
