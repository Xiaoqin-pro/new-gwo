#!/usr/bin/env python3
"""Identity-Credit P1: 2x2 factorial {routing fix} x {refresh-reset fix} (docs/78)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
SEEDS = list(range(3554, 3564))
ARMS = {'A': 'A-Frozen', 'B': 'B-ID+Reset', 'C': 'C-IDonly', 'D': 'D-ResetOnly'}


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def main():
    p = latest('idc_p1_*')
    df = pd.read_csv(p / 'runs.csv')
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert set(df.Algorithm.unique()) == set(ARMS.values()) and len(df) == 4 * 15 * 10
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all()
    rep = ROOT / 'reports' / 'idc_p1_analysis'; rep.mkdir(parents=True, exist_ok=True)

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
                                            ('B/C', 'B', 'C'), ('B/D', 'B', 'D')]}
    sec = df.groupby('Algorithm').Seconds.mean()
    rt = {k: float(sec[ARMS[k]] / sec[ARMS['A']]) for k in ['B', 'C', 'D']}
    H1 = bool(S['B/A']['median'] <= 0.98 and S['B/A']['wins'] >= 11 and S['B/A']['cats'] == 0 and rt['B'] <= 1.15)
    verdict = 'PROMOTE_IDC' if H1 else 'STOP_IDC_P1'
    out = dict(results_dir=str(p), **{k.replace('/', '_'): {kk: vv for kk, vv in v.items() if kk != 'per'} for k, v in S.items()},
               runtime=rt, H1_pass=H1, verdict=verdict)
    (rep / 'summary.json').write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding='utf-8')
    pd.DataFrame({k: v['per'] for k, v in S.items()}).to_csv(rep / 'per_function_ratio.csv')
    lines = ['# Identity-Credit P1 结果（2×2 因子，15 函数 × 10 新种子 3554–3563 × 100k FE）', '',
             f'- 结果目录：`{p}`（{len(df)} 次运行，0 失败）',
             '- A=冻结；B=ID+重置（完整 IDC）；C=仅 ID 路由；D=仅刷新重置', '',
             '| 对比 | 中位比 | 胜/15 | >1.20 | 最大 | 最差函数 | Wilcoxon p | 95% CI |',
             '|---|---:|---:|---:|---:|---:|---:|---|']
    for lab in ['B/A', 'C/A', 'D/A', 'B/C', 'B/D']:
        s = S[lab]
        lines.append(f"| {lab} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max_ratio']:.3f} | "
                     f"F{s['worst_f']} | {s['wilcoxon_p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] |")
    lines += ['', f"- 运行时间（vs A）：B {rt['B']:.3f}，C {rt['C']:.3f}，D {rt['D']:.3f}",
              f'- H1（B/A 主门槛）**{"通过" if H1 else "不通过"}**', '', f'**判定：{verdict}**', '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
