# CD-VACG Branch

独立分支：从 `main` 的 `23be755` 创建，只包含 CD-VACG（Consensus–Divergence Verified Archive Coordinate Grafting）实现、预注册和 P1 结果。

## 文件
- `sparse_q/src/SGWO_VACG.m`
- `sparse_q/experiments/screen27_vacg.m`
- `sparse_q/experiments/analyze_vacg_p1.py`
- `sparse_q/tests/test_vacg_contract.m`
- `sparse_q/docs/23_VACG_PREREG.md`
- `reports/vacg_p1_analysis/`
- `reports/vacg_nightly.md`
- `reports/vacg_SCI_READINESS.md`

## 结论
H1（MAD vs V1）和 H2（MAD vs RandomSplit）均未通过。MAD 嫁接在部分组合函数上改善，但在简单多峰和混合函数上退化，F13 出现灾难性变差。按预注册停止，不扫描新参数。
