# 00 — 旧仓库只是参照，不是起点

## 查到的公开仓库
- URL: https://github.com/Xiaoqin-pro/gwo
- 根目录包含 `README.md`,`PAPER_PLAN.md`,`src/`,`experiments/`,`data/cec2017/`,`results/`,`docs/`,`tests/`。
- 公开 README（2026-10-16 的浏览版本）报告 RASE-GWO 在 CEC2017 D=50，29 个函数、30 种子、100000 真 FE：合并 15 算法时平均排名约 8.28，而 HIDMS-PSO 2.17、HCLPSO 2.72、DMS-PSO 2.83。该数字属于旧仓库披露的历史结果，**在本新项目独立核验之前不可冒充复现实验结果**。
- 历史文档 `docs/04_IGWO_CORRECTION.md` 指出早期 I-GWO 实现曾存在精英历史保留、逐维邻居、领导更新时序及越界处理四处错误。重新用作者源码核查，不允许把弱化实现当强 GWO 基线。
- 老仓库可能已经有 4-worker runner，**不复制/调用它作为新算法评估底座**；可以对照它的验证要点，再在新工程中建立独立可核验管线。

## Codex 必须先做的发现任务
1. 在用户计算机上找到已有 MATLAB 工作区、CEC2017 二进制/源码、已运行的强基线、MATLAB 版本及 toolbox，可使用 shell 搜索，不得猜本地盘符。
2. 在 `reports/baseline_audit.md` 记录每个基线：真实路径、入口函数签名、来源 DOI/作者实现、hash、种群与 FE 约定、实现是否经过测试。
3. 只读加载旧结果用于选取比较对象/发现潜在性能缺口；**禁止根据旧研究策略构造新方法初始代码**，禁止从旧项目复制 `RASE_GWO.m` 等文件。
4. 如果复用历史成绩为最终强基线对照，务必验证函数版本、维度、目标偏置、运行环境、FE 预算、算法修订版本、随机方案、运行次数是否严格匹配；条件不匹配则在本新项目重跑。
5. 所有新源代码与输出写入新目录 `src`, `tests`, `experiments`, `results`, `reports`，不要将旧代码直接迁移为本项目的主算法。

## 概念来源和界线
用户提供的教师材料：
- 《Spatial Screening and Reinforcement Learning-Based Particle Swarm Optimization for Real-Time or Resource-Constrained Engineering Optimization》：启发“有限真实评价与在线调度”的**研究问题**；不直接照抄空间排序规则或 Q 表动作。
- `RL_GNN_PSO.m`：启发“探索与开发的不同学习方向”和“低质量个体受控重启”的**构思**；新方法明确 **不使用 GNN**，且不沿用代码里的奖励、超参数或 PSO 速度更新。
- 新论文写 Related Work 时准确引用上述工作；不要把借鉴机制说成首次出现。
