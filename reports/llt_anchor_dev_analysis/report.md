# LLT anchor 开发验证（8 函数 x 5 种子）

- 结果目录：`D:\111\Desktop\噜噜\new-gwo-g2tr-branch\sparse_q\results\llt_anchor_dev_20261022_050302`
- 160 次运行，0 失败

## 预注册选择规则

- m = median_F(median_seed(anchor/frozen)) = **1.1030**（要求 ≤0.9）
- c = max_F(median_seed(anchor/frozen)) = **1.2149**（要求 ≤1.2）
- 参考：ring 版本 m=1.0550，c=1.9122
- anchor vs anchorrand：中位 0.9253，胜 6/8

**最终判定：STOP_LLT**

| F | anchor/frozen | anchor/anchorrand | ring/frozen |
|---:|---:|---:|---:|
| 1 | 1.0752 | 1.0492 | 0.5580 |
| 3 | 1.1995 | 0.8582 | 1.3851 |
| 4 | 0.9426 | 0.8541 | 1.2394 |
| 7 | 0.4521 | 0.9478 | 0.4762 |
| 10 | 1.1308 | 1.1795 | 0.9230 |
| 13 | 1.2149 | 0.9953 | 0.6243 |
| 14 | 0.8426 | 0.3274 | 1.9122 |
| 30 | 1.1751 | 0.9029 | 1.1870 |
