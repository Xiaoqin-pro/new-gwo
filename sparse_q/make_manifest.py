# -*- coding: utf-8 -*-
"""manifest.json for the D=100 supplementary experiment (paper-grade record)."""
import os, sys, json, hashlib, platform, subprocess
import pandas as pd, numpy as np
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass
SQ = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SQ)
OUT = os.path.join(SQ, "results", "d100_analysis")
os.makedirs(OUT, exist_ok=True)
NEW = os.path.join(SQ, "results", "d100_formal_20261018")

def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest() if os.path.isfile(p) else None

def git(*a):
    try: return subprocess.check_output(["git"]+list(a), cwd=ROOT).decode().strip()
    except Exception: return None

def main():
    raw = pd.read_csv(os.path.join(OUT, "raw_runs.csv"), low_memory=False)
    raw = raw[raw.Status == "ok"]
    prov = {}
    import scipy.io as sio
    m = sio.loadmat(os.path.join(NEW, "provenance.mat"), squeeze_me=True, struct_as_record=False)
    pr = m["prov"]
    h = pr.hashes
    hashes = {f: getattr(h, f) for f in h._fieldnames}

    man = {
        "experiment": "VAST-GWO D=100 high-dimensional generalization (supplementary)",
        "protocol_document": "sparse_q/docs/17_D100_PREREG.md",
        "preregistered_before_run": True,
        "benchmark": {"name": "CEC2017", "functions": [1]+list(range(3,31)),
                      "n_functions": 29, "dimension": 100,
                      "bounds": [-100, 100],
                      "official_note": "F2 is not part of the CEC2017 single-objective suite"},
        "budget": {"true_function_evaluations": 100000, "initialisation_included": True,
                   "best_so_far_record": "T(fe), monotone non-increasing"},
        "population_size": 50,
        "seeds": {"reused_vast": list(range(3001,3011)), "new": list(range(3011,3031)),
                  "all": list(range(3001,3031)), "n": 30},
        "random_streams": {
            "init_seed_rule": "261013000 + function_id*10000 + seed",
            "search_seed_rule": "seed + 1000000",
            "initial_pool": "-100 + 200*rand(50,D) after rng(initSeed,'twister')",
            "separation": "initialisation RNG and search RNG are distinct streams"},
        "algorithms": {
            "VAST-GWO": {"family":"SGWO","source":"sparse_q/src/SGWO.m",
                         "state":{"mode":"sparse","K":10,"nG2":12,"nE":38,"screenPolicy":"random"},
                         "reused_rows":290,"new_rows":580},
            "GWO": {"family":"GWO","source":"src/GWO.m","new_rows":870},
            "IGWO": {"family":"IGWO","source":"D:/111/Desktop/噜噜/狼群/src/IGWO.m","new_rows":870},
            "HAGWO": {"family":"HAGWO","source":"sparse_q/src/HAGWO_CEC.m","new_rows":870},
            "PSO": {"family":"PSO","source":"sparse_q/src/PSO_CEC.m","new_rows":870},
            "CLPSO": {"family":"CLPSO","source":"sparse_q/src/CLPSO_CEC.m","new_rows":870,
                      "note":"N=50 uniform protocol; TEC2006 original code"},
            "AOGWO": {"family":"AOGWO","source":"sparse_q/src/AOGWO_CEC.m","new_rows":870,
                      "note":"author hybrid-OBL initialisation applied to the shared pool"}},
        "code_hashes_sha256": hashes,
        "data_sources": {
            "new_batch": "sparse_q/results/d100_formal_20261018",
            "reused_archive": "sparse_q/results/fd100_20261016_232205 (S-star, seeds 3001:3010)",
            "reuse_evidence": "290/290 bitwise identical re-run (results/d100repro_20261018_200546)"},
        "row_counts": {a: int((raw.Algorithm==a).sum()) for a in raw.Algorithm.unique()},
        "total_rows": int(len(raw)),
        "parallel": {"workers": 4, "backend": "MATLAB parpool('local',4) + parfor"},
        "runtime_environment": {"matlab": prov.get("matlab") if isinstance(prov, dict) else None,
                                "platform": platform.platform(), "python": platform.python_version(),
                                "cpu_logical": os.cpu_count()},
        "git": {"root": ROOT, "commit": git("rev-parse","HEAD"),
                "branch": git("branch","--show-current")},
        "generated": pd.Timestamp.now().isoformat(),
        "statistics_plan": {
            "unit": "function-level paired seeds (29 functions x 30 seeds)",
            "test": "two-sided Wilcoxon signed-rank on log10 error differences, per function",
            "multiplicity": "Holm within each baseline family (29 tests); global 6x29 Holm as sensitivity",
            "effect": "median paired error ratio (VAST/base) at function level; median across 29 functions",
            "ci": "10,000 function-level bootstrap of the 29 function medians",
            "rank": "per-function median-error rank, averaged over 29 functions",
            "runtime": "new seeds 3011:3030 only",
            "fe_vs_iterations": "equal FE is not equal iterations; per-algorithm generation counts reported"},
    }
    # numeric sanity of hashes
    for k,v in man["code_hashes_sha256"].items():
        assert v and len(v)==64, (k,v)
    p = os.path.join(OUT, "manifest.json")
    with open(p, "w", encoding="utf-8", newline="\n") as f:
        json.dump(man, f, indent=2, ensure_ascii=False)
    print("wrote", p)

if __name__ == "__main__":
    main()
