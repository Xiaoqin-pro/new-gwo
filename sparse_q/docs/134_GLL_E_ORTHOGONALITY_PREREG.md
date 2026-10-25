# GLL × E 正交性 P1 预注册（2026-10-23）

## 目的

GLL 改变 β/δ 的形成，E 改变候选来源。两者作用层级不同，但必须用同一个 2×2 因子实验证明 GLL 不是只依赖 E 才有效。

## 设计

- 与 GLL P1 相同的 15 函数、10 种子（4251–4260）、100k FE、D=50。
- A/B 臂复用 `gll_p1` 的 Global/GLL20（E on）。
- 新增两臂：
  - C-Global-Eoff：`ablateE=1`，E 槽位由标准 GWO 候选填补。
  - D-GLL20-Eoff：`ablateE=1`，GLL20 领导。
- 只运行 C/D，300 次；分析时按 `(FunctionID,Seed)` 合并 A/B。

## 判定

- E on 的 GLL gain：`log10(error_global/error_gll)`；
- E off 的 GLL gain；
- 两因子交互项：`gain_Eon - gain_Eoff`（函数级中位）。
- 要求：E on 和 E off 的 GLL/Global 中位比均 ≤ 0.98，且交互项不出现强负向（函数级中位 > -0.05 log10 视为无强冲突）。
- 不通过则 GLL 作为 E 依赖组件，不作为独立主机制。
