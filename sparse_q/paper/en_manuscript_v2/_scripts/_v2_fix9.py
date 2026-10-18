# -*- coding: utf-8 -*-
p = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\main.tex"
t = open(p, encoding="utf-8").read()

reps = [
# abstract
("""verified archive carries the improvement---removing it degrades the method to
27 losses in 29 functions, and replacing it with a single alpha-centred sampler
collapses it to 2 wins---while the alpha-shell route is optional once the
archive is present.""",
 """verified archive carries the improvement: a GWO-only candidate pool loses 27
of the 29 functions to the full method, replacing the archive with a
single alpha-centred sampler with identical slots, scale and acceptance rule
collapses the method to 2 wins, and the alpha-shell route is optional once the
archive is present."""),
# introduction
("""the verified archive is the performance engine: removing it produces 27 losses
in 29 functions, replacing it with a single alpha-centred sampler with
identical slots, scale and acceptance rule collapses the method to 2 wins, and""",
 """the verified archive is the performance engine: a GWO-only pool loses 27 of the
29 functions to the full method, replacing the archive with a single
alpha-centred sampler with identical slots, scale and acceptance rule collapses
the method to 2 wins, and"""),
# conclusion
("""that the verified multi-region archive is the performance engine: removing it
produces 27 losses in 29 functions, and replacing it with a single-centre
sampler with identical slots, scale and acceptance rule collapses the method
to 2 wins, whereas the alpha-shell route becomes optional once the archive is
present.""",
 """that the verified multi-region archive is the performance engine: a pool of
standard GWO moves alone loses 27 of the 29 functions to the full method, and
replacing the archive with a single-centre sampler with identical slots, scale
and acceptance rule collapses the method to 2 wins, whereas the alpha-shell
route becomes optional once the archive is present."""),
]
for old,new in reps:
    assert old in t, "missing: " + old[:60]
    t = t.replace(old,new,1)
open(p,"w",encoding="utf-8").write(t)
print("accuracy fixes applied")
