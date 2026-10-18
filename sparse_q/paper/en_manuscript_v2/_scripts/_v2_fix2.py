p = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\main.tex"
t = open(p, encoding="utf-8").read()
a = "\\usepackage{newtxtext,newtxmath}\n\\usepackage{microtype}\n\\usepackage{amsmath,amssymb}"
b = "\\usepackage{microtype}\n\\usepackage{amsmath}\n\\usepackage{amssymb}\n\\usepackage{newtxtext}\n\\usepackage{newtxmath}"
assert a in t, "preamble pattern not found"
t = t.replace(a,b)
open(p,"w",encoding="utf-8").write(t)
print("preamble reordered")
