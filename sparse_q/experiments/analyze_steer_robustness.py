#!/usr/bin/env python3
"""STEER fresh-seed, confirm-scale robustness replication (A = final with G1-STEER, D = frozen G1+E).

Pre-registration: sparse_q/docs/71_STEER_ROBUSTNESS_PREREG.md
Estimator (repo convention): per function, median over seeds of the PAIRED per-seed ratio A/D;
headline = median over functions; wins = #functions with ratio < 1; cats = #functions with ratio > 1.20.
"""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon, spearmanr

ROOT = Path(__file__).resolve().parents[2]
FUNCS29 = [1] + list(range(3, 31))
FUNCS15 = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
BLOCK1 = 'steer_confirm2_20261022_063141'          # B-Steer-Rand (STEER on), 29 funcs x seeds 3071-3100
BASE1 = 'ablcore_20261017_062209'                   # A2-G1E (STEER off), same seeds
A1, D1 = 'B-Steer-Rand', 'A2-G1E'


def per_function_ratios(dfA, armA, dfB, armB, funcs):
    a = dfA[dfA.Algorithm == armA][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'ea'})
    b = dfB[dfB.Algorithm == armB][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'eb'})
    j = a.merge(b, on=['FunctionID', 'Seed'], how='inner')
    j = j[j.FunctionID.isin(funcs)]
    j['r'] = j.ea / j.eb
    j['dl'] = np.log10(np.maximum(j.ea, 1e-12)) - np.log10(np.maximum(j.eb, 1e-12))
    return j


def boot_ci(v, n=4000, seed=20261022):
    rng = np.random.default_rng(seed); v = np.asarray(v, float)
    b = np.array([np.median(rng.choice(v, len(v), replace=True)) for _ in range(n)])
    return float(np.percentile(b, 2.5)), float(np.percentile(b, 97.5))


def main():
    ds = sorted((ROOT / 'sparse_q' / 'results').glob('steer_robust_*'))
    if not ds:
        raise SystemExit('missing steer_robust_* results')
    p = ds[-1]
    df = pd.read_csv(p / 'runs.csv')
    A, D = 'A-Final-SteerOn', 'D-FrozenG1E-SteerOff'
    assert set(df.Algorithm.unique()) == {A, D}, 'arm mismatch'
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS29 and df.Seed.nunique() == 30
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all() and len(df) == 2 * 29 * 30
    rep = ROOT / 'reports' / 'steer_robustness_analysis'; rep.mkdir(parents=True, exist_ok=True)

    j2 = per_function_ratios(df, A, df, D, FUNCS29)              # new block
    pf2 = j2.groupby('FunctionID').r.median(); r2 = pf2.to_numpy(float)
    b1 = pd.read_csv(ROOT / 'sparse_q' / 'results' / BLOCK1 / 'runs.csv')
    b0 = pd.read_csv(ROOT / 'sparse_q' / 'results' / BASE1 / 'runs.csv')
    j1 = per_function_ratios(b1, A1, b0, D1, FUNCS29)            # first block
    pf1 = j1.groupby('FunctionID').r.median(); r1 = pf1.to_numpy(float)
    # pooled over both blocks (per function: median of 60 paired ratios)
    jp = pd.concat([j1[['FunctionID', 'Seed', 'r', 'dl']], j2[['FunctionID', 'Seed', 'r', 'dl']]])
    pfp = jp.groupby('FunctionID').r.median(); rp = pfp.to_numpy(float)

    def block_stats(r, rr, j):
        d = j.groupby('FunctionID').dl.median().to_numpy(float)
        try:
            pv = float(wilcoxon(d).pvalue)
        except ValueError:
            pv = float('nan')
        return dict(median=float(np.median(r)), wins=int((r < 1).sum()), cats=int((r > 1.20).sum()),
                    max_ratio=float(r.max()), min_ratio=float(r.min()),
                    worst_f=int(rr.index[int(np.argmax(r))]), wilcoxon_p=pv, ci95=list(boot_ci(r)))

    s2 = block_stats(r2, pf2, j2); s1 = block_stats(r1, pf1, j1); sp = block_stats(rp, pfp, jp)
    # block x treatment interaction per function (block2 - block1), on log ratios
    m = pd.DataFrame({'b1': pf1, 'b2': pf2}).dropna()
    di = np.log10(m.b2) - np.log10(m.b1)
    I = float(np.median(di.to_numpy(float))); Ici = list(boot_ci(di.to_numpy(float)))
    rho = float(spearmanr(m.b1, m.b2).statistic)

    sec = df.groupby('Algorithm').Seconds.mean()
    rt = float(sec[A] / sec[D])
    R1 = bool(s2['median'] <= 0.98 and s2['wins'] >= 18 and s2['cats'] == 0 and rt <= 1.15)
    R2 = bool(s2['median'] <= 0.99 and s2['wins'] >= 15 and s2['cats'] == 0)
    verdict = 'STEER_ROBUST' if R1 else ('STEER_PARTIAL' if R2 else 'STEER_NOT_REPLICATED')
    out = dict(results_dir=str(p), block2=s2, block1=s1, pooled=sp, interaction_I=I, interaction_CI=Ici,
               cross_block_rho=rho, runtime_A_over_D=rt, R1_pass=R1, R2_pass=R2, verdict=verdict)
    (rep / 'summary.json').write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding='utf-8')
    m.to_csv(rep / 'per_function_ratio.csv')

    lines = ['# STEER 种子块稳健性复现（29 函数 × 30 全新种子 3459–3488 × 100k FE）', '',
             f'- 结果目录：`{p}`  ({len(df)} 次运行，0 失败)', f'- A = 冻结终版（STEER 开）vs D = 冻结 G1+E（STEER 关）', '',
             '| 数据块 | 中位比 | 胜/29 | >1.20 | 最大 | min | 最差函数 | Wilcoxon p | 95% CI |',
             '|---|---:|---:|---:|---:|---:|---:|---:|---|']
    for lab, s in [('**第二块（新种子 3459–3488）**', s2), ('第一块（确认批 3071–3100）', s1),
                   ('**合并两块（60 种子）**', sp)]:
        lines.append(f"| {lab} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max_ratio']:.3f} | "
                     f"{s['min_ratio']:.3f} | F{s['worst_f']} | {s['wilcoxon_p']:.4f} | "
                     f"[{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] |")
    lines += ['', f'- 块×处理交互（逐函数 log 比值：第二块 − 第一块）中位 **{I:+.4f}**，95% CI '
                  f'[{Ici[0]:+.4f}, {Ici[1]:+.4f}]；两块逐函数比值 Spearman ρ = **{rho:.3f}**',
              f'- 运行时间 A/D = {rt:.3f}',
              f'- 判定门槛：R1（完全复现）中位 ≤0.98 + ≥18/29 胜 + 0 灾难 + 时间 ≤1.15；R2（方向一致但更弱）中位 ≤0.99 + ≥15/29 胜 + 0 灾难',
              f'- R1 {"通过" if R1 else "不通过"}；R2 {"通过" if R2 else "不通过"}', '',
              f'**判定：{verdict}**', '']
    act = {'STEER_ROBUST': '保留 STEER 为第二机制，论文以两个独立种子块报告（附合并估计）。',
           'STEER_PARTIAL': '按"小效应 + 块间异质"表述：给出两块各自 CI 与合并估计，不得只引用第一块。',
           'STEER_NOT_REPLICATED': 'STEER 降级为"块依赖的候选机制"，第二机制叙事必须重写。'}[verdict]
    lines += [f'**行动**：{act}', '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
