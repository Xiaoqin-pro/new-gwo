import numpy as np, pandas as pd
cm = np.load(r"D:\111\Desktop\噜噜\基础版狼群\文章\_analysis\_igwo_colmap.npy")
df = pd.DataFrame(cm, columns=["F","Seed","Col"])
funcs = [1,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]
pos = {f:i for i,f in enumerate(funcs)}
ok=True
for start in [3001,3011,3021]:
    sub = df[(df.Seed>=start)&(df.Seed<start+10)]
    base = sub.Col.min()
    pred = base + (sub.Seed-start)*29 + sub.F.map(pos)
    good = (pred.values == sub.Col.values)
    print(start, "base", base, "n", len(sub), "rule holds:", good.all())
    if not good.all():
        bad = sub[~good]; print(bad.head()); ok=False
print("all rules hold:", ok)
# build full mapping incl. ambiguous via rule
full={}
for start in [3001,3011,3021]:
    sub = df[(df.Seed>=start)&(df.Seed<start+10)]
    base = int(sub.Col.min())
    for f in funcs:
        for s in range(start,start+10):
            full[(f,s)] = base + (s-start)*29 + pos[f]
print("full mapping size", len(full), "max col", max(full.values()))
missing = df[~df.apply(lambda r: full[(int(r.F),int(r.Seed))]==r.Col, axis=1)]
print("contradictions:", len(missing))
np.save(r"D:\111\Desktop\噜噜\基础版狼群\文章\_analysis\_igwo_colmap_full.npy",
        np.array([[f,s,c] for (f,s),c in sorted(full.items())]))
print("saved full")
