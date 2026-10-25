# FL-GWO P0（8 函数 × 5 新种子 4266–4270，100k FE）

- 结果目录：`D:\111\Desktop\噜噜\new-gwo-g2tr-branch\sparse_q\results\flgwo_p0_20261024_003148`（200 次运行，0 失败）
- 预注册：`sparse_q/docs/135_FLGWO_P0_PREREG.md`

| 对比 | median | wins/8 | >1.20 | max | worst | p | 95% CI |
|---|---:|---:|---:|---:|---:|---:|---:|
| FL10/Global | 0.8180 | 5 | 1 | 1.29 | F4 | 0.2500 | [0.516, 1.103] |
| FL10/RandAll10 | 1.0046 | 4 | 1 | 1.39 | F13 | 0.8438 | [0.879, 1.195] |
| FL10/GLL20 | 0.9896 | 5 | 2 | 1.61 | F13 | 1.0000 | [0.808, 1.335] |
| FL30/Global | 0.6694 | 6 | 2 | 1.28 | F30 | 0.0781 | [0.365, 1.206] |
| RandAll10/Global | 0.7496 | 6 | 0 | 1.04 | F4 | 0.0547 | [0.392, 1.013] |

- FL10/Global 时间比：1.384

## 门槛
- vs global: False
- vs random local: False
- vs GLL20: True
- runtime: True

**判定：STOP_FLGWO_P0**
