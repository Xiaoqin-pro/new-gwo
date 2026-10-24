# Diff-GWO 混合消融 P0b（2026-10-24）

## 目的

P0（diffgwo_p0，seed 4281–4285）发现：
- C-DiffNoArc 在 F1（50–2000×）、F30（2–10×）、F4/F7/F13 上大幅改善；
- 但 F20/F24 全部 5 种子一致恶化（1.1–2.1×）。

纯差分算子偏科。本实验用 **opPolicy='hybrid' + opShare** 把标准领导聚合与 DiffNoArc 按比例混合（每只狼以概率 opShare 用差分算子、否则用标准 GWO 聚合），寻找能在保留 F1/F30 收益的同时修复 F20/F24 的混合比。

## 协议

- CEC2017，D=50，N=50，K=10，M=100，100k 真实 FE。
- 8 函数：F1/F4/F7/F10/F13/F20/F24/F30。
- 5 个全新种子：4286–4290。
- 4 个 worker，6 臂 × 8 × 5 = 240 次运行。
- 臂（全部 opDiffMode='nowarc'，opF=0.5）：
  - A-Standard：opShare=0（标准 GWO）。
  - B-Mix25：opShare=0.25。
  - C-Mix50：opShare=0.50。
  - D-Mix75：opShare=0.75。
  - E-DiffAll：opShare=1（纯 DiffNoArc）。
  - F-NoSTEER：opShare=0、succSteer=0（去掉 STEER，检验差分与 STEER 正交性）。

## 判定

1. 存在某个 Mix 臂在 **F1、F30 明显改善（≤0.5×）** 且 **F20、F24 不恶化（≤1.1×）**，整体多数函数向好。
2. Mix 臂相对 A 的函数级中位比 ≤ 0.95 且 wins ≥ 6/8。
3. 找出最优混合比（按 F1/F30 收益与 F20/F24 损失的权衡）。
4. 若 Mix 明显优于 A 且无全种子一致灾难 → 进 15 函数 × 10 种子 P1。
5. F-NoSTEER 用于检验差分算子与 STEER 是否正交（若 Mix 在无 STEER 时仍强，说明可以放弃 STEER）。

## 归因

- 混合比扫描：opShare ∈ {0, 0.25, 0.5, 0.75, 1}；
- STEER 正交性：A vs F（标准骨架有/无 STEER），D vs 其无 STEER 版本。
