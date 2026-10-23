#!/usr/bin/env python3
"""EMIX confirm with a REUSED frozen arm (docs/83)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1] + list(range(3, 31))
SEEDS = list(range(3459, 3489))
BASE_BATCH = 'steer_robust_20261022_213856'
BASE_ARM = 'A-Final-SteerOn'
NEW_ARM = 'B-EMIX-Shell25'


def main():
    ds = sorted((ROOT / 'sparse_q' / 'results').glob('emix_confirm2_*'))
    if not ds:
        raise SystemExit('missing emix_confirm2_* results')
    p = ds[-1]
    df = pd.read_csv(p / 'runs.csv')
    base = pd.read_csv(ROOT / 'sparse_q' / 'results' / BASE_BATCH / 'runs.csv')
    assert set(df.Algorithm.unique()) == {NEW_ARM} and len(df) == 870
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all()
    x = df[['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'ea'})
    y = base[base.Algorithm == BASE_ARM][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'eb'})
    j = x.merge(y, on=['FunctionID', 'Seed'])
    assert len(j) == 870
    j['r'] = j.ea / j.eb
    j['dl'] = np.log10(np.maximum(j.ea, 1e-12)) - np.log10(np.maximum(j.eb, 1e-12))
    pf = j.groupby('FunctionID').r.median(); r = pf.to_numpy(float)
    d = j.groupby('FunctionID').dl.median().to_numpy(float)
    try:
        pv = float(wilcoxon(d).pvalue)
    except ValueError:
        pv = float('nan')
    rng = np.random.default_rng(20261023)
    boot = np.array([np.median(rng.choice(r, len(r), replace=True)) for _ in range(5000)])
    ci = [float(np.percentile(boot, 2.5)), float(np.percentile(boot, 97.5))]
    rt = float(df.Seconds.mean() / base[base.Algorithm == BASE_ARM].Seconds.mean())
    H = bool(np.median(r) <= 0.98 and (r < 1).sum() >= 18 and (r > 1.20).sum() == 0 and rt <= 1.15)
    verdict = 'PROMOTE_EMIX_CONFIRMED' if H else 'STOP_EMIX_CONFIRMED'
    rep = ROOT / 'reports' / 'emix_confirm_analysis'; rep.mkdir(parents=True, exist_ok=True)
    pf.rename('median_ratio_B_over_A').to_csv(rep / 'per_function_ratio.csv')
    summary = dict(results_dir=str(p), base_batch=BASE_BATCH, base_arm=BASE_ARM, new_arm=NEW_ARM, n_pairs=len(j),
                   median=float(np.median(r)), wins=int((r < 1).sum()), losses=int((r > 1).sum()),
                   cats=int((r > 1.20).sum()), max_ratio=float(r.max()), min_ratio=float(r.min()),
                   worst_f=int(pf.index[int(np.argmax(r))]), best_f=int(pf.index[int(np.argmin(r))]),
                   wilcoxon_p=pv, ci95=ci, runtime_B_over_A=rt, H_pass=H, verdict=verdict)
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# EMIX 确认级结果（复用冻结臂：29 函数 × 30 种子 3459–3488 × 100k FE）', '',
             f'- EMIX 臂：`{p}`（870 次运行，0 失败）',
             f'- 冻结臂（复用）：`{BASE_BATCH}` / `{BASE_ARM}`（与 `SGWO_EMIX` 的 `eShellShare=0.5` 逐位等价）', '',
             '| 指标 | 数值 | 门槛 |', '|---|---:|---|',
             f"| 中位误差比 B/A | **{np.median(r):.4f}** | ≤0.98 |",
             f"| 获胜函数 | **{int((r<1).sum())}/29** | ≥18 |",
             f"| >1.20 的函数 | **{int((r>1.20).sum())}** | 0 |",
             f"| 最大 / 最小比值 | {r.max():.3f} (F{pf.index[int(np.argmax(r))]}) / {r.min():.3f} (F{pf.index[int(np.argmin(r))]}) | — |",
             f"| Wilcoxon p | {pv:.4g} | — |", f"| 中位比 95% CI | [{ci[0]:.3f}, {ci[1]:.3f}] | — |",
             f"| 运行时间比 | {rt:.3f} | ≤1.15 |", '', f'**判定：{verdict}**', '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
