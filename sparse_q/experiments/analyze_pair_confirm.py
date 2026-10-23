#!/usr/bin/env python3
"""PAIR confirm: quality-aware pairing vs shuffled-rank control, frozen arm reused (docs/89)."""
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
B_ARM, C_ARM = 'B-PAIR-Quality', 'C-PAIR-Shuffled'


def main():
    ds = sorted((ROOT / 'sparse_q' / 'results').glob('pair_confirm_*'))
    if not ds:
        raise SystemExit('missing pair_confirm_* results')
    p = ds[-1]
    df = pd.read_csv(p / 'runs.csv')
    base = pd.read_csv(ROOT / 'sparse_q' / 'results' / BASE_BATCH / 'runs.csv')
    assert set(df.Algorithm.unique()) == {B_ARM, C_ARM} and len(df) == 2 * 29 * 30
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all()
    rep = ROOT / 'reports' / 'pair_confirm_analysis'; rep.mkdir(parents=True, exist_ok=True)

    def stats(a_df, a, b_df, b):
        x = a_df[a_df.Algorithm == a][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'ea'})
        y = b_df[b_df.Algorithm == b][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'eb'})
        j = x.merge(y, on=['FunctionID', 'Seed']); j['r'] = j.ea / j.eb
        j['dl'] = np.log10(np.maximum(j.ea, 1e-12)) - np.log10(np.maximum(j.eb, 1e-12))
        pf = j.groupby('FunctionID').r.median(); r = pf.to_numpy(float)
        d = j.groupby('FunctionID').dl.median().to_numpy(float)
        try:
            pv = float(wilcoxon(d).pvalue)
        except ValueError:
            pv = float('nan')
        rng = np.random.default_rng(20261023)
        boot = np.array([np.median(rng.choice(r, len(r), replace=True)) for _ in range(5000)])
        return dict(median=float(np.median(r)), wins=int((r < 1).sum()), cats=int((r > 1.20).sum()),
                    max_ratio=float(r.max()), min_ratio=float(r.min()), worst_f=int(pf.index[int(np.argmax(r))]),
                    wilcoxon_p=pv, ci95=[float(np.percentile(boot, 2.5)), float(np.percentile(boot, 97.5))], per=pf)

    S = {'B/A': stats(df, B_ARM, base, BASE_ARM), 'C/A': stats(df, C_ARM, base, BASE_ARM),
         'B/C': stats(df, B_ARM, df, C_ARM)}
    sec = df.groupby('Algorithm').Seconds.mean(); base_rt = base[base.Algorithm == BASE_ARM].Seconds.mean()
    rtB, rtC = float(sec[B_ARM] / base_rt), float(sec[C_ARM] / base_rt)
    gBA = bool(S['B/A']['median'] <= 0.98 and S['B/A']['wins'] >= 18 and S['B/A']['cats'] == 0 and rtB <= 1.15)
    gBC = bool(S['B/C']['median'] <= 0.98 and S['B/C']['wins'] >= 18)
    verdict = 'PROMOTE_PAIR' if (gBA and gBC) else ('PAIR_UNATTRIBUTED' if gBA else 'STOP_PAIR_CONFIRM')
    out = dict(results_dir=str(p), base_batch=BASE_BATCH, base_arm=BASE_ARM,
               **{k.replace('/', '_'): {kk: vv for kk, vv in v.items() if kk != 'per'} for k, v in S.items()},
               runtime=dict(B=rtB, C=rtC), gate_BA=gBA, gate_BC=gBC, verdict=verdict)
    (rep / 'summary.json').write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding='utf-8')
    pd.DataFrame({k: v['per'] for k, v in S.items()}).to_csv(rep / 'per_function_ratio.csv')
    lines = ['# PAIR 确认级结果（质量感知配对 vs 打乱排名对照；29 函数 × 30 种子 3459–3488）', '',
             f'- 结果目录：`{p}`（{len(df)} 次运行，0 失败）',
             f'- 冻结臂（复用）：`{BASE_BATCH}` / `{BASE_ARM}`', '',
             '| 对比 | 中位比 | 胜/29 | >1.20 | 最大 | 最差函数 | p | 95% CI | 时间比 |', '|---|---:|---:|---:|---:|---:|---:|---:|---:|']
    for lab, key in [('B 质量配对 / A', 'B'), ('C 打乱对照 / A', 'C')]:
        s = S['B/A'] if key == 'B' else S['C/A']; rt = rtB if key == 'B' else rtC
        lines.append(f"| {lab} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max_ratio']:.3f} | F{s['worst_f']} | "
                     f"{s['wilcoxon_p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] | {rt:.3f} |")
    s = S['B/C']
    lines.append(f"| **B 质量 / C 打乱（归因）** | **{s['median']:.4f}** | **{s['wins']}** | {s['cats']} | {s['max_ratio']:.3f} | F{s['worst_f']} | "
                 f"{s['wilcoxon_p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] | — |")
    lines += ['', f'- 主假设 B/A **{"通过" if gBA else "不通过"}**；归因 B/C **{"通过" if gBC else "不通过"}**',
              f'**判定：{verdict}**', '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
