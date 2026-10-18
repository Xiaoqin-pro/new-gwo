# -*- coding: utf-8 -*-
p = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\main.tex"
t = open(p, encoding="utf-8").read()
old = "better. Against the frozen reference GWO of the development phase the ratios"
new = "better. Against the frozen development-phase reference (ANGWO) the ratios"
assert old in t
t = t.replace(old,new,1)
old2 = "0.00347 for GWO and 0.00578 for the frozen reference, and the novelty rate in"
new2 = "0.00347 for GWO and 0.00578 for ANGWO, and the novelty rate in"
assert old2 in t
t = t.replace(old2,new2,1)
open(p,"w",encoding="utf-8").write(t)
print("ANGWO naming fixed")
