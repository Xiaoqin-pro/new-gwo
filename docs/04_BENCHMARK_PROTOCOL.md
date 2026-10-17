# 04 — 强基线、真实 FE、公平比较与 4-worker MATLAB

## 0. 环境与清单
- 第一件事找到 MATLAB 版本、Parallel Computing Toolbox、官方 CEC2017 测试函数（本地 mexw64 可能只适用于 Windows）、全部强基线实现与训练/验证设置。
- 记录每个算法作者来源、hash、入口签名、是否官方源码/经过适配、种群规模、预算以及初始化方式。
- **必须包含**标准 GWO（正确性诊断）、≥2 个强 GWO 家族（如源码核验后的 I-GWO + 另一个近期 GWO）、≥3 个非 GWO 强基线（优先 HIDMS-PSO、HCLPSO、DMS-PSO、SAQ-CSO，若可用加 L-SHADE）。如果缺少足够可信的 GWO 强基线，必须先补齐/说明，不得把弱替代物凑数。
- 旧库 README 的 15 算法榜单仅用于确定优先目标，不是本次算法的结果。

## 1. 运行预算与分割
- 开发集：CEC2017 D=30，按函数类别分层选 6–10 个函数；每版 5 seeds 试跑，最高 10 seeds 晋级。**在开发前预先写明哪几道函数以及随机种子范围**，不根据结果挑选函数。
- 独立测试：CEC2017 D=50、D=100，正式包含所有已定义且受支持的函数（官方 F2 的排除须遵循并注明 CEC 套件规范），每函数每算法 30 独立 runs，冻结参数之后统一测试。
- 主对照：相同真实 FE 上限（初设 100000，包括初始化）；增加 20%、50%、100% budget checkpoints。在不同预算对比的任何次要实验单独标注不可替代 equal FE。
- 统计不再只关注 win-vs-GWO：关注强 PSO/CSO/DE 与强 GWO，同 FE 的 mean/median error、IQR/std、Friedman 平均排名、Holm 调整的检验及成对 effect size。
- 对相同 seed 的配对运行（共同问题、可审计相同初始化协议）用 Wilcoxon **signed-rank**；若没有真正可匹配的 pair 使用 Mann-Whitney/秩和，不要混淆。
- 多重比较针对可预先注册的主对照集合做 Holm，不能跑 50 种参数后只公布赢家未经校正的 p 值。

## 2. 4-worker 并行的强制规范
1. 控制端 `pool=overnight.ensureFourWorkers(); assert(pool.NumWorkers==4);`。
2. 对各个 `(algorithm,fid,D,seed)` 建独立 jobs；用 `parfor` 或 `parfeval` 分配任务，**单任务内部不要再并行**，每个 worker 所需路径/初始化在 worker 端执行。
3. 不能因为 license/pool 启动失败转为串行。任务命名唯一，产物 `results/<batch>/runs/run_%05d.mat`，出错会生成 `failed` 记录，重试可从成功记录继续。
4. 若已有 pool != 4，在没有其他任务的前提下先关闭并重新开 4，或者在有其他工作时停止并请求处理；千万别悄悄使用 `parpool(8)` 或多套 pool。
5. 使用本包 `+overnight/runBatch4.m` 作为基础设施示例（可按 MATLAB 版本适配），不含算法实现。每个正式 run 的 result 必须带真实 `Evaluations` 与 `BestCost`。
6. `maxFE` 必须严格真实记账，包含初始化和任何重启、DE 变异候选被评价次数，断点续跑不重复写/混算结果。

## 3. 方法公平性（强制）
- 不靠添加大量**免费生成的候选**使新的方法看上去同 FE 获胜而忽略 CPU 成本：记录 `nCandidateGenerated`, `nCandidateAccepted`, `nDistanceOps`，主文同时展示时钟时间和 FE 曲线。
- 不能反向修改已有强基线的超参数以削弱其表现。引用作者源码/标准最佳实践；记录变更及合法理由。
- 不同算法人口不同，允许其原始推荐人口，但报出每个 N、预算核算与种子；不能硬配成 N=50 导致严重弱化强基线。
- 共享初始点可能有利于配对，但算法内部 RNG 要独立，且对于种群不同的算法，只能称为部分共用前缀，不可宣称完全相同初始群体。
- `method.FEs == budget` 等值校验不适用基于自然停止条件的已预先声明协议；默认全预算测试要求精确等于 B，否则结果失败。

## 4. 消融与失败披露
至少 `New GWO`、`w/o exploration-efficient module`、`w/o escape module`、`random/fixed scheduler`、`simple baseline`。发现有毒模块可在最终方法移除，但必须保留其开发记录。还要比较最强的单模块以防组合只增加复杂度。
正式验证前预登记测试矩阵与停止机制；结果不能删除、改名称掩盖或选择性报告。
