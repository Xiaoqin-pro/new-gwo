#!/usr/bin/env python3
"""Analyze the three-arm active-PCSS P1 (450 runs, 15 funcs x 10 seeds, 100k FE)."""
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
SEEDS = list(range(3327, 3337))
ARMS = ['A-FrozenG1E', 'B-PCSS-Active', 'C-PCSS-Control']


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
        v = min(1.0, (len(order) - rank) * p[i])
        v = max(v, prev)
        out[i] = v
        prev = v
    return out


def main():
    p = latest('pcss_p1_*')
    df = pd.read_csv(p / 'runs.csv')
    rep = ROOT / 'reports' / 'pcss_p1_analysis'
    rep.mkdir(parents=True, exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS, 'function mismatch'
    assert sorted(df.Seed.unique().tolist()) == SEEDS, 'seed mismatch'
    assert set(df.Algorithm.unique()) == set(ARMS), 'arm mismatch'
    assert len(df) == 3 * len(FUNCS) * len(SEEDS) and (df.Status == 'ok').all(), 'P1 incomplete'
    assert (df.Evaluations == 100000).all(), 'FE mismatch'
    med = df.pivot_table(index='FunctionID', columns='Algorithm', values='FinalError',
                         aggfunc='median').reindex(FUNCS)
    med.to_csv(rep / 'per_function_final_error_median.csv')
    pairs = [('B-PCSS-Active', 'C-PCSS-Control', 'B/C'),
             ('B-PCSS-Active', 'A-FrozenG1E', 'B/A'),
             ('C-PCSS-Control', 'A-FrozenG1E', 'C/A')]
    ratios, tests = {}, []
    for a, b, lab in pairs:
        rr, rows = [], []
        for f in FUNCS:
            x = df[(df.Algorithm == a) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
            y = df[(df.Algorithm == b) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
            r = np.array([ratio(u, v) for u, v in zip(x, y)])
            rr.append(float(np.median(r)))
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
        tests += rows
        ratios[lab] = np.array(rr)
    pd.DataFrame(tests).to_csv(rep / 'pairwise_wilcoxon_holm.csv', index=False)
    ba, bc, ca = ratios['B/A'], ratios['B/C'], ratios['C/A']
    wins_ba, wins_bc = int((ba < 1).sum()), int((bc < 1).sum())
    cat_ba, cat_bc = int((ba > 1.20).sum()), int((bc > 1.20).sum())
    rt = df.groupby('Algorithm').Seconds.mean().to_dict()
    r_ba = rt['B-PCSS-Active'] / rt['A-FrozenG1E']
    r_bc = rt['B-PCSS-Active'] / rt['C-PCSS-Control']
    H1 = bool(np.median(bc) <= 0.98 and wins_bc >= 11 and cat_bc == 0 and r_bc <= 1.15)
    H2 = bool(np.median(ba) <= 1.02 and cat_ba == 0)
    if H1 and H2:
        verdict = 'PROMOTE_PCSS_ACTIVE'
    elif H2 and not H1:
        verdict = 'PCSS_NO_INDEPENDENT_GAIN'
    else:
        verdict = 'STOP_PCSS_ACTIVE'
    # process evidence: guided vs random slot quality in arm B
    b = df[df.Algorithm == 'B-PCSS-Active']
    proc = b.groupby('FunctionID').agg(gRate=('PcssGuideRate', 'mean'), rRate=('PcssRandRate', 'mean'),
                                       guideEval=('PcssGuideEval', 'mean'), randEval=('PcssRandEval', 'mean'),
                                       fallback=('PcssFallbackGens', 'mean'), rounds=('Rounds', 'mean')).reindex(FUNCS)
    proc['g_minus_r'] = proc.gRate - proc.rRate
    proc.to_csv(rep / 'process_metrics.csv')
    n_proc_pos = int((proc.g_minus_r > 0).sum())
    summary = dict(results_dir=str(p), runs=len(df), median_BA=float(np.median(ba)), wins_BA=wins_ba, cat_BA=cat_ba,
                   median_BC=float(np.median(bc)), wins_BC=wins_bc, cat_BC=cat_bc, median_CA=float(np.median(ca)),
                   runtime_BA=float(r_ba), runtime_BC=float(r_bc), H1_pass=H1, H2_pass=H2, verdict=verdict,
                   functions_guided_rate_above_random=n_proc_pos, mean_gRate=float(proc.gRate.mean()),
                   mean_rRate=float(proc.rRate.mean()))
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    fig, ax = plt.subplots(figsize=(11, 5))
    x = np.arange(len(FUNCS)); w = 0.28
    ax.bar(x - w, ba, w, label='B/A (vs frozen)')
    ax.bar(x, bc, w, label='B/C (vs matched control)')
    ax.bar(x + w, ca, w, label='C/A (control vs frozen)')
    ax.axhline(1, color='k', lw=1); ax.axhline(0.98, color='tab:green', ls='--', lw=1)
    ax.axhline(1.20, color='tab:red', ls=':', lw=1)
    ax.set_yscale('log'); ax.set_xticks(x); ax.set_xticklabels([f'F{f}' for f in FUNCS])
    ax.set_ylabel('median ratio'); ax.set_title('PCSS P1: 15 functions, 10 seeds, 100k FE')
    ax.legend(ncol=3, fontsize=8); fig.tight_layout(); fig.savefig(rep / 'per_function_ratio.png', dpi=180)
    plt.close(fig)
    lines = ['# PCSS P1 结果（15 函数 × 10 种子 × 100k FE）', '', f'- 结果目录：`{p}`',
             f'- {len(df)} 次运行，0 失败', '', '## 门槛', '',
             f"- H1 B/C（代理 vs 匹配随机对照）：中位比 {np.median(bc):.6g}，胜/负 {wins_bc}/{15-wins_bc}，>1.20 {cat_bc}，时间 {r_bc:.4g} → **{'通过' if H1 else '不通过'}**",
             f"- H2 B/A（不低于冻结 G1+E）：中位比 {np.median(ba):.6g}，胜/负 {wins_ba}/{15-wins_ba}，>1.20 {cat_ba}，时间 {r_ba:.4g} → **{'通过' if H2 else '不通过'}**",
             f"- 参考 C/A（对照 vs 冻结）：中位比 {np.median(ca):.6g}", f'- 最终裁定：**{verdict}**', '',
             f'## 过程证据（B 臂，均值）', '',
             f'- 引导名额优于当前最差个体比例 gRate 平均 {proc.gRate.mean():.4f}，随机名额 rRate 平均 {proc.rRate.mean():.4f}（{n_proc_pos}/15 个函数 gRate>rRate）',
             f'- 引导名额评价数/run 平均 {proc.guideEval.mean():.1f}，宏代数/run 平均 {proc.rounds.mean():.1f}（应为 2x宏代数-2）',
             '', '| F | A | B | C | B/A | B/C | gRate | rRate |', '|---:|---:|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        i = FUNCS.index(f)
        lines.append(f"| {f} | {med.loc[f,'A-FrozenG1E']:.6g} | {med.loc[f,'B-PCSS-Active']:.6g} | "
                     f"{med.loc[f,'C-PCSS-Control']:.6g} | {ba[i]:.4g} | {bc[i]:.4g} | "
                     f"{proc.loc[f,'gRate']:.3f} | {proc.loc[f,'rRate']:.3f} |")
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote', rep)


if __name__ == '__main__':
    main()
