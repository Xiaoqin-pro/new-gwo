# D=100 补充实验：复现记录

## 1. 一句话复现

```powershell
cd D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q
# 1) 审计门（代码 hash、共享初始池、FE 探针、逐位复现、I-GWO 复现）
matlab -batch "addpath('experiments','tests','..'); d100_phase2_audit"
# 2) 正式批次（5800 新作业；固定目录；可断点续跑；恰好 4 worker）
matlab -batch "addpath('experiments','..'); d100_formal"
# 3) 合并归档段 + 逐行校验 MAT，生成 raw_runs.csv
python build_d100_raw.py
# 4) 统计、图表、表格、报告
python analyze_d100.py
python make_manifest.py
python make_audit_report.py
python make_analysis_report.py
python make_d100_report.py
python make_d100_tex.py
python compare_d50_d100.py
# 5) 独立复算（只读 raw_runs.csv）
python verify_d100.py
```

## 2. 文件角色

| 文件 | 作用 |
|---|---|
| `docs/17_D100_PREREG.md` | 预注册（运行前冻结）：协议、统计计划、复用判定 |
| `d100_phase2_audit.m` | 启动前审计门（hash / 同池 / FE / 确定性 / 逐位复现） |
| `d100_repro_batch.m` | 290 条归档 VAST-GWO 的逐位重跑证据 |
| `d100_formal.m` | 正式批次（5,800 作业，固定输出目录） |
| `d100_smoke.m` | 七算法 D=100 烟测 |
| `build_d100_raw.py` | 合并 + 逐行 MAT 校验 + 自描述元数据 |
| `analyze_d100.py` | 主表 / Holm / 类别 / 收敛 / 运行时间 / 图 |
| `verify_d100.py` | 只依赖 raw_runs.csv 的独立复算 |

## 3. 结果目录

`results/d100_analysis/`

| 文件 | 内容 |
|---|---|
| `raw_runs.csv` | 6,090 条有效运行（含算法、函数、种子、参数、代码 hash、FE、误差、检查点） |
| `manifest.json` | 算法/参数/种子/hash/环境/统计计划 |
| `audit_report.md` | 复现与 FE 审计、失败与续跑记录 |
| `analysis_report.md` | 完整统计与结论（含边界） |
| `table_d100_main.csv` / `.tex` | 七算法主表 |
| `table_d100_holm.csv` | 逐函数 Wilcoxon + 家族内 Holm + 全局 Holm 敏感性 |
| `table_d100_categories.csv` | 四类函数汇总 |
| `table_d100_per_function.csv` | 29 函数 × 7 算法中位误差 |
| `table_d100_convergence_ranks.csv` | 10/20/50/80/100% FE 检查点排名 |
| `stats_d100.json` | 机器可读的全部统计量 |
| `figure_d100_ranks.png` / `figure_d100_winloss.png` / `figure_d100_runtime.png` | 排名 / 胜负 / 运行时间（600 dpi，期刊风格） |
| `figure_d100_convergence6.pdf` | D=100 五函数收敛 + 排名轨迹（矢量，期刊风格） |
| `figure_d100_framework.png` | 方法框架图（期刊风格） |
| `comparison_d50_d100.md` | 与 D=50 论文主表的维度对照 |

## 4. 原始批次目录（不要删除或覆盖）

| 目录 | 内容 |
|---|---|
| `results/d100_formal_20261018/` | 本轮 5,800 条新跑 + `manifest.mat` + `provenance.mat` + `runs/` |
| `results/fd100_20261016_232205/` | 历史 D=100 批次；仅 `S-star` 的 290 条被复用 |
| `results/d100repro_20261018_200546/` | 290 条逐位复现证据 |
| `results/d100_phase2_audit/` | 审计门日志与 `phase2_audit.mat` |
| `results/d100smoke_20261018_110542/` | 七算法烟测 |

## 5. 不可变约束

- 不覆盖任何历史结果目录；正式批次只补缺失/失败作业。
- 不因分析结果修改算法、搜索参数、函数集合、种子区间或统计口径。
- 统计以函数内配对种子为单元；不得把 6,090 次运行或 870 个函数×种子单元当作相互独立的样本。
- 等真实 FE ≠ 等迭代代数；论文必须并列报告。
