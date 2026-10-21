# ENAC / Identity-Credit Branch

独立分支：从 `main` 的 `23be755` 创建，包含档案信用被动审计、Identity-Credit 和 ENAC 的 P0/P1 结果。

## 文件
- `sparse_q/src/SGWO_ENAC_AUDIT.m`
- `sparse_q/src/SGWO_ENAC.m`
- `sparse_q/experiments/screen29_enac_audit.m`
- `sparse_q/experiments/screen30_enac.m`
- `sparse_q/experiments/analyze_enac_p1.py`
- `sparse_q/tests/test_enac_audit_contract.m`
- `sparse_q/tests/test_enac_contract.m`
- `sparse_q/docs/25_ENAC_AUDIT_PREREG.md`
- `reports/enac_p1_analysis/`
- `reports/enac_nightly.md`
- `reports/enac_SCI_READINESS.md`

## 结论
P0 证明冻结 V1 的中心身份、信用泄漏和曝光偏差均为 material。清理版 P1 中，ENAC 相对 V1 通过 H1（中位比 0.939，8/8 胜，运行时间 1.035），但 ENAC 相对 Identity-Credit 未通过 H2（4/8 胜，F10 2.257 倍）。最终判定为 `IDENTITY_EFFECT_ONLY`：有效成分是中心身份修正，不是曝光归一化。
