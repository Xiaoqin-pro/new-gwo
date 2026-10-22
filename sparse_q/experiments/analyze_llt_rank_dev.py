#!/usr/bin/env python3
"""Dev-stage gate for the rank-gated LLT variant (pre-registered rule in docs/54)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
SEEDS = list(range(3359, 3369))
ARMS = ['A-FrozenG1E', 'B-LLT-Ring', 'C-LLT-Rank', 'R-LLT-RankRand']
M_GATE, W_GATE, C_GATE = 0.95, 11, 1.20
CTRL_M, CTRL_W = 1.00, 9


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
    p = latest('llt_rank_dev_*')
    df = pd.read_csv(p / 'runs.csv')
    rep = ROOT / 'reports' / 'llt_rank_dev_analysis'
    rep.mkdir(parents=True, exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS, 'function mismatch'
    assert sorted(df.Seed.unique().tolist()) == SEEDS, 'seed mismatch'
    assert set(df.Algorithm.unique()) == set(ARMS), 'arm mismatch'
    assert len(df) == 4 * len(FUNCS) * len(SEEDS) and (df.Status == 'ok').all(), 'dev run incomplete'
    med = df.pivot_table(index='FunctionID', columns='Algorithm', values='FinalError', aggfunc='median').reindex(FUNCS)
    ca = per_func_ratio(df, 'C-LLT-Rank', 'A-FrozenG1E')
    cr = per_func_ratio(df, 'C-LLT-Rank', 'R-LLT-RankRand')
    ba = per_func_ratio(df, 'B-LLT-Ring', 'A-FrozenG1E')
    m, w, c = float(np.median(ca)), int((ca < 1).sum()), float(ca.max())
    gate = bool(m <= M_GATE and w >= W_GATE and c <= C_GATE)
    ctrl_ok = bool(np.median(cr) <= CTRL_M and int((cr < 1).sum()) >= CTRL_W)
    table = pd.DataFrame(dict(FunctionID=FUNCS, rank_vs_frozen=ca, rank_vs_control=cr, ring_vs_frozen=ba)).set_index('FunctionID')
    table.to_csv(rep / 'per_function_ratio.csv')
    summary = dict(results_dir=str(p), runs=len(df), median_rank_vs_frozen=m, wins_rank_vs_frozen=w,
                   max_rank_vs_frozen=c, median_rank_vs_control=float(np.median(cr)),
                   wins_rank_vs_control=int((cr < 1).sum()), control_check_pass=ctrl_ok,
                   median_ring_vs_frozen=float(np.median(ba)), max_ring_vs_frozen=float(ba.max()),
                   gates=dict(median_le=M_GATE, wins_ge=W_GATE, max_le=C_GATE), gate_pass=gate,
                   verdict='PROMOTE_LLT_RANK' if gate else 'STOP_LLT')
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# LLT rank 开发验证（15 函数 x 10 种子）', '', f'- 结果目录：`{p}`', f'- {len(df)} 次运行，0 失败', '',
             '## 预注册选择规则', '',
             f'- m = median_F(rank/frozen) = **{m:.4f}**（要求 ≤{M_GATE}）',
             f'- w = 胜函数数 = **{w}/{len(FUNCS)}**（要求 ≥{W_GATE}）',
             f'- c = max_F(rank/frozen) = **{c:.4f}**（要求 ≤{C_GATE}）',
             f'- 附加检查 rank vs rankrand：中位 {np.median(cr):.4f}（要求 ≤{CTRL_M}），胜 {int((cr<1).sum())}/{len(FUNCS)}（要求 ≥{CTRL_W}）→ '
             f"{'通过' if ctrl_ok else '不通过'}",
             f'- 参考 ring：m={np.median(ba):.4f}，c={ba.max():.4f}', '',
             f"**最终判定：{summary['verdict']}**", '',
             '| F | rank/frozen | rank/rankrand | ring/frozen |', '|---:|---:|---:|---:|']
    for f in FUNCS:
        lines.append(f"| {f} | {table.loc[f,'rank_vs_frozen']:.4f} | {table.loc[f,'rank_vs_control']:.4f} | "
                     f"{table.loc[f,'ring_vs_frozen']:.4f} |")
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote', rep)


if __name__ == '__main__':
    main()
