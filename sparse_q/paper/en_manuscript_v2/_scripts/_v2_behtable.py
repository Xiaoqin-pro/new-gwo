# -*- coding: utf-8 -*-
import os
OUT = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\tables"
tbl = r"""
\begin{tabular}{lrrrrr}
\toprule
Method & Recovery prob. & Long-stag.\ share & Useful novelty & Novelty rate Q4 & Improving rate Q4 \\
\midrule
VAST-GWO ($K=10$) & \textbf{0.823} & \textbf{0.813} & \textbf{0.00640} & 0.712 & 0.00308 \\
S1 ($K=50$) & 0.816 & 0.812 & 0.00590 & 0.695 & 0.00266 \\
S3 (quota 25\%) & 0.808 & 0.821 & 0.00563 & 0.745 & 0.00272 \\
S5 (Q-learning) & 0.780 & 0.835 & 0.00629 & 0.716 & 0.00264 \\
ANGWO (frozen reference) & 0.768 & 0.831 & 0.00578 & 0.690 & 0.00447 \\
GWO & 0.757 & 0.844 & 0.00347 & 0.588 & 0.00481 \\
\bottomrule
\end{tabular}
"""
open(os.path.join(OUT,"table_behaviour.tex"),"w",encoding="utf-8").write(tbl.strip()+"\n")
print("behaviour table rewritten")
