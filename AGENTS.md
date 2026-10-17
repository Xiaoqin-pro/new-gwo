# Codex 科研代理约束（从本新目录启动）

## 一、目标与禁止行为
1. 新项目 **greenfield**；不以 RASE-GWO、I-GWO、RL_GNN_PSO 函数为起点或复制它们的方程组合。基本 GWO 按原始论文重新实现；借鉴概念需注明出处。
2. 双目标不可缺一：**停滞恢复** 与 **探索效率**；两个独立 evidence tables。只提高最终精度但探索/效率退化时，不能说双目标达成。
3. 无 GNN、神经网络、昂贵代理训练。默认最多两个主模块、少量可解释参数。需要复杂新模块须实测优于最简单可比替代。
4. 旧仓库与基线是外部只读资料。只写 `NEW_GWO_2026/` 本目录下文件，不能修改原有对比代码、实验结果与 Git 历史；禁止主动 push 到用户远端。
5. 如果本地代码/官方基准缺失、MATLAB license 或 Parallel Computing Toolbox 不可用，明确阻断并报告；不要模拟正式结果。

## 二、强制并行与随机性
- MATLAB R202? 版本未知，先查询 `version` 和 `ver`；只使用 `parpool('local',4)` 或与其同等严格的 local profile 4-worker 构造；确认 `gcp('nocreate').NumWorkers==4`。
- 用 `parfor`/`parfeval` 并行**独立运行单元**，算法单次执行应串行且单独控制 rng。严禁 worker 内再次调用 `parfor`/`parpool`。
- 每次运行 `seedInit` 与 `seedSearch` 独立存储，尽量让可比算法共享初始化前缀但不能让相同长度强行误配到不同人口策略。
- 每个任务分配唯一 ID 与独立落盘路径；异常捕获、状态 `failed`、日志、断点续跑；失败不能标记为成功。确保所有日志显示 pool workers=4，且 never serial fallback。

## 三、算法与测量正确性
- 不允许使用未真实评价的点作为带有已知 fitness 的领导者；动态构造的每个目标函数调用都计入 FE，包括初始化、重启、局部搜索、预筛选真实评价。
- 每次函数调用维护全局 `FE`（单次运行局部计数器）与 best-so-far；曲线以真实 FE 为横轴，长度/采样点完整。
- 检查边界向量 D 维、alpha/beta/delta 排序、重复领导位置、极值和 NaN/Inf、位置/f 值的一致性、最大预算。强制对小预算做单元测试。
- 训练/开发函数和种子与独立验证/测试分离；冻结方法、参数和主基准前不读取最终测试指标作为调参信号。公开最终结果若被多次查看需说明探索性分析。
- 优先报告平均/中位误差、方差或 IQR、成对每次运行结果、Wilcoxon（配对用 signed-rank 而非 rank-sum）和 Holm、Friedman 平均排名、成功率、显著性/效应大小、wall-clock。

## 四、迭代纪律
每一批必须写 `experiments/registry.csv`，记录：版本、Git hash 或 sha256、假设、唯一修改、范围、参数、预计收益、是否可否证、实际结果、不利函数、耗时与晋级理由。失败不可删。
按照 `docs/05_NIGHTLY_LOOP.md` 做阶段门，不能无限重试同一函数把最终测试集调成开发集。
初筛 5 seeds；晋级 10 seeds，冻结 final 才做 30 seeds。对强基线结果必须做协议与源码真实性检查。比较 RASE-GWO 是允许的，但只作外部历史对照。

## 五、项目交付
实现新的 `src/<NEW_NAME>.m`，对接已验证的本地 CEC benchmark wrapper，新增单元测试、可重现 runner、所有配置与结果、方法公式及复杂度推导；同时保留无改进时的负面结论。最终必须有 `reports/nightly.md` 及 `reports/SCI_READINESS.md`，明确 **A（脱困）、B（探索效率）** 是否分别通过，不得自我宣称已达 SCI 发表条件。
