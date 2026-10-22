#!/usr/bin/env python3
"""Analyze the DSE P1 (3 new arms x 15 funcs x 10 seeds; A2 and STEER reused)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon, binomtest
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
SEEDS = list(range(3071, 3081))
RNG = np.random.default_rng(20261024)


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def align(df_a, a, df_b, b, f, seeds):
    xa = df_a[(df_a.Algorithm == a) & (df_a.FunctionID == f)].set_index('Seed').FinalError
    yb = df_b[(df_b.Algorithm == b) & (df_b.FunctionID == f)].set_index('Seed').FinalError
    common = [s for s in seeds if s in xa.index and s in yb.index]
    return xa.loc[common].to_numpy(float), yb.loc[common].to_numpy(float)


def main():
    p = latest('dse_p1_*')
    new = pd.read_csv(p / 'runs.csv')
    a2 = pd.read_csv(ROOT / 'sparse_q' / 'results' / 'ablcore_20261017_062209' / 'runs.csv')
    steer = pd.read_csv(ROOT / 'sparse_q' / 'results' / 'steer_confirm2_20261022_063141' / 'runs.csv')
    rep = ROOT / 'reports' / 'dse_p1_analysis'
    rep.mkdir(parents=True, exist_ok=True)
    assert sorted(new.FunctionID.unique().tolist()) == FUNCS and sorted(new.Seed.unique().tolist()) == SEEDS
    assert len(new) == 3 * len(FUNCS) * len(SEEDS) and (new.Status == 'ok').all() and (new.Evaluations == 100000).all()
    rows = []
    summary = {}
    for (df_a, a, df_b, b, lab) in [(new, 'D-STEER-DSE-Cauchy', steer, 'B-Steer-Rand', 'D/B'),
                                    (new, 'C-DSE-Cauchy', a2, 'A2-G1E', 'C/A2'),
                                    (new, 'D-STEER-DSE-Cauchy', new, 'E-STEER-DSE-Gauss', 'D/E'),
                                    (new, 'C-DSE-Cauchy', steer, 'B-Steer-Rand', 'C/B'),
                                    (steer, 'B-Steer-Rand', a2, 'A2-G1E', 'B/A2')]:
        rr, wins, losses, lr = [], 0, 0, []
        for f in FUNCS:
            x, y = align(df_a, a, df_b, b, f, SEEDS)
            if len(x) < 5: continue
            r = x / y
            rr.append(float(np.median(r)))
            wins += int((r < 1).sum()); losses += int((r > 1).sum())
            lr.append(np.median(np.log(np.maximum(x, 1e-12)) - np.log(np.maximum(y, 1e-12))))
        rr = np.array(rr); lr = np.array(lr)
        boot = np.array([np.median(RNG.choice(lr, size=lr.size, replace=True)) for _ in range(2000)])
        summary[lab] = dict(median_ratio=float(np.median(rr)), wins=int((rr < 1).sum()), functions=len(rr),
                            cats=int((rr > 1.20).sum()), med_log=float(np.median(lr)),
                            ci_lo=float(np.percentile(boot, 2.5)), ci_hi=float(np.percentile(boot, 97.5)))
        for f, r in zip(FUNCS, rr):
            rows.append(dict(comparison=lab, FunctionID=f, median_ratio=r))
    pd.DataFrame(rows).to_csv(rep / 'per_function_ratio.csv', index=False)
    rt_new = new.groupby('Algorithm').Seconds.mean().to_dict()
    rt_a2 = float(a2[a2.Algorithm == 'A2-G1E'].Seconds.mean()); rt_b = float(steer[steer.Algorithm == 'B-Steer-Rand'].Seconds.mean())
    r_db = rt_new['D-STEER-DSE-Cauchy'] / rt_b
    r_ca = rt_new['C-DSE-Cauchy'] / rt_a2
    H1 = bool(summary['D/B']['median_ratio'] <= 0.98 and summary['D/B']['wins'] >= 11 and summary['D/B']['cats'] == 0 and r_db <= 1.15)
    H2 = bool(summary['C/A2']['median_ratio'] <= 0.98 and summary['C/A2']['wins'] >= 11 and summary['C/A2']['cats'] == 0 and r_ca <= 1.15)
    heavy = bool(abs(summary['D/E']['median_ratio'] - 1) < 0.02 and summary['D/E']['wins'] <= 8)
    if H1 and H2:
        verdict = 'PROMOTE_DSE'
    elif H1:
        verdict = 'DSE_INTERACTION_ONLY (needs 2x2 confirmation)'
    elif H2:
        verdict = 'DSE_ALONE_ONLY (incompatible with STEER)'
    else:
        verdict = 'STOP_DSE_P1'
    proc = new.groupby('Algorithm').agg(gate_gens=('DseGateGens', 'median'), used=('DseUsed', 'median'),
                                        used_frac=('DseUsedFrac', 'median'), first_fe=('DseFirstFE', 'median'),
                                        pop_rate=('DsePopAccRate', 'median'), arc_rate=('DseArcAccRate', 'median'),
                                        seconds=('Seconds', 'mean')).reset_index()
    proc.to_csv(rep / 'process_metrics.csv', index=False)
    summary.update(runtime_DB=float(r_db), runtime_CA2=float(r_ca), H1_pass=H1, H2_pass=H2,
                   heavy_tail_unresolved=heavy, verdict=verdict)
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# DSE P1 结果（15 函数 × 10 种子 × 100k FE；A2/STEER 复用）', '', f'- 结果目录：`{p}`', f'- 新跑 {len(new)} 次（C/D/E 三臂）', '',
             '## 门槛', '']
    for lab in ['D/B', 'C/A2', 'D/E', 'C/B', 'B/A2']:
        o = summary[lab]
        lines.append(f"- {lab}：中位比 {o['median_ratio']:.4f}，胜 {o['wins']}/{o['functions']}，>1.20 {o['cats']}，"
                     f"中位 log 比 {o['med_log']:.4f} [{o['ci_lo']:.4f}, {o['ci_hi']:.4f}]")
    lines += ['', f"- H1（D/B，STEER 之上的增量）：**{'通过' if H1 else '不通过'}**（时间比 {r_db:.3f}）",
              f"- H2（C/A2，独立于 STEER）：**{'通过' if H2 else '不通过'}**（时间比 {r_ca:.3f}）",
              f"- H3（D/E，重尾归因）：{'无法归因于 Cauchy（D≈E）' if heavy else 'D 与 E 存在差异，可讨论重尾作用'}", '',
              '## 过程指标（新臂，中位）', '',
              '| 臂 | 门控代数 | 逃逸评价数 | 占预算比 | 首次触发 FE | 进入种群率 | 进入档案率 |', '|---|---:|---:|---:|---:|---:|---:|']
    for _, r in proc.iterrows():
        lines.append(f"| {r.Algorithm} | {r.gate_gens:.0f} | {r.used:.0f} | {r.used_frac:.4f} | {r.first_fe:.0f} | {r.pop_rate:.3f} | {r.arc_rate:.3f} |")
    lines += ['', f"**最终判定：{verdict}**"]
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
