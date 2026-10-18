# -*- coding: utf-8 -*-
p = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\main.tex"
t = open(p, encoding="utf-8").read()
anchor = "\\setlength{\\parskip}{0.35em}"
add = anchor + """
% allow floats to be placed alongside the text instead of being deferred
\\renewcommand{\\topfraction}{0.92}
\\renewcommand{\\bottomfraction}{0.75}
\\renewcommand{\\textfraction}{0.06}
\\renewcommand{\\floatpagefraction}{0.72}
\\setcounter{topnumber}{3}
\\setcounter{bottomnumber}{2}
\\setcounter{totalnumber}{4}"""
assert anchor in t
t = t.replace(anchor, add, 1)
open(p,"w",encoding="utf-8").write(t)
print("float parameters added")
