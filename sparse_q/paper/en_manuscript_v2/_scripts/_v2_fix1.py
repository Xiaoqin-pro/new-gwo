# -*- coding: utf-8 -*-
p = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\main.tex"
t = open(p, encoding="utf-8").read()

a = (r"leaders, archives, rankings or statistics. \method{} is therefore the first"
     "\n" r"GWO variant, to our knowledge, whose memory is \emph{exactly} the set of"
     "\n" r"positions that were paid for by a real evaluation.")
b = (r"leaders, archives, rankings or statistics, so search memory is \emph{exactly}"
     "\n" r"the set of positions that were paid for by a real evaluation---a discipline"
     "\n" r"that matters here because five of every six generated candidates are never"
     "\n" r"evaluated.")
assert a in t, "A missing"
t = t.replace(a, b)

c = (r"simplification adopted for convenience; it is the best of seven tested"
     "\n" r"allocation policies, including a learned one.")
d = (r"simplification adopted for convenience: of the eight alternative allocation"
     "\n" r"policies that were tested against it---directed screening, three informed"
     "\n" r"allocation rules, a fixed-quota rule scanned at three levels, and three"
     "\n" r"Q-learning schedulers---none improved on it.")
assert c in t, "C missing"
t = t.replace(c, d)
open(p, "w", encoding="utf-8").write(t)
print("fixes applied")
