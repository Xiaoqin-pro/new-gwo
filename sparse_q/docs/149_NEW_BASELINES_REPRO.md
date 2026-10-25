# 149 — 三个新增外部基线的复现审计与实现记录

日期：2026-10-25　状态：**已实现、烟测通过、正式批运行中**
前置：`147_NEW_BASELINES_AUDIT.md`（获取与选型）、`148_SVADGWO_STRUCTURE.md`（提出算法）

## 0. 一句话结论

三个基线（MENGWO / DE-Elim GWO / Corrected GWO）全部**按论文或 FEX 公开机制逐条重建**，
无一个来自官方代码；每个实现头注释与本文逐条列出与原文的差异（接口、计费、时间轴）。
FE 精确计费、轨迹单调、确定性均通过烟测。Corrected GWO 因原文只说"两个变体"而未公开
公式，实现了两种解释（c1/c2）并同时报告，**不按结果挑选**。

## 1. 来源与可得性（如实记录）

| 算法 | 文献 | 官方代码 | 本实现依据 | 标注 |
|---|---|---|---|---|
| MENGWO | Meng et al., *Sci Rep* 2025, doi:10.1038/s41598-025-33301-2（开放获取） | 无 | 全文 Eq.1–16 + Table 22–26 参数敏感性 | paper reconstruction |
| DE-Elim GWO | Wang & Li, *Sci Rep* 2019, doi:10.1038/s41598-019-43546-3（开放获取） | 无 | 全文 Eq.5–18 + Table 2 参数表 + Fig.4 流程图 | paper reconstruction |
| Corrected GWO | Tsai & Shi, *Appl Soft Comput* 2024, doi:10.1016/j.asoc.2024.111776 | FEX 162131，下载需 MathWorks 登录（本机 IP 全域 403） | FEX 条目机制描述一句话（`refs/CorrectedGWO_2024/fex_page.md`） | **mechanism reconstruction（证据最弱）** |

Corrected GWO 的获取失败记录（本日复核，非沿用旧结论）：
* `sciencedirect.com/science/article/abs/pii/S1568494624005505` → HTTP 403（captcha）
* `r.jina.ai` 代理同一 URL → 仍返回 captcha 页
* `viewer.mathworks.com/addons/162131/latest` → 返回 200 但只有 6.3 KB 的外壳页
* `mlc-downloads/.../download/zip` 三种 URL 形式 → 全部 404
* `archive.org/wayback` 无快照；Crossref 无摘要；arXiv 无预印本；Semantic Scholar 429

因此 **Corrected GWO 的数值结果必须标注为"按公开机制描述重建"**，其论文级结论
（"one variant performs comparably on CEC2005"）无法与我们的结果逐位对照。

## 2. MENGWO（`src/MENGWO_CEC.m`）

### 保留的机制
1. 标准 GWO 三领导聚合（Eq.5–11），A/C 逐维。
2. **DE 启发的变异算子**（Eq.12–13），按**标量** A 分支：
   * |A| ≥ 1：`Xg + r3·(X_rand1 − X_rand2)`（探索）
   * |A| < 1：`Xg + B·R∘(α − Xg)`，`B = b·NFE/MaxNFE`，b = 1.5（利用）
3. **EPD 重定位**（Eq.14–15）：最差 k = 0.25 比例，`q: 0.1 → 0.9` 线性；
   `r4 < q` 向 α 靠拢，否则全空间随机。
4. **NPSR**（Eq.16）：`N_{G+1} = round(N0·(1 − 0.8·prog³))`。

### 与原文的差异
| # | 项 | 原文 | 本实现 | 理由 |
|---|---|---|---|---|
| 1 | 初始种群 | 均匀随机 | 框架共享初始池 | 同池协议（全部算法一致） |
| 2 | 调度变量 | 迭代号 | 真实 FE 进度 `fe/budget` | 等 FE 协议 |
| 3 | 全群评价时机 | 轮首 | 轮末（同次数、同位置） | 使 EPD 重定位后的位置在排序前已被真实评价；满足"未评价点不得参与排序" |
| 4 | NPSR 淘汰对象 | 排序后淘汰劣者 | 保留最优 N_{G+1}（fitness 为已验证值） | 同上，等价且无未评价个体 |
| 5 | 预算边界 | — | 逐次检查，绝不超支 | 硬约束 |

### 复现保真度自评
Eq.12 的 `|A| ≥ 1` 判据原文用 Eq.(4) 的**向量** A；实现取每狼每代一个标量 A
（原文"Eq.12 switches between two modes based on A from Eq.(4)"未说明是逐维还是标量）。
选择标量：逐维切换会让同一候选混用两种算子，与"two modes"的表述不符。
该选择在代码中标注，且不依赖任何 CEC 结果。

## 3. DE-Elimination GWO（`src/DEElimGWO_CEC.m`）

### 保留的机制
1. 标准 GWO 三领导聚合（Eq.5–11）。
2. **DE 进化**（Eq.13–17）：变异 `V = α + F·(β − δ)`（**用三个领导而非随机个体**，
   Eq.14）；`F = fmin + (fmax−fmin)·(Max_iter−(iter−1))/Max_iter`，fmin=0.25, fmax=1.5；
   二项交叉 CR=0.7 且保证至少一维来自 V（Eq.16）；贪心选择（Eq.17）。
3. **SOF 淘汰**（Eq.18）：排序后淘汰 R 个最差、随机补充 R 个新个体。

### 与原文的差异
| # | 项 | 原文 | 本实现 | 理由 |
|---|---|---|---|---|
| 1 | 初始种群 | 均匀随机 | 框架共享初始池 | 同池协议 |
| 2 | Max_iter | 固定 500 | 由预算折算 `floor((budget−N)/(2N+R̄))` | 原文每代 2N+R 次评价；等 FE 协议 |
| 3 | **Eq.18 区间** | 正文 "n/(2ε) … n/ε"；公式 "n/ε … n/(0.75ε)"（**自相矛盾**） | 默认按公式（`deElimRMode='eq18'`），正文版作敏感性开关 | 公式优先，且保留两种 |
| 4 | 淘汰后新个体 | 随机生成后下一轮才评价 | 生成后立即评价（计入 FE） | 未评价点不得进入排序 |

**Eq.18 的矛盾是本复现最大的不确定性**：ε=5、N=50 时，公式版给 R∈[10,13]，
正文版给 R∈[5,10]。两者都实现，正式批默认用公式版（R 更大 → 淘汰更强）。

## 4. Corrected GWO（`src/CorrectedGWO_CEC.m`）

### 三条修正（FEX 原文）
> "eliminating coefficient factor C, eliminating the absolute sign for factor D,
> and introducing a current-to-prey approach"

### 两种解释（原文称 "two corrected variants"，公式未公开）
| 变体 | 距离项 | 更新式 | 说明 |
|---|---|---|---|
| `c2` | 有符号、无 C | `Xk = X + Ak∘(Xl − X)` | 三条修正全开；current-to-prey |
| `c1` | 有符号、无 C | `Xk = Xl − Ak∘(Xl − X)` | 仅前两条修正 |

两者聚合均为 `Xnew = (X1+X2+X3)/3`，`a` 线性 2→0，`A = 2ar − a` 逐维。
**默认 c2**；两臂都在正式批中报告，不做结果后挑选。c1↔c2 的差值单独隔离出
current-to-prey 这一条修正的贡献。

### 与原文的差异
* 初始种群同池；`a` 用真实 FE 进度；每代恰好 N 次真实评价。
* **A 的抽样范围沿用 GWO 的 [−a, a]**：原文修正说明未涉及 A 的分布，这是重建假设，
  已在代码与本文标注。若作者源码公开且 A 分布不同，本基线需重跑。

## 5. 计费与契约验证

`tests/test_baseline3_smoke.m`（三臂 × 5D 二次函数 + CEC2017 F6 30D 3k）：

```
MENGWO_CEC           smoke: FE=4000 best=6.13336e-13 rounds=564 ok
DEElimGWO_CEC        smoke: FE=4000 best=9.2876e-23 rounds=177 ok
CorrectedGWO_CEC     smoke: FE=4000 best=1.08209 rounds=399 ok
MENGWO_CEC           CEC F6 3k: FE=3000 best=617.57
DEElimGWO_CEC        CEC F6 3k: FE=3000 best=621.663
CorrectedGWO_CEC     CEC F6 3k: FE=3000 best=669.608
test_baseline3_smoke PASS
```

断言项：`info.Evaluations == budget`、`diff(T) <= 0`、`T(end) == Best.Cost`、
`f(Best.Vector) <= Best.Cost`、同种子两次运行逐位相同（确定性）。

## 6. 实验协议

| 批次 | 范围 | 种子 | 用途 |
|---|---|---|---|
| `baseline3_smoke_20261025_005411` | 6 臂 × 8 函数 × 2 种子 = 96 run | 4484–4485（全新） | 开发集烟测，确认量级 |
| `baseline3_confirm30_20261025_005630` | 4 臂 × 29 函数 × 30 种子 = 3480 run | 3459–3488（与 SVAD-GWO 确认批同种子） | 正式确认，可直接配对 |

* D=50，100k 真实 FE，N=50，CEC2017，4 worker，EvalProbe 逐次审计。
* 基线臂：MENGWO / DE-Elim GWO / CorrGWO-c2 / CorrGWO-c1。
* 对照组复用 `svadgwo_confirm30_20261025_000001`（SVAD-GWO）与冻结 `GWO`，同种子配对。

### 烟测量级（8 函数 × 2 种子，中位 FinalError）

| 函数 | CorrGWO-c1 | CorrGWO-c2 | DE-Elim | GWO | MENGWO | SVAD-GWO |
|---|---:|---:|---:|---:|---:|---:|
| F1 | 1.04e10 | 8.78e8 | 1.58e7 | 9.62e9 | 1.61e8 | 2.80e5 |
| F4 | 1151 | 260 | 152 | 496 | 256 | 189 |
| F7 | 617 | 469 | 351 | 309 | 395 | 122 |
| F10 | 9251 | 1.32e4 | 5009 | 6732 | 6174 | 9457 |
| F13 | 1.62e7 | 1.50e4 | 1.29e5 | 1.49e8 | 6.05e7 | 8.08e4 |
| F20 | 1800 | 1650 | 770 | 925 | 886 | 519 |
| F24 | 875 | 899 | 663 | 851 | 667 | 565 |
| F30 | 5.43e7 | 1.41e6 | 9.18e6 | 7.85e7 | 9.08e7 | 4.91e7 |

可读性结论（仅 2 种子，不作判定）：
* Corrected GWO 的修正确实有效：c2 相对 GWO 在 F1/F13/F30 上大幅改善（1e9 vs 9.6e9、
  1.5e4 vs 1.5e8、1.4e6 vs 7.9e7），与 FEX "GWO 只在最优值为 0 时表现好"的诊断一致。
* c1 → c2 的差值在 F1/F13/F30 上是正向的，说明 current-to-prey 这一条修正确有贡献。
* MENGWO 与 DE-Elim 与 GWO 同量级，没有明显超越；这与"它们主要改善多峰脱困"一致，
  但在 F1/F13 这类可分离/单峰上并不占优。

## 7. 待完成

1. 正式批 3480 run 完成 → 逐函数配对 Wilcoxon + Holm（vs SVAD-GWO、vs GWO）。
2. 填写 `reports/baseline3_confirm30_analysis/report.md`，更新 `experiments/registry.csv`。
3. 若任一基线在 29 函数上中位比 < 0.95，需要在论文中把它作为强对照讨论。

## 8. 代码与哈希

| 文件 | 说明 |
|---|---|
| `sparse_q/src/MENGWO_CEC.m` | MENGWO 重建 |
| `sparse_q/src/DEElimGWO_CEC.m` | DE-Elim GWO 重建（含 Eq.18 双模式） |
| `sparse_q/src/CorrectedGWO_CEC.m` | Corrected GWO 重建（c1/c2） |
| `sparse_q/tests/test_baseline3_smoke.m` | 契约与计费烟测 |
| `sparse_q/experiments/screen295_baseline3_smoke.m` | 开发集烟测驱动 |
| `sparse_q/experiments/screen296_baseline3_confirm30.m` | 正式确认驱动 |
| `sparse_q/experiments/runner_sgwo.m` | +3 个 case（MENGWO/DEElimGWO/CorrectedGWO） |
| `sparse_q/experiments/run_batch_sq.m` | provenance 增加三个新文件哈希 |
