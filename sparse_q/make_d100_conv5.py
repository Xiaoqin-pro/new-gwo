# -*- coding: utf-8 -*-
"""Rebuild D=100 convergence curves (7 methods) from the frozen 6,090 runs.

The manuscript's earlier D=100 convergence figure normalised each method by its
own 10% value, which makes every curve start at 1 and hides the actual spread.
This script instead plots the best-so-far error on a log axis against true FE,
median over 30 seeds, for five functions chosen a priori from the pre-registered
criteria (one per family plus a second spot), exactly as for the D=50 figure.
"""
import os, sys
import numpy as np, pandas as pd, scipy.io as sio
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass

SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
NEW = os.path.join(SQ, "results", "d100_formal_20261018")
OLD = os.path.join(SQ, "results", "fd100_20261016_232205")
OUT = os.path.join(SQ, "results", "d100_analysis")
ALGS = ["VAST-GWO", "GWO", "IGWO", "HAGWO", "PSO", "CLPSO", "AOGWO"]

# five panels: one per family + a second simple-multimodal case
PANELS = [1, 28, 4, 11, 21]
GRID = np.unique(np.round(np.logspace(1, 5, 240)).astype(int))


def load_runs():
    rows = []
    t = pd.read_csv(os.path.join(NEW, "runs.csv"), low_memory=False)
    for _, r in t.iterrows():
        if r.Status != "ok":
            continue
        rows.append(("new", NEW, int(r.RunID), int(r.FunctionID),
                     int(r.Seed), str(r.Algorithm)))
    t = pd.read_csv(os.path.join(OLD, "runs.csv"), low_memory=False)
    t = t[(t.Algorithm == "S-star") & (t.Seed <= 3010)]
    for _, r in t.iterrows():
        rows.append(("old", OLD, int(r.RunID), int(r.FunctionID),
                     int(r.Seed), "VAST-GWO"))
    return rows


def main():
    rows = load_runs()
    curves = {}
    for src, d, rid, fid, seed, alg in rows:
        if fid not in PANELS:
            continue
        m = sio.loadmat(os.path.join(d, "runs", "run_%05d.mat" % rid),
                        squeeze_me=True, struct_as_record=False)
        res = m["record"].result
        fe = np.asarray(res.TraceFE).ravel().astype(float)
        tr = np.asarray(res.Trace).ravel().astype(float) - 100.0 * fid
        err = np.interp(GRID, fe, tr)
        curves.setdefault((fid, alg), []).append(err)

    for f in PANELS:
        for a in ALGS:
            assert len(curves[(f, a)]) == 30, (f, a, len(curves[(f, a)]))

    style = {
        "VAST-GWO": dict(color="#b2182b", lw=2.0, ls="-", zorder=5),
        "IGWO":     dict(color="#d95f02", lw=1.2, ls="-"),
        "HAGWO":    dict(color="#7570b3", lw=1.2, ls="-"),
        "PSO":      dict(color="#1b7837", lw=1.2, ls="-"),
        "CLPSO":    dict(color="#2166ac", lw=1.2, ls="-"),
        "AOGWO":    dict(color="#8c510a", lw=1.1, ls=(0, (4, 2))),
        "GWO":      dict(color="#666666", lw=1.2, ls="--"),
    }
    plt.rcParams.update({
        "font.family": "serif",
        "font.serif": ["Times New Roman", "DejaVu Serif"],
        "font.size": 8,
        "axes.linewidth": 0.7,
        "xtick.direction": "in", "ytick.direction": "in",
        "xtick.major.width": 0.7, "ytick.major.width": 0.7,
    })
    fig, axes = plt.subplots(2, 3, figsize=(7.4, 4.6))
    fam = {1: "Unimodal", 4: "Simple multimodal", 11: "Hybrid", 21: "Composition", 28: "Simple multimodal"}
    for ax, f in zip(axes.ravel(), PANELS):
        for a in ALGS:
            M = np.vstack(curves[(f, a)])
            med = np.median(M, axis=0)
            med = np.maximum(med, 1e-14)
            ax.plot(GRID, med, **style[a])
        ax.set_xscale("log")
        ax.set_yscale("log")
        ax.set_title("F%d (%s)" % (f, fam[f]), fontsize=8.5)
        ax.set_xlim(10, 1e5)
        ax.tick_params(labelsize=7)
        ax.grid(True, which="major", color="0.85", lw=0.5)
        ax.grid(True, which="minor", color="0.94", lw=0.3)
        for s in ("top", "right"):
            ax.spines[s].set_visible(False)
    axes[0, 0].set_ylabel("Best-so-far error", fontsize=8)
    axes[1, 0].set_ylabel("Best-so-far error", fontsize=8)
    axes[1, 1].set_xlabel("True function evaluations", fontsize=8)
    for ax in axes[1, :]:
        if ax is axes[1, 1]:
            continue
        ax.set_xlabel("True function evaluations", fontsize=8)
    axes[1, 2].axis("off")
    handles = [Line2D([], [], label=a, **{k: v for k, v in style[a].items() if k != "zorder"}) for a in ALGS]
    axes[1, 2].legend(handles=handles, loc="center", frameon=False, fontsize=8,
                      title="median of 30 runs", title_fontsize=8)
    fig.tight_layout(pad=0.4, w_pad=0.6, h_pad=0.9)
    p = os.path.join(OUT, "figure_d100_convergence5.png")
    fig.savefig(p, dpi=600)
    fig.savefig(p.replace(".png", ".pdf"))
    plt.close(fig)
    print("saved", p)


if __name__ == "__main__":
    main()
