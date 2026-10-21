# 20. G2-AFE 档案前沿外推预注册（P1 开发集）

## 0. 背景

G2-TR（`codex/g2tr-rescue`，提交 `1f1da2c`）没有通过 P1 预注册门槛：

- G2-TR / A2 跨函数中位误差比 0.99945，逐函数 4 胜 4 负；
- G2-TR / A4 中位比 0.96008，但只有 5/8 更好，2 个函数退化 >1.20；
- 98.43% 的 G2 候选只能替换最差狼，仅 1.09% 改善 Alpha；
- 因此停止 G2-TR 半径搜索，不修改冻结 `SGWO.m` 和 `main`。

本次不继续调 G2-TR 半径，而是检验一个新的可证伪假设：

> **在严格限制真实目标函数评价次数的条件下，利用已验证档案中局部适应度排序形成的外推方向，能否比同预算、同触发条件、同步长的随机方向外推更有效地探索新区域，并在精度不退化的前提下改善停滞恢复？**

这是 G2-AFE（Archive-Frontier Extrapolation，档案前沿外推）。

## 1. 三条候选来源重新分工

| 来源 | 角色 |
|---|---|
| G1 | 标准 GWO 领导聚合，保留群体演化信息 |
| E | 档案中心附近采样和中心之间线段插值，利用已知优质区域内部信息 |
| G2-AFE | 停滞触发后，利用档案点的适应度排序，向档案外部做定向前沿外推 |

G2-AFE 只在停滞后启用。非停滞、档案不足或点对无效时，G2 槽位由标准 GWO 候选填补，不增加真实 FE，不增加候选池规模。

## 2. 候选生成公式（运行前冻结）

### 2.1 档案点对

- 档案 `Arc` 只包含真实评价过的点，适应度为 `Arcv`。
- 有效点至少 `g2AFEMinArc=4`。
- 按适应度升序排序（越小越好），`a` 从档案适应度排名前半部分选择：
  \[
  \mathcal A_{\rm top}=\{a: \operatorname{rank}(a)\le \lceil \operatorname{ArcN}/2\rceil\}.
  \]
- 对每个候选 `a`，选择适应度更差且距离最近的 `b`：
  \[
  b=\arg\min_{c:f(c)>f(a)} \|a-c\|.
  \]
- 点对必须满足
  \[
  \|a-b\|\ge 0.005\,S,
  \]
  其中 \(S=\|ub-lb\|\)。不满足的点对丢弃。
- 所有合法点对构成集合 `Pairs`。每个 G2 槽位从 `Pairs` 等概率有放回抽样。若 `Pairs` 为空，所有 G2 槽位回退为标准 GWO 候选。

### 2.2 有方向外推（G2-AFE-Trigger / Always）

\[
y=\operatorname{clip}\left(a+\lambda(a-b)+\epsilon\right)
\]

其中：

- \(\lambda\sim U(0.25,0.75)\)，固定不扫描；
- \(\epsilon_j=0.05\,\frac{\|a-b\|}{\sqrt D}(2u_j-1)\)，\(u_j\sim U(0,1)\)，逐维独立；
- `clip` 到搜索边界。

### 2.3 随机方向对照（G2-AFE-RandomDir）

使用同一个 `a`、同一个 `b`、同一个 \(\lambda\)、同一个 \(\|a-b\|\) 和同一个 \(\epsilon\)，只把方向从 \(a-b\) 换成随机单位向量 \(r/\|r\|\)：

\[
y=\operatorname{clip}\left(a+\lambda\|a-b\|r/\|r\|+\epsilon\right),\quad r\sim N(0,I_D).
\]

由此，方向对照与处理组在触发、点对、步长、噪声和候选池规模上完全一致；唯一差异是方向是否使用档案适应度排序。

### 2.4 触发规则

- `g2AFEAlways=0`：仅当
  \[
  fe-\mathrm{lastGB}\ge 0.05\cdot budget
  \]
  且 `ArcN>=4` 时允许 AFE；
- 任意严格全局最优改善都会重置 `lastGB`，使 AFE 关闭，直到再次停滞后重新启用；
- `g2AFEAlways=1`：忽略停滞条件，只要档案和点对有效就生成 AFE，用来检验“停滞触发”本身的作用；
- 触发不允许改变真实 FE 预算、初始化池、G1/E 公式或接受规则。

## 3. 成功定义与记录

不再用“替换最差狼”作为主要成功信号。每个 G2-AFE 已评价候选记录：

| 指标 | 含义 |
|---|---|
| `G2AFEGlobalImp` | 评价时刷新全局最优 |
| `G2AFEArchiveImp` | 触发档案插入/替换 |
| `G2AFEAccept` | 被接受到种群（严格优于当前最差狼） |
| `G2AFECandidates` | 实际生成的 AFE 候选数 |
| `G2AFEFallbackCandidates` | 因未触发/档案不足/点对无效而回退 GWO 的槽位数 |
| `G2AFEActiveRounds` | 触发条件满足的轮数 |
| `G2AFEPairValidRounds` | 至少有一个合法点对的轮数 |
| `G2AFEStepMean` | 已生成 AFE 候选的平均步长 \(\lambda\|a-b\|\) |
| `G2EvalCount` | 实际获得真实评价的 G2 候选数 |
| `EvalCnt(1..4)` | 四个来源真实评价候选数 |

同时记录 `NovMean`、`NovRate`、`NovelUsefulRate`、`NovelStrictImprove`、`NRecoveredEventual`、`RecoveryEventualProb`、`LongStagShare` 和运行时间。

## 4. P1 开发实验

### 4.1 协议

- CEC2017，D=50。
- 函数（运行前固定）：F3、F5、F8、F12、F17、F20、F23、F30。
- 种子：3111–3120。已扫描当前源仓库、`拯救G2` 和 `codex/g2tr-rescue` 的 97 个 CSV，未发现使用。
- 真实 FE：30,000。
- 种群：N=50，K=10，nG2=12，nE=38，`screenPolicy='random'`。
- 并行：MATLAB local 恰好 4 worker；worker 内不得嵌套并行。
- 输出：`sparse_q/results/g2afe_p1_<timestamp>/`，失败保留。

### 4.2 五个实验臂

| 臂 | 入口 | 唯一变化 |
|---|---|---|
| V1 | `SGWO` | 冻结完整算法对照 |
| A2 | `SGWO_ABLATION`，`ablateG2=1` | G1+E；G2 槽位由 GWO 候选填补 |
| AFE-Trigger | `SGWO_AFE`，`g2AFEAlways=0`，`g2AFERandomDir=0` | 停滞触发的档案前沿外推 |
| AFE-RandomDir | `SGWO_AFE`，`g2AFEAlways=0`，`g2AFERandomDir=1` | 相同触发和步长，方向随机 |
| AFE-Always | `SGWO_AFE`，`g2AFEAlways=1`，`g2AFERandomDir=0` | 不使用停滞触发 |

所有臂共享相同初始化池、真实 FE、M=100、K=10、nG2=12、nE=38 和边界处理。

### 4.3 规模

5 臂 × 8 函数 × 10 种子 = **400 次独立运行**。冒烟测试使用 seed 3995、F3、3,000 FE，不进入统计。

## 5. 晋级门槛（结果出来前冻结）

### H1：AFE-Trigger 相对 A2 有净收益

1. 跨函数中位误差比 \(\rho_1\le 0.98\)；
2. 至少 6/8 个函数更好；
3. 没有任何函数中位误差比大于 1.20；
4. 报告逐函数配对 Wilcoxon signed-rank 和 Holm 校正，但显著性不能替代上述门槛。

### H2：收益来自档案适应度排序方向

AFE-Trigger 必须明确优于 AFE-RandomDir：

1. 跨函数中位误差比 \(\rho_2\le 0.98\)；
2. 至少 6/8 个函数更好；
3. 没有函数退化 >1.20。

如果 Trigger 与 RandomDir 基本持平，只能声称“停滞后外部探索”可能有用，不能声称档案排序提供了有效方向。

### H3：触发不是唯一来源 / 不破坏 V1

1. AFE-Trigger 相对 V1 最终误差中位比 ≤1.00；
2. CheckT20 相对 V1 中位比 ≤1.00，且最多 3/8 个函数 >1.05；
3. AFE-Trigger 平均秒数不超过 A2 的 1.15 倍；
4. 报告 AFE-Always 结果，用于判断“触发 vs 始终开启”的差异。

### H4：机制过程证据

必须报告：

- `G2AFECandidates>0` 且 `G2EvalCount>0`；
- `G2AFEActiveRounds`、`G2AFEPairValidRounds`；
- `G2AFEGlobalImp`、`G2AFEArchiveImp`、`G2AFEAccept`；
- `G2AFEStepMean`；
- 停滞恢复和有用新颖率指标。

### 淘汰规则

- H1 不通过：停止 G2-AFE，不扫描 λ、ε、触发阈值、点对距离。
- H1 通过但 H2 不通过：不能把收益归因于档案排序方向；只能继续研究“停滞后外部探索”，或停止。
- H1、H2、H3 全部通过：才进入正式 29 函数、100k FE、30 个全新种子的确认阶段。
- 无论结果如何，不使用 P1 种子作为最终测试种子，不修改已冻结门槛。

## 6. 预注册时间

本文件在运行 P1 前写入并冻结。冒烟测试只使用 seed 3995、F3、3,000 FE，不进入统计。
