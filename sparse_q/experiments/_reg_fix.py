import csv
path = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\experiments\registry.csv"
rows = list(csv.reader(open(path, encoding="utf-8")))
# drop the pending SCREEN10/SCREEN12 rows to re-add with results
keep = [r for r in rows if r and r[0] not in ("SCREEN10", "SCREEN12")]
keep.append(["SCREEN10","2026-10-16","sq10_20261016_231226","SGWO.m","Phase-4: radius boost / success steering / coordinate-subset","3 single changes + combo","8fn x 10 seeds D30 30k","ref/boost3/steer25/steer50/subset20/both","gate","steer25 PASS 0.934 (5-3); subset20 0.991 (2-6) but stagnation axis recov 0.887 vs 0.815, longStag 0.785 vs 0.852, novUse +28%; boost3 1.204 / steer50 1.018 / both 1.190 FAIL","steer25+subset20 to fresh validation","options default off; frozen semantics bitwise-audited"])
keep.append(["SCREEN11","2026-10-16","sq11_20261016_231717","SGWO.m","combination steer25+subset20","combo","8fn x 10 seeds D30 30k","ref/steer25/subset20/combo","gate","combo 1.000 (3-5) error-neutral but keeps stagnation gains (recov 0.883, longStag 0.789); per-options reproduce bitwise","kept as documented variant","error and stagnation axes do not add"])
keep.append(["HOLM-IGWO","2026-10-16","final_20261016_215309","-","Holm-corrected significance vs IGWO (user's target metric)","analysis","29fn x 30 seeds D50","S-star vs IGWO","report","+12/-6: sig wins F1,3,5,8,9,21,22,23,24,25,26,28; sig losses F6,F12,F19,F27,F29,F30; near-miss losses F11 p=0.081, F14 p=0.055, F18 p=0.012 raw","Phase-4 iteration targets","steer50 nearly flips F6/F18 on dev"])
keep.append(["SCREEN12","2026-10-16","freshv2_*","SGWO.m","fresh-seed D50 head-to-head incl. IGWO rerun","6 arms","29fn x seeds3031-3060 D50 100k","V1/steer25/steer50/subset20/K5/IGWO-fresh","Holm vs IGWO + dual axis","PENDING","gated","docs/10_FRESH_V2.md"])
with open(path, "w", encoding="utf-8", newline="") as fh:
    csv.writer(fh).writerows(keep)
print("registry updated, rows:", len(keep))
