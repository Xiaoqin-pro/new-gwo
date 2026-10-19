# -*- coding: utf-8 -*-
import hashlib, os
ROOT = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
def sha(p):
    return hashlib.sha256(open(p,"rb").read()).hexdigest()
files = {
 "sparse_q/src/SGWO.m": r"sparse_q\src\SGWO.m",
 "sparse_q/experiments/runner_sgwo.m": r"sparse_q\experiments\runner_sgwo.m",
 "src/GWO.m": r"src\GWO.m",
 "src/ANGWO.m": r"src\ANGWO.m",
 "wolf/src/IGWO.m": r"..\狼群\src\IGWO.m",
 "sparse_q/src/HAGWO_CEC.m": r"sparse_q\src\HAGWO_CEC.m",
 "sparse_q/src/AOGWO_CEC.m": r"sparse_q\src\AOGWO_CEC.m",
 "sparse_q/src/PSO_CEC.m": r"sparse_q\src\PSO_CEC.m",
 "sparse_q/src/CLPSO_CEC.m": r"sparse_q\src\CLPSO_CEC.m",
}
for k, rel in files.items():
    p = os.path.normpath(os.path.join(ROOT, rel))
    print("%-38s %s" % (k, sha(p) if os.path.exists(p) else "MISSING"))
print()
print("fd100 provenance SGWO   = 325436aa12d876c141e091e330a2fd67ad1e838f3743cd1ba09250f2b4b640ee")
print("fd100 provenance runner = bfa7e92e8e9f788dcf7dbd113fbae0b524f2f72891ca2158187aaa9429e313d5")
print("fd100 provenance GWO    = b9927b569edebb76f31c676bb976e0348b7d9aa00ad6c5e287951e4a3ef17d24")
