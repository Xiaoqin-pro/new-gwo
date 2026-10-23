# 93. RSE（Route-Stratified Evaluation）P0/P1 预注册

日期：2026-10-23　状态：**P0 未过，停止；P1 未启动**

## 1. 机制

冻结 G1+E+STEER 候选生成、档案、K=10 和 FE，只改变真实评价在四条候选路线中的分配：

- G1：标准 GWO + STEER；
- filler：G2 关闭后的 GWO 填充；
- E-shell：单中心壳；
- E-line：双中心插值。

固定 RSE 使用每代配额 `[3,1,1,5]`（G1/filler/shell/line，和=10）；类内均匀随机。
匹配对照 `randstrat` 使用相同边际概率 `[0.30,0.10,0.10,0.50]`，但每代随机抽样类别计数。
`rseMode='off'` 与冻结 `SGWO_STEER3` 逐位一致。

## 2. P0（8 函数 × 5 新种子 3619–3623，120 次）

门槛：
- fixed/off 中位比 ≤0.98、≥6/8 胜、无 >1.20；
- fixed/randstrat 中位比 ≤0.98、≥6/8 胜；
- 三臂 FE=100k、0 failed。

## 3. P1（15 函数 × 10 新种子 3624–3633，450 次）

15 函数 [1 3 4 7 10 11 13 14 16 18 20 22 24 26 30] × 100k FE。

- 主假设 fixed/off：中位比 ≤0.98、≥11/15 胜、无 >1.20、时间 ≤1.15；
- 归因 fixed/randstrat：中位比 ≤0.98、≥11/15 胜；
- 判定：两者通过 → `PROMOTE_RSE_TO_CONFIRM`；仅主假设过 → `RSE_UNATTRIBUTED`；否则 `STOP_RSE_P1`。

不扫描配额、不做 Q-learning；如果固定 RSE 没有因果效果，在线路由没有意义。

## 4. 运行后结果（2026-10-23）

- P0：`rse_p0_20261023_101918`，120/120 ok；
- fixed/off 1.0382、4/8 胜、2 个 >1.20；fixed/randstrat 1.0046；
- 判定：**STOP_RSE_P0**，不进入 P1。
