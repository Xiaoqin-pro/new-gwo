# CMA-DE5 P0（8 函数 × 5 新种子 4141–4145，100k FE）

- 结果目录：`D:\111\Desktop\噜噜\new-gwo-g2tr-branch\sparse_q\results\cma_de_p0_20261023_193010`（200 次运行，0 失败）
- 预注册门槛：`sparse_q/docs/126_CMA_DE_P0_PREREG.md`

| 对比 | median | wins/8 | >1.20 | max | worst | p | 95% CI |
|---|---:|---:|---:|---:|---:|---:|---:|
| DE5/CMA | 0.8849 | 5 | 0 | 1.06 | F30 | 0.1562 | [0.670, 1.024] |
| DE5/jSO | 0.5824 | 6 | 1 | 5.09 | F13 | 0.1953 | [0.128, 1.116] |
| DE5/PermutedDE5 | 1.0248 | 3 | 3 | 1.47 | F20 | 0.6875 | [0.849, 1.276] |
| DE5/Random5 | 1.0045 | 3 | 1 | 1.68 | F20 | 0.4688 | [0.876, 1.191] |
| Permuted/CMA | 0.9100 | 5 | 0 | 1.04 | F7 | 0.1562 | [0.732, 1.016] |
| Random/CMA | 0.8498 | 7 | 0 | 1 | F1 | 0.0156 | [0.591, 0.998] |
| jSO/CMA | 1.4357 | 2 | 5 | 1.57e+11 | F1 | 0.3125 | [0.809, 5.227] |

- DE5/CMA 时间比：1.035
- 方向对照胜函数增益：+0

## 门槛
- vs CMA: False
- vs jSO: True
- vs Permuted: False
- vs Random: False
- runtime: True

**判定：STOP_CMA_DE_P0**
