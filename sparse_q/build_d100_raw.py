# -*- coding: utf-8 -*-
"""Build raw_runs.csv for D=100 by merging the new formal batch with the
audited/reused archived VAST-GWO rows (seeds 3001:3010), verifying every row."""
import os, sys, json, hashlib
import numpy as np, pandas as pd, scipy.io as sio
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass

SQ = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(SQ, "results", "d100_analysis")
os.makedirs(OUT, exist_ok=True)
NEW = os.path.join(SQ, "results", "d100_formal_20261018")
OLD = os.path.join(SQ, "results", "fd100_20261016_232205")
ALGS = ["VAST-GWO","GWO","IGWO","HAGWO","PSO","CLPSO","AOGWO"]
FUNCS = [1] + list(range(3, 31))

def sha(p): return hashlib.sha256(open(p,"rb").read()).hexdigest()

def read_batch(d, algo_map=None, only=None):
    t = pd.read_csv(os.path.join(d,"runs.csv"), low_memory=False)
    if only is not None: t = t[t.Algorithm.isin(only)]
    if algo_map: t = t.assign(Algorithm=t.Algorithm.replace(algo_map))
    return t

def verify_mat(d, runid, expect_alg, expect_fid, expect_seed):
    """Return (error_or_None, init_seed, search_seed) read from the MAT record."""
    p = os.path.join(d, "runs", "run_%05d.mat" % int(runid))
    if not os.path.exists(p): return "missing mat", None, None
    m = sio.loadmat(p, squeeze_me=True, struct_as_record=False)
    r = m["record"]; res = r.result
    if str(r.status) != "ok": return "status " + str(r.status), None, None
    if int(res.FunctionID) != int(expect_fid): return "fid mismatch", None, None
    if int(res.Seed) != int(expect_seed): return "seed mismatch", None, None
    if int(res.D) != 100: return "D mismatch", None, None
    if int(res.Evaluations) != 100000 or int(res.ProbeFE) != 100000: return "FE mismatch", None, None
    return None, int(res.InitSeed), int(res.SearchSeed)

def main():
    new = read_batch(NEW)
    old = read_batch(OLD, only=["S-star"])
    old = old[old.Seed <= 3010].copy()
    old["Algorithm"] = "VAST-GWO"
    old["Source"] = "archived_fd100_20261016_232205(reused,bitwise-verified)"
    new = new.copy(); new["Source"] = "d100_formal_20261018"

    problems = []
    meta = {}
    for df, d, name in [(new, NEW, "new"), (old, OLD, "old")]:
        for idx, row in df.iterrows():
            e, iseed, sseed = verify_mat(d, row.RunID, row.Algorithm, row.FunctionID, row.Seed)
            if e: problems.append((name, int(row.RunID), e))
            meta[(name, int(row.RunID))] = (iseed, sseed)
    print("MAT verification problems:", problems[:10], "total", len(problems))

    # per-row self-describing metadata (parameters + code hash + seeds)
    H = {}
    import scipy.io as _sio
    pr = _sio.loadmat(os.path.join(NEW, "provenance.mat"), squeeze_me=True,
                      struct_as_record=False)["prov"]
    for f in pr.hashes._fieldnames:
        H[f] = getattr(pr.hashes, f)
    P = {
        "VAST-GWO": ("SGWO", "mode=sparse;K=10;nG2=12;nE=38;archiveCap=24;dSepFrac=0.02;screenPolicy=random", H["SGWO"]),
        "GWO":      ("GWO",  "canonical GWO; a: 2->0 over true-FE budget", H["GWO"]),
        "IGWO":     ("IGWO", "published I-GWO; 2N evaluations per generation", H["IGWO"]),
        "HAGWO":    ("HAGWO","author code; dynamic tiers 10/30%->30/30%", H["HAGWO"]),
        "PSO":      ("PSO",  "w 0.9->0.4; c1=c2=2; vmax=0.2*range", H["PSO"]),
        "CLPSO":    ("CLPSO","TEC2006 original; N=50; refresh interval 5; w 0.9->0.2", H["CLPSO"]),
        "AOGWO":    ("AOGWO","author code; hybrid-OBL init; a=2cos(pi/2*prog)", H["AOGWO"]),
    }
    def attach(frame, name):
        frame = frame.copy()
        frame["PopulationN"] = 50
        frame["Parameters"] = frame.Algorithm.map(lambda a: P[a][1])
        frame["CodeFamily"] = frame.Algorithm.map(lambda a: P[a][0])
        frame["CodeHash"] = frame.Algorithm.map(lambda a: P[a][2])
        frame["InitSeed"] = [meta[(name, int(r.RunID))][0] for _, r in frame.iterrows()]
        frame["SearchSeed"] = [meta[(name, int(r.RunID))][1] for _, r in frame.iterrows()]
        return frame
    new = attach(new, "new"); old = attach(old, "old")

    keep = ["RunID","Algorithm","Family","FunctionID","D","Seed","Status","Message",
            "BestCost","FinalError","Evaluations","ProbeFE","Rounds","Seconds",
            "CheckT10","CheckT20","CheckT50","CheckT80","CheckT100",
            "PopulationN","Parameters","CodeFamily","CodeHash","InitSeed","SearchSeed","Source"]
    for c in keep:
        if c not in new.columns: new[c] = np.nan
        if c not in old.columns: old[c] = np.nan
    both = pd.concat([new[keep], old[keep]], ignore_index=True)
    both = both[both.Status == "ok"].copy()
    both["FinalError"] = both.BestCost.astype(float) - 100.0 * both.FunctionID.astype(float)

    # integrity
    dup = both.duplicated(["Algorithm","FunctionID","Seed"], keep=False)
    print("duplicates:", int(dup.sum()))
    if dup.any(): print(both[dup].sort_values(["Algorithm","FunctionID","Seed"]).head(20).to_string())
    for a in ALGS:
        d = both[both.Algorithm == a]
        print(f"{a:>9}: rows={len(d):4d} fn={d.FunctionID.nunique():2d} seeds={d.Seed.nunique():2d} "
              f"FEok={bool((d.Evaluations==100000).all())} minSeed={d.Seed.min()} maxSeed={d.Seed.max()}")
    both = both.sort_values(["FunctionID","Seed","Algorithm"]).reset_index(drop=True)
    both.to_csv(os.path.join(OUT,"raw_runs.csv"), index=False)
    print("wrote", os.path.join(OUT,"raw_runs.csv"), len(both))

if __name__ == "__main__":
    main()
