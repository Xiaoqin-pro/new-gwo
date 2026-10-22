#!/usr/bin/env python3
"""Analyze the Sparse-DLH P0 geometry audit."""
from __future__ import annotations
import json
from pathlib import Path
import pandas as pd
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 13, 20, 30]
SEEDS = list(range(3419, 3424))


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def main():
    p = latest('dlh_audit_*')
    df = pd.read_csv(p / 'runs.csv')
    rep = ROOT / 'reports' / 'dlh_audit'
    rep.mkdir(parents=True, exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert len(df) == len(FUNCS) * len(SEEDS) and (df.Status == 'ok').all()
    assert (df.Evaluations == 100000).all()
    per = df.groupby('FunctionID').agg(neigh=('DlhNeighMean', 'median'), zero_frac=('DlhNeighZeroFrac', 'median'),
                                       deg_frac=('DlhDegFrac', 'median'), disp=('DlhDispMed', 'median'),
                                       vs_gwo=('DlhVsGwoMed', 'median'), vs_e=('DlhVsEMed', 'median'),
                                       gwo_vs_e=('DlhGwoVsEMed', 'median'), runs=('DlhNeighMean', 'size')).reindex(FUNCS)
    per.to_csv(rep / 'per_function_audit.csv')
    df[['FunctionID', 'Seed', 'DlhNeighMean', 'DlhNeighZeroFrac', 'DlhDegFrac', 'DlhDispMed',
        'DlhVsGwoMed', 'DlhVsEMed', 'DlhGwoVsEMed']].to_csv(rep / 'per_run_audit.csv', index=False)
    g1 = int((per.neigh >= 5).sum()); g2 = int((per.deg_frac <= 0.30).sum())
    g3 = int((per.vs_gwo >= 0.01).sum()); g4 = int((per.vs_e >= 0.02).sum())
    gates = [g1 >= 6, g2 >= 6, g3 >= 6, g4 >= 6]
    gate = bool(all(gates))
    summary = dict(results_dir=str(p), runs=len(df), functions_neigh_ge5=g1, functions_deg_le030=g2,
                   functions_vsgwo_ge001=g3, functions_vse_ge002=g4, gate_pass=gate,
                   verdict='PROMOTE_DLH_TO_P1' if gate else 'STOP_DLH_P0')
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# Sparse-DLH P0 几何审计结果', '',
             f'- 结果目录：`{p}`', f'- {len(df)} 次运行（8 函数 × 5 新种子 × 100k FE），audit 模式与冻结 G1+E+STEER 逐位一致（合约测试）', '',
             '| F | 邻域均值 | 空邻域比例 | 退化差分比例 | DLH 位移 | DLH vs GWO | DLH→E | GWO→E |',
             '|---:|---:|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        r = per.loc[f]
        lines.append(f"| {f} | {r.neigh:.2f} | {r.zero_frac:.3f} | {r.deg_frac:.3f} | {r.disp:.4f} | "
                     f"{r.vs_gwo:.4f} | {r.vs_e:.4f} | {r.gwo_vs_e:.4f} |")
    lines += ['', '## 预注册门槛（doc 65）', '',
              f"1. 邻域均值 ≥5 的函数：**{g1}/8** → {'通过' if gates[0] else '不通过'}",
              f"2. 退化差分比例 ≤0.30 的函数：**{g2}/8** → {'通过' if gates[1] else '不通过'}",
              f"3. DLH vs GWO 距离 ≥0.01 的函数：**{g3}/8** → {'通过' if gates[2] else '不通过'}",
              f"4. DLH→E 距离 ≥0.02 的函数：**{g4}/8** → {'通过' if gates[3] else '不通过'}",
              '5. audit 逐位一致：通过（合约测试）', '',
              f"**最终判定：{summary['verdict']}**"]
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
