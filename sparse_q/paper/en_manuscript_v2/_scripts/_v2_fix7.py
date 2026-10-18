# -*- coding: utf-8 -*-
p = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\main.tex"
t = open(p, encoding="utf-8").read()
a = ("\\usepackage[expansion=false]{microtype}\n"
     "\\usepackage{amsmath}\n"
     "\\usepackage{amssymb}\n"
     "\\usepackage{newtxtext}\n"
     "\\usepackage{newtxmath}\n"
     "\\pdfmapfile{+newtx.map}")
b = ("\\usepackage{mathptmx}\n"
     "\\usepackage[expansion=false]{microtype}\n"
     "\\usepackage{amsmath}\n"
     "\\usepackage{amssymb}")
assert a in t, "font block not found"
t = t.replace(a,b,1)
open(p,"w",encoding="utf-8").write(t)
print("switched to mathptmx")
