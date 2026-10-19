# D=100 结果写入论文的整合说明

> 本文件只给出补丁与替换文本，**不覆盖** `paper/en_manuscript_v2/main.tex`、D=50 主表或历史报告。

## 1. 现有稿件的冲突点

`paper/en_manuscript_v2/main.tex` 第 487 行写的是旧的 D=100 10 种子、3 臂结果（“1.72 against 2.00, 2.33, 3.52 and 3.67 … I-GWO on the twelve functions”）。该结果已被本轮 7 算法 × 29 函数 × 30 种子的完整补充实验取代。

**必须替换，不能并存**，否则审稿人会发现同一实验两套数字。

## 2. 替换操作

1. 在 `main.tex` 导言区加入：`\input{sections/d100_supplement}` 需要放在 `\subsection{Additional operating points}` 之后（或直接替换该小节前半段）。
2. 删除/改写 690–700 行关于旧 D=100 的段落，保留 20k FE 的段落。
3. 同步 `Computational cost` 小节的 D=100 时间：旧值 “11.97 s against 8.32 s and 7.83 s” 为三臂结果；新七算法中位值见下表。

## 3. 新七算法 D=100 时间（种子 3011:3030）

| 算法 | 中位秒 | IQR | 相对 GWO |
|---|---:|---:|---:|
| VAST-GWO | 8.33 | 7.98 | 1.98× |
| GWO | 4.20 | 7.71 | 1.00× |
| IGWO | 4.47 | 7.76 | 1.07× |
| HAGWO | 4.54 | 7.87 | 1.08× |
| PSO | 3.87 | 7.74 | 0.92× |
| CLPSO | 4.57 | 6.97 | 1.09× |
| AOGWO | 6.40 | 6.79 | 1.52× |

## 4. 摘要/结论可用句（英文）

At $D=100$ with the same 100{,}000-evaluation budget and 30 seeds, VAST-GWO retains the lowest mean rank (1.76 versus 2.76 for I-GWO), with significantly more function-level wins than losses against all six baselines after Holm correction; the advantage is not universal, as six functions remain significantly worse than I-GWO.

## 5. 不可写的句子

- “VAST-GWO significantly outperforms all baselines on every function.”（不成立）
- “The D=100 advantage is larger, therefore the method scales.”（对 GWO 的比值实际由 0.525 变为 0.561）
- “At equal FE the methods perform equal iterations.”（不成立）

## 6. 文件清单

| 文件 | 用途 |
|---|---|
| `en_manuscript_v2/sections/d100_supplement.tex` | 可直接 `\input` 的小节（含 4 图 1 表） |
| `en_manuscript_v2/tables/table_d100_main.tex` | 主表 |
| `en_manuscript_v2/figures/figure_d100_*.png` | 论文图 |
| `results/d100_analysis/` | 全部原始数据、统计、审计 |
| `reports/D100_SUPPLEMENT_zh.md` | 中文补充报告 |
