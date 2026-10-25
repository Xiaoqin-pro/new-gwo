# 最终算法 29×30 消融（seeds 3071–3100，100k FE）

- 新臂：`sparse_q/results/final_ablation_confirm30_20261024_194759`（3480 次）
- 复用对照：`sparse_q/results/ablcore_20261017_062209`（A0-GWOonly / A2-G1E，同种子）

| 对比 | median | wins/29 | >1.20 | p |
|---|---:|---:|---:|---:|
| A-Final vs GWOonly | 0.3609 | 29/29 | 0 | 0.0000 |
| A-Final vs G1E | 0.9028 | 25/29 | 0 | 0.0000 |
| A-Final vs NoDiff | 0.9166 | 25/29 | 0 | 0.0000 |
| A-Final vs NoE | 0.8801 | 26/29 | 0 | 0.0000 |
| A-Final vs NoSteer | 0.9867 | 19/29 | 3 | 0.3042 |