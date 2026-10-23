#!/usr/bin/env python3
"""EMIX P1: E-route internal mix rebalancing, 4 arms incl. reverse control (docs/80)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
SEEDS = list(range(3574, 3584))
ARMS = {'A': 'A-Shell50', 'B': 'B-Shell25', 'C': 'C-Shell00', 'D': 'D-Shell75'}


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def main():
    p = latest('emix_p1_*')
    df = pd.read_csv(p / 'runs.csv')
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert set(df.Algorithm.unique()) == set(ARMS.values()) and len(df) == 4 * 15 * 10
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all()
    rep = ROOT / 'reports' / 'emix_p1_analysis'; rep.mkdir(parents=True, exist_ok=True)

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
        rng = np.random.default_rng(20261023)
        boot = np.array([np.median(rng.choice(r, len(r), replace=True)) for _ in range(4000)])
        return dict(median=float(np.median(r)), wins=int((r < 1).sum()), cats=int((r > 1.20).sum()),
                    max_ratio=float(r.max()), worst_f=int(pf.index[int(np.argmax(r))]), wilcoxon_p=pv,
                    ci95=[float(np.percentile(boot, 2.5)), float(np.percentile(boot, 97.5))], per=pf)

    S = {lab: stats(a, b) for lab, a, b in [('B/A', 'B', 'A'), ('C/A', 'C', 'A'), ('D/A', 'D', 'A'),
                                            ('B/C', 'B', 'C'), ('C/D', 'C', 'D')]}
    sec = df.groupby('Algorithm').Seconds.mean()
    rt = {k: float(sec[ARMS[k]] / sec[ARMS['A']]) for k in ['B', 'C', 'D']}
    def gate(lab, key):
        s = S[lab]
        return bool(s['median'] <= 0.98 and s['wins'] >= 11 and s['cats'] == 0 and rt[key] <= 1.15)
    gB, gC, gD = gate('B/A', 'B'), gate('C/A', 'C'), gate('D/A', 'D')
    cands = [(S['B/A']['median'], 'B (shell 0.25)')] if gB else []
    if gC:
        cands.append((S['C/A']['median'], 'C (shell 0.00)'))
    if cands:
        winner = min(cands)[1]
        verdict = 'PROMOTE_EMIX' if not gD else 'EMIX_SENSITIVE_ONLY'
    else:
        winner = None
        verdict = 'STOP_EMIX_P1'
    out = dict(results_dir=str(p), **{k.replace('/', '_'): {kk: vv for kk, vv in v.items() if kk != 'per'} for k, v in S.items()},
               runtime=rt, gate_B=gB, gate_C=gC, gate_D=gD, winner=winner, verdict=verdict)
    (rep / 'summary.json').write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding='utf-8')
    pd.DataFrame({k: v['per'] for k, v in S.items()}).to_csv(rep / 'per_function_ratio.csv')
    lines = ['# EMIX P1 结果（E 路线内部配比重构，4 臂，15 函数 × 10 新种子 3574–3583 × 100k FE）', '',
             f'- 结果目录：`{p}`（{len(df)} 次运行，0 失败）',
             '- A=冻结(壳 0.50) / B=壳 0.25 / C=壳 0.00（全插值）/ D=壳 0.75（反向对照）', '',
             '| 对比 | 中位比 | 胜/15 | >1.20 | 最大 | 最差函数 | Wilcoxon p | 95% CI | 时间比 |',
             '|---|---:|---:|---:|---:|---:|---:|---:|---:|']
    for lab, key in [('B/A', 'B'), ('C/A', 'C'), ('D/A', 'D'), ('B/C', None), ('C/D', None)]:
        s = S[lab]
        lines.append(f"| {lab} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max_ratio']:.3f} | "
                     f"F{s['worst_f']} | {s['wilcoxon_p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] | "
                     f"{rt[key]:.3f} |" if key else
                     f"| {lab} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max_ratio']:.3f} | "
                     f"F{s['worst_f']} | {s['wilcoxon_p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] | — |")
    lines += ['', f'- 门槛：B/A **{"通过" if gB else "不通过"}**；C/A **{"通过" if gC else "不通过"}**；'
                  f'D/A（反向对照，应不通过）**{"通过" if gD else "不通过"}**',
              f'**判定：{verdict}**' + (f'（晋级臂：{winner}）' if winner else ''), '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
