#!/usr/bin/env python3
"""MIS-GWO dev screen vs a REUSED frozen arm (docs/82)."""
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
BASE_ARM = 'B-Steer-Rand'          # frozen final; bitwise-equal to SGWO_MIS with misIslands=1
NEW = {'B': 'B-2Isl-Mig', 'C': 'C-2Isl-NoMig', 'D': 'D-5Isl-Mig'}


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def main():
    p = latest('mis_dev_*')
    df = pd.read_csv(p / 'runs.csv')
    base = pd.read_csv(ROOT / 'sparse_q' / 'results' / BASE_BATCH / 'runs.csv')
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert set(df.Algorithm.unique()) == set(NEW.values()) and len(df) == 3 * 15 * 10
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all()
    rep = ROOT / 'reports' / 'mis_dev_analysis'; rep.mkdir(parents=True, exist_ok=True)

    def stats(arm):
        x = df[df.Algorithm == arm][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'ea'})
        y = base[base.Algorithm == BASE_ARM][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'eb'})
        j = x.merge(y, on=['FunctionID', 'Seed'])
        j['r'] = j.ea / j.eb
        j['dl'] = np.log10(np.maximum(j.ea, 1e-12)) - np.log10(np.maximum(j.eb, 1e-12))
        pf = j.groupby('FunctionID').r.median(); r = pf.to_numpy(float)
        d = j.groupby('FunctionID').dl.median().to_numpy(float)
        try:
            pv = float(wilcoxon(d).pvalue)
        except ValueError:
            pv = float('nan')
        rng = np.random.default_rng(20261023)
        boot = np.array([np.median(rng.choice(r, len(r), replace=True)) for _ in range(4000)])
        return dict(median=float(np.median(r)), wins=int((r < 1).sum()), cats=int((r > 1.20).sum()),
                    max_ratio=float(r.max()), worst_f=int(pf.index[int(np.argmax(r))]), wilcoxon_p=pv,
                    ci95=[float(np.percentile(boot, 2.5)), float(np.percentile(boot, 97.5))], per=pf)

    S = {k: stats(v) for k, v in NEW.items()}
    # same-implementation contrast: B (migration) vs C (no migration)
    xb = df[df.Algorithm == NEW['B']][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'eb'})
    xc = df[df.Algorithm == NEW['C']][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'ec'})
    jbc = xb.merge(xc, on=['FunctionID', 'Seed']); jbc['r'] = jbc.eb / jbc.ec
    bc = jbc.groupby('FunctionID').r.median()
    BC = dict(median=float(bc.median()), wins=int((bc < 1).sum()), cats=int((bc > 1.20).sum()), per=bc)
    sec = df.groupby('Algorithm').Seconds.mean()
    base_rt = base[base.Algorithm == BASE_ARM].Seconds.mean()
    rt = {k: float(sec[v] / base_rt) for k, v in NEW.items()}
    def gate(k):
        s = S[k]
        return bool(s['median'] <= 0.98 and s['wins'] >= 11 and s['cats'] == 0 and rt[k] <= 1.15)
    g = {k: gate(k) for k in NEW}
    if g['B']:
        verdict, winner = 'PROMOTE_MIS_B', NEW['B']
    elif g['C']:
        verdict, winner = 'PROMOTE_MIS_C_STRUCTURE_ONLY', NEW['C']
    else:
        verdict, winner = 'STOP_MIS_DEV', None
    out = dict(results_dir=str(p), base_batch=BASE_BATCH, base_arm=BASE_ARM,
               **{k: {kk: vv for kk, vv in v.items() if kk != 'per'} for k, v in S.items()},
               B_over_C={k: v for k, v in BC.items() if k != 'per'}, runtime=rt, gates=g,
               winner=winner, verdict=verdict)
    (rep / 'summary.json').write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding='utf-8')
    pd.DataFrame({'B_over_A': S['B']['per'], 'C_over_A': S['C']['per'], 'D_over_A': S['D']['per'],
                  'B_over_C': BC['per']}).to_csv(rep / 'per_function_ratio.csv')
    lines = ['# MIS-GWO dev 结果（3 新臂 × 15 函数 × 10 种子 3071–3080；冻结臂复用 `steer_confirm2`）', '',
             f'- 结果目录：`{p}`（{len(df)} 次运行，0 失败）',
             f'- 冻结臂（1 岛 = 冻结终版，逐位一致）：复用 `{BASE_BATCH}` 的 `{BASE_ARM}`，同种子配对', '',
             '| 对比 | 中位比 | 胜/15 | >1.20 | 最大 | 最差函数 | Wilcoxon p | 95% CI | 时间比 |',
             '|---|---:|---:|---:|---:|---:|---:|---:|---:|']
    for k, lab in [('B', 'B:2岛+迁移 / A'), ('C', 'C:2岛无迁移 / A'), ('D', 'D:5岛+迁移 / A')]:
        s = S[k]
        lines.append(f"| {lab} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max_ratio']:.3f} | "
                     f"F{s['worst_f']} | {s['wilcoxon_p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] | {rt[k]:.3f} |")
    lines.append(f"| B/C（同实现：迁移 vs 无迁移） | {BC['median']:.4f} | {BC['wins']} | {BC['cats']} | — | — | — | — | — |")
    lines += ['', f"- 门槛：B **{'通过' if g['B'] else '不通过'}**；C **{'通过' if g['C'] else '不通过'}**；D **{'通过' if g['D'] else '不通过'}**",
              f'**判定：{verdict}**' + (f'（晋级臂：{winner}）' if winner else ''), '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
