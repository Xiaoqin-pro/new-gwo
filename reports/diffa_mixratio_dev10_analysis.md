# DiffA 混合比扫描结论（15 函数 × 10 种子 4414–4423，100k FE）
- 结果：`sparse_q/results/diffa_mixratio_dev10_20261024_151929`（900 次，0 失败）

## 结论

| 臂 | 配置 | vs F-DiffA-F10 (med) | wins/15 | F1 |
|---|---:|---:|---:|---:|
| F | 全差分 F=1.0（无衰减） | **基准** | — | — |
| B | shell0/diff12 Fdecay | 0.996 | 8 | 1.06 |
| C | shell3/diff9 Fdecay | 0.998 | 8 | 0.80 |
| A | shell6/diff6 Fdecay | 1.058 | 5 | 0.67 |
| D | shell9/diff3 Fdecay | 1.135 | 4 | 0.82 |
| E | shell12/diff0 Fdecay | 1.101 | 4 | 1.08 |

**没有任何 shell/diff 混合超过全差分 F=1.0**：shell 稀释差分收益（S9D3/S12D0 显著更差），F-decay 也不如固定 F=1.0。**最终结构 = `g2Mode='diffa', g2F=1.0, g2Pool='pool', g2Anchor='any', nG2=12, nE=38`**（= 29×30 冠军 0.9037、22/29、p=0.0007）。

## 剩余问题
- F1（单峰）退化 1.28× 是唯一稳定弱点，也是 Holm 数（当前 5）到 10-12 的唯一障碍。
- 下一步：F1 定向修复（差分幅度/截断对 F1 单峰的影响），保持其它函数不变。
