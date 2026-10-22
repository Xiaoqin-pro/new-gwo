#!/usr/bin/env python3
"""Analyze the STJ confirmation batch (STJ arm only; A2 and always-on STEER reused)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon, binomtest
from scipy.io import loadmat
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1] + list(range(3, 31))
SEEDS = list(range(3071, 3101))
CHK = [0.10, 0.20, 0.50, 0.80, 1.00]
RNG = np.random.default_rng(20261023)


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def holm(p):
    p = np.asarray(p, float); out = np.full_like(p, np.nan)
    idx = np.where(np.isfinite(p))[0]
    if not len(idx):
        return out
    order = idx[np.argsort(p[idx])]; prev = 0.0
    for rank, i in enumerate(order):
        v = min(1.0, (len(order) - rank) * p[i]); v = max(v, prev); out[i] = v; prev = v
    return out


def load_partial(dirp):
    rows = []
    for f in sorted((dirp / 'runs').glob('run_*.mat')):
        try:
            r = loadmat(f, struct_as_record=False, squeeze_me=True)['record']
            res = r.result
            rows.append(dict(RunID=float(r.id), Algorithm=str(res.Algorithm), FunctionID=float(res.FunctionID),
                             Seed=float(res.Seed), Status=str(r.status), FinalError=float(res.BestCost) - 100.0 * float(res.FunctionID),
                             Evaluations=float(res.Evaluations), Seconds=float(res.Seconds)))
        except Exception:
            continue
    return pd.DataFrame(rows)


def trace(dirp, rid):
    m = loadmat(dirp / 'runs' / f"run_{rid:05d}.mat", struct_as_record=False, squeeze_me=True)['record'].result
    return np.asarray(m.TraceFE, float).ravel(), np.asarray(m.Trace, float).ravel()


def main():
    p = latest('stj_confirm_*')
    csv_p = p / 'runs.csv'
    stj = pd.read_csv(csv_p) if csv_p.exists() else load_partial(p)
    a2 = pd.read_csv(ROOT / 'sparse_q' / 'results' / 'ablcore_20261017_062209' / 'runs.csv')
    steer_dir = ROOT / 'sparse_q' / 'results' / 'steer_confirm2_20261022_063141'
    steer = pd.read_csv(steer_dir / 'runs.csv')
    rep = ROOT / 'reports' / 'stj_confirm_analysis'
    rep.mkdir(parents=True, exist_ok=True)
    import os
    if os.environ.get('STJ_PARTIAL') != '1':
        assert sorted(stj.FunctionID.unique().tolist()) == FUNCS and sorted(stj.Seed.unique().tolist()) == SEEDS
        assert (stj.Status == 'ok').all() and (stj.Evaluations == 100000).all()
    def aligned(df_a, a, df_b, b, f):
        xa = df_a[(df_a.Algorithm == a) & (df_a.FunctionID == f)].set_index('Seed').FinalError
        yb = df_b[(df_b.Algorithm == b) & (df_b.FunctionID == f)].set_index('Seed').FinalError
        common = sorted(set(xa.index) & set(yb.index))
        if len(common) == 0:
            return None, None
        return xa.loc[common].to_numpy(float), yb.loc[common].to_numpy(float)
    def paired(df_a, a, df_b, b):
        xs, ys = [], []
        for f in FUNCS:
            x, y = aligned(df_a, a, df_b, b, f)
            if x is None: continue
            xs.append(float(np.median(x))); ys.append(float(np.median(y)))
        return np.array(xs), np.array(ys)
    out = {}
    tests = []
    for (df_a, a, df_b, b, lab) in [(stj, 'C-STJ', a2, 'A2-G1E', 'C/A2'),
                                    (stj, 'C-STJ', steer, 'B-Steer-Rand', 'C/B'),
                                    (steer, 'B-Steer-Rand', a2, 'A2-G1E', 'B/A2')]:
        x, y = paired(df_a, a, df_b, b)
        lr = np.log(np.maximum(x, 1e-12)) - np.log(np.maximum(y, 1e-12))
        pv = wilcoxon(lr).pvalue if len(lr) > 5 else np.nan
        wins, losses = int((x < y).sum()), int((x > y).sum())
        sg = binomtest(wins, wins + losses, 0.5).pvalue if wins + losses > 0 else np.nan
        boot = np.array([np.median(RNG.choice(lr, size=lr.size, replace=True)) for _ in range(2000)])
        out[lab] = dict(median_ratio_of_medians=float(np.median(x / y)), wins=wins, losses=losses,
                        wilcoxon_p=float(pv), sign_p=float(sg), med_log=float(np.median(lr)),
                        ci_lo=float(np.percentile(boot, 2.5)), ci_hi=float(np.percentile(boot, 97.5)))
        per = []
        for f in FUNCS:
            xr, yr = aligned(df_a, a, df_b, b, f)
            if xr is None or len(xr) < 5:
                continue
            try:
                pr = wilcoxon(xr, yr, alternative='two-sided').pvalue
            except ValueError:
                pr = np.nan
            per.append(dict(comparison=lab, FunctionID=f, median_ratio=float(np.median(xr / yr)), p_raw=float(pr)))
        q = holm([r['p_raw'] for r in per])
        for r, v in zip(per, q):
            r['p_holm'] = float(v) if np.isfinite(v) else np.nan
        tests += per
        out[lab]['n_holm_sig'] = int(sum(1 for r in per if np.isfinite(r['p_holm']) and r['p_holm'] < 0.05))
    pd.DataFrame(tests).to_csv(rep / 'pairwise_wilcoxon_holm.csv', index=False)
    rt = {k: float(v) for k, v in stj.groupby('Algorithm').Seconds.mean().items()}
    r_ca = rt['C-STJ'] / float(a2[a2.Algorithm == 'A2-G1E'].Seconds.mean())
    r_cb = rt['C-STJ'] / float(steer[steer.Algorithm == 'B-Steer-Rand'].Seconds.mean())
    def per_func_ratio(df_a, a, df_b, b):
        out_r = {}
        for f in FUNCS:
            xr, yr = aligned(df_a, a, df_b, b, f)
            if xr is not None and len(xr) >= 5:
                out_r[f] = float(np.median(xr / yr))
        return out_r
    ca = per_func_ratio(stj, 'C-STJ', a2, 'A2-G1E')
    cb = per_func_ratio(stj, 'C-STJ', steer, 'B-Steer-Rand')
    cat_ca = sum(1 for v in ca.values() if v > 1.20)
    H1 = bool(np.median(list(ca.values())) <= 0.98 and sum(1 for v in ca.values() if v < 1) >= 18 and cat_ca == 0 and r_ca <= 1.10)
    H2 = bool(np.median(list(cb.values())) <= 1.00 and np.exp(out['C/B']['ci_hi']) <= 1.05)
    if H1 and H2:
        verdict = 'PROMOTE_STJ'
    elif not H1:
        verdict = 'KEEP_STEER (STJ fails H1)'
    else:
        verdict = 'KEEP_STEER (STJ worse than always-on STEER beyond margin)'
    # checkpoint profile STJ vs STEER (same cells, traces available for both)
    prof = []
    for f in FUNCS:
        for s in SEEDS:
            rs = stj[(stj.Algorithm == 'C-STJ') & (stj.FunctionID == f) & (stj.Seed == s)]
            rb = steer[(steer.Algorithm == 'B-Steer-Rand') & (steer.FunctionID == f) & (steer.Seed == s)]
            if not len(rs) or not len(rb):
                continue
            fe_s, T_s = trace(p, int(rs.RunID.iloc[0])); fe_b, T_b = trace(steer_dir, int(rb.RunID.iloc[0]))
            grid = np.array(CHK) * 100000
            prof.append(np.interp(grid, fe_s, T_s) / np.interp(grid, fe_b, T_b))
    prof = np.array(prof)
    # 门控开启率：由 STJ 臂自身的 trace 重算（= 机制内部使用的 (FE-lastGB)>=tau 判据）
    gate_rates = []
    for _, r in stj.iterrows():
        fe, T = trace(p, int(r.RunID))
        last = np.zeros_like(T); cur = fe[0]; best = T[0]
        for k in range(len(T)):
            if T[k] < best:
                best = T[k]; cur = fe[k]
            last[k] = cur
        gate_rates.append(float(np.mean((fe - last) >= 2000)))
    gate_rates = np.array(gate_rates)
    summary = dict(results_dir=str(p), runs=len(stj), comparisons=out, cats_CA2=cat_ca, runtime_CA2=float(r_ca), runtime_CB=float(r_cb),
                   H1_pass=H1, H2_pass=H2, verdict=verdict,
                   checkpoint_median_STJ_over_STEER={str(k): float(v) for k, v in zip(CHK, np.median(prof, axis=0))} if len(prof) else {},
                   stj_gate_rate_median=float(np.median(gate_rates)), stj_gate_rate_mean=float(np.mean(gate_rates)))
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# STJ 确认级结果（29 函数 × 30 种子 × 100k FE）', '', f'- 结果目录：`{p}`', f'- 新跑 STJ {len(stj)} 次；A2 与始终启用 STEER 复用', '',
             '## 主门槛', '',
             f"- H1 C/A2：中位比（中位误差比）{out['C/A2']['median_ratio_of_medians']:.4f}，胜 {out['C/A2']['wins']}/29，"
             f">1.20 = {cat_ca}，时间比 {r_ca:.3f} → {'通过' if H1 else '不通过'}",
             f"- H2 C/B：中位比 {out['C/B']['median_ratio_of_medians']:.4f}，CI 上界 {np.exp(out['C/B']['ci_hi']):.4f}（要求 ≤1.05），"
             f"胜 {out['C/B']['wins']}/29 → {'通过' if H2 else '不通过'}", '',
             '## 比较级统计', '',
             '| 比较 | 中位比 | 胜-负 | Wilcoxon p | 符号检验 p | 中位 log 比 [95% CI] | Holm 显著函数 |',
             '|---|---:|---:|---:|---:|---|---:|']
    for lab in ['C/A2', 'C/B', 'B/A2']:
        o = out[lab]
        lines.append(f"| {lab} | {o['median_ratio_of_medians']:.4f} | {o['wins']}-{o['losses']} | {o['wilcoxon_p']:.4f} | "
                     f"{o['sign_p']:.4f} | {o['med_log']:.4f} [{o['ci_lo']:.4f}, {o['ci_hi']:.4f}] | {o['n_holm_sig']} |")
    lines += ['', '## 过程与轨迹', '',
              f"- STJ 门控开启率（中位，占代数）：**{summary['stj_gate_rate_median']:.3f}**（P0 预期 ~0.16–0.23）",
              f"- （扰动次数未写入本批 counters，合约测试中 20k 冒烟为 26,490 次；门控率已由轨迹重算）",
              f"- 检查点中位轨迹比 STJ/STEER：10% {summary['checkpoint_median_STJ_over_STEER'].get('0.1', np.nan):.3f}、"
              f"20% {summary['checkpoint_median_STJ_over_STEER'].get('0.2', np.nan):.3f}、"
              f"50% {summary['checkpoint_median_STJ_over_STEER'].get('0.5', np.nan):.3f}、"
              f"80% {summary['checkpoint_median_STJ_over_STEER'].get('0.8', np.nan):.3f}、"
              f"100% {summary['checkpoint_median_STJ_over_STEER'].get('1.0', np.nan):.3f}",
              '', f"**最终判定：{verdict}**"]
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
