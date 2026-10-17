#!/usr/bin/env python3
"""Aggregate Q-learning window traces from run MAT files (requires the runner
option that stores SGWO.QuotaTrace; used for the qdiag batches).

Usage: python analyze_q_windows.py <batch_dir> [label]
"""
import glob
import os
import sys
import numpy as np
import scipy.io as sio

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass


def get(obj, name, default=None):
    return getattr(obj, name, default) if hasattr(obj, name) else default


def main():
    batch = sys.argv[1]
    label = sys.argv[2] if len(sys.argv) > 2 else None
    files = sorted(glob.glob(os.path.join(batch, "runs", "run_*.mat")))
    act_by_state = np.zeros((6, 3))
    rows = []
    n = 0
    for f in files:
        m = sio.loadmat(f, squeeze_me=True, struct_as_record=False)
        r = m["record"]
        if str(get(getattr(r, "status", ""), "__str__", lambda: "")) != "" and str(getattr(r, "status", "")) != "ok":
            continue
        res = getattr(r, "result", None)
        if res is None:
            continue
        if label is not None and str(getattr(res, "Algorithm", "")) != label:
            continue
        S = getattr(res, "SGWO", None)
        qt = None if S is None else get(S, "QuotaTrace", None)
        if qt is None:
            continue
        qt = np.atleast_2d(qt)
        for row in qt:
            fe, qE, a, s, rew, gbf = [float(v) for v in row[:6]]
            if a > 0 and s > 0:
                act_by_state[int(s) - 1, int(a) - 1] += 1
            rows.append((fe / 100000.0, rew, gbf, qE, a, s))
        n += 1
    R = np.array(rows)
    if len(R) == 0:
        print("no traces found (runner without QuotaTrace?)")
        return
    print(f"label={label}: runs with traces={n}, windows/run={len(R)/max(n,1):.1f}")
    print("\naction counts by state (rows=state 1..6; cols=q25/q50/q75):")
    print(act_by_state.astype(int))
    for lo, hi, name in [(0, .33, "early"), (.33, .7, "middle"), (.7, 1.01, "late")]:
        sel = (R[:, 0] >= lo) & (R[:, 0] < hi)
        if sel.sum() == 0:
            continue
        shares = np.bincount(R[sel, 4].astype(int), minlength=4)[1:] / sel.sum()
        print(f"{name:6s} windows={int(sel.sum()):7d}  reward {R[sel,1].mean():.4f}  "
              f"gb-improve {R[sel,2].mean():.3f}  mean qE {R[sel,3].mean():.3f}  "
              f"actions {np.round(shares, 3)}")
    print(f"\noverall: reward {R[:,1].mean():.4f}, gb-improve {R[:,2].mean():.3f}, "
          f"action shares {np.round(np.bincount(R[:,4].astype(int),minlength=4)[1:]/len(R),3)}")


if __name__ == "__main__":
    main()
