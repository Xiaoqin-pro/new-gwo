# sparse_q 门槛判定 — screen1

batch: `D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\results\sq1_20261016_211539` | runs: 200

| 判定项 | 实测 | 门槛 | 结果 |
|---|---:|---:|---|
| G_S1: S1 vs GWO 中位比值 / 胜负 | 0.529 / 8-0 | ≤1.00 且 ≥4/8 胜 | PASS |
| G_S2a: S2 vs S1 中位比值 / 胜负 | 1.394 / 4-4 | ≤0.98 或 (≥6/8 且 ≤1.00) | FAIL |
| G_S2b: FE20k 比值 / 简单多峰子集胜 | 1.048 / 2/3 | ≤0.98 且 ≥2/3 | FAIL |

**SCREEN1 结论：未过门槛**（G_S1 PASS；G_S2a FAIL；G_S2b FAIL）

- B0-ANGWO: 对 GWO 中位比值 0.716，函数胜负 6-2
- B1-dense-sync: 对 GWO 中位比值 1.007，函数胜负 3-5
- GWO: 对 GWO 中位比值 1.000，函数胜负 0-0
- S1-sparse-random: 对 GWO 中位比值 0.529，函数胜负 8-0
- S2-sparse-directed: 对 GWO 中位比值 0.803，函数胜负 6-2

- S2/S1 @ CheckT10: 中位比值 0.918, 胜负 4-4
- S2/S1 @ CheckT20: 中位比值 1.048, 胜负 3-5
- S2/S1 @ CheckT50: 中位比值 0.990, 胜负 4-4

- 有用新颖率: B0-ANGWO=0.01265  GWO=0.009498  S1-sparse-random=0.0124  S2-sparse-directed=0.01425  
- 长停滞占比: B0-ANGWO=0.8468  GWO=0.8621  S1-sparse-random=0.8424  S2-sparse-directed=0.8392  
- 恢复窗口概率: B0-ANGWO=0.7852  GWO=0.7747  S1-sparse-random=0.7855  S2-sparse-directed=0.8072  
- 末段改善率: B0-ANGWO=0.007427  GWO=0.007103  S1-sparse-random=0.004497  S2-sparse-directed=0.005187  
- 运行秒: B0-ANGWO=0.4978  GWO=0.4462  S1-sparse-random=0.6327  S2-sparse-directed=0.7818  

