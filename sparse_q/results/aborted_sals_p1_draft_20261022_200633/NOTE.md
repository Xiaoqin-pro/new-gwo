# 已作废：SALS P1 的第一版实现批次（2026-10-22 20:06 启动，20:17 中止）

本目录包含 115 个已完成运行。它们在**数值上与正式批次逐位一致**（优化只改实现方式，
`tests/test_sals_opt_equivalence.m` 断言 4 个模式全部 bitwise equal），但**不参与任何分析**：
批次在中途被中止，且墙钟时间记录属于优化前实现（活跃臂 3.7×），不能用于运行时间结论。

- 中止原因：活跃臂每宏代 300 次标量 RandStream 抽取 + 300 次 `unique()` 诊断调用，开销 3.7×。
- 处理：`sparse_q/docs/69_SALS_IMPL_RUNTIME_NOTE.md`；修正后同批计时见
  `reports/sals_runtime_optimization.md`（C/A = 1.178×，C/B = 1.011）。
- 正式批次：`results/sals_p1_<timestamp>/`，协议与种子（3439–3448）不变。
