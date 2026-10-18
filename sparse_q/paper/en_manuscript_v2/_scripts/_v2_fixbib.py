# -*- coding: utf-8 -*-
p = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\references.bib"
t = open(p, encoding="utf-8").read()
t = t.replace("doi={10.1016/j.eswa.2020.114170}", "doi={10.1016/j.eswa.2020.113917}")
old = ("  journal={Scientific Reports}, volume={15}, year={2025}, doi={10.1038/s41598-025-33301-2},\n"
       "  note={Article number to be verified before submission}}")
new = ("  journal={Scientific Reports}, volume={15}, number={1}, pages={3351}, year={2025},\n"
       "  doi={10.1038/s41598-025-33301-2}}")
assert old in t, "zhang entry pattern not found"
t = t.replace(old, new)
t = t.replace("doi={10.1109/TEVC.2005.857074}", "doi={10.1109/TEVC.2005.857610}")
open(p,"w",encoding="utf-8").write(t)
print("bib fixed")
print("check1:", "10.1016/j.eswa.2020.113917" in t)
print("check2:", "10.1109/TEVC.2005.857610" in t)
print("check3 note removed:", "Article number to be verified" not in t)
