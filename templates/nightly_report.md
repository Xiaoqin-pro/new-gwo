# Nightly — NEW-GWO

## 执行事实
开始结束时间 / MATLAB / 操作系统 / MATLAB local pool=4 证据 / 是否无中断 / git hash / FE 协议 / CEC 套件版本

## 新算法（从零实现）
名称（暂定） / 核心方程 / 模块数 / 参数 / 来源归属 / 是否含GNN（必须否）

## 任务 A：停滞恢复（证据）
停滞定义，GWO、强 GWO、New GWO 的 plateau_count / recovery_probability / FE_to_recover / 未恢复比例；负面函数和统计显著性。

## 任务 B：探索效率（证据）
Novelty 数、useful novelty per FE、global best improvement per FE、FE10%/20%/50%曲线、候选生成数量、墙钟时间；说明如何排除“乱跳”。

## 强基线对比
全29函数×全种子强对照排名、均值/中位、Holm校正结果、正负函数、D30/50/100状况。

## 消融
new / without E / without S / fixed or random scheduler / equal CPU or equal-candidate check

## 失败与可信度
日志位置；FE 计数、边界、版本、基线认证、跑失败数、未完成任务、数据泄漏风险。

## 下一步（不自动继续调最终测试集）
保留/删除哪些机制，仍欠缺哪些强GWO对照，论文能否成立（是/否/证据不足）。
