#!/usr/bin/env python3
"""Analyze the five-arm LLT P1 (750 runs: 15 funcs x 10 seeds x 100k FE)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
SEEDS = list(range(3342, 3352))
ARMS = ['A-FrozenG1E', 'B-LLT-Ring', 'C-LLT-RingRand', 'D-LLT-NoE', 'E-NoE-Frozen']
RNG = np.random.default_rng(20261022)


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def ratio(a, b):
    return float(a / b) if b != 0 else (float('inf') if a > 0 else 1.0)


def holm(p):
    p = np.asarray(p, float)
    out = np.full_like(p, np.nan)
    idx = np.where(np.isfinite(p))[0]
    if not len(idx):
        return out
    order = idx[np.argsort(p[idx])]
    prev = 0.0
    for rank, i in enumerate(order):
        v = min(1.0, (len(order) - rank) * p[i]); v = max(v, prev)
        out[i] = v; prev = v
    return out


def main():
    p = latest('llt_p1_*')
    df = pd.read_csv(p / 'runs.csv')
    rep = ROOT / 'reports' / 'llt_p1_analysis'
    rep.mkdir(parents=True, exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS, 'function mismatch'
    assert sorted(df.Seed.unique().tolist()) == SEEDS, 'seed mismatch'
    assert set(df.Algorithm.unique()) == set(ARMS), 'arm mismatch'
    assert len(df) == 5 * len(FUNCS) * len(SEEDS) and (df.Status == 'ok').all(), 'P1 incomplete'
    assert (df.Evaluations == 100000).all(), 'FE mismatch'
    med = df.pivot_table(index='FunctionID', columns='Algorithm', values='FinalError',
                         aggfunc='median').reindex(FUNCS)
    med.to_csv(rep / 'per_function_final_error_median.csv')
    pairs = [('B-LLT-Ring', 'A-FrozenG1E', 'B/A'),
             ('B-LLT-Ring', 'C-LLT-RingRand', 'B/C'),
             ('D-LLT-NoE', 'E-NoE-Frozen', 'D/E'),
             ('C-LLT-RingRand', 'A-FrozenG1E', 'C/A')]
    ratios, tests, logdiffs = {}, [], {}
    for a, b, lab in pairs:
        rr, rows, ld = [], [], []
        for f in FUNCS:
            x = df[(df.Algorithm == a) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
            y = df[(df.Algorithm == b) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
            r = np.array([ratio(u, v) for u, v in zip(x, y)])
            rr.append(float(np.median(r)))
            ld.append(np.log(np.maximum(x, 1e-12)) - np.log(np.maximum(y, 1e-12)))
            try:
                _, pv = wilcoxon(x, y, alternative='two-sided', zero_method='wilcox', method='auto')
            except ValueError:
                pv = np.nan
            rows.append(dict(comparison=f'{a} vs {b}', FunctionID=f, median_ratio=float(np.median(r)),
                             wins=int((r < 1).sum()), losses=int((r > 1).sum()),
                             p_raw=float(pv) if np.isfinite(pv) else np.nan))
        q = holm([r['p_raw'] for r in rows])
        for r, v in zip(rows, q):
            r['p_holm'] = float(v) if np.isfinite(v) else np.nan
        tests += rows; ratios[lab] = np.array(rr); logdiffs[lab] = np.array(ld)
    pd.DataFrame(tests).to_csv(rep / 'pairwise_wilcoxon_holm.csv', index=False)
    ba, bc, de, ca = ratios['B/A'], ratios['B/C'], ratios['D/E'], ratios['C/A']
    wins = {k: int((v < 1).sum()) for k, v in dict(BA=ba, BC=bc, DE=de, CA=ca).items()}
    cats = {k: int((v > 1.20).sum()) for k, v in dict(BA=ba, BC=bc, DE=de, CA=ca).items()}
    rt = df.groupby('Algorithm').Seconds.mean().to_dict()
    r_ba = rt['B-LLT-Ring'] / rt['A-FrozenG1E']; r_bc = rt['B-LLT-Ring'] / rt['C-LLT-RingRand']
    r_de = rt['D-LLT-NoE'] / rt['E-NoE-Frozen']
    H1 = bool(np.median(ba) <= 0.98 and wins['BA'] >= 11 and cats['BA'] == 0 and r_ba <= 1.15)
    H2 = bool(np.median(bc) <= 0.98 and wins['BC'] >= 11 and cats['BC'] == 0)
    H3 = bool(np.median(de) <= 1.00 and cats['DE'] == 0)
    if H1 and H2:
        verdict = 'PROMOTE_LLT'
    elif H1 and not H2:
        verdict = 'LLT_RANDOM_EFFECT_ONLY'
    else:
        verdict = 'STOP_LLT_P1'
    # 2x2 interaction on log errors: I = (B-A) - (D-E)
    I = logdiffs['B/A'] - logdiffs['D/E']          # (n_func, n_seed) log-error interaction per pair
    I_fun = np.median(I, axis=1)                   # per-function interaction
    boot = np.array([np.mean(RNG.choice(I_fun, size=I_fun.size, replace=True)) for _ in range(2000)])
    I_med = float(np.median(I_fun))
    I_ci = [float(np.percentile(boot, 2.5)), float(np.percentile(boot, 97.5))]
    proc = df.groupby(['Algorithm']).agg(localRate=('LltLocalNeGlobalRate', 'mean'),
                                         seconds=('Seconds', 'mean'),
                                         rounds=('Rounds', 'mean')).reset_index()
    proc.to_csv(rep / 'process_metrics.csv', index=False)
    summary = dict(results_dir=str(p), runs=len(df), median_BA=float(np.median(ba)), wins_BA=wins['BA'],
                   cat_BA=cats['BA'], median_BC=float(np.median(bc)), wins_BC=wins['BC'], cat_BC=cats['BC'],
                   median_DE=float(np.median(de)), wins_DE=wins['DE'], cat_DE=cats['DE'],
                   median_CA=float(np.median(ca)), runtime_BA=float(r_ba), runtime_BC=float(r_bc),
                   runtime_DE=float(r_de), H1_pass=H1, H2_pass=H2, H3_pass=H3, verdict=verdict,
                   interaction_median=I_med, interaction_ci=I_ci)
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    fig, ax = plt.subplots(figsize=(11, 5)); x = np.arange(len(FUNCS)); w = 0.27
    ax.bar(x - w, ba, w, label='B/A (G1E)'); ax.bar(x, bc, w, label='B/C (ringrand)'); ax.bar(x + w, de, w, label='D/E (no E)')
    ax.axhline(1, color='k', lw=1); ax.axhline(0.98, color='tab:green', ls='--', lw=1); ax.axhline(1.20, color='tab:red', ls=':', lw=1)
    ax.set_yscale('log'); ax.set_xticks(x); ax.set_xticklabels([f'F{f}' for f in FUNCS]); ax.set_ylabel('median ratio')
    ax.set_title('LLT P1: 15 functions, 10 seeds, 100k FE'); ax.legend(ncol=3, fontsize=8)
    fig.tight_layout(); fig.savefig(rep / 'per_function_ratio.png', dpi=180); plt.close(fig)
    lines = ['# LLT P1 结果（15 函数 × 10 种子 × 100k FE，五臂）', '', f'- 结果目录：`{p}`', f'- {len(df)} 次运行，0 失败', '',
             '## 门槛', '',
             f"- H1 B/A：中位比 {np.median(ba):.6g}，胜/负 {wins['BA']}/{15-wins['BA']}，>1.20 {cats['BA']}，时间 {r_ba:.4g} → **{'通过' if H1 else '不通过'}**",
             f"- H2 B/C（拓扑质量）：中位比 {np.median(bc):.6g}，胜/负 {wins['BC']}/{15-wins['BC']}，>1.20 {cats['BC']} → **{'通过' if H2 else '不通过'}**",
             f"- H3 D/E（与 E 正交）：中位比 {np.median(de):.6g}，胜/负 {wins['DE']}/{15-wins['DE']}，>1.20 {cats['DE']}，时间 {r_de:.4g} → **{'通过' if H3 else '不通过'}**",
             f"- 参考 C/A（ringrand vs 冻结）：中位比 {np.median(ca):.6g}",
             f"- 2×2 交互 I = (B-A)-(D-E)：中位 {I_med:.4f}，95% bootstrap CI [{I_ci[0]:.4f}, {I_ci[1]:.4f}]",
             f'- 最终裁定：**{verdict}**', '',
             '| F | A | B | C | D | E | B/A | B/C | D/E |', '|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        i = FUNCS.index(f)
        lines.append(f"| {f} | {med.loc[f,'A-FrozenG1E']:.6g} | {med.loc[f,'B-LLT-Ring']:.6g} | "
                     f"{med.loc[f,'C-LLT-RingRand']:.6g} | {med.loc[f,'D-LLT-NoE']:.6g} | {med.loc[f,'E-NoE-Frozen']:.6g} | "
                     f"{ba[i]:.4g} | {bc[i]:.4g} | {de[i]:.4g} |")
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote', rep)


if __name__ == '__main__':
    main()
