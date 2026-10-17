#!/usr/bin/env python3
"""Generate figures for the DCS-GWO draft from the frozen formal batch."""
import glob
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import scipy.io as sio

ROOT = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
BATCH = os.path.join(ROOT, "results", "formal_20261016_140254")
OUT = os.path.join(ROOT, "paper", "angwo", "figures")
os.makedirs(OUT, exist_ok=True)
plt.rcParams.update({"font.size": 8, "axes.grid": True, "grid.alpha": 0.3})

merged = pd.read_csv(os.path.join(BATCH, "merged_runs.csv"))
merged = merged[merged.Status == "ok"]
piv = merged.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm",
                         values="FinalError", aggfunc="first")
med = piv.groupby(level=0).median()
rank = med.rank(axis=1).mean(axis=0).sort_values()

# ---- Figure 1: mean ranks ----
fig, ax = plt.subplots(figsize=(6.4, 3.2))
colors = ["#c0392b" if a == "ANGWO-final" else ("#7f8c8d" if a == "GWO" else "#2c6fbb") for a in rank.index]
ax.barh(range(len(rank)), rank.values, color=colors)
ax.set_yticks(range(len(rank)))
ax.set_yticklabels(rank.index)
ax.invert_yaxis()
ax.set_xlabel("mean rank over 29 functions (30 runs)")
for i, v in enumerate(rank.values):
    ax.text(v + 0.05, i, f"{v:.2f}", va="center", fontsize=7)
fig.tight_layout()
fig.savefig(os.path.join(OUT, "ranks.png"), dpi=300)
plt.close(fig)

# ---- Figure 2: per-function ratios, ANGWO-final vs GWO ----
A, B = "ANGWO-final", "GWO"
funcs = sorted(merged.FunctionID.unique())
ratios = []
for f in funcs:
    ra = piv.loc[f, A].dropna(); rb = piv.loc[f, B].dropna()
    ratios.append(np.median(ra / rb))
fam = ["unimodal" if f in (1, 3) else "simple" if 4 <= f <= 10 else
       "hybrid" if 11 <= f <= 20 else "composition" for f in funcs]
cmap = {"unimodal": "#c0392b", "simple": "#e67e22", "hybrid": "#27ae60", "composition": "#2c6fbb"}
fig, ax = plt.subplots(figsize=(6.4, 2.6))
ax.bar(range(len(funcs)), ratios, color=[cmap[c] for c in fam])
ax.axhline(1.0, color="k", lw=0.8)
ax.set_xticks(range(len(funcs)))
ax.set_xticklabels([f"F{f}" for f in funcs], rotation=90, fontsize=6)
ax.set_ylabel("median error ratio\n(DCS-GWO / GWO)")
handles = [plt.Rectangle((0, 0), 1, 1, color=cmap[c]) for c in cmap]
ax.legend(handles, cmap.keys(), fontsize=7, ncol=4, frameon=False)
fig.tight_layout()
fig.savefig(os.path.join(OUT, "ratios.png"), dpi=300)
plt.close(fig)

# ---- Figure 3: convergence curves ----
cond_map = {"HIDMS-PSO-IndexCorrected": "HIDMS-PSO", "HCLPSO-AuthorSource": "HCLPSO",
            "DMS-PSO-SIS2005": "DMS-PSO", "SAQ-CSO": "SAQ-CSO"}
base = pd.read_csv(r"D:\111\Desktop\噜噜\9.29\CEC2017_8Algorithm_30Seed\results\main_8algorithms\convergence_nodes.csv")
fig, axes = plt.subplots(2, 2, figsize=(6.6, 4.6))
files = glob.glob(os.path.join(BATCH, "runs", "run_*.mat"))
targets = [1, 11, 13, 24]
our = {}
for f in files:
    m = sio.loadmat(f, squeeze_me=True, struct_as_record=False)
    r = m["record"]
    if getattr(r, "status", "") != "ok":
        continue
    res = r.result
    if res.FunctionID in targets and res.Algorithm in ("ANGWO-final", "GWO"):
        our.setdefault((res.FunctionID, res.Algorithm), []).append(
            (res.TraceFE, np.asarray(res.Trace).ravel(), res.FunctionID))
for ax, f in zip(axes.ravel(), targets):
    for alg, style in [("ANGWO-final", dict(color="#c0392b", lw=1.6)),
                       ("GWO", dict(color="#7f8c8d", lw=1.2, ls="--"))]:
        runs = our[(f, alg)]
        fe = np.asarray(runs[0][0]).ravel()
        errs = np.vstack([np.asarray(t).ravel() - 100 * f for _, t, _ in runs])
        med = np.median(errs, axis=0)
        ax.plot(fe, np.maximum(med, 1e-12), label=alg, **style)
    for cond, name in cond_map.items():
        sel = base[(base.FunctionID == f) & (base.Condition == cond)]
        if len(sel):
            ax.plot(sel.FE, np.maximum(sel.Error, 1e-12), lw=0.9, alpha=0.8, label=name)
    ax.set_xscale("log"); ax.set_yscale("log")
    ax.set_title(f"F{f}")
    if f == 1:
        ax.legend(fontsize=6, ncol=2, frameon=False)
    ax.set_xlabel("true FE"); ax.set_ylabel("best-so-far error")
fig.tight_layout()
fig.savefig(os.path.join(OUT, "convergence.png"), dpi=300)
plt.close(fig)
print("figures written to", OUT)
