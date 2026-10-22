#!/usr/bin/env python3
"""Analyze the Sparse-DLH P1 (three arms, 15 functions x 10 new seeds)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
SEEDS = list(range(3424, 3434))
ARMS = ['A-Frozen-Final', 'B-DLH', 'C-GlobalDiff']


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def ratio_tbl(df, a, b):
    out = {}
    for f in FUNCS:
        x = df[(df.Algorithm == a) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
        y = df[(df.Algorithm == b) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
        if len(x) and len(y):
            out[f] = (float(np.median(x / y)), x, y)
    return out


def main():
    p = latest('dlh_p1_*')
    df = pd.read_csv(p / 'runs.csv')
    rep = ROOT / 'reports' / 'dlh_p1_analysis'
    rep.mkdir(parents=True, exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert set(df.Algorithm.unique()) == set(ARMS) and len(df) == 3 * len(FUNCS) * len(SEEDS)
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all()
    tabs = {lab: ratio_tbl(df, a, b) for a, b, lab in
            [('B-DLH', 'A-Frozen-Final', 'B/A'), ('B-DLH', 'C-GlobalDiff', 'B/C'), ('C-GlobalDiff', 'A-Frozen-Final', 'C/A')]}
    rows = []
    summary = {}
    for lab, t in tabs.items():
        rr = np.array([v[0] for v in t.values()])
        lr = np.array([np.median(np.log(np.maximum(v[1], 1e-12)) - np.log(np.maximum(v[2], 1e-12))) for v in t.values()])
        try:
            pv = float(wilcoxon(lr).pvalue)
        except ValueError:
            pv = float('nan')
        summary[lab] = dict(median_ratio=float(np.median(rr)), wins=int((rr < 1).sum()), functions=len(rr),
                            cats=int((rr > 1.20).sum()), max_ratio=float(rr.max()),
                            wilcoxon_p=pv, med_log=float(np.median(lr)))
        for f, v in t.items():
            rows.append(dict(comparison=lab, FunctionID=f, median_ratio=v[0]))
    pd.DataFrame(rows).to_csv(rep / 'per_function_ratio.csv', index=False)
    med = df.pivot_table(index='FunctionID', columns='Algorithm', values='FinalError', aggfunc='median').reindex(FUNCS)
    med.to_csv(rep / 'per_function_final_error_median.csv')
    rt = df.groupby('Algorithm').Seconds.mean().to_dict()
    r_ba = rt['B-DLH'] / rt['A-Frozen-Final']; r_bc = rt['B-DLH'] / rt['C-GlobalDiff']
    H1 = bool(summary['B/A']['median_ratio'] <= 0.98 and summary['B/A']['wins'] >= 11
              and summary['B/A']['cats'] == 0 and r_ba <= 1.15)
    H2 = bool(summary['B/C']['median_ratio'] <= 0.98 and summary['B/C']['wins'] >= 11)
    if H1 and H2:
        verdict = 'PROMOTE_DLH'
    elif H1:
        verdict = 'DIFFERENTIAL_FILLER_ONLY'
    else:
        verdict = 'STOP_DLH_P1'
    summary.update(runtime_BA=float(r_ba), runtime_BC=float(r_bc), H1_pass=H1, H2_pass=H2, verdict=verdict)
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# Sparse-DLH P1 结果（15 函数 × 10 新种子 × 100k FE，三臂）', '', f'- 结果目录：`{p}`', f'- {len(df)} 次运行，0 失败', '',
             '## 门槛', '']
    for lab in ['B/A', 'B/C', 'C/A']:
        o = summary[lab]
        lines.append(f"- {lab}：中位比 {o['median_ratio']:.4f}，胜 {o['wins']}/{o['functions']}，>1.20 {o['cats']}，"
                     f"最大 {o['max_ratio']:.3f}，Wilcoxon p {o['wilcoxon_p']:.4f}")
    lines += ['', f"- H1（B/A 净收益）：**{'通过' if H1 else '不通过'}**（时间比 {r_ba:.3f}）",
              f"- H2（B/C 动态邻域归因）：**{'通过' if H2 else '不通过'}**（时间比 {r_bc:.3f}）", '',
              f"**最终判定：{verdict}**", '',
              '| F | A 冻结 | B DLH | C 全局差分 | B/A | B/C |', '|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        lines.append(f"| {f} | {med.loc[f,'A-Frozen-Final']:.6g} | {med.loc[f,'B-DLH']:.6g} | {med.loc[f,'C-GlobalDiff']:.6g} | "
                     f"{tabs['B/A'][f][0]:.4f} | {tabs['B/C'][f][0]:.4f} |")
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
