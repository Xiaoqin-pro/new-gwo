#!/usr/bin/env python3
"""MSE P1 three-arm analysis: A frozen / B multi-scale mix / C matched-RMS single scale (docs/73)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
SEEDS = list(range(3494, 3504))
ARMS = {'A': 'A-Frozen', 'B': 'B-Mix', 'C': 'C-CtrlRMS'}


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def main():
    p = latest('mse_p1_*')
    df = pd.read_csv(p / 'runs.csv')
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert set(df.Algorithm.unique()) == set(ARMS.values()) and len(df) == 3 * 15 * 10
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all()
    rep = ROOT / 'reports' / 'mse_p1_analysis'; rep.mkdir(parents=True, exist_ok=True)

    def stats(a, b):
        x = df[df.Algorithm == ARMS[a]][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'ea'})
        y = df[df.Algorithm == ARMS[b]][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'eb'})
        j = x.merge(y, on=['FunctionID', 'Seed'])
        j['r'] = j.ea / j.eb
        j['dl'] = np.log10(np.maximum(j.ea, 1e-12)) - np.log10(np.maximum(j.eb, 1e-12))
        pf = j.groupby('FunctionID').r.median()
        d = j.groupby('FunctionID').dl.median().to_numpy(float)
        r = pf.to_numpy(float)
        try:
            pv = float(wilcoxon(d).pvalue)
        except ValueError:
            pv = float('nan')
        rng = np.random.default_rng(20261022)
        boot = np.array([np.median(rng.choice(r, len(r), replace=True)) for _ in range(4000)])
        return dict(median=float(np.median(r)), wins=int((r < 1).sum()), cats=int((r > 1.20).sum()),
                    max_ratio=float(r.max()), worst_f=int(pf.index[int(np.argmax(r))]), wilcoxon_p=pv,
                    ci95=[float(np.percentile(boot, 2.5)), float(np.percentile(boot, 97.5))], per=pf)

    sBA, sCA, sBC = stats('B', 'A'), stats('C', 'A'), stats('B', 'C')
    sec = df.groupby('Algorithm').Seconds.mean()
    rtBA, rtCA = float(sec[ARMS['B']] / sec[ARMS['A']]), float(sec[ARMS['C']] / sec[ARMS['A']])
    H1 = bool(sBA['median'] <= 0.98 and sBA['wins'] >= 11 and sBA['cats'] == 0 and rtBA <= 1.15)
    H2 = bool(sBC['median'] <= 0.98 and sBC['wins'] >= 11)
    verdict = 'PROMOTE_MSE' if (H1 and H2) else ('MSE_MAGNITUDE_ONLY' if H1 else 'STOP_MSE_P1')
    out = dict(results_dir=str(p), B_over_A={k: v for k, v in sBA.items() if k != 'per'},
               C_over_A={k: v for k, v in sCA.items() if k != 'per'},
               B_over_C={k: v for k, v in sBC.items() if k != 'per'},
               runtime_BA=rtBA, runtime_CA=rtCA, H1_pass=H1, H2_pass=H2, verdict=verdict)
    (rep / 'summary.json').write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding='utf-8')
    pd.DataFrame({'B_over_A': sBA['per'], 'C_over_A': sCA['per'], 'B_over_C': sBC['per']}).to_csv(
        rep / 'per_function_ratio.csv')
    lines = ['# MSE P1 结果（三臂，15 函数 × 10 新种子 3494–3503 × 100k FE）', '',
             f'- 结果目录：`{p}`（{len(df)} 次运行，0 失败）',
             '- A=冻结（单尺度）、B=多尺度均值保持混合、C=匹配 RMS 的单尺度对照', '',
             '| 对比 | 中位比 | 胜/15 | >1.20 | 最大 | 最差函数 | Wilcoxon p | 95% CI |',
             '|---|---:|---:|---:|---:|---:|---:|---|']
    for lab, s in [('B/A（主假设：多尺度 vs 冻结）', sBA), ('C/A（匹配 RMS 单尺度 vs 冻结）', sCA),
                   ('B/C（归因：形状 vs 幅度）', sBC)]:
        lines.append(f"| {lab} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max_ratio']:.3f} | "
                     f"F{s['worst_f']} | {s['wilcoxon_p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] |")
    lines += ['', f'- 运行时间：B/A {rtBA:.3f}，C/A {rtCA:.3f}',
              f'- H1（B/A 主门槛）**{"通过" if H1 else "不通过"}**；H2（B/C 归因）**{"通过" if H2 else "不通过"}**', '',
              f'**判定：{verdict}**', '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
