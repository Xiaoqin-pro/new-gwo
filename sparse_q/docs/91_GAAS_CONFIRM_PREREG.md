# 91. GAAS（几何感知档案搜索）确认级预注册

日期：2026-10-23　状态：**P0 通过、P1 失败停止；确认级未启动**

## 1. 机制（论文口径：我们提出……）

G1+E+STEER 已把已验证精英档案 E 用于单中心壳（点，0D）和双中心插值（线，1D）。
GAAS 增加第三层：从三个真实评价过的档案中心构造 2D 单纯形候选。

- \(c_1\)：质量锚点，从前 `gaasAnchorK=8` 个中心中随机选；
- \(c_2\)：从离 \(c_1\) 最远的 `gaasPartnerK=3` 个中心中随机选；
- \(c_3\)：从使 \(\min(d(c,c_1),d(c,c_2))\) 最大的 3 个中心中随机选；
- 候选：\(y=w_1c_1+w_2c_2+w_3c_3+\epsilon\)，其中 \(w_1\in[0.4,0.8]\)，剩余权重随机分给 \(w_2,w_3\)，噪声系数 0.20。

E 的 38 个槽位在 GAAS 模式下固定为：10 个单中心壳、14 个线、14 个单纯形。
`gaasMode='none'` 与冻结 `SGWO_STEER3` 逐位一致（`tests/test_gaas_contract.m`）。
`random3` 是匹配对照：同样三个不同中心、同样权重/噪声/槽位，只把“锚点+空间伙伴”换成均匀随机三元组。

## 2. 设计（复用冻结臂）

| 臂 | gaasMode | 说明 |
|---|---|---|
| A（复用） | none | `steer_robust_20261022_213856` 的 `A-Final-SteerOn`，seeds 3459–3488 |
| B | simplex | 10/14/14，质量锚点 + farthest-point 伙伴 |
| C | random3 | 10/14/14，均匀随机三元组 |

29 函数 [1 3:30] × 30 种子 × 2 新臂 = **1740 次运行**，D=50，100k 真实 FE。

## 3. 门槛

- **主假设 B/A**：中位比 ≤0.98、≥18/29 胜、无函数 >1.20、时间 ≤1.15；
- **归因 B/C**：中位比 ≤0.98 且 ≥18/29 胜；
- 报告过程量：各分支真实评价数、GB 率、档案入库率。

判定：B/A 且 B/C 通过 → `PROMOTE_GAAS`；
仅 B/A 通过 → `GAAS_UNATTRIBUTED`；
B/A 不通过 → `STOP_GAAS_CONFIRM`（不再扫描单纯形比例、锚点 k、伙伴 k 或噪声）。

## 4. 记录

`reports/gaas_confirm_analysis/`；结论追加到总报告；registry 一行。

## 5. 运行后结果（2026-10-23）

- P0：`gaas_p0_20261023_084008`，80/80 ok；分支前提 8/8；B/A 最终中位 1.0621（仅作警告）；
- P1：`gaas_p1_20261023_084752`，450/450 ok；B/A 1.1266（4/15、6 cats、最大 160.1、运行时间 1.418×）；B/C 0.9897（8/15、2 cats）；
- 判定：**STOP_GAAS_P1**。不进入 29×30，不进行参数扫描。

完整结果见 `reports/gaas_p0_analysis/report.md`、`reports/gaas_p1_analysis/report.md`，总报告见 `reports/mechanism_exploration_conclusion.md` 第四十七节。
