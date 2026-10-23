#!/usr/bin/env python3
"""GAAS P0: branch-level premise audit."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 4, 7, 10, 13, 20, 24, 30]

def latest():
    ds = sorted((ROOT / 'sparse_q' / 'results').glob('gaas_p0_*'))
    if not ds: raise SystemExit('missing gaas_p0_*')
    return ds[-1]

def main():
    p = latest(); df = pd.read_csv(p / 'runs.csv')
    assert len(df) == 80 and (df.Status == 'ok').all()
    b = df[df.Algorithm == 'B-GAAS-Simplex'].copy()
    a = df[df.Algorithm == 'A-GAAS-Off'].copy()
    rows = []
    for f, g in b.groupby('FunctionID'):
        ev = [g[f'GaasEval_{i}'].sum() for i in range(1, 4)]
        gb = [g[f'GaasGB_{i}'].sum() for i in range(1, 4)]
        ar = [g[f'GaasArc_{i}'].sum() for i in range(1, 4)]
        rates_gb = [gb[i] / max(ev[i], 1) for i in range(3)]
        rates_ar = [ar[i] / max(ev[i], 1) for i in range(3)]
        gate = (gb[2] >= 10) and ((rates_gb[2] >= 1.5 * rates_gb[1]) or (rates_ar[2] >= 1.5 * rates_ar[1]))
        rows.append([f, *ev, *gb, *ar, *rates_gb, *rates_ar, bool(gate)])
    cols = ['F','ev_sh','ev_line','ev_sim','gb_sh','gb_line','gb_sim','ar_sh','ar_line','ar_sim',
            'rate_sh','rate_line','rate_sim','arc_sh','arc_line','arc_sim','gate']
    r = pd.DataFrame(rows, columns=cols)
    j = a[['FunctionID','Seed','FinalError']].merge(b[['FunctionID','Seed','FinalError']], on=['FunctionID','Seed'], suffixes=('_a','_b'))
    j['ratio'] = j.FinalError_b / j.FinalError_a
    pf = j.groupby('FunctionID').ratio.median()
    perf = dict(median=float(pf.median()), wins=int((pf < 1).sum()), cats=int((pf > 1.20).sum()), max=float(pf.max()), per=pf)
    rep = ROOT / 'reports' / 'gaas_p0_analysis'; rep.mkdir(parents=True, exist_ok=True)
    r.to_csv(rep / 'branch_metrics.csv', index=False)
    pd.DataFrame({'B/A': perf['per']}).to_csv(rep / 'per_function_ratio.csv')
    out = dict(results_dir=str(p), branch_gate=int(r.gate.sum()), gate_required=6,
               performance=dict(median=perf['median'], wins=perf['wins'], cats=perf['cats'], max=perf['max']),
               verdict='PROMOTE_GAAS_TO_P1' if r.gate.sum() >= 6 else 'STOP_GAAS_P0')
    (rep / 'summary.json').write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# GAAS P0（8 函数 × 5 种子 3619–3623，100k FE）', '',
             f'- 结果目录：`{p}`（80 次运行，0 失败）',
             f'- 分支前提：{int(r.gate.sum())}/8 通过（门槛 ≥6）',
             f'- 最终性能 B/A（探索性，不作 P0 门槛）：中位 {perf["median"]:.4f}，胜 {perf["wins"]}/8，>1.20 {perf["cats"]}', '',
             '| F | shell GB | line GB | simplex GB | shell rate | line rate | simplex rate | gate |',
             '|---:|---:|---:|---:|---:|---:|---:|:--:|']
    for _, x in r.iterrows():
        lines.append(f"| {int(x.F)} | {int(x.gb_sh)} | {int(x.gb_line)} | {int(x.gb_sim)} | {x.rate_sh:.4%} | {x.rate_line:.4%} | {x.rate_sim:.4%} | {'是' if x.gate else '否'} |")
    lines += ['', f'**判定：{out["verdict"]}**', '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))

if __name__ == '__main__': main()
