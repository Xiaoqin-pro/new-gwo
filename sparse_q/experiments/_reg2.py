import csv
path = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\experiments\registry.csv"
rows = list(csv.reader(open(path, encoding="utf-8")))
rows.append(["D100","2026-10-16","fd100_20261016_232205","SGWO.m (frozen)","D=100 scalability tier","report tier","29fn x seeds3001-3010 D100 100k","S-star/S1/B1 + audited IGWO/RASE(12fn)",
 "rank first","S* rank 1.72 (S1 2.00, RASE 2.33, B1 3.52, IGWO 3.67); vs IGWO 0.703 W-L 10-2 Holm +5/-1; vs RASE 0.836 6-6 +5/-2; vs B1 0.549 26-3; runtime S* 11.97s",
 "scalability confirmed","870/870 ok"])
rows.append(["20K","2026-10-16","f20k_20261016_235723","SGWO.m (frozen)","20k-FE equal-budget resource tier","report tier","29fn x seeds3001-3010 D50 20k","GWO/B0/B1/S1/S-star",
 "rank first","S* rank 1.97 (S1 2.31, B0 3.10, B1 3.79, GWO 3.83); vs GWO 0.721 W-L 24-5; vs B0 0.807 24-5; vs B1 0.678",
 "resource-constrained regime supported","1450/1450 ok"])
with open(path, "w", encoding="utf-8", newline="") as fh:
    csv.writer(fh).writerows(rows)
print("registry rows:", len(rows))
