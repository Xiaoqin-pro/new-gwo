#!/usr/bin/env python3
"""Analyze the SALS P1 (three arms: frozen / post-selection IID / post-selection LHS)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon
from scipy.io import loadmat
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
SEEDS = list(range(3439, 3449))
ARMS = ['A-Frozen-Final', 'B-PostIID', 'C-SALS']


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def trace(dirp, rid):
    m = loadmat(dirp / 'runs' / f"run_{rid:05d}.mat", struct_as_record=False, squeeze_me=True)['record'].result
    return np.asarray(m.TraceFE, float).ravel(), np.asarray(m.Trace, float).ravel()


def main():
    p = latest('sals_p1_*')
    df = pd.read_csv(p / 'runs.csv')
    rep = ROOT / 'reports' / 'sals_p1_analysis'
    rep.mkdir(parents=True, exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert set(df.Algorithm.unique()) == set(ARMS) and len(df) == 3 * len(FUNCS) * len(SEEDS)
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all()
    def tbl(a, b):
        out = {}
        for f in FUNCS:
            x = df[(df.Algorithm == a) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
            y = df[(df.Algorithm == b) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
            out[f] = (float(np.median(x / y)), x, y)
        return out
    tabs = {'C/B': tbl('C-SALS', 'B-PostIID'), 'B/A': tbl('B-PostIID', 'A-Frozen-Final'),
            'C/A': tbl('C-SALS', 'A-Frozen-Final')}
    summary = {}
    rows = []
    for lab, t in tabs.items():
        rr = np.array([v[0] for v in t.values()])
        lr = np.array([np.median(np.log(np.maximum(v[1], 1e-12)) - np.log(np.maximum(v[2], 1e-12))) for v in t.values()])
        try:
            pv = float(wilcoxon(lr).pvalue)
        except ValueError:
            pv = float('nan')
        summary[lab] = dict(median_ratio=float(np.median(rr)), wins=int((rr < 1).sum()), functions=len(rr),
                            cats=int((rr > 1.20).sum()), max_ratio=float(rr.max()), wilcoxon_p=pv,
                            med_log=float(np.median(lr)))
        for f, v in t.items():
            rows.append(dict(comparison=lab, FunctionID=f, median_ratio=v[0]))
    pd.DataFrame(rows).to_csv(rep / 'per_function_ratio.csv', index=False)
    med = df.pivot_table(index='FunctionID', columns='Algorithm', values='FinalError', aggfunc='median').reindex(FUNCS)
    med.to_csv(rep / 'per_function_final_error_median.csv')
    # FE20 checkpoint (C vs B), paired per cell
    fe20 = []
    for f in FUNCS:
        for s in SEEDS:
            rc = df[(df.Algorithm == 'C-SALS') & (df.FunctionID == f) & (df.Seed == s)]
            rb = df[(df.Algorithm == 'B-PostIID') & (df.FunctionID == f) & (df.Seed == s)]
            if not len(rc) or not len(rb):
                continue
            fe_c, T_c = trace(p, int(rc.RunID.iloc[0])); fe_b, T_b = trace(p, int(rb.RunID.iloc[0]))
            fe20.append(float(np.interp(20000, fe_c, T_c) / np.interp(20000, fe_b, T_b)))
    fe20 = np.array(fe20)
    fe20_by_f = {}
    for f in FUNCS:
        vals = []
        for s in SEEDS:
            rc = df[(df.Algorithm == 'C-SALS') & (df.FunctionID == f) & (df.Seed == s)]
            rb = df[(df.Algorithm == 'B-PostIID') & (df.FunctionID == f) & (df.Seed == s)]
            if not len(rc) or not len(rb):
                continue
            fe_c, T_c = trace(p, int(rc.RunID.iloc[0])); fe_b, T_b = trace(p, int(rb.RunID.iloc[0]))
            vals.append(float(np.interp(20000, fe_c, T_c) / np.interp(20000, fe_b, T_b)))
        fe20_by_f[f] = float(np.median(vals)) if vals else float('nan')
    fe20_wins = int(sum(1 for v in fe20_by_f.values() if v < 1))
    early_claim = bool(float(np.median(list(fe20_by_f.values()))) <= 0.98 and fe20_wins >= 10)
    rt = df.groupby('Algorithm').Seconds.mean().to_dict()
    r_cb = rt['C-SALS'] / rt['B-PostIID']; r_ba = rt['B-PostIID'] / rt['A-Frozen-Final']; r_ca = rt['C-SALS'] / rt['A-Frozen-Final']
    H1 = bool(summary['C/B']['median_ratio'] <= 0.98 and summary['C/B']['wins'] >= 11 and summary['C/B']['cats'] == 0 and r_cb <= 1.15)
    H3 = bool(summary['C/A']['median_ratio'] <= 0.98 and summary['C/A']['wins'] >= 11 and summary['C/A']['cats'] == 0)
    if H1 and H3:
        verdict = 'PROMOTE_SALS'
    elif H3:
        verdict = 'SALS_UNATTRIBUTED'
    else:
        verdict = 'STOP_SALS_P1'
    summary.update(runtime_CB=float(r_cb), runtime_BA=float(r_ba), runtime_CA=float(r_ca),
                   H1_pass=H1, H3_pass=H3, fe20_median=float(np.median(list(fe20_by_f.values()))),
                   fe20_wins=fe20_wins, early_exploration_claim=early_claim, verdict=verdict,
                   fe20_per_function=fe20_by_f)
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# SALS P1 结果（15 函数 × 10 新种子 × 100k FE，三臂）', '', f'- 结果目录：`{p}`', f'- {len(df)} 次运行，0 失败', '',
             '## 门槛', '']
    for lab in ['C/B', 'B/A', 'C/A']:
        o = summary[lab]
        lines.append(f"- {lab}：中位比 {o['median_ratio']:.4f}，胜 {o['wins']}/{o['functions']}，>1.20 {o['cats']}，"
                     f"最大 {o['max_ratio']:.3f}，Wilcoxon p {o['wilcoxon_p']:.4f}")
    lines += ['', f"- H1（主假设 C/B）：**{'通过' if H1 else '不通过'}**（时间比 {r_cb:.3f}）",
              f"- H3（净收益 C/A）：**{'通过' if H3 else '不通过'}**（时间比 {r_ca:.3f}）",
              f"- FE20 检查点 C/B：中位 {summary['fe20_median']:.4f}，胜 {fe20_wins}/15 → "
              f"**{'可声称改善早期探索' if early_claim else '只能声称最终精度价值'}**", '',
              f"**最终判定：{verdict}**", '',
              '| F | A 冻结 | B PostIID | C SALS | C/B | B/A | C/A | C/B@FE20 |', '|---:|---:|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        lines.append(f"| {f} | {med.loc[f,'A-Frozen-Final']:.6g} | {med.loc[f,'B-PostIID']:.6g} | {med.loc[f,'C-SALS']:.6g} | "
                     f"{tabs['C/B'][f][0]:.4f} | {tabs['B/A'][f][0]:.4f} | {tabs['C/A'][f][0]:.4f} | {fe20_by_f[f]:.4f} |")
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
