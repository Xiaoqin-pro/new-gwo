# AMC / Adaptive Move Control Branch

独立分支：从 `main` 的 `23be755` 创建，包含 15 函数、5 臂双因素 AMC 实验。

## 文件
- `sparse_q/src/SGWO_AMC.m`
- `sparse_q/experiments/runner_sgwo_amc.m`
- `sparse_q/experiments/screen32_amc.m`
- `sparse_q/experiments/analyze_amc_p1.py`
- `sparse_q/tests/test_amc_contract.m`
- `sparse_q/docs/27_AMC_PREREG.md`
- `reports/amc_p1_analysis/`
- `reports/amc_nightly.md`
- `reports/amc_SCI_READINESS.md`

## 结论
修正后的 750 次 P1 显示 AMC gamma 扩张在 15 个函数上普遍退化：
- C/A 中位比 1.2178，1/15 胜，9 个函数 >1.20；
- D/B 中位比 1.4215，0/15 胜，10 个函数 >1.20；
- B/A 和 D/C 也未通过。

按预注册停止 AMC，不扫描 gamma 参数。Identity-Credit 保留为独立候选。
