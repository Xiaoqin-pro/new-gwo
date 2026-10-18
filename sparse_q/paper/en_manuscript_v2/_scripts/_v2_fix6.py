# -*- coding: utf-8 -*-
import os, re
base = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2"
for fn in ["main.tex", os.path.join("tables","table_setup.tex")]:
    p = os.path.join(base, fn)
    t = open(p, encoding="utf-8").read()
    n = len(re.findall(r"\\texttt\{([^}]*)\}", t))
    t = re.sub(r"\\texttt\{([^}]*)\}", r"\1", t)
    open(p,"w",encoding="utf-8").write(t)
    print(fn, "replaced", n)
