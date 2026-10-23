#!/usr/bin/env python3
"""MSE P0 passive audit: are the three scale classes distinguishable, non-degenerate and reachable?"""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 13, 20, 30]
SEEDS = list(range(3489, 3494))


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def main():
    p = latest('mse_p0_*')
    df = pd.read_csv(p / 'runs.csv')
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all() and len(df) == 40
    # collect_sq flattens the 1x3 vectors into columns MseCand_1..3 etc.
    def vec(name):
        return df[[f'{name}_{i}' for i in (1, 2, 3)]].to_numpy(float)
    cand, ev, disp, clip = vec('MseCand'), vec('MseEval'), vec('MseDispMean'), vec('MseClipRate')
    df['disp_ratio_coarse_base'] = disp[:, 2] / disp[:, 1]
    df['disp_ratio_fine_base'] = disp[:, 0] / disp[:, 1]
    df['clip_coarse'] = clip[:, 2]
    df['evrate_fine'] = ev[:, 0] / np.maximum(cand[:, 0], 1)
    df['evrate_base'] = ev[:, 1] / np.maximum(cand[:, 1], 1)
    df['evrate_coarse'] = ev[:, 2] / np.maximum(cand[:, 2], 1)
    per = df.groupby('FunctionID').agg(n=('Seed', 'size'),
                                       cand_fine=('MseCand_1', 'mean'),
                                       cand_base=('MseCand_2', 'mean'),
                                       cand_coarse=('MseCand_3', 'mean'),
                                       disp_ratio_cb=('disp_ratio_coarse_base', 'median'),
                                       disp_ratio_fb=('disp_ratio_fine_base', 'median'),
                                       clip_coarse=('clip_coarse', 'median'),
                                       evrate_min=('evrate_fine', 'median'),
                                       evrate_base=('evrate_base', 'median'),
                                       evrate_coarse=('evrate_coarse', 'median')).reindex(FUNCS)
    per['evrate_min'] = df.groupby('FunctionID')[['evrate_fine', 'evrate_base', 'evrate_coarse']].median().min(axis=1).reindex(FUNCS)
    g2 = int(((per.disp_ratio_cb >= 1.6) & (per.disp_ratio_cb <= 2.1) &
              (per.disp_ratio_fb >= 0.40) & (per.disp_ratio_fb <= 0.60)).sum())
    g3 = int((per.clip_coarse <= 0.30).sum())
    g4 = int((per.evrate_min >= 0.05).sum())
    verdict = 'PROMOTE_MSE_TO_P1' if (g2 >= 6 and g3 >= 6 and g4 >= 6) else 'STOP_MSE_P0'
    rep = ROOT / 'reports' / 'mse_p0_audit'; rep.mkdir(parents=True, exist_ok=True)
    per.to_csv(rep / 'per_function_audit.csv')
    summary = dict(results_dir=str(p), runs=len(df), functions=FUNCS, seeds=SEEDS,
                   gate_dispersion_functions=g2, gate_clip_functions=g3, gate_reach_functions=g4,
                   verdict=verdict,
                   means=dict(cand_fine=float(cand[:, 0].mean()), cand_base=float(cand[:, 1].mean()),
                              cand_coarse=float(cand[:, 2].mean()),
                              disp_ratio_cb=float(df.disp_ratio_coarse_base.median()),
                              disp_ratio_fb=float(df.disp_ratio_fine_base.median()),
                              clip_coarse=float(df.clip_coarse.median()),
                              evrate_fine=float(df.evrate_fine.median()),
                              evrate_base=float(df.evrate_base.median()),
                              evrate_coarse=float(df.evrate_coarse.median())))
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# MSE P0 被动审计结果（8 函数 × 5 新种子 3489–3493 × 100k FE）', '',
             f'- 结果目录：`{p}`（{len(df)} 次运行，0 失败；审计模式与冻结终版逐位一致由合约测试断言）', '',
             '| F | 细/基准 位移比 | 粗/基准 位移比 | 粗类裁剪率 | 细/基准/粗 评价率 |', '|---:|---:|---:|---:|---|']
    for f in FUNCS:
        r = per.loc[f]
        lines.append(f"| {f} | {r.disp_ratio_fb:.3f} | {r.disp_ratio_cb:.3f} | {r.clip_coarse:.3f} | "
                     f"{r.evrate_min:.3f} / {r.evrate_base:.3f} / {r.evrate_coarse:.3f} |")
    lines += ['', f"- 门槛2（可区分性：粗/基准 ∈[1.6,2.1] 且 细/基准 ∈[0.40,0.60]）：**{g2}/8**",
              f"- 门槛3（非退化：粗类裁剪 ≤0.30）：**{g3}/8**",
              f"- 门槛4（可到达：每类被评价比例 ≥0.05）：**{g4}/8**", '', f'**判定：{verdict}**', '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
