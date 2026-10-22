#!/usr/bin/env python3
"""Analyze the STEER dev batch (600 runs: frozen / vectorised control / random-dir / success-dir)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
SEEDS = list(range(3379, 3389))
ARMS = ['A-Frozen', 'V-Vec', 'B-Steer-Rand', 'C-Steer-Dir']


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def per_func_ratio(df, a, b):
    out = []
    for f in FUNCS:
        x = df[(df.Algorithm == a) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
        y = df[(df.Algorithm == b) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
        out.append(float(np.median(x / y)))
    return np.array(out)


def main():
    p = latest('steer_dev_*')
    df = pd.read_csv(p / 'runs.csv')
    rep = ROOT / 'reports' / 'steer_dev_analysis'
    rep.mkdir(parents=True, exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS, 'function mismatch'
    assert sorted(df.Seed.unique().tolist()) == SEEDS, 'seed mismatch'
    assert set(df.Algorithm.unique()) == set(ARMS), 'arm mismatch'
    assert len(df) == 4 * len(FUNCS) * len(SEEDS) and (df.Status == 'ok').all(), 'dev run incomplete'
    assert (df.Evaluations == 100000).all(), 'FE mismatch'
    med = df.pivot_table(index='FunctionID', columns='Algorithm', values='FinalError', aggfunc='median').reindex(FUNCS)
    med.to_csv(rep / 'per_function_final_error_median.csv')
    cmp_defs = [('V-Vec', 'A-Frozen', 'V/A'), ('B-Steer-Rand', 'V-Vec', 'B/V'),
                ('C-Steer-Dir', 'V-Vec', 'C/V'), ('C-Steer-Dir', 'B-Steer-Rand', 'C/B'),
                ('B-Steer-Rand', 'A-Frozen', 'B/A'), ('C-Steer-Dir', 'A-Frozen', 'C/A')]
    ratios = {lab: per_func_ratio(df, a, b) for a, b, lab in cmp_defs}
    wins = {k: int((v < 1).sum()) for k, v in ratios.items()}
    cats = {k: int((v > 1.20).sum()) for k, v in ratios.items()}
    rt = df.groupby('Algorithm').Seconds.mean().to_dict()
    r_ba = rt['B-Steer-Rand'] / rt['V-Vec']; r_ca = rt['C-Steer-Dir'] / rt['V-Vec']
    impl_ok = bool(0.98 <= np.median(ratios['V/A']) <= 1.02 and cats['V/A'] == 0)
    H1 = bool(np.median(ratios['B/V']) <= 0.98 and wins['B/V'] >= 11 and cats['B/V'] == 0 and r_ba <= 1.15)
    H2 = bool(np.median(ratios['C/V']) <= 0.98 and wins['C/V'] >= 11 and cats['C/V'] == 0 and r_ca <= 1.15)
    if not impl_ok:
        verdict = 'INCONCLUSIVE_VECTORISATION'
    elif H1 and H2:
        verdict = 'PROMOTE_STEER_BOTH'
    elif H1:
        verdict = 'PROMOTE_STEER_RAND'
    elif H2:
        verdict = 'PROMOTE_STEER_DIR'
    else:
        verdict = 'STOP_STEER'
    proc = df.groupby('Algorithm').agg(steer_rate=('SteerRate', 'median'), seconds=('Seconds', 'mean')).loc[ARMS]
    proc.to_csv(rep / 'process_metrics.csv')
    tbl = pd.DataFrame(dict(FunctionID=FUNCS, **{k: v for k, v in ratios.items()})).set_index('FunctionID')
    tbl.to_csv(rep / 'per_function_ratio.csv')
    summary = dict(results_dir=str(p), runs=len(df),
                   median_VA=float(np.median(ratios['V/A'])), cat_VA=cats['V/A'], impl_check_pass=impl_ok,
                   median_BV=float(np.median(ratios['B/V'])), wins_BV=wins['B/V'], cat_BV=cats['B/V'], runtime_BV=float(r_ba),
                   median_CV=float(np.median(ratios['C/V'])), wins_CV=wins['C/V'], cat_CV=cats['C/V'], runtime_CV=float(r_ca),
                   median_CB=float(np.median(ratios['C/B'])), wins_CB=wins['C/B'],
                   median_BA=float(np.median(ratios['B/A'])), median_CA=float(np.median(ratios['C/A'])),
                   H1_pass=H1, H2_pass=H2, verdict=verdict)
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# STEER dev 结果（G1+E，15 函数 × 10 种子 × 100k FE）', '', f'- 结果目录：`{p}`', f'- {len(df)} 次运行，0 失败', '',
             '## 门槛', '',
             f"- 实现对照 V/A：中位比 {np.median(ratios['V/A']):.4f}，>1.20 {cats['V/A']} → **{'通过' if impl_ok else '不通过'}**",
             f"- H1 B(随机方向)/V：中位比 {np.median(ratios['B/V']):.4f}，胜 {wins['B/V']}/{len(FUNCS)}，>1.20 {cats['B/V']}，时间比 {r_ba:.4f} → **{'通过' if H1 else '不通过'}**",
             f"- H2 C(成功方向)/V：中位比 {np.median(ratios['C/V']):.4f}，胜 {wins['C/V']}/{len(FUNCS)}，>1.20 {cats['C/V']}，时间比 {r_ca:.4f} → **{'通过' if H2 else '不通过'}**",
             f"- 方向归因 C/B：中位比 {np.median(ratios['C/B']):.4f}，胜 {wins['C/B']}/{len(FUNCS)}",
             f"- 参考 B/A {np.median(ratios['B/A']):.4f}；C/A {np.median(ratios['C/A']):.4f}",
             f'- 扰动触发率（中位）：V {proc.loc["V-Vec","steer_rate"]:.3f}，B {proc.loc["B-Steer-Rand","steer_rate"]:.3f}，C {proc.loc["C-Steer-Dir","steer_rate"]:.3f}',
             '', f"**最终判定：{verdict}**", '',
             '| F | A | V | B | C | V/A | B/V | C/V | C/B |', '|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        lines.append(f"| {f} | {med.loc[f,'A-Frozen']:.6g} | {med.loc[f,'V-Vec']:.6g} | {med.loc[f,'B-Steer-Rand']:.6g} | "
                     f"{med.loc[f,'C-Steer-Dir']:.6g} | {ratios['V/A'][FUNCS.index(f)]:.4f} | {ratios['B/V'][FUNCS.index(f)]:.4f} | "
                     f"{ratios['C/V'][FUNCS.index(f)]:.4f} | {ratios['C/B'][FUNCS.index(f)]:.4f} |")
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote', rep)


if __name__ == '__main__':
    main()
