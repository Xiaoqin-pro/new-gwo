#!/usr/bin/env python3
"""Cross-batch reproducibility audit: compare overlapping (label, fn, seed) rows.

Usage: python audit_reproducibility.py <batchA/runs.csv> <batchB/runs.csv> [LabelA=LabelB ...]
Exits non-zero if any overlapping FinalError differs beyond 1e-12 relative.
"""
import sys
import numpy as np, pandas as pd

a = pd.read_csv(sys.argv[1])
b = pd.read_csv(sys.argv[2])
pairs = {}
for spec in sys.argv[3:]:
    x, y = spec.split("=", 1)
    pairs[x] = y
if not pairs:
    for lab in sorted(set(a.Algorithm) & set(b.Algorithm)):
        pairs[lab] = lab

bad = 0
for la, lb in pairs.items():
    A = a[a.Algorithm == la][["FunctionID", "Seed", "FinalError"]]
    B = b[b.Algorithm == lb][["FunctionID", "Seed", "FinalError"]]
    m = A.merge(B, on=["FunctionID", "Seed"], suffixes=("_a", "_b"))
    if len(m) == 0:
        print(f"{la} = {lb}: no overlap")
        continue
    rel = np.abs(m.FinalError_a - m.FinalError_b) / np.maximum(1.0, np.abs(m.FinalError_a))
    ok = np.all(rel < 1e-12)
    bad += 0 if ok else 1
    print(f"{la} = {lb}: overlap {len(m)} rows, bitwise-identical={ok}, max rel diff={rel.max():.3e}")
sys.exit(1 if bad else 0)
