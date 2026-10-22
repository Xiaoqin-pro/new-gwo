#!/usr/bin/env python3
"""Analyze the confirmation-grade STEER batch (3 new arms x 29 funcs x 30 seeds + reused A2/A0)."""
from __future__ import annotations
import json, os
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon
from scipy.io import loadmat
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1] + list(range(3, 31))
SEEDS = list(range(3071, 3101))
BASE_DIR = ROOT / 'sparse_q' / 'results' / 'ablcore_20261017_062209'
NEW_ARMS = ['B-Steer-Rand', 'C-Steer-Dir', 'D-Steer-NoE']
CHECKPOINTS = [0.10, 0.20, 0.50, 0.80, 1.00]


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
    """Build a runs-like frame from the per-run .mat files (used before collect_sq writes runs.csv)."""
    rows = []
    for f in sorted((dirp / 'runs').glob('run_*.mat')):
        try:
            r = loadmat(f, struct_as_record=False, squeeze_me=True)['record']
            res = r.result
            rows.append(dict(RunID=float(r.id), Algorithm=str(res.Algorithm), FunctionID=float(res.FunctionID),
                             Seed=float(res.Seed), Status=str(r.status), FinalError=float(res.BestCost) - 100.0*float(res.FunctionID),
                             Evaluations=float(res.Evaluations), Seconds=float(res.Seconds)))
        except Exception:
            continue
    return pd.DataFrame(rows)


def load_run(df, arm, f):
    x = df[(df.Algorithm == arm) & (df.FunctionID == f)].sort_values('Seed')
    return x.FinalError.to_numpy(float), x.Seed.to_numpy(int)


def aligned_pair(df_a, arm_a, df_b, arm_b, f):
    """Return per-seed errors for the two arms on their common seeds."""
    a = df_a[(df_a.Algorithm == arm_a) & (df_a.FunctionID == f)].set_index('Seed').FinalError
    b = df_b[(df_b.Algorithm == arm_b) & (df_b.FunctionID == f)].set_index('Seed').FinalError
    common = sorted(set(a.index) & set(b.index))
    if len(common) < 10:
        return None, None
    return a.loc[common].to_numpy(float), b.loc[common].to_numpy(float)


def ratio_stats(x, y):
    r = x / y
    return float(np.median(r)), int((r < 1).sum()), int((r > 1.20).sum())


def trace_ratio(new_dir, new_df, new_arm, base_df, base_arm, f):
    """median trace ratio (new/old) at FE checkpoints, interpolated from run records."""
    def series(dirp, df, arm):
        vals = []
        for _, row in df[(df.Algorithm == arm) & (df.FunctionID == f)].iterrows():
            mat = dirp / 'runs' / f"run_{int(row.RunID):05d}.mat"
            if not mat.exists():
                continue
            res = loadmat(mat, struct_as_record=False, squeeze_me=True)['record'].result
            fe = np.asarray(res.TraceFE, float).ravel(); T = np.asarray(res.Trace, float).ravel()
            vals.append(np.interp(np.array(CHECKPOINTS) * 100000, fe, T))
        return np.median(np.array(vals), axis=0) if vals else None
    a = series(new_dir, new_df, new_arm); b = series(BASE_DIR, base_df, base_arm)
    if a is None or b is None:
        return None
    return (a / b).tolist()


if __name__ == '__main__':
    p = latest('steer_confirm2_*')
    csv_p = p / 'runs.csv'
    new_df = pd.read_csv(csv_p) if csv_p.exists() else load_partial(p)
    new_df_cache = new_df
    base_df = pd.read_csv(BASE_DIR / 'runs.csv')
    rep = ROOT / 'reports' / 'steer_confirm2_analysis'
    rep.mkdir(parents=True, exist_ok=True)
    if not (os.environ.get('STEER_PARTIAL') == '1'):
        assert sorted(new_df.FunctionID.unique().tolist()) == FUNCS, 'function mismatch'
    assert sorted(new_df.Seed.unique().tolist()) == SEEDS, 'seed mismatch'
    assert set(new_df.Algorithm.unique()) == set(NEW_ARMS), 'arm mismatch'
    import os
    partial = os.environ.get('STEER_PARTIAL') == '1'
    if not partial:
        assert len(new_df) == 3 * len(FUNCS) * len(SEEDS) and (new_df.Status == 'ok').all(), 'batch incomplete'
    else:
        new_df = new_df.copy()
        keep = sorted(new_df.groupby(['FunctionID']).size().index)[:]
        funcs_num = sorted(new_df.FunctionID.unique().tolist())
        new_df = new_df[new_df.FunctionID.isin(funcs_num)]
        FUNCS_USE = funcs_num
        print('[dry-run] partial batch:', len(new_df), 'runs,', len(funcs_num), 'functions')
    assert (new_df.Evaluations == 100000).all(), 'FE mismatch'
    pairs = [(a, b, lab) for a, b, lab in [
        ('B-Steer-Rand', 'A2-G1E', 'B/A2'), ('C-Steer-Dir', 'A2-G1E', 'C/A2'),
        ('C-Steer-Dir', 'B-Steer-Rand', 'C/B'), ('D-Steer-NoE', 'A0-GWOonly', 'D/A0'),
        ('B-Steer-Rand', 'D-Steer-NoE', 'B/D')]]
    summary = dict(results_dir=str(p), new_runs=len(new_df), functions=FUNCS, seeds=SEEDS)
    ratio_tbl = {}
    tests = []
    for a, b, lab in pairs:
        rr = []
        for f in FUNCS:
            x, y = aligned_pair(new_df, a, base_df, b, f) if a in NEW_ARMS and b not in NEW_ARMS else \
                aligned_pair(base_df, a, new_df, b, f) if a not in NEW_ARMS and b in NEW_ARMS else \
                aligned_pair(new_df, a, new_df, b, f) if a in NEW_ARMS and b in NEW_ARMS else \
                aligned_pair(base_df, a, base_df, b, f)
            if x is None:
                continue
            med, w, cat = ratio_stats(x, y)
            rr.append(med)
            try:
                pv = wilcoxon(x, y, alternative='two-sided', zero_method='wilcox', method='auto').pvalue
            except ValueError:
                pv = np.nan
            tests.append(dict(comparison=lab, FunctionID=f, median_ratio=med, wins=w, losses=int((x/y > 1).sum()),
                              p_raw=float(pv) if np.isfinite(pv) else np.nan))
        rr = np.array(rr); ratio_tbl[lab] = rr
        summary[f'median_{lab}'] = float(np.median(rr))
        summary[f'wins_{lab}'] = int((rr < 1).sum())
        summary[f'cats_{lab}'] = int((rr > 1.20).sum())
    for lab in {t['comparison'] for t in tests}:
        rows_lab = [t for t in tests if t['comparison'] == lab]
        q = holm([t['p_raw'] for t in rows_lab])
        for t, v in zip(rows_lab, q):
            t['p_holm'] = float(v) if np.isfinite(v) else np.nan
    tdf = pd.DataFrame(tests)
    tdf.to_csv(rep / 'pairwise_wilcoxon_holm.csv', index=False)
    rt_new = new_df.groupby('Algorithm').Seconds.mean().to_dict()
    rt_base = base_df.groupby('Algorithm').Seconds.mean().to_dict()
    r_B = rt_new['B-Steer-Rand'] / rt_base['A2-G1E']
    r_C = rt_new['C-Steer-Dir'] / rt_base['A2-G1E']
    r_D = rt_new['D-Steer-NoE'] / rt_base['A0-GWOonly']
    summary.update(runtime_BA2=float(r_B), runtime_CA2=float(r_C), runtime_DA0=float(r_D))
    H1 = bool(summary['median_B/A2'] <= 0.98 and summary['wins_B/A2'] >= 18 and summary['cats_B/A2'] == 0)
    H2 = bool(summary['median_C/A2'] <= 0.98 and summary['wins_C/A2'] >= 18 and summary['cats_C/A2'] == 0)
    summary.update(H1_pass=H1, H2_pass=H2,
                   verdict='PROMOTE_STEER_RAND' if H1 else ('PROMOTE_STEER_DIR' if H2 else 'STOP_STEER'))
    # early-FE checkpoint profile (median trace ratio vs A2)
    prof = {}
    for arm in NEW_ARMS:
        rows = []
        for f in FUNCS:
            tr = trace_ratio(p, new_df, arm, base_df, 'A2-G1E' if arm != 'D-Steer-NoE' else 'A0-GWOonly', f)
            if tr is not None:
                rows.append(tr)
        if rows:
            prof[arm] = np.median(np.array(rows), axis=0).round(4).tolist()
    summary['trace_ratio_profile'] = prof
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    med_all = new_df.pivot_table(index='FunctionID', columns='Algorithm', values='FinalError', aggfunc='median')
    base_med = base_df.pivot_table(index='FunctionID', columns='Algorithm', values='FinalError', aggfunc='median')
    for c in ['A2-G1E', 'A0-GWOonly']:
        med_all[c] = base_med[c]
    med_all.reindex(FUNCS).to_csv(rep / 'per_function_final_error_median.csv')
    lines = ['# STEER 确认级复评（29 函数 × 30 种子 × 100k FE）', '', f'- 结果目录：`{p}`', f'- 新跑 {len(new_df)} 次，0 失败；A2/A0 复用 `ablcore_20261017_062209`', '',
             '## 主门槛（相对 A2：冻结 G1+E）', '',
             f"- B（随机方向扰动）：中位比 {summary['median_B/A2']:.4f}，胜 {summary['wins_B/A2']}/29，>1.20 {summary['cats_B/A2']} → **{'通过' if H1 else '不通过'}**",
             f"- C（成功方向扰动）：中位比 {summary['median_C/A2']:.4f}，胜 {summary['wins_C/A2']}/29，>1.20 {summary['cats_C/A2']} → **{'通过' if H2 else '不通过'}**", '',
             '## 报告项', '',
             f"- 方向归因 C/B：中位比 {summary['median_C/B']:.4f}，胜 {summary['wins_C/B']}/29",
             f"- E 关臂 D/A0：中位比 {summary['median_D/A0']:.4f}，胜 {summary['wins_D/A0']}/29，>1.20 {summary['cats_D/A0']}",
             f"- 运行时间比：B/A2 {r_B:.3f}，C/A2 {r_C:.3f}，D/A0 {r_D:.3f}",
             f"- 早期轨迹（中位 trace 比 vs A2/A0）：" + '；'.join(f"{k} " + str(v) for k, v in prof.items()),
             '', f"**最终判定：{summary['verdict']}**"]
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote', rep)
