import scipy.io as sio, numpy as np, pandas as pd, os
# 1) ordering check for merged_30seed traces
p = r"D:\111\Desktop\噜噜\狼群\results\merged_30seed"
runs = pd.read_csv(os.path.join(p,"runs.csv"))
m = sio.loadmat(os.path.join(p,"traces.mat"), squeeze_me=True, struct_as_record=False)
Tr = m["Traces"]; fe = m["traceFE"]
print("Traces", Tr.shape, "FE", fe[:3], fe[-1], "runs", len(runs))
idx = runs[(runs.Algorithm=="IGWO")&(runs.FunctionID==1)&(runs.Seed==3001)].index
print("row index:", idx.tolist())
for i in idx[:1]:
    col = Tr[:, i]
    print("last trace val:", col[-1], "FinalCost:", runs.loc[i,"FinalCost"], "match:", np.isclose(col[-1], runs.loc[i,"FinalCost"]))
# 2) CLPSO run dir jobs
q = r"D:\111\Desktop\噜噜\9.29\results\cec\saq_cso_formal_100k_30seed_study_20261013_083541"
mani = pd.read_csv(os.path.join(q,"job_manifest.csv"))
print("manifest cols:", list(mani.columns)[:12], len(mani))
cl = mani[mani.Condition=="CLPSO-AuthorSource"]
print("CLPSO jobs:", len(cl), "functions", sorted(cl.FunctionID.unique())[:5], "...")
row = cl[(cl.FunctionID==1)&(cl.Seed==3001)].iloc[0]
fp = os.path.join(q,"runs","job_%04d.mat"%int(row.JobID))
mm = sio.loadmat(fp, squeeze_me=True, struct_as_record=False)
T = np.asarray(mm["T"]).ravel(); rec = mm["rec"]
print("T len", len(T), "T(end)", T[-1], "FinalCost", rec.FinalCost, "match:", np.isclose(T[-1], rec.FinalCost))
