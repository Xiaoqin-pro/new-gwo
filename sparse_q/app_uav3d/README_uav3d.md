# 三维无人机配送路径规划应用（文章应用部分）

来源：从 `D:\111\Desktop\噜噜\9.29`（archive/legacy 的 benchmark-v1 工程）整理搬运，
用于 VAST-GWO 论文的工程应用章节。**五张地图均为"带硬时间窗"的三维配送场景。**

## 1. 场景与数据

* 五张真实地形（Copernicus DEM GLO-90 DSM，AWS 公开 2021 版）：
  `ridge`（山脊沟谷）、`peaks`（多峰起伏）、`mountain`（山地区）、`hills`（丘陵）、`plateau`（高原）。
* 每张地图一套 N20 场景：20 个配送站 + **硬时间窗**（ready/due），按固定空间参考路线分 5 个
  时间带（带内顺序可变、带间有先后约束）；数据：`data/map_scenarios_v6/N20_<map>.csv`。
* 三维圆柱威胁区：`data/threat_zones.csv`（3 个）。
* 地形元数据与可复算哈希：`data/terrain_manifest.json`、`data/scenario_manifest_v6.json`；
  地形栅格原始 tif（5×5.5MB）留在 9.29 原目录，不随仓库分发；`.mat`（51×51 数值地形）已随仓库。

## 2. 优化模型（benchmark-v1，参数与 legacy main.m 一致）

| 项 | 值 |
|---|---|
| 决策变量 | 每航段 3 个中间控制点（lambda、横向偏移、高度偏移），D = N + 3(N+1)·3 = **209**（N=20） |
| 搜索空间 | [0,1]^209（解码为物理量；解码/约束/目标全部在 `Fitness.m`） |
| 目标 | 三维航程 + 等待 + 平滑度（罚项） |
| 约束 | 迟到、返仓超时、地形/障碍碰撞、净空、越界、爬升角 ≤35°、转弯角 ≤120° |
| 参数 | speed=10, serviceHeight=16, minClearance=4, maxAltitude=42, 偏移 ≤4, depot 窗 [0,360] |

## 3. 实验协议（与 9.29 冻结协议一致）

* 种群 **50（预注册 D1 决定；与 CEC 冻结版一致）**，真实适应度预算 **30,000 FE/次**；
  初始化评价计入预算；结束后复算 1 次单独记录。
* 同一 (地图, 重复) 下所有算法共享同一初始种群：`rng(seed); rand(50,209)`，
  seed = 20271004 + 100·ceil(case/2) + repeat；搜索随机流 = seed + 100000。
* 重复编号：开发 `1:3`；正式 `101:130`（各 30 种子）。
* 指标：先比**可行率**与**首次可行 FE**，再在可行运行间比距离/等待/平滑度；收敛曲线标注为罚项 Cost。

## 4. 本目录文件

```
CreateModel.m / Fitness.m / PlotSolution.m   模型与绘图（自 9.29 legacy 原样搬运）
data/                                        五张地图 .mat + N20 场景 CSV + 威胁区 + 清单
uav_cfg.m                                    标准配置（路径全部相对本目录）
uav_fitness_tracker.m                        适应度包装（真实 FE/可行轨迹/首次可行 FE）
uav_run_one.m                                单次运行（我们算法的接口适配 + 记录）
uav_runner.m / uav_batch.m                   4-worker 批处理（runBatch4；断点续跑）
smoke_uav.m                                  七算法 × 3000FE 功能烟测
ref_legacy/                                  9.29 原版算法与 main.m（对照保存，不参与运行）
```

算法接口适配：我们的算法均为 `[Best,T,info]=ALG(f,state,~,N,seed)`；
`uav_run_one` 将位置域设为 [0,1]^D 并把 `Fitness` 包成 `f`，FE 精确计费（断言 == 预算）。
**正式对比集（已冻结）**：`{'VAST-GWO','GWO','IGWO','HAGWO','PSO','CLPSO'}`（六臂，N=50）；
应用章节不做消融（机制归因见 CEC 章节）。备用预设 VAST-N60 / VAST-A0 保留在代码中，不进入正式档。

## 4b. 预注册配置与审计（2026-10-17 增补）

* **VAST 配置显式化**（`uav_run_one.m` 预设）：`VAST-GWO` = N=50、G1/G2/E=**50/12/38**、
  K=10（与 CEC 冻结版逐参数一致，推荐）；`VAST-N60` = 60/14/46（比例缩放备选）；
  `VAST-A0` = 关闭 G2/E 的 GWO-only 稀疏池（消融预设；**用户决定：不进 UAV 正式档**，
  机制归因以 CEC 消融章节为准，该预设保留备用）。
* **严格 FE 审计**：`uav_fitness_tracker` 拒绝预算外调用；`uav_run_one` 断言
  `trk.feCount == maxEval`（与 CEC 探针同标准）。
* **五图可行解见证**：`data/witness/witness_v1.mat`（GWO@10k FE；mountain/plateau 升到
  30k；含 209 维决策向量与全部指标）；`verify_witness.m` 用本目录代码独立重算并逐项
  比对（已通过：五图 cost/可行/距离全部一致）。生成脚本：`make_witness.m`。
  旧实例记录 `legacy_v3_tight/` 与 `v6_*_witness.csv` 仅存档（属不同参数版本）。
* **评价加速（P1）**：`FitnessFast.m` = `Fitness.m` 的逐行等价版本（唯一改动：
  每条航段的 `interp2` → 预建 `griddedInterpolant`，`prepare_model_fast` 一次构建）。
  **等价审计** `audit_fitness_fast.m`：五图 4010 例（随机/见证±1e-3/边界/端点）
  `maxCostRel = 0`（逐位一致）、GWO-1000FE 轨迹 maxdiff = 0。搜索路径改用
  FitnessFast，末态复核仍用完整 `Fitness`（1e-12 断言）。单线程 8.87→3.39 ms/评价
  （**2.62×**）；4-worker 实测 711 evals/s → 正式档 900 次×30k FE ≈ **10.6 h**。
* **实验规划**：见 `PLAN_uav3d.md`（三条可证伪假设、三层指标、统计口径、阶段与时间预算）。

## 5. 运行

```matlab
cd sparse_q\app_uav3d
smoke_uav                                  % 烟测（约 3-4 分钟）
uav_batch()                                % 默认：6 算法 × 5 地图 × 101:130 × N=50 × 30k
uav_batch({'VAST-GWO','GWO','PSO'},1:5,101:110)   % 自定义算法集/地图/种子
out=uav_batch(...); writetable(out.runs,'raw_runs.csv')  % 自动写 raw_runs.csv
```

* 同一 `outDir` 重新调用 `uav_batch` 即**断点续跑**（只补缺失/失败作业）。
* 全部作业经 `overnight.runBatch4`：**恰好 4 worker**，逐作业原子落盘。

## 6. 运行时间实测（本机，MATLAB R2025b）

* 适应度 ≈ **9–10 ms/次**（209 维解码 + 逐段碰撞/约束检查）→ 3,000 FE ≈ 26–30 s/次。
* 外推：**30,000 FE ≈ 4.5 min/次**；4 worker 下：
  * 6 算法 × 5 地图 × 30 种子 = **900 次**（实测 7.5 h，含每次建模；中位 114 s/次）；
  * 5 算法 × 5 地图 × 30 种子 = 750 次 ≈ **14 h**；
  * 开发档 7 × 5 × 3 种子 = 105 次 ≈ **2 h**。
* 建议按"开发档 → 冻结 → 正式档"顺序执行；如须压缩，优先缩减算法集或种子数，
  不要动协议参数（N=50/30k）以保持与预注册协议可比。


## 7. 正式结果（2026-10-18，900/900 ok，0 failed）

完整统计见 `../../results/uav_formal_N50_30k/analysis_report.txt`（v2 修订版：
首次可行 FE 采用 **30k 截尾** RMST/有序配对，不剔除失败运行）。

| 算法 | 可行率 | RMST(FE) [95%CI] | 首次可行FE中位* | 可行Cost中位 | 罚项中位 |
|---|---:|---|---:|---:|---:|
| **VAST-GWO** | **100%** | **7062 [6449,7731]** | 6314 | 667.4 | 667.4 |
| HAGWO | 97.3% | 8133 [7355,8950] | 7432 | 663.4 | 666.9 |
| PSO | 95.3% | 8138 [7058,9324] | 5357 | 766.4 | 772.9 |
| IGWO | 97.3% | 12270 [11374,13179] | 11152 | 724.7 | 728.4 |
| GWO | 94.0% | 10936 [9941,11983] | 8920 | 699.8 | 701.7 |
| CLPSO | 61.3% | 24427 [23312,25383] | 21330 | 1015.4 | 1099.4 |

*有条件口径（仅成功运行），仅作对照；主证据为 RMST 与累计可行率 + McNemar。

配对检验（150 对；Holm 跨 5 基线）：最终 Cost 对全部基线显著更优
（GWO 3.8e-4 / IGWO 2.9e-12 / HAGWO 0.0458 / PSO 8.2e-20 / CLPSO 3.3e-16）；
McNemar 可行性显著优于 GWO/PSO/CLPSO；截尾有序配对显著早于 GWO/IGWO/HAGWO/CLPSO
（对 PSO p=0.598，时间-可行性相当，但 PSO 最终质量更差）。

图：`figures/feasibility_curve.png`（累计可行率）、`rmst_bar.png`（RMST）、
`final_cost_box.png`（可行 Cost 箱线，与表中 `CkptBestFeasCost_5` 逐位一致）、
`first_feasible_ecdf.png`（有条件补充图）。
