# 92. SHA-GWO（Success-History Adaptive a）P0/P1 预注册

日期：2026-10-23　状态：**P0 未过，停止；P1 未启动**

## 1. 机制

标准 GWO 的 \(a_t=2-2\,\mathrm{FE}_t/B\) 只由预算进度决定。SHA 只改变 G1 的 \(a\)：
用真实 G1 父代改进历史维护快/慢两个成功率的 EWMA，令
\[
a^{G1}_t=a_t\sqrt{rac{s_{
m slow}+0.05}{s_{
m fast}+0.05}},
\]
并裁剪到 \(a_t\in[0.75,1.50]	imes\) 基准（且 \(a^{G1}\in[0,2]\)）。
近期成功低于长期成功时保留更多探索；近期成功高于长期成功时加快开发。

- 只作用于 G1；E、STEER、档案、筛选、K 和真实 FE 全不变；
- `shaMode='linear'` 与冻结 `SGWO_STEER3` 逐位一致；
- `shaMode='history'` 使用真实 G1 父代成功；
- `shaMode='placebo'` 使用独立随机流产生同样更新形状的假成功，用于归因。

## 2. P0（机制审计）

8 函数 [1 4 7 10 13 20 24 30] × 5 新种子 3619–3623 × 100k FE，A/B/C 三臂 = 120 次。

门槛：
- history 臂 `ShaFactorMean` 偏离 1，且 `ShaAUpPct>0`、`ShaADownPct>0` 在 ≥6/8 函数出现；
- 三臂 FE=100k、0 failed；
- 报告 B/A、C/A、B/C 作为探索性性能信号，不作 P0 晋级主门槛。

## 3. P1（15×10）

15 函数 [1 3 4 7 10 11 13 14 16 18 20 22 24 26 30] × 10 新种子 3624–3633 × 100k FE，A/B/C 三臂 = 450 次。

- **主假设 B/A**：中位比 ≤0.98、≥11/15 胜、无 >1.20、时间 ≤1.15；
- **归因 B/C**：中位比 ≤0.98 且 ≥11/15 胜；
- 判定：两者通过 → `PROMOTE_SHA_TO_CONFIRM`；仅 B/A → `SHA_UNATTRIBUTED`；B/A 失败 → `STOP_SHA_P1`。

不扫描 fast/slow 窗口、prior、factor bounds 或把 SHA 扩展到 E；P1 不过就停止。

## 4. 运行后结果（2026-10-23）

- P0：`sha_p0_20261023_100425`，120/120 ok；触发门槛 2/8；
- history/linear 中位 0.9865，4/8 胜，0 个 >1.20；
- 判定：**STOP_SHA_P0**；不进入 P1。
