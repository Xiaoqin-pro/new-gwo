# CASS P0（8 函数 × 5 新种子 4170–4174，100k FE）

- 结果目录：`D:\111\Desktop\噜噜\new-gwo-g2tr-branch\sparse_q\results\cass_p0_20261023_202724`（200 次运行，0 失败）
- 预注册门槛：`sparse_q/docs/127_CASS_P0_PREREG.md`

| 对比 | median | wins/8 | >1.20 | max | worst | p | 95% CI |
|---|---:|---:|---:|---:|---:|---:|---:|
| CASS5/CMA | 1.0625 | 1 | 2 | 1.82 | F4 | 0.2188 | [1.000, 1.356] |
| CASS5/jSO | 0.5444 | 6 | 1 | 5.01 | F13 | 0.2500 | [0.318, 1.082] |
| CASS5/NoCov | 1.0000 | 2 | 0 | 1 | F1 | 0.5000 | [0.819, 1.000] |
| CASS5/CASS10 | 0.9969 | 4 | 3 | 1.52 | F13 | 0.5781 | [0.892, 1.433] |
| NoCov/CMA | 1.1803 | 0 | 3 | 1.82 | F4 | 0.0156 | [1.005, 1.356] |
| CASS10/CMA | 1.0058 | 3 | 1 | 1.46 | F4 | 1.0000 | [0.800, 1.090] |
| jSO/CMA | 1.4346 | 1 | 5 | 1.07e+10 | F1 | 0.1094 | [1.016, 5.841] |

- CASS5/CMA 时间比：1.120

## 门槛
- vs CMA: False
- vs jSO: True
- covariance assimilation: False
- runtime: True

**判定：STOP_CASS_P0**
