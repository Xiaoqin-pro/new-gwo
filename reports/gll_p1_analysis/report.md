# GLL P1（15 函数 × 10 新种子 4251–4260，100k FE）

- 结果目录：`D:\111\Desktop\噜噜\new-gwo-g2tr-branch\sparse_q\results\gll_p1_20261023_233239`（750 次运行，0 失败）
- 预注册：`sparse_q/docs/132_GLL_P1_PREREG.md`

| 对比 | median | wins/15 | >1.20 | max | worst | p | 95% CI |
|---|---:|---:|---:|---:|---:|---:|---:|
| GLL20/Global | 0.9465 | 10 | 2 | 1.79 | F3 | 0.1876 | [0.848, 1.046] |
| GLL20/EuclidKNN10 | 0.9814 | 9 | 2 | 1.41 | F14 | 0.6387 | [0.892, 1.114] |
| GLL20/RandLocal20 | 1.0148 | 7 | 3 | 1.35 | F20 | 0.6387 | [0.941, 1.147] |
| GLL20/Blend0.8 | 0.9554 | 10 | 1 | 1.29 | F13 | 0.1205 | [0.934, 1.044] |
| EuclidKNN10/Global | 0.9536 | 8 | 3 | 1.94 | F3 | 0.5995 | [0.789, 1.161] |
| RandLocal20/Global | 0.9405 | 10 | 1 | 1.82 | F3 | 0.1205 | [0.819, 1.029] |

- GLL20/Global 时间比：1.405

## 门槛
- vs global: True
- vs Euclid: True
- vs random local: False
- runtime: True

**判定：STOP_GLL_P1**
