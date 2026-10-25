# 最终算法消融预注册（2026-10-24）

## 前置
- DiffA-Slot 机制 29×30 确认通过（any-anchor 0.9037、22/29、1 cat、p=0.0007、Holm 显著更好 5）。
- 参数敏感性（screen277）确定最优结构：g2Mode=diffa, g2F=1.0（或 F 衰减方案，视 fdecay 结果）, nG2=12, nE=38, g2Pool=pool, g2Anchor=best/any。
- 目标：Holm 显著更好 ≥10（12 更好），允许 2-3 个显著更差。

## 消融设计（证明每个部件必要）

最终算法 = G1（标准 GWO 领导聚合）+ STEER（等长方向扰动）+ E（已验证多区域档案）+ DiffA（toward-alpha 差分槽位，池=狼群∪E）。

| 臂 | G1 | E | STEER | DiffA-G2 | 说明 |
|---|---|---|---|---|---|
| A-Final | ✓ | ✓ | ✓ | ✓ | 完整算法 |
| B-NoDiff | ✓ | ✓ | ✓ | ✗(shell α壳) | 去掉差分（DiffA 必要性） |
| C-NoE | ✓ | ✗(标准填补) | ✓ | ✓ | 去掉 E（E 必要性） |
| D-NoSteer | ✓ | ✓ | ✗ | ✓ | 去掉 STEER（STEER 必要性） |
| E-NoESteer | ✓ | ✗ | ✗ | ✓ | 只剩 G1+DiffA |
| F-GWOonly | ✓ | ✗ | ✗ | ✗ | 原始 GWO（基线） |

判定：
- B/A：若 A 优于 B（中位比 ≤0.95）→ DiffA 槽位是正贡献。
- C/A：若 A 优于 C → E 档位是正贡献。
- D/A：若 A 优于 D → STEER 是正贡献。
- F→A 全链：展示每个部件的增量增益。

## 实验协议
- CEC2017 D=50, 100k FE, 复用种子 3459–3488（与 steer_robust A 臂配对，A/B/D/E/F 的 A 复用或重跑）。
- 每臂 29 函数 × 30 种子。
- 先 P0/P1 快速确认信号，再全量确认。

## 预期论文表
- 消融表：每行一个部件 on/off 的 29×30 中位比、胜/负、Holm 显著计数。
- 结论：E 和 DiffA 都是必要部件，各自提供独立增益。
