# 06 — 导师材料与公开文献重叠风险（截至 2026-10-16）

## 用户给的两份材料（提供研究动机，不作代码底座）
A. **Spatial Screening and Reinforcement Learning-Based Particle Swarm Optimization for Real-Time or Resource-Constrained Engineering Optimization**（用户上传 PDF）：稀疏空间评价加 Q-learning 四算子调度，论文自述主要增益来自筛选，并强调资源约束。转化的是科研问题：哪些评价有信息价值？而不是直接移植其距离排序规则。
B. **RL_GNN_PSO.m**（用户上传）：探索/开发双角色、REINFORCE 邻域大小、排名受限差粒子重启。不得保留 GNN、PSO 速度公式，也不能复制固定参数作为新 GWO 默认值。

## 已确认的相关研究（需在正式投稿前系统扩展检索）
1. Maleki et al., **Enhancing leadership-based metaheuristics using reinforcement learning: A case study in grey wolf optimizer**, *Knowledge-Based Systems*, 2025, DOI: https://doi.org/10.1016/j.knosys.2025.114471 。RL-LGWO + 多智能体共享 Q 表、动态领导。警示：Q 调领导已经有人做过。
2. Wang et al., **Multi-population dynamic grey wolf optimizer based on dimension learning and Laplace Mutation for global optimization**, *Expert Systems with Applications*, 2025, DOI: https://doi.org/10.1016/j.eswa.2024.125863 。多种群 + 维度学习 + 变异；警示：双子群/逐维学习不能单独视作新意。
3. Chen et al., **Strengthened grey wolf optimization algorithms for numerical optimization tasks and AutoML**, *Swarm and Evolutionary Computation*, 2025, DOI: https://doi.org/10.1016/j.swevo.2025.101891 。精英重选/Cauchy 变异等；警示：重尾扰动并不新。
4. **Dynamic multi-strategy Grey Wolf optimizer and its applications**, *Scientific Reports*, 2026, https://www.nature.com/articles/s41598-026-54428-w 。动态探索/开发分组；警示：不能声称首次动态分组。
5. **An improved Grey Wolf Optimizer based on mutation operator, evolutionary population dynamics, and nonlinear population size reduction strategy**, *Scientific Reports*, 2025, https://www.nature.com/articles/s41598-025-33301-2 。差分扰动/种群减小等；警示：机制堆叠的饱和度。
6. **Grey wolf optimizer and whale optimization algorithm: a systematic review**, *Artificial Intelligence Review*, 2026, https://link.springer.com/article/10.1007/s10462-026-11585-8 。综述明确指出多样性塌缩、局部停滞和探索开发平衡是反复研究的难题。
7. **EABIF for exploration-aware metaheuristic benchmarking and behavior-triggered control (CEC-2025)**, *Applied Soft Computing*, 2026, https://www.sciencedirect.com/science/article/pii/S1568494626007921 。行为诊断相关，但本研究的 `useful novelty per FE` 指标是**自定义提议**，需要明示具体定义与限度，不能声称直接采用 EABIF 的现成指标。

## 投稿创新性的陈述原则
- 基于机制“对什么信息作决策、何时作决策、哪部分真实 FE 受影响”来区分，而非新名字/两个常见算子的堆叠。
- 不能写“首次解决 GWO 局部最优和探索效率”或“保证最优”。
- 开发时保持 Related Work 明确注明与已有 RL-GWO、双种群 GWO、SGWO、稀疏评价 PSO 的交叠，投稿前再核查 2026 最新期刊/预印本。
