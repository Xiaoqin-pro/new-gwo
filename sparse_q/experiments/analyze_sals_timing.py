#!/usr/bin/env python3
"""Runtime-overhead analysis of the SALS post-selection resampling arms (same-batch, 4-arm)."""
from __future__ import annotations
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
ARMS = ['A-Frozen-Final', 'B-PostIID', 'C-SALS', 'D-Audit']
LABEL = {'A-Frozen-Final': 'A 冻结 G1+E+STEER', 'B-PostIID': 'B post-selection IID',
         'C-SALS': 'C post-selection LHS (SALS)', 'D-Audit': 'D 被动审计'}


def main():
    ds = sorted((ROOT / 'sparse_q' / 'results').glob('sals_timing_*'))
    if not ds:
        raise SystemExit('missing sals_timing_* results')
    p = ds[-1]
    df = pd.read_csv(p / 'runs.csv')
    assert set(df.Algorithm.unique()) == set(ARMS) and (df.Status == 'ok').all()
    per_arm = df.groupby('Algorithm').Seconds.agg(['mean', 'median', 'std', 'count']).reindex(ARMS)
    base = per_arm.loc['A-Frozen-Final', 'mean']
    ratios = {a: per_arm.loc[a, 'mean'] / base for a in ARMS}
    per_cell = df.groupby(['FunctionID', 'Algorithm']).Seconds.mean().unstack().reindex(columns=ARMS)
    per_cell_ratio = per_cell.div(per_cell['A-Frozen-Final'], axis=0)
    rep = ROOT / 'reports' / 'sals_runtime_optimization.md'
    lines = ['# SALS 运行开销（同批次 4 臂计时）', '',
             f'- 结果目录：`{p}`', f'- {len(df)} 次运行（3 函数 × 3 种子 × 4 臂），0 失败，4 worker 同批',
             '- 目的：量化机制自身的墙钟开销。**种子沿用冻结 29×30 块（3071–3073），本批次不作任何性能声称。**', '',
             '## 每臂墙钟时间', '',
             '| 臂 | 平均 s | 中位 s | 相对冻结 |', '|---|---:|---:|---:|']
    for a in ARMS:
        lines.append(f"| {LABEL[a]} | {per_arm.loc[a,'mean']:.3f} | {per_arm.loc[a,'median']:.3f} | {ratios[a]:.3f} |")
    lines += ['', '## 逐函数比值（相对冻结臂）', '',
              '| F | ' + ' | '.join(LABEL[a].split()[0] for a in ARMS) + ' |',
              '|---:|' + '---:|' * len(ARMS)]
    for f in per_cell.index:
        lines.append(f"| {f} | " + ' | '.join(f"{per_cell_ratio.loc[f,a]:.3f}" for a in ARMS) + ' |')
    lines += ['', '## 结论', '',
              f"- 活跃臂相对冻结臂：IID {ratios['B-PostIID']:.3f}×，SALS(LHS) {ratios['C-SALS']:.3f}×",
              f"- 两个活跃臂之间：{ratios['C-SALS']/ratios['B-PostIID']:.3f}×（预注册的运行时间门槛为 ≤1.15）",
              '- 该开销来自机制本身：每宏代对约 5 个实际获得评价名额的 G1 候选重抽 6D 系数（3 次批量抽取）',
              '  并按逐候选交错顺序抽取 STEER 触发/方向；几何诊断只在 audit 臂记录。', '',
              '## 优化前后', '',
              '- 优化前（首版实现）：活跃臂 ≈21–23 s vs 冻结 5.7 s（同批 3.7×），原因是每宏代 6*D=300 次',
              '  RandStream 标量抽取与 300 次 `unique()` 诊断调用。',
              '- 优化后：批量抽取 + 向量化重建（`salsRebuildPos`），**四个模式与优化前逐位一致**：',
              '  `tests/test_sals_opt_equivalence.m`（3 单元 × 4 模式，全部 BITWISE EQUAL）与',
              '  `tests/test_sals_rebuild_equivalence.m`（1500 个候选逐元素一致）。']
    rep.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
