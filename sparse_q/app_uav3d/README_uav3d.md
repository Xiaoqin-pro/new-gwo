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

* 种群 60，真实适应度预算 **30,000 FE/次**；初始化评价计入预算；结束后复算 1 次单独记录。
* 同一 (地图, 重复) 下所有算法共享同一初始种群：`rng(seed); rand(60,209)`，
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
**对比算法集可配置**（默认 `{'VAST-GWO','GWO','IGWO','PSO','CLPSO','HAGWO','AOGWO'}`，
不必与 CEC 主表相同）。

## 4b. 预注册配置与审计（2026-10-17 增补）

* **VAST 配置显式化**（`uav_run_one.m` 预设）：`VAST-GWO` = N=50、G1/G2/E=**50/12/38**、
  K=10（与 CEC 冻结版逐参数一致，推荐）；`VAST-N60` = 60/14/46（比例缩放备选）；
  `VAST-A0` = 关闭 G2/E 的 GWO-only 稀疏池（机制对照臂）。
* **严格 FE 审计**：`uav_fitness_tracker` 拒绝预算外调用；`uav_run_one` 断言
  `trk.feCount == maxEval`（与 CEC 探针同标准）。
* **五图可行解见证**：`data/witness/witness_v1.mat`（GWO@10k FE；mountain/plateau 升到
  30k；含 209 维决策向量与全部指标）；`verify_witness.m` 用本目录代码独立重算并逐项
  比对（已通过：五图 cost/可行/距离全部一致）。生成脚本：`make_witness.m`。
  旧实例记录 `legacy_v3_tight/` 与 `v6_*_witness.csv` 仅存档（属不同参数版本）。
* **实验规划**：见 `PLAN_uav3d.md`（三条可证伪假设、三层指标、统计口径、阶段与时间预算）。

## 5. 运行

```matlab
cd sparse_q\app_uav3d
smoke_uav                                  % 烟测（约 3-4 分钟）
uav_batch()                                % 默认：7 算法 × 5 地图 × 101:130 × 60 × 30k
uav_batch({'VAST-GWO','GWO','PSO'},1:5,101:110)   % 自定义算法集/地图/种子
out=uav_batch(...); writetable(out.runs,'raw_runs.csv')  % 自动写 raw_runs.csv
```

* 同一 `outDir` 重新调用 `uav_batch` 即**断点续跑**（只补缺失/失败作业）。
* 全部作业经 `overnight.runBatch4`：**恰好 4 worker**，逐作业原子落盘。

## 6. 运行时间实测（本机，MATLAB R2025b）

* 适应度 ≈ **9–10 ms/次**（209 维解码 + 逐段碰撞/约束检查）→ 3,000 FE ≈ 26–30 s/次。
* 外推：**30,000 FE ≈ 4.5 min/次**；4 worker 下：
  * 7 算法 × 5 地图 × 30 种子 = 1050 次 ≈ **20 h**；
  * 5 算法 × 5 地图 × 30 种子 = 750 次 ≈ **14 h**；
  * 开发档 7 × 5 × 3 种子 = 105 次 ≈ **2 h**。
* 建议按"开发档 → 冻结 → 正式档"顺序执行；如须压缩，优先缩减算法集或种子数，
  不要动协议参数（60/30k）以保持与 9.29 结果可比。
