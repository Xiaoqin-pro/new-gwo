#!/usr/bin/env python3
"""Analyze the RED dev batch (450 runs: audit + two de-duplication doses)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
SEEDS = list(range(3369, 3379))
ARMS = ['A-RED-Audit', 'B-RED-002', 'C-RED-0005']


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def per_func_ratio(df, a, b):
    out = []
    for f in FUNCS:
        x = df[(df.Algorithm == a) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
        y = df[(df.Algorithm == b) & (df.FunctionID == f)].sort_values('Seed').FinalError.to_numpy(float)
        out.append(float(np.median(x / y)))
    return np.array(out)


def main():
    p = latest('red_dev_*')
    df = pd.read_csv(p / 'runs.csv')
    rep = ROOT / 'reports' / 'red_dev_analysis'
    rep.mkdir(parents=True, exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS, 'function mismatch'
    assert sorted(df.Seed.unique().tolist()) == SEEDS, 'seed mismatch'
    assert set(df.Algorithm.unique()) == set(ARMS), 'arm mismatch'
    assert len(df) == 3 * len(FUNCS) * len(SEEDS) and (df.Status == 'ok').all(), 'dev run incomplete'
    assert (df.Evaluations == 100000).all(), 'FE mismatch'
    med = df.pivot_table(index='FunctionID', columns='Algorithm', values='FinalError', aggfunc='median').reindex(FUNCS)
    ba = per_func_ratio(df, 'B-RED-002', 'A-RED-Audit')
    ca = per_func_ratio(df, 'C-RED-0005', 'A-RED-Audit')
    bc = per_func_ratio(df, 'B-RED-002', 'C-RED-0005')
    wins_ba, cat_ba = int((ba < 1).sum()), int((ba > 1.20).sum())
    wins_ca, cat_ca = int((ca < 1).sum()), int((ca > 1.20).sum())
    rt = df.groupby('Algorithm').Seconds.mean().to_dict()
    r_ba = rt['B-RED-002'] / rt['A-RED-Audit']
    H1 = bool(np.median(ba) <= 0.98 and wins_ba >= 11 and cat_ba == 0 and r_ba <= 1.15)
    audit = df[df.Algorithm == 'A-RED-Audit']
    premise_imp = int((audit.RedDupImpRate < audit.RedDistImpRate).sum())
    premise_arc = int((audit.RedDupArcRate < audit.RedDistArcRate).sum())
    proc = df.groupby('Algorithm').agg(dup_rate=('RedSelDupRate', 'median'), rejects=('RedRejects', 'mean'),
                                       draws=('RedDraws', 'mean'), seconds=('Seconds', 'mean'),
                                       dup_imp=('RedDupImpRate', 'median'), dist_imp=('RedDistImpRate', 'median'),
                                       dup_arc=('RedDupArcRate', 'median'), dist_arc=('RedDistArcRate', 'median')).loc[ARMS]
    proc.to_csv(rep / 'process_metrics.csv')
    tbl = pd.DataFrame(dict(FunctionID=FUNCS, BA=ba, CA=ca, BC=bc)).set_index('FunctionID')
    tbl.to_csv(rep / 'per_function_ratio.csv')
    med.to_csv(rep / 'per_function_final_error_median.csv')
    summary = dict(results_dir=str(p), runs=len(df),
                   median_BA=float(np.median(ba)), wins_BA=wins_ba, cat_BA=cat_ba, runtime_BA=float(r_ba),
                   median_CA=float(np.median(ca)), wins_CA=wins_ca, cat_CA=cat_ca,
                   median_BC=float(np.median(bc)), wins_BC=int((bc < 1).sum()),
                   H1_pass=H1,
                   premise_dup_imp_lower=premise_imp, premise_dup_arc_lower=premise_arc, premise_runs=len(audit),
                   dup_rate_audit=float(proc.loc['A-RED-Audit', 'dup_rate']),
                   dup_rate_red002=float(proc.loc['B-RED-002', 'dup_rate']),
                   dup_rate_mild=float(proc.loc['C-RED-0005', 'dup_rate']),
                   verdict='PROMOTE_RED_TO_CONFIRMATION' if H1 else 'STOP_RED')
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# RED dev 结果（15 函数 × 10 种子 × 100k FE）', '', f'- 结果目录：`{p}`', f'- {len(df)} 次运行，0 失败', '',
             '## 前提（audit 臂，逐运行比较，共 %d 次）' % len(audit), '',
             f'- 近邻重复候选"改进参考"比例低于非重复的次数：**{premise_imp}/{len(audit)}**',
             f'- 近邻重复候选"进入档案"比例低于非重复的次数：**{premise_arc}/{len(audit)}**',
             f"- 中位数：重复候选 improve {proc.loc['A-RED-Audit','dup_imp']:.3f} vs 非重复 {proc.loc['A-RED-Audit','dist_imp']:.3f}；"
             f"档案插入 {proc.loc['A-RED-Audit','dup_arc']:.4f} vs {proc.loc['A-RED-Audit','dist_arc']:.4f}",
             '', '## 去重执行情况', '',
             f"- 被选候选的重复率：audit **{proc.loc['A-RED-Audit','dup_rate']:.3f}** → RED@0.02 **{proc.loc['B-RED-002','dup_rate']:.3f}** → RED@0.005 **{proc.loc['C-RED-0005','dup_rate']:.3f}**",
             f"- 平均拒绝次数/run：RED@0.02 {proc.loc['B-RED-002','rejects']:.0f}，RED@0.005 {proc.loc['C-RED-0005','rejects']:.0f}",
             '', '## 门槛', '',
             f"- H1 B/A：中位比 {np.median(ba):.4f}，胜/负 {wins_ba}/{len(FUNCS)-wins_ba}，>1.20 {cat_ba}，时间比 {r_ba:.4f} → **{'通过' if H1 else '不通过'}**",
             f"- 对照 C/A（轻剂型）：中位比 {np.median(ca):.4f}，胜 {wins_ca}/{len(FUNCS)}，>1.20 {cat_ca}",
             f"- 剂型对比 B/C：中位比 {np.median(bc):.4f}，胜 {int((bc<1).sum())}/{len(FUNCS)}",
             '', f"**最终判定：{summary['verdict']}**", '',
             '| F | audit | RED-0.02 | RED-0.005 | B/A | C/A | B/C |', '|---:|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        i = FUNCS.index(f)
        lines.append(f"| {f} | {med.loc[f,'A-RED-Audit']:.6g} | {med.loc[f,'B-RED-002']:.6g} | {med.loc[f,'C-RED-0005']:.6g} | "
                     f"{ba[i]:.4f} | {ca[i]:.4f} | {bc[i]:.4f} |")
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote', rep)


if __name__ == '__main__':
    main()
