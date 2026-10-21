# 25. ENAC 被动诊断预注册

## 0. 目的

在决定是否实现 ENAC 之前，先用不改变算法行为的被动日志检查三个问题：

1. 档案中心被替换后，是否仍有候选把信用反馈记到错误的新中心；
2. 近距离替换 `Arc(ni,:)=y` 时，旧信用是否被错误继承；
3. 当前 `1+累计成功次数` 权重是否造成明显的中心抽样集中或曝光偏差。

如果 P0 证明这些问题很少发生，或者曝光偏差不严重，则直接停止 ENAC，保留冻结 V1 并结束算法开发。

## 1. 诊断对象

冻结 `SGWO.m` 的行为完全不变。新增独立文件 `SGWO_ENAC_AUDIT.m`，只增加身份、曝光和信用日志。

### 1.1 中心身份

- 每个真实档案中心分配唯一 `ArcID`；
- 新插入、远距离替换、近距离替换都分配新 ID；
- 不重置冻结版本的 `ArcCred`，以保持行为逐位一致；
- 候选记录生成时的父中心 ID，而不是只记录槽位索引。

### 1.2 错配事件

对每个被真实评价的 E 候选，记录：

- `StaleFeedbackEvents`：生成时的父中心 ID 在评价时已不存在；
- `SlotReassignedEvents`：旧代码将要更新的槽位 `ctr(j)` 现在对应另一个 ID；
- `WrongUpdateEvents`：候选成功且旧代码会更新错误槽位；
- `SecondParentMissingEvents`：双中心线段候选未更新第二父中心（仅记录，不作为晋级门槛）。

### 1.3 信用泄漏

在近距离替换路径 `elseif v<Arcv(ni)` 中，冻结代码保留 `ArcCred(ni)`。记录：

- `LeakEvents`：被替换槽位的旧信用大于 0；
- `LeakTotal`：被替换槽位的旧信用总和；
- `NearReplacements`、`FarReplacements`；
- `LeakEventRate = LeakEvents / NearReplacements`；
- `LeakCreditRate = LeakTotal / TotalCreditIncrements`。

### 1.4 抽样权重与曝光偏差

每一轮计算当前单中心抽样权重：

\[
w_i=1+C_i,\qquad p_i=w_i/\sum_j w_j
\]

记录：

- `TopShare = max(p_i)`；
- `TopRatio = TopShare / (1/ArcN)`；
- `WeightEntropy = -\sum p_i \log p_i / \log(ArcN)`；
- ENAC 对照权重：
  \[
  \hat p_i=\frac{s_i+1}{n_i+2},\qquad w_i^{ENAC}=1/ArcN+\hat p_i
  \]
  其中 \(n_i\) 是该中心真实评价候选数，\(s_i\) 是 `recImp || arcImp` 次数；
- `ENACTopShare`；
- `SpearmanCreditPhat`：当前仍存在且 \(n_i\ge5\) 的中心上，累计信用 \(C_i\) 与 \(\hat p_i\) 的 Spearman 相关。

### 1.5 E 路线有效改善

记录：

- `EImpPer1000FE = ImpCnt(3)/(budget/1000)`；
- `EEvalCount`、`EImpCnt`、`EAnySuccessCount`、`EAnySuccessRate`；
- 这些仅用于解释，不改变算法。

## 2. P0 运行设计

- CEC2017，D=50；
- 函数：F7、F10、F13、F16、F18、F22、F24、F30；
- 种子：3161–3165，运行前扫描未使用；
- 真实 FE：30,000；
- MATLAB local 4 worker；
- 单臂 `SGWO_ENAC_AUDIT`，8 函数 × 5 种子 = **40 次运行**；
- 每次运行与冻结 `SGWO` 逐位一致；
- 冒烟：F7、seed 3989、3,000 FE。

## 3. P0 判定规则（运行前冻结）

### 3.1 身份错配是否严重

满足任一条件即视为身份问题 material：

- `SlotReassignedRate = WrongUpdateEvents / ESuccessUpdates >= 0.01`；
- 或 `StaleFeedbackRate = StaleFeedbackEvents / EEvalWithParent >= 0.01`。

### 3.2 信用泄漏是否严重

满足任一条件即视为信用泄漏 material：

- `LeakEventRate >= 0.05`；
- 或 `LeakCreditRate >= 0.05`。

### 3.3 曝光偏差是否严重

满足任一条件即视为曝光偏差 material：

- `SpearmanCreditPhat < 0.50`；
- 或 `MeanTopRatio >= 2.0`；
- 或 `MeanWeightEntropy < 0.50`。

### 3.4 是否进入 P1

- 三类问题中至少 **两类** material：允许进入 ENAC P1；
- 少于两类：停止 ENAC，保留冻结 V1，算法开发结束；
- 不根据单个函数的偶然结果改变门槛。

## 4. 如果进入 P1

只有当 P0 判定进入 P1 时，才执行：

- 3 臂：V1-Frozen、Identity-Credit、ENAC；
- 8 函数 × 10 全新种子 × 3 臂 = 240 次运行；
- 种子：3151–3160；
- D=50，30,000 FE，MATLAB local 4 worker；
- 运行时间对照 matched A3-Off；
- 晋级门槛：
  - ENAC / V1 中位误差比 ≤0.98；
  - 至少 6/8 函数获胜；
  - 无函数退化 >1.20；
  - 运行时间 ≤1.15；
  - ENAC 相对 Identity-Credit 必须证明成功率归一化有独立贡献。
- 不扫描平滑参数、历史窗口或衰减系数。

## 5. 如果 P0 判定不进入 P1

直接停止 ENAC：

- 不实现 Identity-Credit 或 ENAC 的性能版本；
- 不运行 240 次正式筛选；
- 保留 P0 被动日志作为审计证据；
- 论文继续使用冻结 V1 的“稀疏评价 + 多区域档案”主线；
- 算法开发结束，除非出现全新的、与现有档案信用无关的问题。

## 附录：正式 P1 前的实现修正（2026-10-21）

第一版 `SGWO_ENAC.m` 在被动审计块和 ENAC 信用块中重复增加了 `centerEval/centerSucc`，导致 Beta(1,1) 平滑的曝光量被重复计数。对应的 `enac_p1_20261021_022454` 批次不作为最终结果使用。

清理版 `SGWO_ENAC.m`：

- 移除 P0 专用审计日志和 131072 长度数组；
- 每个被评价候选只更新一次中心曝光；
- `enacOn=0` 仍然与冻结 `SGWO.m` 逐位一致；
- 机制定义、Beta(1,1) 平滑、权重公式、候选池和 FE 预算均未改变。

最终 P1 使用清理版 `enac_p1_20261021_023237` 与 `enac_a3offc_20261021_023511`。
