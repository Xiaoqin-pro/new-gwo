#!/usr/bin/env python3
"""Dev-stage gate for the alpha-anchored LLT variant (pre-registered rule in docs/53)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 13, 14, 30]
SEEDS = list(range(3354, 3359))
ARMS = ['A-FrozenG1E', 'B-LLT-Ring', 'D-LLT-Anchor', 'C-LLT-AnchorRand']
M_GATE, C_GATE = 0.90, 1.20


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
    p = latest('llt_anchor_dev_*')
    df = pd.read_csv(p / 'runs.csv')
    rep = ROOT / 'reports' / 'llt_anchor_dev_analysis'
    rep.mkdir(parents=True, exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS, 'function mismatch'
    assert sorted(df.Seed.unique().tolist()) == SEEDS, 'seed mismatch'
    assert set(df.Algorithm.unique()) == set(ARMS), 'arm mismatch'
    assert len(df) == 4 * len(FUNCS) * len(SEEDS) and (df.Status == 'ok').all(), 'dev run incomplete'
    med = df.pivot_table(index='FunctionID', columns='Algorithm', values='FinalError', aggfunc='median').reindex(FUNCS)
    da = per_func_ratio(df, 'D-LLT-Anchor', 'A-FrozenG1E')
    dc = per_func_ratio(df, 'D-LLT-Anchor', 'C-LLT-AnchorRand')
    ba = per_func_ratio(df, 'B-LLT-Ring', 'A-FrozenG1E')
    m, c = float(np.median(da)), float(da.max())
    gate = bool(m <= M_GATE and c <= C_GATE)
    table = pd.DataFrame(dict(FunctionID=FUNCS, anchor_vs_frozen=da, anchor_vs_anchorrand=dc,
                              ring_vs_frozen=ba)).set_index('FunctionID')
    table.to_csv(rep / 'per_function_ratio.csv')
    summary = dict(results_dir=str(p), runs=len(df), median_anchor_vs_frozen=m, max_anchor_vs_frozen=c,
                   median_anchor_vs_control=float(np.median(dc)),
                   winners_anchor_vs_control=int((dc < 1).sum()),
                   median_ring_vs_frozen=float(np.median(ba)), max_ring_vs_frozen=float(ba.max()),
                   gates=dict(median_le=M_GATE, max_le=C_GATE), gate_pass=gate,
                   verdict='PROMOTE_LLT_ANCHOR' if gate else 'STOP_LLT')
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# LLT anchor 开发验证（8 函数 x 5 种子）', '', f'- 结果目录：`{p}`', f'- {len(df)} 次运行，0 失败', '',
             '## 预注册选择规则', '',
             f'- m = median_F(median_seed(anchor/frozen)) = **{m:.4f}**（要求 ≤{M_GATE}）',
             f'- c = max_F(median_seed(anchor/frozen)) = **{c:.4f}**（要求 ≤{C_GATE}）',
             f'- 参考：ring 版本 m={np.median(ba):.4f}，c={ba.max():.4f}',
             f"- anchor vs anchorrand：中位 {np.median(dc):.4f}，胜 {int((dc<1).sum())}/{len(FUNCS)}", '',
             f"**最终判定：{summary['verdict']}**", '',
             '| F | anchor/frozen | anchor/anchorrand | ring/frozen |', '|---:|---:|---:|---:|']
    for f in FUNCS:
        lines.append(f"| {f} | {table.loc[f,'anchor_vs_frozen']:.4f} | {table.loc[f,'anchor_vs_anchorrand']:.4f} | "
                     f"{table.loc[f,'ring_vs_frozen']:.4f} |")
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote', rep)


if __name__ == '__main__':
    main()
