# NEW_GWO_2026 — 稀疏真实评价灰狼优化（sparse_q 研究分支）

本仓库为 2026 年灰狼优化（GWO）改进研究的工作快照：**无 GNN、机制轻量**的稀疏评价
调度框架 —— 双路线候选池（GWO 移动 + α 成功步长壳 + 已验证精英档案壳/线段）+
每代 K=10 个真实评价，未评价候选绝不进入排序/领导/档案。

状态：研究进行中。V1 已冻结；交叉臂 combo（succSteer=0.5 + g2Subset=0.2）为 v2 候选。

## 目录结构

```
AGENTS.md, setup_project.m        项目协议与初始化脚本
src/                              冻结参考实现（EvalProbe / trace_metrics / GWO / ANGWO）
data/cec2017/                     CEC2017 基准（mex/源码 + input_data，复现必需）
docs/, reports/, paper/           研究协议、实验报告、论文草稿
experiments/, tests/, overnight/  批次驱动（4-worker parfor）、单元/审计测试
sparse_q/                         主研究分支（代码 + 文档 + 报告 + 论文 + 结果汇总）
sparse_q/results/                 各批次 runs.csv / summary.mat / manifest.mat / provenance.mat
```

## 关键结果（截至 2026-10-17）

| 层级 | 结论 |
|---|---|
| 正式批 D=50（29fn x 30 seeds, 100k 真实 FE） | vs GWO 0.525（28-1，Holm +24/-0）；vs IGWO 0.938（17-12，池化 p=0.55，Holm +12/-6） |
| 交叉臂 V2-steer50-g20（fresh 3031:3060, 30 seeds） | **vs IGWO 中位比 0.978，原始 17-12，池化 p=1.18e-07，Holm +11/-5**；停滞双门槛通过（recov 0.8775，longStag 0.7482） |
| D=100 扩展 | 平均排名第一（1.72）；对 IGWO 子集 0.703（10-2） |
| 20k FE 资源层 | 排名第一（1.97） |
| Q-learning | **否定结果**：三变体 0.99-1.13 vs 最优固定配额，如实保留 |

全部批次、单变量改动、通过与失败配置见 `sparse_q/experiments/registry.csv`；
完整报告见 `sparse_q/reports/EXPERIMENT_REPORT_zh.md`（交叉臂 = 5c 节）。

## 未上传内容（体积原因，本地保留）

* `**/results/**/runs/`：逐次运行的原始 trace（约 90 MB / 1.6 万个小文件）。
  每个批次的 `runs.csv` 已包含全部逐次指标（误差、恢复、新颖率、耗时），可据此完整复算统计。
* `sparse_q/refs/RL-LGWO`、`sparse_q/refs/DMSGWO`、`sparse_q/refs/MELGWO`：
  第三方论文源码克隆（DOI 见 `sparse_q/reports/LITERATURE_zh.md`），需要时自行 clone。
  对应 MATLAB 移植版在 `sparse_q/src/RLGWO_CEC.m`、`sparse_q/src/DMSGWO_CEC.m`。

## 复现

```powershell
cd sparse_q
# 单元测试 + 抽样审计（与冻结实现逐位一致）
matlab -batch "addpath('src','experiments','tests'); test_sgwo_unit(); test_sgwo_audit()"
# 冻结正式批（断点续跑：opt.resume）
matlab -batch "addpath('src','experiments','tests'); final_d50()"
# 分析与图表
python experiments/analyze_final.py
python experiments/make_tables_sq.py ; python experiments/make_figures_sq.py
```

## 环境

MATLAB R2025b + Parallel Computing Toolbox（严格 4 worker：`parpool('local',4)`）；
Python 3（numpy / pandas / scipy）；CEC2017 MATLAB 基准代码与 input_data 已含在 `data/`。
所有正式实验遵守严格真实 FE 计费（EvalProbe 探针校验，100k 预算，0 违规）。
