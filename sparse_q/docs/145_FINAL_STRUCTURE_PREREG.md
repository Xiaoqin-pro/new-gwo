# 最终算法结构（参数敏感性收敛，2026-10-24）

## 最终结构

```
GWO 差分-档案框架（Diff-Archive GWO, 暂名 DAGWO）：
  G1: 50 只狼，标准 α/β/δ 领导聚合 + STEER（perwolf 随机方向，succSteer=0.5, lambda=0.5）
  G2: 12 个 toward-alpha 差分槽位（src=2，仅击败最差狼才替换）
      y = x_r1 + F·(α − x_r1) + F·(x_r2 − x_r3),  F=1.0（g2F=1.0, g2DiffScale=1.0）
      r1,r2,r3 从「狼群 ∪ E 已验证档案」独立抽取（g2Pool=pool, g2Anchor=any）
  E: 38 个已验证档案槽位（中心壳 + 双中心线段）
  评价: K=10, M=100，真实 FE 计费（不变）
```

## 参数敏感性证据（全部 15 函数 × 10 新种子 dev + 29×30 确认）

| 维度 | 扫描 | 最优 | 证据 |
|---|---|---|---|
| g2F | 0.75/1.0/1.25 | 1.0 | F=1.0 29×30 0.9037/22 胜/p=0.0007 |
| g2Fend | inf/0.3 | inf | Fdecay confirm30 0.964 更差 |
| g2DiffScale | 0/0.3/0.5/0.75/1.0 | 1.0 | Scale10 11/15 p=0.015，Scale00 崩 |
| nG2/nE | 6/12/18/24 | 12/38 | 任何 mix 不超全差分 |
| g2Pool | pool/wolves/archive | pool | pool 0.776/12 胜/0 cat；archive 有尾部 |
| g2Anchor | any/best | any | best confirm30 未复现 dev 优势 |
| g2MixDiff | 0..12 | 0（全差分） | 任何 shell 稀释收益 |

## 已确认的 29×30 结果（vs A-Final-SteerOn，seeds 3459–3488 配对）

- 中位比 **0.9037**、**22/29 胜**、1 cat、Wilcoxon p=0.0007
- Holm 显著更好 5（F30/F18/F3/F7/F14）、显著更差 1（F1）
- 目标：Holm 显著更好 ≥10-12（F1 退化修复后）

## 消融（下一步，screen286 运行中）

A-Final / B-NoDiff / C-NoE / D-NoSteer / E-GWOonly，证明 E 和差分都有存在必要。
