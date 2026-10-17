import csv
path = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\experiments\registry.csv"
rows = list(csv.reader(open(path, encoding="utf-8")))
rows = [r for r in rows if r and r[0] != "SCREEN12"]
rows.append(["SCREEN12","2026-10-17","freshv2_20261017_000252","SGWO.m","fresh-seed (3031:3060) D=50 对拍 V1/steer25/steer50/subset20/K5 + IGWO 同批重跑","6 arms","29fn x 30 seeds D50 100k","V1/steer25/steer50/subset20/K5/IGWO","Holm vs IGWO","5220/5220 ok (870 次因 runner 缺 IGWO 分支/DMSGWO 守卫 bug 失败后修复并两次断点续跑, 0 失败保留记录). Holm vs IGWO: V1 +10/-7, steer25 +10/-5, steer50 +9/-6 (mean rank 2.55 第一; vs V1 22-7 且 Holm +2/-0; F6 1.94->1.08, F18 1.74->1.18), subset20 +8/-4 (停滞轴: recov 0.883 vs 0.819, longStag 0.743 vs 0.816 双门槛过), K5 +10/-6","v2 候选 = steer50 或 combo50g20（运行中）","runner bug 修复记录保留"])
with open(path, "w", encoding="utf-8", newline="") as fh:
    csv.writer(fh).writerows(rows)
print("registry rows:", len(rows))
