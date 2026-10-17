#!/usr/bin/env python3
"""Figures for the sparse_q paper: rank bars + convergence panels."""
import glob
import os
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import scipy.io as sio

ROOT = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
SQ = os.path.join(ROOT, "sparse_q")
OUT = os.path.join(SQ, "paper", "figures")
os.makedirs(OUT, exist_ok=True)
plt.rcParams.update({"font.size": 8, "axes.grid": True, "grid.alpha": 0.3})

batch = sorted([d for d in os.listdir(os.path.join(SQ, "results")) if d.startswith("final_")])[-1]
df = pd.read_csv(os.path.join(SQ, "results", batch, "merged_runs.csv"))
df = df[df.Status == "ok"]
piv = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
med = piv.groupby(level=0).median()
rank = med.rank(axis=1).mean(axis=0).sort_values()

fig, ax = plt.subplots(figsize=(6.4, 3.6))
colors = ["#c0392b" if a == "S-star" else ("#7f8c8d" if a in ("GWO", "B0-ANGWO") else "#2c6fbb") for a in rank.index]
ax.barh(range(len(rank)), rank.values, color=colors)
ax.set_yticks(range(len(rank)))
ax.set_yticklabels(rank.index, fontsize=7)
ax.invert_yaxis()
ax.set_xlabel("mean rank over 29 functions (30 runs)")
for i, v in enumerate(rank.values):
    ax.text(v + 0.05, i, f"{v:.2f}", va="center", fontsize=6)
fig.tight_layout()
fig.savefig(os.path.join(OUT, "ranks.png"), dpi=300)
plt.close(fig)

# convergence: our traces from the final batch + frozen batch, baselines from nodes csv
targets = [1, 4, 9, 13, 24]
curves = {}
def add_traces(batch_dir, label_filter):
    for f in glob.glob(os.path.join(batch_dir, "runs", "run_*.mat")):
        m = sio.loadmat(f, squeeze_me=True, struct_as_record=False)
        r = m["record"]
        if getattr(r, "status", "") != "ok":
            continue
        res = r.result
        lab = str(res.Algorithm)
        if res.FunctionID in targets and lab in label_filter:
            curves.setdefault((res.FunctionID, lab), []).append(
                (np.asarray(res.TraceFE).ravel(), np.asarray(res.Trace).ravel()))
add_traces(os.path.join(SQ, "results", batch), {"S-star", "S1-pool38"})
add_traces(os.path.join(ROOT, "results", "formal_20261016_140254"), {"GWO", "ANGWO-final"})
base = pd.read_csv(os.path.join(ROOT, "9.29", "CEC2017_8Algorithm_30Seed", "results",
                                "main_8algorithms", "convergence_nodes.csv")) if False else None
base = pd.read_csv(r"D:\111\Desktop\噜噜\9.29\CEC2017_8Algorithm_30Seed\results\main_8algorithms\convergence_nodes.csv")
cmap = {"S-star": ("#c0392b", 1.7, "-"), "S1-pool38": ("#8e44ad", 1.2, "-"),
        "ANGWO-final": ("#2980b9", 1.1, "--"), "GWO": ("#7f8c8d", 1.1, "--")}
fig, axes = plt.subplots(2, 3, figsize=(9.6, 5.0))
for ax, f in zip(axes.ravel(), targets + [None]):
    if f is None:
        ax.axis("off")
        continue
    for lab, (c, lw, ls) in cmap.items():
        runs = curves.get((f, lab))
        if not runs:
            continue
        fe = runs[0][0]
        errs = np.vstack([np.asarray(t).ravel() - 100 * f for _, t in runs])
        ax.plot(fe, np.maximum(np.median(errs, axis=0), 1e-12), color=c, lw=lw, ls=ls, label=lab)
    for cond, name in {"HIDMS-PSO-IndexCorrected": "HIDMS-PSO", "HCLPSO-AuthorSource": "HCLPSO",
                       "DMS-PSO-SIS2005": "DMS-PSO", "SAQ-CSO": "SAQ-CSO"}.items():
        sel = base[(base.FunctionID == f) & (base.Condition == cond)]
        if len(sel):
            ax.plot(sel.FE, np.maximum(sel.Error, 1e-12), lw=0.8, alpha=0.75, label=name)
    ax.set_xscale("log"); ax.set_yscale("log")
    ax.set_title(f"F{f}")
    ax.set_xlabel("true FE"); ax.set_ylabel("best-so-far error")
    if f == targets[0]:
        ax.legend(fontsize=5.5, ncol=2, frameon=False)
fig.tight_layout()
fig.savefig(os.path.join(OUT, "convergence.png"), dpi=300)
plt.close(fig)
print("figures ->", OUT)
