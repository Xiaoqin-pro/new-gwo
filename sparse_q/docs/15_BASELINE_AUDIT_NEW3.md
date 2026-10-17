# 15 — 新增三个 GWO 基线的复现审计（HAGWO / AOGWO / EDGWO，2026-10-17）

范围：按用户要求"严格按原文或公开代码"新增三个 GWO 变体基线。**不修改 VAST-GWO(V1) 与既有结果。**
RL-LGWO / DMSGWO：**用户决定（2026-10-17）：不再参与与 VAST-GWO 的对比，此后不再使用**；
两份已完成对比结果（final7 批次）保留归档，不进入主表与后续分析。

## 0. 来源与版本（全部冻结）

| 算法 | 论文 | 参考代码 | commit / 文件 |
|---|---|---|---|
| HAGWO | Mathematics 2026, 14(16):3011, doi:10.3390/math14163011 | **作者 MATLAB**：SylvanHuang/HAGWO | `bdfda96b449eec7f3dd1a7bd20a956759f03b716`（`HAGWO_optimizer.m`） |
| AOGWO | Scientific Reports 2026, doi:10.1038/s41598-026-53090-6 | **作者 MATLAB**：OthmanWaleed/AOGWO | `4122cefcbc1b2fb52df4e80656982af0a75357f7`（`AOGWO_17.m`） |
| EDGWO | Swarm & Evol. Comput. 2025, doi:10.1016/j.swevo.2024.101795（Zhang & Chen） | **第三方公开 Python 复现**（非作者代码）：TWCkaijin/Elite-driven-Grey-Wolf-Optimization | `8e1773992a62ed407d3daef65f28f7846ce6b99a`（`optimizers/EDGWO.py`） |

移植文件与本文件同批冻结哈希（sha256 前 16 位）：

* `src/HAGWO_CEC.m` = `12cd68e32e19ce4f`
* `src/AOGWO_CEC.m` = `c2f0cc3d854961f7`
* `src/EDGWO_CEC.m` = `cca3c476445513a5`（v2：调度索引对齐作者 t 从 0 起；
  首次批 new3_20261017_100335 在 284 次运行后中止作废保留）

## 1. HAGWO（作者 MATLAB，逐机制对应）

机制保留：动态分层（前期 10%/30%，后期 30%/30%）、优狼精炼（Eq.28）、中狼
Levy 扰动（Eq.30）、劣狼对抗跳出（Eq.32）、GWO 精英引导 X1/X2/X3、动态权重 p。

适配（仅接口与计费，逐条）：
1. 初始种群由实验框架给定（同池协议）；不调用其 `initialization`。
2. **`Avg_curve` 的每代 N 次重复 fobj 调用改为使用已评价的 `fitness`**
   （结果统计缓存；不改变搜索行为，也不重复计费）——评审指出的关键点。
3. 每代恰好 N 次真实评价；`Max_iter = floor((budget-N)/N)`，FE 精确等于预算。

## 2. AOGWO（作者 MATLAB，逐机制对应）

机制保留：混合反向学习(DO)初始化、余弦自适应 a、衰减跳跃率 Jr + Levy 扰动、
仅对 Alpha 的选择性反向学习（SLO）。

适配（仅接口与计费，逐条）：
1. **搜索域改为实验框架的 [-100,100]^D**（作者演示码硬编码 [0,1]；反向学习公式
   只依赖 lb/ub，属尺度适配，机制不变）。
2. 初始人口 = 框架共享基池 **+** 作者的 DO 初始化变换（初始化机制保留，基池同池）。
3. 调度变量：`a=2cos(pi/2·prog)`、`Jr=0.5(1-prog)`，`prog=fe/budget`
   （等 FE 适配；作者用 t/maxIter）。
4. 逐次评价检查预算，绝不超支；同一位置不重复评价。

## 3. EDGWO（第三方公开代码复现——**如实标注非作者实现**）

机制保留（与原文描述核对）：精英层（α/β/δ）与普通层差异化更新；各领导者候选按
`|A|<1` 在"局部 GWO 利用算子"与"全局探索算子（`target-Xm-r3(lb+(ub-lb)r4)`）"
间动态切换；普通狼按概率 `0.5(1-t/T)` 在领导聚合与螺旋式全局算子间二选一。

适配（仅接口与计费，逐条）：
1. 初始种群由实验框架给定（同池）；原码为均匀随机。
2. 连续搜索域 [-100,100]^D；移除参考码的离散/特征选择分支（`f_type=='d'`）。
3. `max_iter = floor(budget/N)`（每代 N 次真实评价）→ FE 精确等于预算。
4. 不确定性（如实记录）：该实现为第三方复现，未与作者确认；与原文伪代码核对一致，
   但若作者后续公开官方代码，应以其为准复核。

## 4. 验证与预注册

* 版本纪律记录：首启批次 `new3_20261017_100335` 在运行中发现 EDGWO 调度索引
  未与作者 t=0 起始完全对齐，**立即中止（284 次运行作废保留，无 runs.csv）**；
  对齐后冻结为 `cca3c476445513a5` 再启动正式批次——整批单一版本。

* 烟测（`tests/test_new3_smoke.m`）：三臂 FE=3000 精确、轨迹单调、T(end)==Best、确定性 PASS。
* 正式批：`new3_*`（3 臂 × 29 函数 × seeds 3001:3030 × D=50 × 100k 真 FE，4 worker，可续跑
  `experiments/resume_new3.m`）。
* 统计口径与主表一致：同初始池、逐函数配对 Wilcoxon + Holm、平均排名、运行时间、FE 轨迹。
* 预注册：新增三臂进主表；**不因结果删除或替换预注册的算法**；RL-LGWO/DMSGWO 保留在补充材料。
