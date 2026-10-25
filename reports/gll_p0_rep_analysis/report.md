# GLL P0 独立复现（8 函数 × 5 新种子 4246–4250，100k FE）

- 结果目录：`D:\111\Desktop\噜噜\new-gwo-g2tr-branch\sparse_q\results\gll_p0_rep_20261023_231918`（200 次运行，0 失败）
- 预注册：`sparse_q/docs/131_GLL_P0_REPLICATION_PREREG.md`

| 对比 | median | wins/8 | >1.20 | max | worst | p | 95% CI |
|---|---:|---:|---:|---:|---:|---:|---:|
| GLL20/Global | 0.8565 | 8 | 0 | 0.976 | F24 | 0.0078 | [0.371, 0.962] |
| GLL20/EuclidKNN10 | 0.8275 | 6 | 1 | 1.2 | F30 | 0.0547 | [0.748, 1.009] |
| GLL20/RandLocal20 | 0.9507 | 5 | 0 | 1.17 | F30 | 0.4609 | [0.757, 1.158] |
| GLL20/Blend0.8 | 0.9176 | 5 | 0 | 1.1 | F30 | 0.1953 | [0.785, 1.090] |
| EuclidKNN10/Global | 0.9909 | 4 | 1 | 1.44 | F13 | 1.0000 | [0.892, 1.121] |
| RandLocal20/Global | 0.8959 | 5 | 1 | 1.24 | F10 | 0.2500 | [0.644, 1.051] |

- GLL20/Global 时间比：1.391

## 门槛
- vs global: True
- vs Euclid: True
- vs random local: True
- runtime: True

**判定：PROMOTE_GLL_TO_P1**
