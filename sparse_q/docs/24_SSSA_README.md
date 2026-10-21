# SSSA Branch

独立分支：从 `main` 的 `23be755` 创建，只包含 SSSA（Source-Specific Success-Scale Adaptation）实现、预注册和 P1 结果。

## 文件
- `sparse_q/src/SGWO_SSSA.m`
- `sparse_q/src/sssa_source_sigma.m`
- `sparse_q/experiments/screen28_sssa.m`
- `sparse_q/experiments/analyze_sssa_p1.py`
- `sparse_q/tests/test_sssa_contract.m`
- `sparse_q/docs/24_SSSA_PREREG.md`
- `reports/sssa_p1_analysis/`
- `reports/sssa_nightly.md`
- `reports/sssa_SCI_READINESS.md`

## 结论
H1（SSSA vs V1）和 H2（SSSA vs SSSA-Swap）均未通过。σ_G2/σ_E 确实分离，但没有带来稳定净收益；F7 上来源交换反而更好。按预注册停止，不扫描新参数。
