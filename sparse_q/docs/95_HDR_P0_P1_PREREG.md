# 95. HDR（Hybrid Differential Refinement）P0/P1 预注册

日期：2026-10-23　状态：**P0 失败，停止；P1 未启动**

## 1. 机制

前 70% 真实 FE 保持冻结的 G1+E+STEER；之后只把 G1 更新替换为
DE/current-to-best/1：
\[
v_i=x_i+F(x_lpha-x_i)+F(x_{r1}-x_{r2}),\quad F=0.5,
\]
再做 CR=0.9 的二项交叉并裁剪。E、STEER、档案、K 和 FE 不变。
`deMode='off'` 与冻结 `SGWO_STEER3` 逐位一致；`deMode='late'` 才切换。
STEER 继续作用于切换后的 G1 候选，因此 HDR 是“后期精化”层，不改变 E/评价预算。

## 2. P0（8 函数 × 5 新种子 3619–3623，80 次）

- late/off 中位比 ≤0.98、≥6/8 胜、无 >1.20；
- FE=100k、0 failed，late 实际触发。

## 3. P1（15 函数 × 10 新种子 3624–3633，300 次）

15 函数 [1 3 4 7 10 11 13 14 16 18 20 22 24 26 30] × 100k FE。

- late/off 中位比 ≤0.98、≥11/15 胜、无 >1.20、时间 ≤1.15；
- 判定：`PROMOTE_HDR_TO_CONFIRM` 或 `STOP_HDR_P1`。

不扫描切换比例、F、CR 或混合其他算子；P1 不过就停止。

## 4. 运行后结果（2026-10-23）

- P0：`hdr_p0_20261023_104226`，80/80 ok；
- late/off 1.2673、1/8 胜、4 个 >1.20、最大 206.34；
- 判定：**STOP_HDR_P0**，不进入 P1。
