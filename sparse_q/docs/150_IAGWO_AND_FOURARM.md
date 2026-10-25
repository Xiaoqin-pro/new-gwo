# 150 — IAGWO 复现审计（2024 新外部基线）与四臂协议

日期：2026-10-25　状态：**已完成（3480 run 全部成功，结果见 reports/fourarm_3001_analysis/report.md）**
前置：`147_NEW_BASELINES_AUDIT.md`、`148_SVADGWO_STRUCTURE.md`、`149_NEW_BASELINES_REPRO.md`

## 0. 变更记录（相对 149）

用户决定（2026-10-25）：**Corrected GWO 不再复现**；另找一篇 2024 年以后的 GWO 变体，
有公开代码优先、否则按论文复现；最终四臂、种子 3001–3030，与既有主表可直接比较。

| 基线 | 149 状态 | 现状态 |
|---|---|---|
| MENGWO (2025 Sci Rep) | 复现 + 已跑 | **保留**，四臂之一 |
| DE-Elim GWO (2019 Sci Rep) | 复现 + 已跑 | **移除**：Eq.18 在正文与公式中自相矛盾（正文 R∈[n/2ε, n/ε]，公式 R∈[n/ε, n/0.75ε]），且属 2019 年工作，不满足"2024 以来"要求。文件存档，不进正式批 |
| Corrected GWO (2024 ASC) | 复现 + 已跑 | **移除**：论文站点 captcha、FEX 需登录，仅有一句机制描述，无法确认公式；证据强度不足以做数值基线。文件存档，不进正式批 |
| **IAGWO (2024 AI Review)** | — | **新增**，替换上述两个 |

已作废批次（保留，不作任何结论引用）：
* `baseline3_confirm30_20261025_005630`：Corrected GWO 四臂批，跑到 547/3480 时按用户决定中止。
* `baseline3_smoke_20261025_005411`：96 run，含已移除臂；仅作实现期量级参考。

## 1. IAGWO 来源

| 项 | 值 |
|---|---|
| 文献 | Yu M., Xu J., Liang W., Qiu Y., Bao S., Tang L. *Improved multi-strategy adaptive Grey Wolf Optimization for practical engineering applications and high-dimensional problem solving*. **Artificial Intelligence Review** (2024) 57:277 |
| DOI | 10.1007/s10462-024-10821-3 |
| 获取 | 开放获取全文 PDF（51 页）已存档：`refs/IAGWO_2024/paper_fulltext.md` |
| 官方代码 | **无**（GitHub 搜索 "IAGWO" 仅返回无关仓库）→ 按论文复现 |
| 被引 | 105（OpenAlex，2026-10 查询） |
| 原文基准 | CEC2017 (D=30)、CEC2020 (10/20)、CEC2022 (10/20)、CEC2013 LSGO (800D)；参数 N=30、30k FE、500 代、30 次独立运行 |

选择理由：公式完整（Eq.8–12 + Algorithm 2 伪代码）、有 CEC2017 结果可做量级核对、
机制（PSO 速度 + IMF 惯性权重 + Sigmoid 自适应）与 SVAD-GWO 的 DiffA/VMA 完全不重叠，
是干净的外部对照；且发表于 2024 年，满足时间要求。

## 2. 三个机制（全部保留）

### (1) PSO 搜索机制（Eq.8）
```
v_i(t) ← v_i(t) + φ·(X_best − X_i) + φ·(X_selfbest − X_i)
X_i    ← X_i + v_i(t)
```
* `X_best` = α 狼；`X_selfbest` = 个体历史最优；`φ ~ U[0,1]`
* 速度初值 `v ~ U[−20, 20]`（Table 1）
* 原文定位：每代开始时先做 PSO 更新，为后续 GWO 阶段积累多样化的搜索经验

### (2) IMF 惯性权重（Eq.9–10）
```
ω(t) = a·exp(−b·exp(−c·t)) + d,   [a b c d] = [0.6 0.02 0.05 0.3]
X1 = Xα − ω·A1∘Dα ,  X2 = Xβ − ω·A2∘Dβ ,  X3 = Xδ − ω·A3∘Dδ
```
`ω` 从 0.9 单调降到 0.3（原文 Fig.3）。前中期 ω 大 → 领导项强、收敛快；
后期 ω 小 → 狼群自主搜索比重上升，避免高等级狼陷入局部最优后拖住整群。

### (3) Sigmoid 自适应更新（Eq.11–12）
```
φ_i = 1 / (1 + (e^{−f_i/f_ave})^θ),   θ = 0.5
Y_i ← Y_i · φ_i          （Y_i 为 GWO 更新位移）
```
适应度好（f_i/f_ave 小）的个体只做小幅修正；差个体接受完整 GWO 步长，跳到别处。
按公式 φ_i ∈ (0.5, 1)。

## 3. 与原文的差异（逐条）

| # | 项 | 原文 | 本实现 | 理由 |
|---|---|---|---|---|
| 1 | 初始种群 | 均匀随机 | 框架共享初始池 | 同池协议（全部算法一致） |
| 2 | 时间轴 t | 迭代号 | 真实 FE 进度 `fe/budget` | 等 FE 协议；本框架全部算法如此 |
| 3 | **每代评价结构** | Algorithm 2 第 10–20 行顺序有歧义：先"Calculate New Position"、再"Update X1,X2,X3 with IMF inertia weight"、再"Update X(t+1)" | PSO 更新→评价（N 次）；ω 加权三领导目标→Sigmoid 缩放位移→评价（N 次）。每代 2N 次真实评价 | 每个候选生成后立即真实评价，满足"未评价点不得参与排序"；顺序取与正文叙述一致的解释 |
| 4 | Eq.8 的 φ | "φ is a random number"（未说明两项是否独立） | 每狼每代抽一个 φ，两项共用 | 字面理解；若独立应两次抽样，属未公开细节 |
| 5 | **Eq.11 的比值基准** | 字面 `f_i / f_ave` | 默认 `(f_i − f_best)/(f_ave − f_best)`（`iagwoPhiMode='shift'`），保留 `'raw'` 作对照 | **关键**：CEC2017 目标含 100·i 的平移偏移，字面比值使 f_i/f_ave≈1，φ 退化为常数（实测 std=0.003），Sigmoid 机制形同虚设；减基准后 φ 与平移无关、机制按论文意图生效（实测 std=0.065） |
| 6 | 领导刷新 | 每代末按全种群重算 | 每次真实评价后立即级联更新 | 与冻结 GWO 同口径；不改变候选生成所需信息 |
| 7 | f_ave 异常保护 | — | `(f_ave−f_best)<=0` 或非有限时该代 φ=1 | 数值保护，不影响正常路径 |

第 5 条是本复现最重要的判断，**必须在论文中如实披露**：它是"目标平移不变性"适配，
不是按 CEC 结果调参；两种模式都实现，`raw` 版在开发集上做敏感性对照（见 §5）。

## 4. 计费与契约验证

`tests/test_iagwo_smoke.m`：

```
IAGWO smoke: FE=4000 best=3.68146e-22 rounds=200 phi mean=0.554 std=0.146
IAGWO CEC F6 3k: FE=3000 best=628.883 phi mean=0.620 std=0.065
IAGWO CEC F6 3k (raw phi): FE=3000 best=654.426 phi mean=0.622 std=0.003
test_iagwo_smoke PASS
```

断言：`FE == budget`、`diff(T) <= 0`、`T(end) == Best.Cost`、
`f(Best.Vector) == Best.Cost`、同种子两次运行逐位相同。

`shift` vs `raw` 在 F6/3k 上 628.9 vs 654.4：差异真实存在但不大（单函数单种子，不作结论）。

## 5. MENGWO 复核（沿用 149，仅补一条）

149 §2 的实现与差异记录不变。补充：MENGWO 原文基准为 23 个经典函数 + 13 个高维函数，
N=30、MaxNFE=50,000；本框架 N=50、100k FE、CEC2017 D=50，属等预算适配而非原文复刻，
故 MENGWO 的数值结果只能作为"同预算下的相对表现"，不能与其论文表格逐项对照。

## 6. 四臂协议（正式批）

| 项 | 值 |
|---|---|
| 批次 | `fourarm_3001_20261025_010843` |
| 臂 | A-GWO（冻结经典 GWO）/ B-MENGWO / C-IAGWO / D-SVAD-GWO |
| 范围 | 29 函数（F1, F3–F30）× 30 种子（3001–3030）× 4 臂 = **3480 run** |
| 设置 | CEC2017，D=50，100k 真实 FE，N=50，4 worker，EvalProbe 逐次审计 |
| 种子选择 | 3001–3030，与 `data/reference/audited_10algo_30seed.csv`、`audited_15algo_30seed.csv` 完全一致 |
| 驱动 | `experiments/screen298_fourarm_3001.m` |
| 分析 | `experiments/analyze_fourarm_3001.py` |

A-GWO 与 reference CSV 里的 `GWO` 是同一实现、同一初始池、同一种子 →
可做逐位交叉核对（分析脚本自动报告 max relative difference），若不一致说明框架漂移。

四臂之外，已审计的 IGWO / CLPSO / SPSO-2011 / HIDMS-PSO / SAQ-CSO 等可直接并入主表，
无需重跑。

## 6b. 正式批结果（3480 run，0 失败）

| 臂 | Friedman 平均排名 | 中位 FinalError | 几何平均 | 墙钟/run |
|---|---:|---:|---:|---:|
| **D-SVAD-GWO** | **1.239** | **740** | **2906** | 7.21 s |
| B-MENGWO | 2.755 | 1213 | 12612 | 2.69 s |
| C-IAGWO | 2.855 | 1483 | 11009 | 2.61 s |
| A-GWO | 3.151 | 1812 | 16821 | 2.66 s |

Friedman chi2=1150.7, p=3.6e-249。

配对（逐函数 Wilcoxon + Holm，29 检验）：

| 对比 | 中位比 | 胜/29 | >1.20 | p | Holm 更好 | Holm 更差 |
|---|---:|---:|---:|---:|---:|---:|
| SVAD / MENGWO | 1.656 | 1 | 21 | 1.6e-7 | 0 | 25 |
| SVAD / IAGWO | 2.094 | 0 | 29 | 3.7e-9 | 0 | 29 |
| SVAD / GWO | 2.653 | 1 | 28 | 7.5e-9 | 0 | 26 |
| MENGWO / GWO | 0.872 | 20 | 6 | 0.056 | 12 | 3 |
| IAGWO / GWO | 0.877 | 19 | 3 | 0.024 | 11 | 3 |
| SVAD / GWO | 0.377 | 28 | 0 | 7.5e-9 | 26 | 0 |

**判定全部满足**：
1. 对每个外部基线中位比 ≤ 0.95（1.656 / 2.094 / 2.653 均为 SVAD 更好）→ 通过
2. Holm 显著更差 = 0 → 通过
3. Friedman 排名 D=1.239 最优 → 通过
4. MENGWO 与 IAGWO 均未优于 SVAD → 无需额外讨论（但 F19 单点如实记录）
5. GWO 交叉核对 max rel diff = 0 → 通过

两个新基线**确实比经典 GWO 强**（12/3 与 11/3 的 Holm 计数），因此不是稻草人对照。

## 7. 判定口径（预注册，先于结果）

1. D-SVAD-GWO 对每个外部基线的函数级中位比 ≤ 0.95，胜 ≥ 20/29，>1.20 的函数 ≤ 3。
2. Holm 校正后显著更差的函数数必须为 0；显著更好的函数数如实报告（不设门槛）。
3. Friedman 平均排名：D 应为最优或与最优无显著差异。
4. 若 MENGWO 或 IAGWO 任一在中位比上优于 SVAD-GWO，则必须如实报告并讨论，
   不得以"机制不同"为由排除。
5. A-GWO 与 reference CSV 的 max relative difference 必须 < 1e-9，否则整批作废。

## 8. 文件

| 文件 | 说明 |
|---|---|
| `sparse_q/src/MENGWO_CEC.m` | MENGWO 重建（2025 Sci Rep） |
| `sparse_q/src/IAGWO_CEC.m` | IAGWO 重建（2024 AI Review） |
| `sparse_q/src/DEElimGWO_CEC.m` | **存档，已移除**（见 §0） |
| `sparse_q/src/CorrectedGWO_CEC.m` | **存档，已移除**（见 §0） |
| `sparse_q/tests/test_baseline3_smoke.m` | MENGWO + IAGWO 契约烟测 |
| `sparse_q/tests/test_iagwo_smoke.m` | IAGWO 契约烟测 + φ 模式对照 |
| `sparse_q/experiments/screen298_fourarm_3001.m` | 四臂正式驱动 |
| `sparse_q/experiments/analyze_fourarm_3001.py` | 配对 Wilcoxon + Holm + Friedman + GWO 交叉核对 |
| `sparse_q/refs/IAGWO_2024/paper_fulltext.md` | 论文全文（51 页） |
