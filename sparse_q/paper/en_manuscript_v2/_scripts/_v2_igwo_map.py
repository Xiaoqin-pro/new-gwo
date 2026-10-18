import pandas as pd, scipy.io as sio, numpy as np, os
IGD = r"D:\111\Desktop\噜噜\狼群\results\merged_30seed"
runs = pd.read_csv(os.path.join(IGD,"runs.csv"))
mm = sio.loadmat(os.path.join(IGD,"traces.mat"), squeeze_me=True, struct_as_record=False)
Tr = mm["Traces"]
fin = Tr[-1,:]
ig = runs[runs.Algorithm=="IGWO"].reset_index(drop=True)
colmap={}
amb=0
for i,row in ig.iterrows():
    hit = np.where(np.isclose(fin, row.FinalCost))[0]
    if len(hit)!=1: amb+=1; continue
    colmap[(int(row.FunctionID),int(row.Seed))] = int(hit[0])
print("IGWO rows", len(ig), "mapped", len(colmap), "ambiguous", amb)
missing = [(f,s) for f in sorted(ig.FunctionID.unique()) for s in sorted(ig.Seed.unique()) if (f,s) not in colmap]
print("missing:", missing[:10])
cols = sorted(colmap.values()); print("col range", cols[0], cols[-1])
print("sample", list(colmap.items())[:5])
np.save(r"D:\111\Desktop\噜噜\基础版狼群\文章\_analysis\_igwo_colmap.npy",
        np.array([[k[0],k[1],v] for k,v in sorted(colmap.items())]))
print("saved colmap")
