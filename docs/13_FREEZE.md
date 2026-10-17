# 13 — 冻结记录（2026-10-16）

## 冻结的主方法：ANGWO（working name）= E* 形态

| 项 | 值 |
|---|---|
| 探索份额 theta | 固定 0.20（每代 round(0.2N) 只侦察狼） |
| 侦察狼选择 | pbest 排名后 50% 中"最久无改善"者（确定性） |
| 采样中心 | 当前 alpha（incumbent） |
| 采样尺度 | 最近 25 次真实成功步长的中位数，下限 1% 对角线；逐维均匀 x + sigma*(2u-1) |
| 目标规则 | 单随机候选（不再做新颖度池过滤） |
| 停滞恢复模块 | **关闭**（RD2a/RD2b 全部未通过 A1 恢复门槛；负结果保留） |
| 配额自适应 | **关闭**（B3 触发：自适应 0.892 vs 固定 0.661） |
| 额外参数 | 无（成功步长中位数由数据决定） |
| 真实 FE | 与 GWO 相同：每代每狼 1 次评价，初始化计入 |
| 候选生成成本 | 每侦察狼 1 个候选；无距离运算（过滤已移除） |

开发证据（D30/30k，8 函数 × 10 种子，预注册门槛见 docs/08–12）：

* E* vs GWO：中位误差比值 **0.634**，函数级 **7/8** 胜，逐种子 Wilcoxon
  p=2.4e-7，Holm 后 2 个函数显著更好、0 个显著更差；
* 有用新颖率 0.0128 vs GWO 0.0094（+36%）；末段改善率 +12%；
* 单次运行时间约为 GWO 的 1.3 倍（D50/100k）。

## 代码 hash（SHA-256）

| 文件 | hash |
|---|---|
| src/ANGWO.m | 424b74f35c8810bd8a20854e7b62258da6371461ca3500793ef2fd91585d5f2f |
| src/GWO.m | b9927b569edebb76f31c676bb976e0348b7d9aa00ad6c5e287951e4a3ef17d24 |
| src/EvalProbe.m | 4061fbef8618c41dcb1ba1e34b7d0f0f0880c43ac09f536813b067468f745c54 |
| experiments/runner_cec.m | d3f227ae48d0df614c2635de560f68d907b71e2703278c994085b0f38d97e9e9 |

## 正式批（冻结后唯一一次 D=50 主实验）

* 协议：CEC2017，D=50，100000 真 FE（含初始化），29 函数（F1,F3–F30），
  种子 3001–3030，4 workers。
* 新运行变体（6 个）：
  1. GWO（指标补全 + 与已审计表逐位核对）
  2. ANGWO-final（E*）
  3. ANGWO-self（中心改自身；消融）
  4. ANGWO-novdest（目标改新颖度过滤；消融）
  5. ANGWO-adapt（配额自适应；消融）
  6. ANGWO-ES2（E* + S2-elite；恢复模块文档化对照）
* 强基线（HIDMS-PSO / HCLPSO / DMS-PSO / SAQ-CSO / SPSO-2011 /
  HPSO-TVAC / CLPSO / IGWO / Original-CSO 等）复用已审计 30 种子表格
  （reports/baseline_audit.md；本工程已逐位复现验证）。
* 分析：merge_audited.py 合并后跑 analyze_batch.py（配对 Wilcoxon + Holm +
  Friedman 排名 + 停滞/新颖度表 + 检查点曲线）。
