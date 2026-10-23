#!/usr/bin/env python3
"""K/M protocol sweep: M=100 fixed, K in {10,15,20} (docs/76)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
SEEDS = list(range(3539, 3549))
ARMS = {'A': 'A-K10', 'B': 'B-K15', 'C': 'C-K20'}


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def main():
    p = latest('km_protocol_*')
    df = pd.read_csv(p / 'runs.csv')
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert set(df.Algorithm.unique()) == set(ARMS.values()) and len(df) == 3 * 15 * 10
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all()
    rep = ROOT / 'reports' / 'km_protocol_analysis'; rep.mkdir(parents=True, exist_ok=True)

    def stats(a, b):
        x = df[df.Algorithm == ARMS[a]][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'ea'})
        y = df[df.Algorithm == ARMS[b]][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'eb'})
        j = x.merge(y, on=['FunctionID', 'Seed'])
        j['r'] = j.ea / j.eb
        j['dl'] = np.log10(np.maximum(j.ea, 1e-12)) - np.log10(np.maximum(j.eb, 1e-12))
        pf = j.groupby('FunctionID').r.median(); r = pf.to_numpy(float)
        d = j.groupby('FunctionID').dl.median().to_numpy(float)
        try:
            pv = float(wilcoxon(d).pvalue)
        except ValueError:
            pv = float('nan')
        return dict(median=float(np.median(r)), wins=int((r < 1).sum()), cats=int((r > 1.20).sum()),
                    max_ratio=float(r.max()), worst_f=int(pf.index[int(np.argmax(r))]), wilcoxon_p=pv, per=pf)

    sBA, sCA = stats('B', 'A'), stats('C', 'A')
    sec = df.groupby('Algorithm').Seconds.mean()
    rtB, rtC = float(sec[ARMS['B']] / sec[ARMS['A']]), float(sec[ARMS['C']] / sec[ARMS['A']])
    def gate(s, rt):
        return bool(s['median'] <= 0.98 and s['wins'] >= 11 and s['cats'] == 0 and rt <= 1.15)
    gB, gC = gate(sBA, rtB), gate(sCA, rtC)
    passed = [(sBA['median'], 'B-K15')] if gB else []
    if gC:
        passed.append((sCA['median'], 'C-K20'))
    winner = min(passed)[1] if passed else None
    verdict = ('PROMOTE_' + winner) if winner else 'STOP_KM_PROTOCOL'
    out = dict(results_dir=str(p), B_K15_over_A={k: v for k, v in sBA.items() if k != 'per'},
               C_K20_over_A={k: v for k, v in sCA.items() if k != 'per'},
               runtime_B=rtB, runtime_C=rtC, gate_B=gB, gate_C=gC, winner=winner, verdict=verdict)
    (rep / 'summary.json').write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding='utf-8')
    pd.DataFrame({'B_K15_over_A': sBA['per'], 'C_K20_over_A': sCA['per']}).to_csv(rep / 'per_function_ratio.csv')
    lines = ['# K/M 评价协议扫描结果（M=100 固定，K∈{10,15,20}，15 函数 × 10 新种子 3539–3548）', '',
             f'- 结果目录：`{p}`（{len(df)} 次运行，0 失败）',
             '- 所有臂 100k 真实 FE；K 越大 → 每代评价越多、完整代数越少', '',
             '| 对比 | 中位比 | 胜/15 | >1.20 | 最大 | 最差函数 | Wilcoxon p | 时间比 |',
             '|---|---:|---:|---:|---:|---:|---:|---:|']
    for lab, s, rt in [('K=15 / K=10', sBA, rtB), ('K=20 / K=10', sCA, rtC)]:
        lines.append(f"| {lab} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max_ratio']:.3f} | "
                     f"F{s['worst_f']} | {s['wilcoxon_p']:.4f} | {rt:.3f} |")
    lines += ['', f'- 门槛（中位 ≤0.98、≥11/15 胜、无 >1.20、时间 ≤1.15）：K=15 **{"通过" if gB else "不通过"}**；'
                  f'K=20 **{"通过" if gC else "不通过"}**',
              f'**判定：{verdict}**' + (f'（晋级臂：{winner}）' if winner else '（不扫描 K=25/30、不改 M）'), '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
