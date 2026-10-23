# 94. AGLM（Archive-Guided Soft Leader Mixing）P0/P1 预注册

日期：2026-10-23　状态：**运行前冻结**

## 1. 机制

GWO 的 α/β/δ 会塌缩到同一盆地。AGLM 不替换领导，只在部分代把 G1 的 α 软混合到一个已验证档案中心：

\[
lpha_{m mix}=(1-\gamma)lpha+\gamma c,\qquad c\in	ext{verified archive},
\]

其中 \(c\) 从离 α 最远的 3 个档案中心随机取，γ=0.25，触发概率 p=0.35。
G1 的 X1 使用 α_mix；β、δ、E、STEER、档案、K 和真实 FE 全部不变。

匹配对照 `mixMode='random'` 使用同样的触发概率和 γ，但把档案中心换成随机当前狼；
`mixMode='none'` 与 `SGWO_STEER3` 逐位一致。

## 2. P0（8 函数 × 5 新种子 3619–3623，120 次）

门槛：
- archive/none 中位比 ≤0.98、≥6/8 胜、无 >1.20；
- archive/random 中位比 ≤0.98、≥6/8 胜；
- FE=100k、0 failed，且 archive/random 均实际触发。

## 3. P1（15 函数 × 10 新种子 3624–3633，450 次）

15 函数 [1 3 4 7 10 11 13 14 16 18 20 22 24 26 30] × 100k FE。

- 主假设 archive/none：中位比 ≤0.98、≥11/15 胜、无 >1.20、时间 ≤1.15；
- 归因 archive/random：中位比 ≤0.98、≥11/15 胜；
- 判定：两者通过 → `PROMOTE_AGLM_TO_CONFIRM`；仅主假设过 → `AGLM_UNATTRIBUTED`；否则 `STOP_AGLM_P1`。

不扫描 γ、p、partner-k；P1 不过就停止。
