# -*- coding: utf-8 -*-
"""Phase-1 audit: integrity of the archived D=100 batch (fd100_20261016_232205)."""
import os, sys, glob
import numpy as np, pandas as pd, scipy.io as sio
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass
SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
B  = os.path.join(SQ, "results", "fd100_20261016_232205")
df = pd.read_csv(os.path.join(B, "runs.csv"))
print("runs.csv rows:", len(df), "status:", df.Status.value_counts().to_dict())
bad = []
for _, row in df[df.Algorithm == "S-star"].iterrows():
    fid = int(row.FunctionID); seed = int(row.Seed)
    fp = os.path.join(B, "runs", "run_%05d.mat" % int(row.RunID))
    if not os.path.exists(fp):
        bad.append((row.RunID, "missing file")); continue
    m = sio.loadmat(fp, squeeze_me=True, struct_as_record=False)
    rec = m["record"]
    if str(rec.status) != "ok":
        bad.append((row.RunID, "record not ok")); continue
    res = rec.result
    T = np.asarray(res.Trace).ravel(); fe = np.asarray(res.TraceFE).ravel()
    if res.Evaluations != 100000 or res.ProbeFE != 100000:
        bad.append((row.RunID, "FE mismatch"))
    if np.any(np.diff(T) > 1e-12):
        bad.append((row.RunID, "trace not monotone"))
    if abs(T[-1] - res.BestCost) > 1e-9 * max(1.0, abs(res.BestCost)):
        bad.append((row.RunID, "trace end != best"))
    if abs((res.BestCost - 100.0 * fid) - row.FinalError) > 1e-6 * max(1.0, abs(row.FinalError)):
        bad.append((row.RunID, "FinalError mismatch"))
    if res.D != 100 or res.Seed != seed or res.FunctionID != fid:
        bad.append((row.RunID, "metadata mismatch"))
print("S-star rows checked:", (df.Algorithm == "S-star").sum(), "problems:", len(bad))
for b in bad[:10]: print("   ", b)
# rounds expectation for K=10 sparse
s = df[df.Algorithm == "S-star"]
print("Rounds: min", s.Rounds.min(), "max", s.Rounds.max(), "expected (100000-50)/10 =", (100000-50)//10)
print("Seconds by arm:")
print(df.groupby("Algorithm").Seconds.agg(["mean", "median"]).round(2))
print("NCandidateGenerated (S-star) median:", s.NCandidateGenerated.median())
