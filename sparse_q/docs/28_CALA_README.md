# CALA / Consensus-Aware Leader Aggregation Branch

从 `main` 的 `23be755` 创建；包含 100k FE 下的 4 臂、15 函数、600 次 CALA P1。

## 文件
- `sparse_q/src/SGWO_CALA.m`
- `sparse_q/experiments/screen33_cala.m`
- `sparse_q/experiments/analyze_cala_p1.py`
- `sparse_q/tests/test_cala_contract.m`
- `sparse_q/docs/28_CALA_PREREG.md`
- `reports/cala_p1_analysis/`
- `reports/cala_nightly.md`
- `reports/cala_SCI_READINESS.md`

## 结论
H1、H2、H3 均未通过：CALA 在混合/组合函数上有局部收益，但在单峰函数上退化；两路线删除 G2 总体更好但存在灾难性退化。按预注册停止 CALA，不扫 rho 参数。
