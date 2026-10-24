# 最终结构确认：diffa F=1.0 pool any（多次 29×30 对比后仍最优）

## 五次 29×30 确认对比（vs A-Final-SteerOn, seeds 3459-3488 配对）

| 配置 | med | wins/29 | cats | p | Holm better/worse |
|---|---:|---:|---:|---:|---:|
| **diffa F=1.0 any pool** | **0.9037** | **22** | **1** | **0.0007** | **5 / 1** |
| diffa F=1.0 best pool | 0.9708 | 17 | 2 | 0.056 | 6 / 0 |
| diffa F-decay 1→0.3 any | 0.9638 | 17 | 3 | 0.048 | 4 / 0 |
| diffa mix 6shell+6diff | 0.9890 | 17 | 2 | 0.169 | 4 / 0 |
| diffa F=0.75 any | 0.9912 | 16 | 1 | 0.156 | 5 / 0 |

**diffa F=1.0 any pool 仍是唯一同时满足 med<0.95、wins≥20、cats≤2、p<0.001 的配置。**

## 消融（final_ablation_p0）
- NoDiff: 1.127、2/15、p=0.001 → 差分必要
- NoE: 1.268、3/15、p=0.003 → E 必要
- NoSteer: 1.105、7/15 → STEER 温和
- A/GWOonly: 0.588、15/15、p=0.000 → 框架必要

## Holm 目标现状
- 当前 29×30: Holm 显著更好 5（F30/F18/F3/F7/F14），显著更差 1（F1 1.28×）。
- 目标 ≥10-12：F1 退化修复 + 边缘函数（F19/F29/F16 raw p 0.016-0.043）效应量增强。
- 尝试过：F-decay（F1 仍 1.31）、mix（丢收益）、anchor-best（未复现）、F=0.75（0.991）、g2DiffScale（0.75 略强）。
- 下一步候选：late-stage F 收缩（前 70% F=1.0 保强度，后 30% F→0.5 修单峰）。
