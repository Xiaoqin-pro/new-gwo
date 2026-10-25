# GLL P0（8 函数 × 5 新种子 4241–4245，100k FE）

- 结果目录：`D:\111\Desktop\噜噜\new-gwo-g2tr-branch\sparse_q\results\gll_p0_20261023_230614`（200 次运行，0 失败）
- 预注册：`sparse_q/docs/130_GLL_P0_PREREG.md`

| 对比 | median | wins/8 | >1.20 | max | worst | p | 95% CI |
|---|---:|---:|---:|---:|---:|---:|---:|
| GLL20/Global | 0.9597 | 5 | 2 | 1.26 | F13 | 0.7422 | [0.667, 1.226] |
| GLL20/EuclidKNN10 | 1.0270 | 3 | 1 | 1.43 | F13 | 0.7422 | [0.862, 1.119] |
| GLL20/RandLocal20 | 1.0526 | 3 | 1 | 1.24 | F30 | 0.7422 | [0.858, 1.174] |
| GLL20/Blend0.8 | 1.1233 | 2 | 3 | 1.29 | F1 | 0.0547 | [0.987, 1.276] |
| EuclidKNN10/Global | 1.0033 | 4 | 1 | 2.3 | F1 | 0.9453 | [0.624, 1.137] |
| RandLocal20/Global | 1.0443 | 3 | 0 | 1.19 | F1 | 0.7422 | [0.906, 1.151] |

- GLL20/Global 时间比：1.392

## 门槛
- vs global: False
- vs Euclid: False
- vs random local: False
- runtime: True

**判定：STOP_GLL_P0**
