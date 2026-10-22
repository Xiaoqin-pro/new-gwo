#!/usr/bin/env python3
"""Analyze the nE slot-composition sweep with STEER enabled (doc 63)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
SEEDS = list(range(3404, 3414))
NELIST = [0, 10, 19, 28, 38, 48, 50]
REF = 'NE38-STEER'


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def trace(dirp, rid):
    m = loadmat(dirp / 'runs' / f"run_{rid:05d}.mat", struct_as_record=False, squeeze_me=True)['record'].result
    return np.asarray(m.TraceFE, float).ravel(), np.asarray(m.Trace, float).ravel()


def main():
    p = latest('nesweep_steer_*')
    df = pd.read_csv(p / 'runs.csv')
    rep = ROOT / 'reports' / 'nesweep_steer_analysis'
    rep.mkdir(parents=True, exist_ok=True)
    arms = [f'NE{n:02d}-STEER' for n in NELIST]
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert set(df.Algorithm.unique()) == set(arms), sorted(df.Algorithm.unique().tolist())
    assert len(df) == len(arms) * len(FUNCS) * len(SEEDS) and (df.Status == 'ok').all()
    assert (df.Evaluations == 100000).all()
    rows = []
    for arm in arms:
        rr = []
        for f in FUNCS:
            x = df[(df.Algorithm == arm) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
            y = df[(df.Algorithm == REF) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
            rr.append(float(np.median(x / y)))
        rr = np.array(rr)
        rows.append(dict(arm=arm, nE=NELIST[arms.index(arm)], median_ratio=float(np.median(rr)),
                         wins=int((rr < 1).sum()), cats=int((rr > 1.20).sum()), max_ratio=float(rr.max())))
    tab = pd.DataFrame(rows)
    tab.to_csv(rep / 'per_arm_summary.csv', index=False)
    # per-function detail for every arm
    det = []
    for arm in arms:
        for f in FUNCS:
            x = df[(df.Algorithm == arm) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
            y = df[(df.Algorithm == REF) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
            det.append(dict(arm=arm, nE=NELIST[arms.index(arm)], FunctionID=f, median_ratio=float(np.median(x / y))))
    pd.DataFrame(det).to_csv(rep / 'per_function_ratio.csv', index=False)
    # selection rule (doc 63)
    elig = tab[(tab.wins >= 9) & (tab.max_ratio <= 1.20)]
    if len(elig):
        best = elig.sort_values('median_ratio').iloc[0]
        nE_star = int(best.nE)
        verdict = f'PROMOTE_nE{nE_star}_TO_CONFIRMATION'
    else:
        nE_star = 38
        verdict = 'KEEP_nE38 (no arm met wins>=9/15 and max<=1.20)'
    # 20% FE checkpoint: median trace ratio vs NE38
    prof = {}
    for arm in arms:
        vals = []
        for f in FUNCS:
            for s in SEEDS:
                a = df[(df.Algorithm == arm) & (df.FunctionID == f) & (df.Seed == s)]
                r = df[(df.Algorithm == REF) & (df.FunctionID == f) & (df.Seed == s)]
                if not len(a) or not len(r):
                    continue
                fe_a, T_a = trace(p, int(a.RunID.iloc[0])); fe_r, T_r = trace(p, int(r.RunID.iloc[0]))
                g = np.array([0.20, 1.00]) * 100000
                vals.append(np.interp(g, fe_a, T_a) / np.interp(g, fe_r, T_r))
        if vals:
            prof[arm] = {'fe20': float(np.median(np.array(vals)[:, 0])), 'fe100': float(np.median(np.array(vals)[:, 1]))}
    summary = dict(results_dir=str(p), runs=len(df), arms=tab.to_dict('records'), selected_nE=nE_star,
                   verdict=verdict, checkpoint_profile=prof)
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# nE 槽位构成敏感性（含 STEER，15 函数 × 10 新种子 × 100k FE）', '', f'- 结果目录：`{p}`', f'- {len(df)} 次运行（7 臂）', '',
             '## 各臂相对 NE38（当前构型）', '',
             '| 臂 | nE | 中位误差比 | 胜/15 | >1.20 | 最大比 | 20%FE 轨迹比 |',
             '|---|---:|---:|---:|---:|---:|---:|']
    for r in tab.itertuples():
        cp = prof.get(r.arm, {}).get('fe20', float('nan'))
        lines.append(f"| {r.arm} | {r.nE} | {r.median_ratio:.4f} | {r.wins} | {r.cats} | {r.max_ratio:.3f} | {cp:.3f} |")
    lines += ['', '## 预注册选择规则（doc 63）', '',
              '- 候选臂需满足 `wins ≥ 9/15` 且 `max ≤ 1.20`；在其中取中位比最小者；',
              f'- 命中臂：{list(elig.arm) if len(elig) else "无"}',
              f'- 结论：**{verdict}**']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
