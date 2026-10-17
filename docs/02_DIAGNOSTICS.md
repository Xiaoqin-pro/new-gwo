# 02 — 诊断先行，不要凭感觉加模块

## 基本粒度
每个 `(algorithm, fid, D, seed)` 存：`seedInit,seedSearch,FE,BestCost,BestError,seconds,objective_calls,n_positions_generated,version_hash,success,status`；曲线按真实 FE 对齐采样，记录 10%,20%,50%,80%,100% checkpoint。

## 搜索机制诊断（不额外消耗真实 FE）
1. 种群多样性：归一化 mean pairwise distance / 标准差；避免 O(N²D) 每 FE，按 checkpoint 采样。
2. 精英同质化：alpha-beta、alpha-delta、beta-delta 距离除以边界对角线；若重合另记 0 距离计数。
3. 连续无改善 FE 与过去 W FE 改善（W 开发时预登记，如 5% budget）；`plateau=true` 条件统一。
4. 候选范围：新位置到历史 elite 的距离分位数、到已评样本 archive 的最近邻距离；档案大小固定且抽样规则公开。避免复杂 O(FE²D) 全量 nearest neighbor；对历史样本作分层有限采样并报告近似定义。
5. 真实改进：global best、个人历史最好、保留 archive 的分项改进计数；无 pbest 的算法不能强行制造不公平指标。
6. 同 FE 区间的 `novelty_count`, `novelty_success`, `duplicate_count`, `gbest_improve_count`, `recovery_events`、候选生成数及附加CPU时间。

## 诊断失败类型（对每个函数/种子自动打标签）
- **Collapse**：alpha/beta/delta 及群体距离下降过快，且长期没有改善。
- **Wasteful wandering**：多样性很大但新颖点几乎不改善任何质量指标。
- **Early over-exploitation**：前 20% FE 收敛快，但此后误差过早平台化。
- **Late inefficiency**：前期有探索但晚期预算耗尽前没有高质量局部精修。
- **Cost explosion**：新方法选点能力可观，但位置生成/筛选 CPU 暴涨。
- **False escape**：所谓重启并未改善真实 best，只是多次大跳。

## 关键对照实验
- 相同 FEs、相同预算检查点，与原 GWO / 经源码核对 I-GWO / 强 PSO / CSO 分别比较。
- 提交含不同函数景观类别的 6–10 函数例子，说明某机制针对哪一类失败，不只展示获胜函数。
- 对提高新颖度的任何策略，同时与**同样预算的纯随机重启或随机选点**比较；如果不如随机，不构成探索效率创新。
- 对停滞触发策略，同时与**固定周期触发**比较；如果无增益，去掉自适应部分。

## 结果解释防止过度声明
未知黑盒函数时，通常无法证明“困在数学意义的局部最优”。论文可称 "stagnation escape" 或 "premature convergence mitigation"；不要称已证明逃离所有 local minima。
