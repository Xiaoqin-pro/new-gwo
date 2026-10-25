# Q12 P0（8 函数 × 5 新种子 4222–4226，20k FE）

- 结果目录：`D:\111\Desktop\噜噜\new-gwo-g2tr-branch\sparse_q\results\q12_p0_20261023_222126`（200 次运行，0 失败）
- 预注册：`sparse_q/docs/129_Q12_P0_PREREG.md`

| 对比 | median | wins/8 | >1.20 | max | worst | p | 95% CI |
|---|---:|---:|---:|---:|---:|---:|---:|
| Q12/Standard | 0.9761 | 5 | 1 | 1.27 | F1 | 0.8438 | [0.842, 1.065] |
| Q12/Random12 | 1.1584 | 1 | 3 | 1.99 | F1 | 0.0234 | [1.032, 1.562] |
| Q12/DiffAll | 1.2016 | 2 | 4 | 2.5 | F1 | 0.1484 | [0.856, 2.502] |
| Random12/Standard | 0.9579 | 5 | 0 | 1.12 | F20 | 0.3828 | [0.638, 1.087] |
| DiffAll/Standard | 0.8868 | 4 | 0 | 1.2 | F24 | 0.3125 | [0.415, 1.183] |
| NoSTEER/Standard | 0.9687 | 6 | 0 | 1.05 | F1 | 0.1484 | [0.764, 1.050] |

- Q12/Standard 时间比：1.033

## 门槛
- vs standard: False
- vs random12: False
- vs diff all / tail: False
- runtime: True

**判定：STOP_Q12_P0**

## Q12 动作分布（1=standard, 2=differential）

- F1: 0.769, 0.231
- F4: 0.846, 0.154
- F7: 0.949, 0.051
- F10: 0.949, 0.051
- F13: 0.897, 0.103
- F20: 0.949, 0.051
- F24: 0.923, 0.077
- F30: 0.897, 0.103