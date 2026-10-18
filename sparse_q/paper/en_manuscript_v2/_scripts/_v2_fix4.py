p = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\main.tex"
t = open(p, encoding="utf-8").read()
a = "\\usepackage{newtxmath}"
b = ("\\usepackage{newtxmath}\n"
     "% ensure the newtx type1 map is available in this local MiKTeX profile\n"
     "\\pdfmapfile{+newtx.map}")
assert a in t
t = t.replace(a,b,1)
open(p,"w",encoding="utf-8").write(t)
print("map directive added")
