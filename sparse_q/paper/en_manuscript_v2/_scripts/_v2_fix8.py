# -*- coding: utf-8 -*-
import re, os
p = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\main.tex"
t = open(p, encoding="utf-8").read()
# 1) slightly larger text block
t = t.replace("\\usepackage[margin=2.4cm]{geometry}", "\\usepackage[margin=2.2cm]{geometry}", 1)
# 2) shrink wide tables to text width
for name in ["table_taxonomy","table_setup","table_boundaries","table_ablation_design","table_uav_model","table_family","table_main7","table_behaviour","table_tiers","table_ablation","table_uav","table_uav_maps"]:
    old = "\\input{tables/%s.tex}" % name
    new = "\\resizebox{\\linewidth}{!}{\\input{tables/%s.tex}}" % name
    if old in t:
        t = t.replace(old, new, 1)
    else:
        print("not found:", name)
open(p,"w",encoding="utf-8").write(t)
print("tables boxed; margin set")
