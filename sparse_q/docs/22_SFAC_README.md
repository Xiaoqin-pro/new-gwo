# SFAC Branch

独立分支：从 `main` 的 `23be755` 创建，只包含 SFAC（Success–Failure Adaptive Credit）实现和 P1 结果。

## 文件
- `sparse_q/src/SGWO_SFAC.m`
- `sparse_q/experiments/screen26_sfac.m`
- `sparse_q/experiments/analyze_sfac_p1.py`
- `sparse_q/tests/test_sfac_contract.m`
- `sparse_q/docs/22_SFAC_PREREG.md`
- `reports/sfac_p1_analysis/`
- `reports/sfac_nightly.md`
- `reports/sfac_SCI_READINESS.md`

## 结论
SFAC P1 的最终误差门槛未通过；机制改变了区域信用行为，但没有净性能收益。按预注册停止，不扫描信用参数。
