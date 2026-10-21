# SFAC P1 开发实验结果

- 主结果目录：`D:\111\Desktop\噜噜\拯救G2\sparse_q\results\sfac_p1_20261021_000502`
- A3-Off 对照目录：`D:\111\Desktop\噜噜\拯救G2\sparse_q\results\sfac_a3off2_20261021_000758`
- 160 次主运行（V1-Frozen、V1-SFAC），80 次 matched-scaffold A3-Off；失败 0；全部 30,000 真 FE

## 预注册门槛

- 最终误差中位比 SFAC/V1：0.995607
- 逐函数胜/负：4/4；>1.20 的函数数：3
- 运行时间 SFAC/A3-Off：均值 1.032，中位 1.026
- **H1 判定：不通过**

| F | V1 median | SFAC median | SFAC/V1 |
|---:|---:|---:|---:|
| 7 | 350.106 | 433.59 | 1.238 |
| 10 | 11206 | 13597.6 | 1.213 |
| 13 | 672332 | 367139 | 0.5461 |
| 14 | 407285 | 326882 | 0.8026 |
| 16 | 1456 | 1104.56 | 0.7586 |
| 18 | 1.72401e+06 | 2.09161e+06 | 1.213 |
| 22 | 12259.5 | 12644.9 | 1.031 |
| 24 | 621.681 | 596.676 | 0.9598 |

## 机制行为（均值）

- ArcCredZeroFrac：SFAC 0.687 vs A3-Off 0.004167
- ArcGenTopShare：SFAC 0.03145 vs A3-Off 0.03528
- ArcGenEntropy：SFAC 0.8393 vs A3-Off 0.8378
- ArcEvalTopShare：SFAC 0.03208 vs A3-Off 0.03613
- ArcEvalSuccessRate：SFAC 0.711 vs A3-Off 0.7035
- SFAC boost/decay 事件：11921.4 / 4850.1
- ArcStaleFeedback：SFAC 318.6 vs A3-Off 323.1

按预注册规则：H1 不通过则停止 SFAC，不扫描信用参数；H1 通过才进入正式确认。
