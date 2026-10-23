# 机制安全性综合（统一重算）

对磁盘上每个已关闭机制线的机制臂，按各自批次的冻结/参照臂统一重算函数级中位比、胜场、
**>1.20 灾难函数数（cats）**、最大比值与运行时间比。基线为批内冻结臂，或该线复用的共享 29×30 `A2-G1E` 块。

- 纳入臂：**26** 条（17 个批次）

| 机制（臂） | 类别 | 函数 | 中位比 | 胜 | **>1.20** | 最大 | 最差函数 |
|---|---|---:|---:|---:|---:|---:|---:|
| E: archive slots vs GWO-only pool | ADD | 29 | 0.5102 | 29 | 0 | 0.943 | F19 |
| STEER: success direction | ADD | 29 | 0.9538 | 22 | **2** | 1.263 | F12 |
| E-STEER alone (B/D) | ADD | 15 | 0.9539 | 11 | **2** | 1.809 | F13 |
| STEER: random direction | ADD | 29 | 0.9663 | 20 | 0 | 1.196 | F19 |
| E-STEER on the final algorithm (C/A) | ADD | 15 | 1.0021 | 7 | 0 | 1.191 | F20 |
| G1-STEER alone, fresh 15x10 block (A/D) | ADD | 15 | 1.0745 | 4 | **5** | 1.738 | F18 |
| nE sweep: NE19 composition | COMPOSE | 15 | 0.9847 | 8 | **2** | 1.304 | F4 |
| nE sweep: NE00 composition | COMPOSE | 15 | 1.1618 | 2 | **6** | 5.496 | F1 |
| ECPS: evaluation-credit screening | GATE | 15 | 0.8899 | 10 | **4** | 1.356 | F3 |
| STJ: stagnation-gated steer | GATE | 29 | 0.9977 | 17 | 0 | 1.140 | F9 |
| PCSS: surrogate-guided screening | GATE | 15 | 1.0217 | 6 | **2** | 1.746 | F14 |
| RED: duplicate rejection | GATE | 15 | 1.0318 | 6 | **2** | 1.446 | F13 |
| VGA (P1, G2 off) | GATE | 15 | 1.0802 | 4 | **5** | 1.588 | F14 |
| VGA: greedy parent acceptance | GATE | 15 | 1.0897 | 3 | **6** | 1.485 | F18 |
| LLT: local leader topology | REPLACE | 15 | 0.7939 | 11 | **2** | 1.598 | F3 |
| NEL: neighbourhood exemplar filler | REPLACE | 8 | 0.9283 | 6 | 0 | 1.091 | F4 |
| TSD-full: E cursor-only admission | REPLACE | 15 | 0.9605 | 9 | **1** | 1.210 | F16 |
| TSD-R: trajectory recovery | REPLACE | 29 | 0.9763 | 21 | **2** | 1.249 | F15 |
| TSD-base: state decoupling | REPLACE | 15 | 0.9943 | 9 | **2** | 1.246 | F14 |
| SALS: post-selection LHS redraw | REPLACE | 15 | 0.9965 | 9 | **1** | 1.234 | F14 |
| DLH control: global difference | REPLACE | 15 | 1.0046 | 6 | **1** | 1.878 | F13 |
| SALS control: post-selection IID | REPLACE | 15 | 1.0242 | 6 | **1** | 1.243 | F18 |
| RGI: rank-gated restart | REPLACE | 29 | 1.0344 | 8 | **5** | 1.592 | F12 |
| DLH: neighbourhood fillers | REPLACE | 15 | 1.0375 | 4 | **2** | 1.807 | F13 |
| REF: diversity filler | REPLACE | 15 | 1.0919 | 6 | **4** | 2.885 | F10 |
| RGI: stall restart (no rank gate) | REPLACE | 29 | 1.4382 | 0 | **21** | 167.989 | F9 |

## 统一重算得到的模式

- 统一采用**配对比值中位**口径（每函数先取同种子配对比值的中位，再跨函数取中位），与本仓库
  SALS / DLH / STEER 确认的预注册主口径一致；个别线报告里另有'比值比'口径，数值会小幅不同
  （例：STEER B/A2 配对 **0.9663**、比值比 0.9769；STJ 配对 0.9977、比值比 1.0055）；
- 纳入 26 条机制臂，**零灾难函数（cats=0）** 的只有 5 条：E: archive slots vs GWO-only pool, STEER: random direction, STJ: stagnation-gated steer, NEL: neighbourhood exemplar filler, E-STEER on the final algorithm (C/A)；
- 其中**通过各自预注册 P1 主门槛的只有 E 与 STEER（随机方向）**；STJ 与 NEL 虽然零灾难，
  但分别在胜场/归因（STJ/A2 17 胜但 STJ/B 1.0230、7/22）与运行时间（5.28×）上失败 →
  **安全是必要不充分条件**；
- 出现 ≥1 个 >1.20 的臂占多数（21/26），最极端的是无门控停滞重启 （C-StallRestart：中位 1.438、**21 个 >1.20**、最大 168×）与 NE00（6 个 >1.20、最大 5.50×）；
- **中位比好看 ≠ 可采纳**：LLT 0.794 但 2 个 >1.20；ECPS 0.890 但 4 个 >1.20；NEL 0.928（6/8 胜、0 灾难）但 5.28× 时间；STEER 的成功方向变体 0.954 但 2 个 >1.20（只有随机方向变体零灾难）；SALS 0.9965 但 F14 1.234；
- 运行时间只在同批内可比：REF 1.01、DLH 1.23、PCSS 1.45、NEL **5.28**（跨批次基线的比值一律不参与，
  以免重复已被撤回的跨批次 +24.4% 口径）。

## 设计规则（待前瞻检验的假设，不是已证定律）

> **合规改动 = 只增不减 + 零均值有界**：机制只能给候选池/评价名额**增加**新提案，
> 或沿**零均值、幅度由现有步长界定**的方向延伸已有候选；不得削减、门控或以历史统计量
> **重写/重加权**领导驱动流（G1）的几何。

证据：两个通过确认的机制 E（+38 个多区域档案槽位）与 STEER-随机方向（等步长零均值延伸）都属于合规类，
且都是零灾难；反过来，GATE（门控：STJ/RED/VGA/PCSS）、REPLACE（替换：DLH/NEL/REF/TSD/SALS/LLT/RGI）、
COMPOSE（配比：nE 扫描）三类中共 22 条臂，只有 STJ 与 NEL 零灾难，且两者都在其它门槛失败。
也就是说：**合规类目前 2/2 安全且 2/2 通过；不合规类无一通过，且多数带尾部灾难。**

**前瞻检验结果（E-STEER 2×2 因子，`docs/70`，600 次运行）**：
- 主比较 C/A（E-STEER 叠加在冻结终版上）中位比 1.0021、7/15 胜、**0 个 >1.20**（最大 1.191）→ 规则的安全预测成立；
- 但次级臂 B/D（E-STEER 单独 vs 冻结 G1+E）中位比 0.9539、11/15 胜、**2 个 >1.20（F13 1.809）**→
  同一合规算子在没有 G1-STEER 时仍出现尾部灾难；
- 因此"合规 ⇒ 安全"在本轮是**部分支持、部分否证**（主比较安全、次级比较不安全）。诚实结论：
  合规性是"只增不减"类改动的**弱安全提示**，不是充分条件；15 函数 × 10 种子的 dev 尺度上 cats 本身也不稳定
  （参照：确认尺度上 STEER-随机方向 0 个 >1.20，而几乎同族的成功方向变体有 2 个）。
- 该批次的有效性检查也未通过：A/D（G1-STEER 单独 vs 冻结 G1+E）中位比 1.0745、4/15 胜
  → 已确认的 STEER 效应（29×30 上 0.9663、20/29 胜）在这个 15×10 块上**未能复现**，
  说明 dev 块对 ~3% 量级效应的检验力不足（详细见结论 §三十一）。

## 限制（必须写进论文）

- 分类是**事后归纳**（post-hoc），各线协议不完全一致（8 函数 × 30k/100k dev、15 函数 × 100k、29 函数 × 100k），
  部分线的基线跨批次复用（同种子配对）；只能作为"设计边界"叙事与未来预注册门槛的依据，不能作为统计推断；
- 两种比值口径会给出不同的小数（配对比值中位 vs 比值比），本表已统一为前者并注明；
- Tier B（本工作区无 runs.csv、仅在各自分支有报告）：SSSA、CD-VACG、AMC、CALA、ENAC 的数字
  见 `reports/mechanism_exploration_conclusion.md` §四 与各自 nightly 报告：SSSA 1.0306（4-4、2 个 >1.20，
  Swap 对照在 F7 反超 1.633）、CD-VACG 1.0656（2-6、F13 22.5×）、AMC 1.2178（1/15 胜、9 个 >1.20）、
  CALA 0.9557（9/15、3 个 >1.20）、ENAC B/A 1.0155（6/15、F20 1.52）；
- E 行的基线是 A0（无 E 的 GWO 候选池），其"运行时间比"与其它行不可比。
