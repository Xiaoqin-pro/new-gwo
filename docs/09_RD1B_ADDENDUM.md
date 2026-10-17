# 09 — RD1a 缺陷记录与 RD1b 追加预注册（2026-10-16）

## 1. RD1a 批次（results/rd1_20261016_134704）的缺陷

**程序缺陷（不是算法结果）**：run_batch_new 把不同变体的 `state` 结构体
并入一个 struct 数组时，MATLAB 对缺失字段补 `[]`；ANGWO 的选项解析把空值
也照抄，于是：

* `exploreMode='random'` 的 theta 重抽条件 `fe>=winEnd` 因 `winEnd=[]`
  永远为假 → E-rand 实际退化为 E-fixed10（两列**逐位相同**，已核验）；
* `exploreMode='adaptive'` 的 `exploreShare=[]` → `round([]*N)` →
  每代固定 1 只侦察狼，自适应更新被 `[]` 短路 → 不是自适应机制；
* 其余 fixed 变体（05/10/20）与 nofilter 变体不受影响，结果有效。

修复：ANGWO 选项解析与 runner_cec 的状态合并都改为**跳过空值**；
新增回归测试 `tests/test_angwo_modes.m`（fixed/random/adaptive 调度形状、
α 中心与目标规则切换）与既有 `test_angwo_equivalence.m` 全部通过。

**有效结论（保留）**：

1. “候选池取最近邻距离最大者”的新颖度过滤**输给**同样尺度下的随机目标：
   E-fixed10（novelty 目标）比值 1.115 (2/8 胜) vs E-fixed10-nofilter
   （random 目标）比值 0.938 (5/8 胜)。→ 与手册要求的"不如随机则不成
   立"一致：**新颖度过滤不作为贡献**，RD1b 起默认目标改为随机。
2. 固定 10% 的“以自身为中心的随机壳侦察”相对 GWO 有轻微正效果
   （中位比值 0.938，5/8 函数胜，未达显著）；5%/20% 反而更差。

## 2. RD1b 追加预注册（在运行前写下）

变体（均为单机制：exploreMode/roverCenter/roverDest 的一个组合）：

| 标签 | 设置 | 作用 |
|---|---|---|
| GWO | 参考 | - |
| E-f10-self-r | fixed 0.10, center=self, dest=random | RD1a 赢家复跑（跨批逐位核对） |
| E-rand-self-r | random, center=self, dest=random | 随机配额对照 |
| E-adapt-self-r | adaptive, center=self, dest=random | 自适应配额（修复后首次有效测试） |
| E-f10-alpha-r | fixed 0.10, center=alpha, dest=random | 采样中心改在最优解附近 |
| E-f10-alpha-n | fixed 0.10, center=alpha, dest=novelty | 过滤在 α 壳中的二次检验 |
| E-f20-alpha-r | fixed 0.20, center=alpha, dest=random | α 壳份额对照 |

沿用 RD1 预注册门槛 B1/B2/B3/B4（docs/08 §4），参考对象仍为 GWO；
`E-f10-self-r` 与 RD1a `E-fixed10-nofilter` 必须逐位一致（协议审计）。

开发协议同 docs/08：D=30，maxFE=30000，函数 [1 3 4 6 9 13 18 24]，
种子 3001:3005。

## 3. 判定预告

* 若 α 中心 + random 目标（任何份额）既不满足 B1 也不满足 B2 → E 模块
  判负，按 docs/03 规则直接淘汰或另立**新的**可证伪假说（计入配置预算）；
* 若 adaptive 未超过最佳 fixed（差 ≥2%）→ 按 B3 记录“自适应未被数据
  支持”，最终形态用 fixed；
* 任何结果（含失败）写入 experiments/registry.csv。
