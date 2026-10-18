p = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\main.tex"
t = open(p, encoding="utf-8").read()
a = "\\usepackage{microtype}"
b = "\\usepackage[expansion=false]{microtype}"
assert a in t
t = t.replace(a,b,1)
open(p,"w",encoding="utf-8").write(t)
print("microtype expansion disabled")
