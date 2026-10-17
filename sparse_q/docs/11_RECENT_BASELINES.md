# 11 — 近年强 GWO 基线复现对比（预注册，2026-10-17）

用户提供近年论文清单；按"有开源代码优先"原则选定：

| 基线 | 来源 | 复现方式 | 标注 |
|---|---|---|---|
| **RL-LGWO** | Maleki/Roayaei/Mirjalali 2025, KBS, 10.1016/j.knosys.2025.114471 | 作者 Python 源码（mroayaei/RL-LGWO）**逐机制移植**至 MATLAB（`src/RLGWO_CEC.m`）：领导者级 3×3 Q、每狼 16×4 Q、两组领导者扰动、移动权重动作；**评价缓存**去除源码中的重复 objf 调用，全部新位置评价计费 | "author-code-based MATLAB port" |
| **DMSGWO** | Wang et al. 2026, Sci Rep, 10.1038/s41598-026-54428-w | 官方 GitHub（wangyoki/DMSGWO）**开发组循环为空**；按开放获取论文公式补全（phi=(f/f_avg)^3、w=0.5+0.5cos(pi t/T)、X←(1-w)X+w X·phi） | "paper-repair implementation" |
| I-GWO | Nadimi-Shahraki 2021 | 已审计 MATLAB ✓ | 审计版 |
| GWO | Mirjalili 2014 | 已审计 ✓ | 审计版 |
| QLFDGWO | Huang 2026, Biomimetics | 无公开代码 / MDPI 抓取受限 → 暂不加入数值对比，仅文献引用 | — |
| MELGWO | KBS 2023 | FEX 作者源码被本机网络 403；GitHub 镜像为垃圾仓 → 暂缓 | — |

协议：D=50，29 函数，种子 3001:3010（先 10 种子），100k 真 FE（严格计费），
4 worker；同一初始化前缀；对比主指标：中位误差比、函数胜负、Wilcoxon+Holm、
平均排名、运行时间。DMSGWO 每代消耗 ~n1·D+n2 次评价（作者设计），
在等 FE 下约 ~78 代 —— 这是等 FE 协议的真实含义，如实报告。
