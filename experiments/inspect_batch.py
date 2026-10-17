#!/usr/bin/env python3
"""Quick inspection of a batch: identity checks and per-function ratios vs a reference."""
import glob, os, sys
import numpy as np, pandas as pd

batch = sys.argv[1]
ref = sys.argv[2] if len(sys.argv) > 2 else "GWO"
df = pd.read_csv(os.path.join(batch, "runs.csv"))
piv = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
print("algorithms:", list(piv.columns))
algs = [a for a in piv.columns if a != ref]
for a in algs:
    r = piv.groupby(level=0).apply(lambda g: np.median(g[a] / g[ref]), include_groups=False)
    ov = np.median(piv[a] / piv[ref])
    wl = (piv.groupby(level=0).apply(lambda g: g[a].mean() < g[ref].mean(), include_groups=False)).sum()
    print(f"{a:22s} overall_ratio={ov:7.3f}  fnW={wl}/{piv.index.get_level_values(0).nunique()}")
    print("   " + " ".join(f"F{int(k)}:{v:6.3f}" for k, v in r.items()))
# pairwise identity check between suspicious columns
import itertools
for a, b in itertools.combinations(algs, 2):
    if np.allclose(piv[a], piv[b], rtol=0, atol=0):
        print(f"!! {a} is bitwise identical to {b}")
