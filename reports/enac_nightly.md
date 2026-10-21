# ENAC Nightly Report

日期：2026-10-21（本地客户端时区）

## 结论

ENAC 被动诊断发现了明确的档案信用问题；清理版 P1 后：

- **H1（ENAC vs V1）通过**：中位误差比 **0.93917**，**8/8** 函数获胜，无函数退化 >1.20，运行时间 ENAC/A3-Off = **1.035**；
- **H2（ENAC vs Identity-Credit）不通过**：中位比 **0.97527**，仅 **4/8** 获胜，F10 上 ENAC 比 Identity 差 **2.257 倍**；
- Identity-Credit 相对 V1（次级）：中位比 **0.96126**，**6/8** 获胜，无函数 >1.20。

最终判定：**IDENTITY_EFFECT_ONLY**。有效成分是修正档案中心身份和替换后的信用归属，而不是成功率曝光归一化。

## P0 被动诊断

40 次运行，8 函数 × 5 种子，30k FE，单臂被动审计，与冻结 `SGWO` 逐位一致。

| 指标 | 均值 | 预注册 material 门槛 | 判定 |
|---|---:|---:|---|
| Wrong update rate | **2.30%** | ≥1% | material |
| Stale feedback rate | **3.23%** | ≥1% | material |
| Near-replacement leak event rate | **83.8%** | ≥5% | material |
| Leak credit / total credit increments | **295%** | ≥5% | material |
| Spearman credit vs normalized success | **−0.175** | <0.5 | material |
| Mean top-weight ratio | **3.51** | ≥2.0 | material |

三类问题全部 material，按预注册进入 ENAC P1。

## P1 实验完整性

- 清理版 P1：3 臂 × 8 函数 × 10 种子 = **240/240 成功，0 失败**；
- 清理版 A3-Off：**80/80 成功，0 失败**；
- D=50，30,000 真 FE，MATLAB local 4 worker；
- 函数：F7、F10、F13、F16、F18、F22、F24、F30；
- 种子：3151–3160；
- 冒烟：F7，seed 3989，3k FE，3/3 成功。

## 逐函数结果

| F | V1 中位数 | Identity 中位数 | ENAC 中位数 | ENAC/V1 | ENAC/Identity |
|---:|---:|---:|---:|---:|---:|
| F7 | 432.297 | 444.62 | 421.179 | 0.974 | 0.947 |
| F10 | 13,335.6 | 5,621.06 | 12,686.2 | 0.951 | **2.257** |
| F13 | 453,995 | 422,121 | 351,545 | 0.774 | 0.833 |
| F16 | 1,116.4 | 1,089.42 | 1,110.55 | 0.995 | 1.019 |
| F18 | 2.420e6 | 1.676e6 | 1.774e6 | 0.733 | 1.058 |
| F22 | 14,022.3 | 13,873.1 | 13,020.9 | 0.929 | 0.939 |
| F24 | 623.617 | 590.37 | 592.291 | 0.950 | 1.003 |
| F30 | 1.106e8 | 1.176e8 | 9.703e7 | 0.877 | 0.825 |

## 机制过程证据

| 指标 | Identity-Credit | ENAC |
|---|---:|---:|
| Mean top-weight ratio | 4.009 | **1.287** |
| Mean weight entropy | 0.872 | **0.996** |
| Center evaluations | 11,175.9 | 11,188.7 |
| Center successes | 6,905.9 | 6,980.4 |
| Dropped stale feedback | 205.7 | 193.4 |
| E improvements / 1000 FE | 235.7 | 237.9 |

ENAC 确实让中心权重接近均匀，但并没有在最终精度上稳定超过 Identity-Credit。它改善了 F13、F22、F30，却在 F10 上严重退化。

## 实现修正记录

第一版 P1（`enac_p1_20261021_022454`）在审计块和 ENAC 块中重复计数 `centerEval/centerSucc`，Beta(1,1) 平滑使用的曝光量被重复增加。该批次作废，不作为最终结果。清理版把每个候选只计一次，机制公式、候选池、FE 和 `enacOn=0` 逐位一致性均保持不变。

## 最终建议

1. 停止 ENAC 曝光归一化作为独立贡献。
2. 保留 **Identity-Credit** 作为唯一值得进入正式确认的候选：
   - 唯一中心 ID；
   - 评价后只更新生成时的中心；
   - 中心被替换后新中心重新累计；
   - 仍使用累计成功次数作为权重。
3. 如果采用 Identity-Credit，必须重新预注册并执行 29 函数、D=50、100k FE、30 个全新种子的正式确认；不能直接用本次 8 函数 P1 结果替换主算法。
4. 如果不准备再开正式确认，则保持冻结 V1 和现有论文结果，把 ENAC/Identity 作为审计与设计边界结果。
