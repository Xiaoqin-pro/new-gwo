#!/usr/bin/env python3
"""E-STEER P1: 2x2 factorial {G1-STEER on/off} x {E-STEER on/off} on the frozen scaffold.

Primary estimator (repo convention): per function, median over seeds of the PAIRED per-seed ratio
mechanism/baseline; headline = median over functions; wins = #functions with ratio < 1;
cats = #functions with ratio > 1.20.  Pre-registration: sparse_q/docs/70_ESTEER_P1_PREREG.md
"""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
SEEDS = list(range(3449, 3459))
ARMS = {'A': 'A-G1on-Eoff', 'B': 'B-G1off-Eon', 'C': 'C-G1on-Eon', 'D': 'D-G1off-Eoff'}


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def paired(df, a, b):
    """per-function median of per-seed paired ratios a/b + the arrays for tests."""
    x = df[df.Algorithm == ARMS[a]][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'ea'})
    y = df[df.Algorithm == ARMS[b]][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'eb'})
    j = x.merge(y, on=['FunctionID', 'Seed'], how='inner')
    j['r'] = j.ea / j.eb
    j['dl'] = np.log10(np.maximum(j.ea, 1e-12)) - np.log10(np.maximum(j.eb, 1e-12))
    g = j.groupby('FunctionID')
    return g.r.median(), g.dl.median(), j


def summarize(rr, j):
    r = rr.to_numpy(float)
    try:
        pv = float(wilcoxon(j.groupby('FunctionID').dl.median().to_numpy(float)).pvalue)
    except ValueError:
        pv = float('nan')
    return dict(median=float(np.median(r)), wins=int((r < 1).sum()), losses=int((r > 1).sum()),
                cats=int((r > 1.20).sum()), max_ratio=float(r.max()),
                worst_f=int(rr.index[int(np.argmax(r))]), wilcoxon_p=pv)


def main():
    p = latest('esteer_p1_*')
    df = pd.read_csv(p / 'runs.csv')
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert set(df.Algorithm.unique()) == set(ARMS.values()) and len(df) == 4 * 15 * 10
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all()
    rep = ROOT / 'reports' / 'esteer_p1_analysis'
    rep.mkdir(parents=True, exist_ok=True)

    pairs = [('C', 'A', 'C/A (E-STEER on top of the final algorithm)'),
             ('B', 'D', 'B/D (E-STEER alone vs frozen G1+E)'),
             ('A', 'D', 'A/D (G1-STEER alone; validity check) '),
             ('C', 'D', 'C/D (both vs frozen G1+E)'),
             ('C', 'B', 'C/B (G1-STEER on top of E-STEER)'),
             ('B', 'A', 'B/A (stream swap)')]
    summary, rows = {}, []
    for a, b, lab in pairs:
        rr, dl, j = paired(df, a, b)
        s = summarize(rr, j)
        summary[lab] = s
        for f in rr.index:
            rows.append(dict(comparison=lab, FunctionID=int(f), median_ratio=float(rr.loc[f])))
    pd.DataFrame(rows).to_csv(rep / 'per_function_ratio.csv', index=False)

    # interaction (paired per function, then across functions)
    jCA = paired(df, 'C', 'A')[2][['FunctionID', 'Seed', 'dl']].rename(columns={'dl': 'dCA'})
    jBD = paired(df, 'B', 'D')[2][['FunctionID', 'Seed', 'dl']].rename(columns={'dl': 'dBD'})
    inter = jCA.merge(jBD, on=['FunctionID', 'Seed'])
    inter['I'] = inter.dCA - inter.dBD
    I_f = inter.groupby('FunctionID').I.median()
    I = float(I_f.median())
    rng = np.random.default_rng(20261022)
    boot = np.array([np.median(rng.choice(I_f.to_numpy(float), len(I_f), replace=True)) for _ in range(4000)])
    I_ci = [float(np.percentile(boot, 2.5)), float(np.percentile(boot, 97.5))]

    sec = df.groupby('Algorithm').Seconds.mean()
    rt = {f"{k}": float(sec[ARMS[k]] / sec[ARMS['A']]) for k in ['A', 'B', 'C', 'D']}
    cols = [c for c in ['EsteerTrigRate', 'EsteerStepMean'] if c in df.columns]
    if cols:
        est = df[df.Algorithm.isin([ARMS['B'], ARMS['C']])].groupby('Algorithm')[cols].mean()
    else:
        est = pd.DataFrame(0.0, index=[ARMS['B'], ARMS['C']], columns=['EsteerTrigRate', 'EsteerStepMean'])

    h1 = summary['C/A (E-STEER on top of the final algorithm)']
    H1 = bool(h1['median'] <= 0.98 and h1['wins'] >= 11 and h1['cats'] == 0 and rt['C'] <= 1.15)
    valid = summary['A/D (G1-STEER alone; validity check) ']
    H3 = bool(valid['median'] <= 0.99 and valid['wins'] >= 10)
    if H1 and I <= 0:
        verdict = 'PROMOTE_ESTEER'
    elif H1 and I > 0:
        verdict = 'ESTEER_SUBSTITUTE'
    else:
        verdict = 'STOP_ESTEER'
    summary.update(results_dir=str(p), interaction_I=I, interaction_CI=I_ci, runtime=rt,
                   H1_pass=H1, H3_validity=H3, verdict=verdict,
                   esteer_activity={k: {kk: float(vv) for kk, vv in v.items()} for k, v in est.to_dict('index').items()})
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')

    lines = ['# E-STEER P1 结果（2×2 因子，15 函数 × 10 新种子 3449–3458 × 100k FE）', '',
             f'- 结果目录：`{p}`', f'- {len(df)} 次运行，0 失败',
             f'- A=G1-STEER 开/E-STEER 关（冻结终版）、B=G1 关/E 开、C=两者开、D=两者关（冻结 G1+E）', '',
             '| 对比 | 中位比 | 胜 | >1.20 | 最大 | 最差函数 | Wilcoxon p |', '|---|---:|---:|---:|---:|---:|---:|']
    for _, _, lab in pairs:
        s = summary[lab]
        lines.append(f"| {lab} | {s['median']:.4f} | {s['wins']}/{s['wins']+s['losses']} | {s['cats']} | "
                     f"{s['max_ratio']:.3f} | F{s['worst_f']} | {s['wilcoxon_p']:.4f} |")
    lines += ['', f"- 交互项 I（配对，跨函数中位）= **{I:+.4f}**，95% bootstrap CI [{I_ci[0]:+.4f}, {I_ci[1]:+.4f}] → "
                  f"{'不冲突（可加/互补）' if I <= 0 else '替代关系（两者提供同类探索）'}",
              f"- 运行时间比（vs A）：B {rt['B']:.3f}，C {rt['C']:.3f}，D {rt['D']:.3f}",
              f"- E-STEER 活动（B/C 臂平均）：触发率 {est['EsteerTrigRate'].mean():.3f}，平均步长 {est['EsteerStepMean'].mean():.4g}（归一化跨度的比例另见 P0）",
              '', f"- H1（C/A：主门槛）**{'通过' if H1 else '不通过'}**；H3（A/D 有效性检查，G1-STEER 复现）**{'通过' if H3 else '不通过'}**",
              f"- 安全预测（设计规则：合规类不应出现 >1.20）：C/A 的 >1.20 个数 = **{h1['cats']}** → "
              f"{'与规则一致' if h1['cats']==0 else '**规则被否证**'}", '',
              f"**最终判定：{verdict}**", '', '## 逐函数 C/A 中位比', '']
    ca = pd.DataFrame(rows); ca = ca[ca.comparison.str.startswith('C/A')]
    lines.append('| F | C/A |')
    lines.append('|---:|---:|')
    for _, r in ca.iterrows():
        lines.append(f"| {int(r.FunctionID)} | {r.median_ratio:.4f} |")
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
