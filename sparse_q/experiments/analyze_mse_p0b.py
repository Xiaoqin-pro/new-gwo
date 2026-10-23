#!/usr/bin/env python3
"""MSE P0b: corrected, intent-faithful degeneracy audit (docs/74). Fresh seeds."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 13, 20, 30]
SEEDS = list(range(3504, 3509))


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def main():
    p = latest('mse_p0b_*')
    df = pd.read_csv(p / 'runs.csv')
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all() and len(df) == 40
    cf = df[['MseClipFracMean_1', 'MseClipFracMean_2', 'MseClipFracMean_3']].to_numpy(float)
    sv = df[['MseSurvMean_1', 'MseSurvMean_2', 'MseSurvMean_3']].to_numpy(float)
    dp = df[['MseDispMean_1', 'MseDispMean_2', 'MseDispMean_3']].to_numpy(float)
    ca = df[['MseCand_1', 'MseCand_2', 'MseCand_3']].to_numpy(float)
    df['clip_frac_coarse'] = cf[:, 2]
    df['surv_coarse'] = sv[:, 2]
    df['disp_real_ratio'] = dp[:, 2] / dp[:, 1]
    df['clip_frac_base'] = cf[:, 1]
    df['surv_base'] = sv[:, 1]
    per = df.groupby('FunctionID').agg(cand_coarse=('MseCand_3', 'mean'),
                                       clip_frac_coarse=('clip_frac_coarse', 'median'),
                                       surv_coarse=('surv_coarse', 'median'),
                                       disp_real_ratio=('disp_real_ratio', 'median'),
                                       clip_frac_base=('clip_frac_base', 'median'),
                                       surv_base=('surv_base', 'median')).reindex(FUNCS)
    per['pass'] = ((per.clip_frac_coarse <= 0.10) & (per.surv_coarse >= 0.85) &
                   (per.disp_real_ratio >= 1.7) & (per.disp_real_ratio <= 2.1))
    npass = int(per['pass'].sum())
    verdict = 'PROMOTE_MSE_TO_P1' if npass >= 6 else 'STOP_MSE_P0B'
    rep = ROOT / 'reports' / 'mse_p0b_audit'; rep.mkdir(parents=True, exist_ok=True)
    per.to_csv(rep / 'per_function_audit.csv')
    summary = dict(results_dir=str(p), runs=len(df), functions=FUNCS, seeds=SEEDS,
                   functions_pass=npass, verdict=verdict,
                   medians=dict(clip_frac_coarse=float(df.clip_frac_coarse.median()),
                                surv_coarse=float(df.surv_coarse.median()),
                                disp_real_ratio=float(df.disp_real_ratio.median()),
                                clip_frac_base=float(df.clip_frac_base.median()),
                                surv_base=float(df.surv_base.median())))
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# MSE P0b 结果（修正口径，8 函数 × 5 新种子 3504–3508）', '',
             f'- 结果目录：`{p}`（{len(df)} 次运行，0 失败）',
             '- 口径修正原因见 `sparse_q/docs/74_MSE_P0B_PREREG.md`（P0 的"任意一维触界"在 D=50 下过严）', '',
             '| F | 粗类候选数 | 触界坐标比例(粗) | 位移存活率(粗) | 实际位移比 粗/基准 | 同项(基准类) | 通过 |',
             '|---:|---:|---:|---:|---:|---:|:--:|']
    for f in FUNCS:
        r = per.loc[f]
        lines.append(f"| {f} | {r.cand_coarse:.0f} | {r.clip_frac_coarse:.4f} | {r.surv_coarse:.3f} | "
                     f"{r.disp_real_ratio:.3f} | {r.clip_frac_base:.4f} / {r.surv_base:.3f} | "
                     f"{'是' if r['pass'] else '否'} |")
    lines += ['', f'**通过函数数：{npass}/8（门槛 ≥6）**', '', f'**判定：{verdict}**', '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
