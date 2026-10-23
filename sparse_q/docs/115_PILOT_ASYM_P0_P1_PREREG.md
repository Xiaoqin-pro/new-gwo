# 115. Asymmetric Pilot Racing P0/P1 预注册

日期：2026-10-23　状态：**P0 失败，停止**

## 机制

两个核先各运行 20k 真实 FE：

- CMA-ES：全协方差、旋转/病态搜索；
- L-SHADE：差分变异、pbest、archive。

选核使用尺度归一化规则：

`cRel=(cBest-initBest)/initBest`，`lRel=(lBest-initBest)/initBest`。
仅当 `lBest<cBest`、`lRel>5e-9`、`1e-7<cRel<1e-3` 时选择 LSHADE，否则 CMA。

选核后的预算处理是**非对称**的：

- CMA 胜者：从 pilot 的 `mean/C/pc/ps/sigma` 继续 60k；
- LSHADE 胜者：不用已缩小的 pilot 种群续跑，而是从同一初始化池重新启动 60k。

总 FE = 20k(CMA pilot) + 20k(LSHADE pilot) + 60k(winner) = 100k。

## P0

- 8 函数：`[1 4 7 10 13 20 24 30]`
- 5 个新种子：`3919:3923`
- D=50，N=50，100k FE，严格 4 workers
- 4 臂：A LSHADE；B CMA；C PilotRestart；D PilotAsym
- 共 160 次运行，0 失败。

### 门槛

- D/A：中位比 `<=0.90`，至少 `6/8` 胜，`>1.20` 不超过 1 个
- D/B：中位比 `<=1.00`，至少 `5/8` 胜
- D/C：中位比 `<=1.05`
- D/A 时间比 `<=1.30`
- 两个 pilot 核和 winner 的真实 FE 必须分别正确计费
- 不允许未评价点进入任何核的 best/排序

## P1

仅在 P0 通过后启动：

- 15 函数：`[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]`
- 10 个新种子：`3924:3933`
- 4 臂同上，共 600 次运行
- D/A 中位 `<=0.90`、至少 `9/15` 胜、`>1.20` 不超过 2 个
- D/B 中位 `<=1.00`、至少 `8/15` 胜
- D/C 中位 `<=1.05`，时间比 `<=1.30`
- 不修改 pilot 比例、阈值或非对称规则；失败即停止
