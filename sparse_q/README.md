# sparse_q 研究分支（最终状态，2026-10-17）

> 稀疏真实评价 × 预算调度 GWO。旧 ANGWO / RASE-GWO / 强基线 / 原 results
> 全部只读；本分支只写 `sparse_q/**`。

## 冻结主方法（docs/07_FREEZE.md）

* 双路线候选池 M=100：G1=50（GWO 移动）+ G2=12（α 成功步长壳）+
  E=38（已验证精英档案中心壳/双中心线段）；档案容量 24、分离阈值 2%。
* 每代 K=10 个真实评价，全池均匀随机；未评价候选绝不进入排序/领导/档案。
* 实现：`src/SGWO.m`（独立实现，与冻结 GWO 逐位审计）；
  runner：`experiments/runner_sgwo.m`；批次：`experiments/run_batch_sq.m`。

## 结果速览（全部 4-worker、0 失败、探针 0 违规）

| 层级 | 结论 |
|---|---|
| 正式 D=50（29fn×30seeds，100k FE） | S\* 平均排名 **4/17（5.97）**；对 GWO 0.525（28-1、Holm **+24/−0**）；对冻结 ANGWO 0.723（27-2、+22/−1）；**对 I-GWO 0.938（17-12、池化 p=0.55、Holm +12/−6）**；对 SAQ-CSO 1.010（平手） |
| 双轴 | A（探索效率）**通过**（FE20 0.768、简单多峰 0.714、有用新颖 +11%）；B（停滞恢复）**部分**（恢复 +0.0557 过门槛；长停滞 −0.0176 未达 −0.03） |
| D=100（29fn×10seeds） | 排名第一（1.72）；对 IGWO（12 函数子集）0.703、10-2、Holm +5/−1 |
| 20k FE 资源层 | 排名第一（1.97）；对 GWO 0.721（24-5） |
| Q-learning | **否定**：三变体 0.99–1.13 vs 最优固定；仅胜随机（0.75–0.87），如实报告 |

## 关键负结果（全部保留在 registry.csv）

定向筛选 1.39×、informed-in-strata 1.53×、配额偏离 1.02–1.67×、随机配额
1/7 胜、Q 三变体、boost 半径放大 1.20×、E50 池不稳定、sq1b 派发缺陷整批作废。

## 文档索引

* `docs/01_PREREG.md`–`docs/10_FRESH_V2.md`：预注册阶梯与修复记录
* `reports/D50_AUDIT_VERIFICATION.md`：5220 次旧结果严格复核
* `reports/LITERATURE_zh.md`：2021–2026 文献与重叠警示
* `reports/MECHANISM_zh.md`：中文机理分析
* `reports/EXPERIMENT_REPORT_zh.md`：完整实验报告（含 Holm 总表）
* `reports/FAILURE_ANALYSIS_zh.md`：失败函数分析（Phase 4）
* `reports/SCI_READINESS.md` / `reports/NOVELTY_zh.md` / `reports/NEXT_STEPS_zh.md`
* `paper/main.pdf`：SCI Method/Experiments 草稿（IEEEtran，5 页）
* `experiments/registry.csv`：全部批次/配置的决策日志

## 复现

```powershell
cd D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q
matlab -batch "addpath('src','experiments','tests'); test_sgwo_unit(); test_sgwo_audit()"
matlab -batch "addpath('src','experiments','tests'); final_d50()"      # 断点续跑: opt.resume
python experiments/analyze_final.py ; python experiments/analyze_failures.py
python experiments/make_tables_sq.py ; python experiments/make_figures_sq.py
```
