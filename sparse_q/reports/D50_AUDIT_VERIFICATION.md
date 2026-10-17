# D50 正式批严格复核（5220 次运行）

批次目录：`D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\results\formal_20261016_140254`

- raw run files: **5220** (expected 5220)
- manifest jobs: 5220
- status ok: **5220**, failed: **0**
- runs with FE accounting violation: **0**
- runs with trace violations (non-finite/non-monotone/cost mismatch): **0**
- manifest label mismatches: **0**
- per-algorithm counts: {'GWO': 870, 'ANGWO-final': 870, 'ANGWO-self': 870, 'ANGWO-novdest': 870, 'ANGWO-adapt': 870, 'ANGWO-ES2': 870}

## 2. CSV ↔ MAT 一致性

- runs.csv rows: 5220
- rows with CSV↔MAT mismatch: **0**

## 3. 统计复核（ANGWO-final vs GWO，29 函数 × 30 种子）

| 指标 | 复核值 | NEXT_GOAL 声称 | 判定 |
|---|---:|---:|---|
| 函数均值胜负 (W/L) | 21/8 | 21/8 | 一致 |
| 配对 Wilcoxon+Holm (better/worse) | 11/0 | 11/0 | 一致 |
| 早期 FE10k 函数均值胜 | 10/29 | 10/29 | 一致 |
| 早期 FE20k 函数均值胜 | 13/29 | 13/29 | 一致 |
| 有用新颖率均值 GWO→ANGWO | 0.0034660 → 0.0057833 | 0.0034660 → 0.005783 | 一致(舍入) |
| 真实恢复事件均值 GWO→ANGWO | 14.555 → 14.562 | 14.555 → 14.562 | 一致(舍入) |

备注：ANGWO（冻结）为全评价、无 Q 表；ANGWO-adapt 为启发式比例反馈（θ += η(r_rover − r_exploit)），两者都不是 Q-learning —— 与 frozen 代码（docs/13_FREEZE.md 记录 hash）逐行核对成立。

## 4. 与用户 D50_AUDIT_source.csv 对照

- 29 个函数 mean-ratio 最大绝对偏差：**4.441e-16** (一致)


## 5. 合并基线完整性

- audited 行与源表逐位一致：**True**


## 结论

**全部复核通过**：5220/5220 状态 ok、FE 精确 100000、轨迹单调有限、manifest↔记录逐一对应、CSV↔MAT 一致、统计声称全部复现、用户审计表一致、合并基线逐位一致。
