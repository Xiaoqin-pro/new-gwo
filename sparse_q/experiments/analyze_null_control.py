#!/usr/bin/env python3
"""Null control: four random-stream offsets of the same frozen algorithm (docs/87)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
SEEDS = list(range(3071, 3081))
BASE_BATCH = 'steer_confirm2_20261022_063141'
BASE_ARM = 'B-Steer-Rand'
ARMS = ['N1-Off900001', 'N2-Off900002', 'N3-Off900003', 'N4-Off900004']


def main():
    ds = sorted((ROOT / 'sparse_q' / 'results').glob('null_control_*'))
    if not ds:
        raise SystemExit('missing null_control_* results')
    p = ds[-1]
    df = pd.read_csv(p / 'runs.csv')
    base = pd.read_csv(ROOT / 'sparse_q' / 'results' / BASE_BATCH / 'runs.csv')
    assert set(df.Algorithm.unique()) == set(ARMS) and len(df) == 4 * 15 * 10
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all()
    reps = []
    rows = []
    for arm in ARMS:
        x = df[df.Algorithm == arm][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'ea'})
        y = base[base.Algorithm == BASE_ARM][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'eb'})
        j = x.merge(y, on=['FunctionID', 'Seed']); j['r'] = j.ea / j.eb
        pf = j.groupby('FunctionID').r.median(); r = pf.to_numpy(float)
        try:
            pv = float(wilcoxon(j.groupby('FunctionID').r.median()).pvalue)
        except ValueError:
            pv = float('nan')
        reps.append(dict(arm=arm, median=float(np.median(r)), wins=int((r < 1).sum()),
                         cats=int((r > 1.20).sum()), max_ratio=float(r.max()),
                         worst_f=int(pf.index[int(np.argmax(r))]), p=float(pv)))
        for f in FUNCS:
            rows.append(dict(arm=arm, FunctionID=f, ratio=float(pf.loc[f])))
    allr = np.array([d['ratio'] for d in rows])
    f18 = np.array([d['ratio'] for d in rows if d['FunctionID'] == 18])
    rep = ROOT / 'reports' / 'null_control_analysis'; rep.mkdir(parents=True, exist_ok=True)
    pd.DataFrame(rows).to_csv(rep / 'per_function_ratio.csv', index=False)
    summary = dict(results_dir=str(p), base_batch=BASE_BATCH, base_arm=BASE_ARM, arms=reps,
                   pooled=dict(median=float(np.median(allr)), p05=float(np.percentile(allr, 5)),
                               p95=float(np.percentile(allr, 95)), max=float(allr.max()),
                               n_gt_120=int((allr > 1.20).sum()), n=len(allr)),
                   f18=dict(values=[float(v) for v in f18], median=float(np.median(f18)),
                            max=float(f18.max()), n_gt_120=int((f18 > 1.20).sum())))
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# 零对照（同一算法 × 4 个随机流偏移）——dev 协议的噪声底', '',
             f'- 结果目录：`{p}`（600 次运行，0 失败）',
             f'- 对照臂（复用）：`{BASE_BATCH}` / `{BASE_ARM}`，同种子配对 3071–3080', '',
             '| 零对照臂 | 中位比 | 胜/15 | >1.20 | 最大 | 最差函数 | p |', '|---|---:|---:|---:|---:|---:|---:|']
    for d in reps:
        lines.append(f"| {d['arm']} | {d['median']:.4f} | {d['wins']} | {d['cats']} | {d['max_ratio']:.3f} | F{d['worst_f']} | {d['p']:.3f} |")
    lines += ['', f"- 逐函数比值池（{len(allr)} 个）：中位 {np.median(allr):.4f}，5% {np.percentile(allr,5):.4f}，"
                  f"95% {np.percentile(allr,95):.4f}，最大 {allr.max():.3f}；>1.20 共 **{int((allr>1.20).sum())}/{len(allr)}**",
              f"- **F18 零分布**：{', '.join(f'{v:.2f}' for v in f18)} → 中位 {np.median(f18):.3f}，最大 {f18.max():.3f}，"
              f">1.20 共 {int((f18>1.20).sum())}/4", '',
              '## 判读（写入结论 §43）', '',
              '- 若零对照臂自身经常出现 ≥1 个 >1.20，则 dev 协议的 cats 判定不可靠，',
              '  今天以 cats 停止的候选（CR / KNOB-D / LAST-B / LAST-D）需按此重新评估；',
              '- 对其中最有希望的 1–2 个进入确认级（复用冻结臂，只跑候选臂）。', '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
