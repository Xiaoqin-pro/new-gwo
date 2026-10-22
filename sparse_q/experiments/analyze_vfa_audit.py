#!/usr/bin/env python3
"""Analyze the VFA P0 shadow audit (two-layer archive premise)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 13, 20, 30]
SEEDS = list(range(3414, 3419))


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def main():
    p = latest('vfa_audit_*')
    df = pd.read_csv(p / 'runs.csv')
    rep = ROOT / 'reports' / 'vfa_audit'
    rep.mkdir(parents=True, exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert len(df) == len(FUNCS) * len(SEEDS) and (df.Status == 'ok').all()
    assert (df.Evaluations == 100000).all()
    df = df.copy()
    df['lift'] = np.where((df.VfaImpTot > 0) & (df.VfaEvalTot > 0),
                          (df.VfaImpNear / df.VfaImpTot.replace(0, np.nan)) /
                          (df.VfaEvalNear / df.VfaEvalTot.replace(0, np.nan)), np.nan)
    df['eval_near_frac'] = df.VfaEvalNear / df.VfaEvalTot.replace(0, np.nan)
    df['imp_near_frac'] = df.VfaImpNear / df.VfaImpTot.replace(0, np.nan)
    per_run = df[['FunctionID', 'Seed', 'VfaAdmits', 'VfaSize', 'VfaSizeMax', 'VfaSepEMed',
                  'VfaDistEMed', 'VfaGapMed', 'eval_near_frac', 'imp_near_frac', 'lift']]
    per_run.to_csv(rep / 'per_run_audit.csv', index=False)
    per = df.groupby('FunctionID').agg(admits=('VfaAdmits', 'median'), size=('VfaSize', 'median'),
                                       size_max=('VfaSizeMax', 'median'), distE=('VfaDistEMed', 'median'),
                                       gap=('VfaGapMed', 'median'), eval_near=('eval_near_frac', 'median'),
                                       imp_near=('imp_near_frac', 'median'), lift=('lift', 'median'),
                                       runs=('VfaAdmits', 'size')).reindex(FUNCS)
    per.to_csv(rep / 'per_function_audit.csv')
    g1 = int((per.admits >= 20).sum()); g2 = int((per['size'] >= 4).sum())
    g3 = int((per.distE >= 0.04).sum()); g4 = int((per.lift >= 1.0).sum())
    gate1, gate2, gate3, gate4 = g1 >= 6, g2 >= 6, g3 >= 6, g4 >= 6
    gate = bool(gate1 and gate2 and gate3 and gate4)
    summary = dict(results_dir=str(p), runs=len(df),
                   functions_admits_ge20=g1, functions_size_ge4=g2, functions_distE_ge004=g3, functions_lift_ge1=g4,
                   gate_admits=gate1, gate_occupancy=gate2, gate_distinctness=gate3, gate_relevance=gate4,
                   gate_pass=gate, verdict='PROMOTE_VFA_TO_P1' if gate else 'STOP_VFA_P0')
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# VFA（双层档案）P0 影子审计结果', '',
             f'- 结果目录：`{p}`', f'- {len(df)} 次运行（8 函数 × 5 新种子 × 100k FE），与冻结 G1+E+STEER 逐位一致（合约测试）', '',
             '## 前提指标（分函数中位数）', '',
             '| F | F 插入次数 | F 规模 | 规模峰值 | F→E 距离 | F/E 质量比 | 评价近 F 比例 | 改善近 F 比例 | lift |',
             '|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        r = per.loc[f]
        lines.append(f"| {f} | {r.admits:.0f} | {r['size']:.1f} | {r.size_max:.0f} | {r.distE:.4f} | {r.gap:.3f} | "
                     f"{r.eval_near:.3f} | {r.imp_near:.3f} | {r.lift:.3f} |")
    lines += ['', '## 预注册门槛（doc 64）', '',
              f"1. 插入次数 ≥20 的函数：**{g1}/8**（需 ≥6）→ {'通过' if gate1 else '不通过'}",
              f"2. 结束时 F 规模 ≥4 的函数：**{g2}/8**（需 ≥6）→ {'通过' if gate2 else '不通过'}",
              f"3. F→E 距离 ≥0.04 的函数：**{g3}/8**（需 ≥6）→ {'通过' if gate3 else '不通过'}",
              f"4. lift ≥1.0 的函数：**{g4}/8**（需 ≥6）→ {'通过' if gate4 else '不通过'}",
              f"5. 影子模式逐位一致：通过（合约测试）", '',
              f"**最终判定：{summary['verdict']}**"]
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
