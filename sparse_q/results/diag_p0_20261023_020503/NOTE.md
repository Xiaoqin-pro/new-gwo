# 已作废：diag_p0_20261023_020503 —— 记录器字段白名单仍为旧字段名（DiagSucc），
# 导致 DiagGB/DiagPop/DiagLife*/DiagQual 未落盘。机制实现（SGWO_DIAG.m）本身正确且与冻结逐位一致，
# 但该批次的数据不可用；修正管线后用全新种子 3569–3573 重跑（见 registry 的 DIAG-P0-002）。
