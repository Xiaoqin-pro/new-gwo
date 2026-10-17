# 文献报告（Phase 1，2026-10-16）：稀疏评价 × Q-learning × GWO

检索方式：Crossref API（query.bibliographic，2026-10-16 执行，
`experiments/lit_results.json` 保存原始条目）；本地材料：导师
SS-RLPSO 手稿（用户提供 PDF）、`RL_GNN_PSO.m`、旧工程 docs/06 文献图、
本项目 D50 复核报告。**不以任何先验假定哪种机制有效**。

## 1. 2021–2026 关键 GWO 改进与重叠警示

| 论文（年份/期刊/DOI） | 机制 | 与我们设计的关系 |
|---|---|---|
| I-GWO（Nadimi-Shahraki 2021, ESWA, 10.1016/j.eswa.2020.113917; 1069 引） | 逐维邻居学习（DLH）+ 个人历史保留 | 强基线；"逐维学习"是我们的对照原则（S2 曾试几何/历史筛选被证伪） |
| R-GWO / GGWO / BE-GWO（同组 2021–2023） | 代表个体 / 注视线索学习 / 二元极值 | 领导与学习机制多样化的警戒线 |
| SGWO（Chen 2025, SWEVO, 10.1016/j.swevo.2025.101891; 18 引） | 精英重选 + Cauchy 变异等强化算子 | "重尾扰动/精英选择"不是新意 |
| DLMDGWO（Wang 2025, ESWA, 10.1016/j.eswa.2024.125863; 22 引） | 多种群 + 维度学习 + Laplace 变异 | "多种群/逐维学习/重尾"三重堆叠已被占位 |
| DMSGWO（Wang/Song/Zhao 2026, Sci Rep, 10.1038/s41598-026-54428-w） | 动态多策略分组 | 动态分组不可声称首次 |
| RL-LGWO（Maleki 2025, KBS, 10.1016/j.knosys.2025.114471） | RL 选择领导 | "RL 调领导"已被占位 |
| Adaptive multi-strategy GWO + RL（Algorithms 2026, 10.3390/a19030168） | RL + 多策略 | RL 调度多算子先例 |
| RL-driven spherical-vector GWO（Biomimetics 2026, 10.3390/biomimetics11070470） | RL + 球面向量 | 同上 |
| **QLFDGWO**（Huang 2026, Biomimetics, 10.3390/biomimetics11060428） | **Q-learning 引导加权 适应度–距离 GWO（UAV）** | **最直接重叠警示：Q+GWO 已有**；差异点必须落在"分配的是昂贵真实评价名额"而不是选择算子/权重 |
| **Adaptive Q-Learning GWO for UAV**（Drones 2025, 10.3390/drones9040246; 27 引） | Q-learning 自适应 GWO（UAV 路径） | 同上 |
| Surrogate-assisted GWO（Dong & Dong 2020, SWEVO, 10.1016/j.swevo.2020.100713; 84 引） | 代理模型 + 高维昂贵问题 | 昂贵优化+GWO 已有；我们**不用代理**，稀疏真实评价 |
| HCLPSO（Lynn 2015, SWEVO; 503 引）+ heterogeneous pbest-guided CLPSO（Meng 2024, ASOC） | 异构子群/增强探索开发 | 强基线；异构分工思想与我们"双路线候选池"需区分 |
| Grid-classification surrogate PSO（TEVC 2023）；adaptive surrogate PSO（2021）；sequential approximation PSO（2019, ASOC） | 昂贵优化的代理/序贯近似 | 评价效率主题的相邻工作 |

## 2. 导师两篇材料与本地历史的结论（只读复核）

* SS-RLPSO：空间筛选（评价名额分配）是主收益来源，RL 调度是次要补充；
  K/N 是最敏感参数；预算受限时"少评价、多代数"有效。
* RL_GNN_PSO：探索/开发双角色、排名受限重启；GNN 部分不作为我们的方向。
* 本地 D50 5220 次正式批复核（`reports/D50_AUDIT_VERIFICATION.md`）：
  ANGWO（全评价）对 GWO 21/8、Holm 11/0、FE10/20 胜 10/13、恢复事件
  14.555→14.562（几乎不动）——证明"α 附近改良"不能解决停滞恢复。

## 3. 本地失败记录（本分支与旧工程）

* 旧工程：几何筛选价值随 K 与生成器强度变化；K 极小（6）时随机筛选反而更好；
  "远点多样性"评价转化率仅 0.4%（vs 近点 5.7%）。
* 本分支 SCREEN1/1C：最近邻 α 定向筛选 1.39×（对随机）、informed-in-strata
  1.53×——**定向筛选饿死狼自身移动**。
* 本分支 SCREEN2/3/7：探索配额 0.5/0.75 与随机配额有害；三种 Q 变体
  （零初值/调参/先验初值）均未超过最优固定配额（对随机配额 0.75–0.87 胜）。
* 机制层面：**"新颖候选多但没有真实改善"**的根因在评价分配；扩大扰动半径
  （E50 池、boost 未完成）需要证据支持。

## 4. 可检验假设（进入 Phase 4/5）

* H-A：双路线池（α 局部精化 + 已验证多区域）在等 FE 下提高早期与简单多峰
  表现（SCREEN 已支持，待正式批；F4–F10）。
* H-B：停滞触发的高半径壳（escape boost，屏数值 ×3/×5）能提高真实恢复
  概率而不牺牲末端（**待测**；旧证据表明盲目远跳无效，故限定"已验证中心 +
  放大半径"）。
* H-Q：轻量 Q 表（6 态×3 动作，每 500 FE 结算）在 K 固定时优于最优固定
  配额（**当前证据为否**：0.99/1.02/1.13；对随机配额为是）。若或 Phase 4
  的诊断显示 Q 只学到"永远选择默认动作"，则该结论以"RL 无独立收益"写入论文。
* H-K：K=10 的细粒度评价密度在两套独立种子一致优于 K=50（0.970/0.955，
  均 6/8），正式批复核。

## 5. 新颖性边界（写作时必须遵守）

1. 不能说"首次用 Q-learning 于 GWO"（QLFDGWO/Drones 2025 已有）。
2. 不能把"稀疏评价"本身当作首次（SS-RLPSO/SAQ-CSO 线+screening PSO 文献）。
3. 可以主张的是：**在固定真实 FE 预算下，"候选池如何构成"（双路线、仅验证
   中心、成功尺度）比"如何筛选/调度"更能决定 GWO 的收益**——并以完整消融
   （定向/历史筛选、固定/随机/Q 配额、K 与池比例）作为可复现证据。
4. 每次机制变化必须配可证伪假设与失败记录（registry.csv）。

## 6. 复现进度（2026-10-17，按"有开源代码优先"）

| 算法 | 代码状态 | 本工程状态 |
|---|---|---|
| I-GWO | 已审计 MATLAB | ✅ 已入主表（30 种子） |
| RL-LGWO（KBS 2025） | 作者 Python 源码（mroayaei/RL-LGWO） | ✅ 已逐机制移植 `src/RLGWO_CEC.m`（评价缓存 + 严格计费；标注 port） |
| DMSGWO（Sci Rep 2026） | 官方 GitHub 开发组循环为空 | ✅ 按开放获取论文公式补全 `src/DMSGWO_CEC.m`（标注 paper-repair） |
| MELGWO（KBS 2023） | FEX 作者源码被网络 403；GitHub 镜像为垃圾仓 | ⏸ 暂缓（记录在案） |
| QLFDGWO（Biomimetics 2026） | 无公开代码；MDPI 403 | ⏸ 仅文献引用 |
| GWO-C1/C2（Tsai & Shi） | 无代码，公式简单 | ⏸ 如需要可后补 |

对比协议：与主方法相同的 init 池/种子/100k 真 FE/4 worker；
所有新复现算法均标注实现来源与偏差（评价缓存、FE 进度替代表迭代进度等）。
