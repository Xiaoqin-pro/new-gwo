# -*- coding: utf-8 -*-
"""Publication-style figures: (1) framework diagram, (2) D=100 convergence panels."""
import os, sys
import numpy as np, pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
from matplotlib.lines import Line2D

try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass

SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
HERE = os.path.dirname(os.path.abspath(__file__))
FIG = os.path.join(os.path.dirname(HERE), "figures")
os.makedirs(FIG, exist_ok=True)

SERIF = ["Times New Roman", "DejaVu Serif"]
plt.rcParams.update({
    "font.family": "serif", "font.serif": SERIF,
    "font.size": 8, "axes.linewidth": 0.7,
    "xtick.direction": "in", "ytick.direction": "in",
    "xtick.major.width": 0.7, "ytick.major.width": 0.7,
    "mathtext.fontset": "stix",
})

# ---------------------------------------------------------------- framework
def box(ax, x, y, w, h, text, fs=8, lw=0.9, fc="#f7f7f7", ec="#333333", align="center"):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="square,pad=0",
                                linewidth=lw, edgecolor=ec, facecolor=fc))
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center",
            fontsize=fs, linespacing=1.35)

def arrow(ax, p0, p1, style="-", lw=0.9, color="#333333", ls=None, rad=0.0):
    a = FancyArrowPatch(p0, p1, arrowstyle="-|>", mutation_scale=7,
                        linewidth=lw, color=color, linestyle=ls or style,
                        connectionstyle=f"arc3,rad={rad}", shrinkA=1, shrinkB=1)
    ax.add_patch(a)

def framework():
    fig, ax = plt.subplots(figsize=(7.1, 3.6))
    ax.set_xlim(0, 100); ax.set_ylim(0, 56); ax.axis("off")

    # ---- candidate sources (no objective calls) ----
    box(ax, 1, 34, 24, 13, r"$G_1$: GWO leader moves (50)" "\n" r"$(X_\alpha,X_\beta,X_\delta)$", fs=7.6)
    box(ax, 1, 19, 24, 13, r"$G_2$: success-scale shells (12)" "\n" r"$\sigma=\mathrm{med}(\mathcal{S}_{25})$", fs=7.6)
    box(ax, 1, 4, 24, 13, r"$E$: verified archive (38)" "\n" r"multi-region shells / segments", fs=7.6)
    ax.text(13, 49.7, "candidate generation: 0 objective calls", ha="center", va="bottom",
            fontsize=7.2, style="italic")

    # ---- pool ----
    box(ax, 31, 17, 15, 30, "", fc="#ffffff")
    ax.text(38.5, 40.5, "candidate pool", ha="center", va="center", fontsize=7.8)
    ax.text(38.5, 35.8, r"$M=100$", ha="center", va="center", fontsize=11)
    # composition bar
    widths = [50, 12, 38]
    cols = ["#bdbdbd", "#8c8c8c", "#4d4d4d"]
    x0 = 32.0; yb = 21.0; W = 13.0; tot = sum(widths)
    for w_, c in zip(widths, cols):
        ax.add_patch(plt.Rectangle((x0, yb), W * w_ / tot, 2.0, facecolor=c, edgecolor="none"))
        x0 += W * w_ / tot
    ax.text(38.5, 18.9, r"$50\;/\;12\;/\;38$", ha="center", va="center", fontsize=6.8)

    # ---- draw ----
    box(ax, 51, 26, 14, 12, "uniform draw\n" r"$K=10$", fs=7.8)
    # ---- evaluate ----
    box(ax, 69, 26, 15, 12, "real evaluation\nbilled, FE-audited", fs=7.6)
    # ---- commit ----
    box(ax, 88, 26, 11, 12, "commit\nverified\npositions", fs=7.4)

    arrow(ax, (25.2, 40.5), (30.8, 38.0))
    arrow(ax, (25.2, 25.5), (30.8, 31.5))
    arrow(ax, (25.2, 10.5), (30.8, 25.0))
    arrow(ax, (46.2, 32), (50.8, 32))
    arrow(ax, (65.2, 32), (68.8, 32))
    arrow(ax, (84.2, 32), (87.8, 32))

    # ---- verified state ----
    box(ax, 55, 6, 44, 13, "", fc="#ffffff")
    ax.text(77, 15.2, "verified search state", ha="center", va="center", fontsize=7.8)
    ax.text(77, 11.0, r"leaders $\alpha,\beta,\delta$  |  elite archive (cap 24, sep $\geq 2\%$)" "\n"
                      r"only real-evaluated positions may enter", ha="center", va="center", fontsize=7.0)
    arrow(ax, (93.5, 25.6), (93.5, 19.4))
    # feedback to E
    arrow(ax, (55.0, 9.5), (25.4, 9.5), ls=(0, (3, 2)))
    ax.text(40.0, 7.4, "verified information only", ha="center", va="center",
            fontsize=6.8, style="italic")
    # annotation: unevaluated candidates never flow back
    ax.text(77, 3.2, "unevaluated candidates never update leaders, archive or rank",
            ha="center", va="center", fontsize=6.6)
    fig.tight_layout(pad=0.2)
    p = os.path.join(FIG, "fig1_framework.png")
    fig.savefig(p, dpi=600); fig.savefig(p.replace(".png", ".pdf"))
    plt.close(fig)
    print("saved", p)

# ---------------------------------------------------------------- D=100 panels
ALGS = ["VAST-GWO", "GWO", "IGWO", "HAGWO", "PSO", "CLPSO", "AOGWO"]
PANELS = [1, 4, 8, 11, 28]
GRID = np.unique(np.round(np.logspace(1, 5, 240)).astype(int))
CK = ["CheckT10", "CheckT20", "CheckT50", "CheckT80", "CheckT100"]
CKL = ["10", "20", "50", "80", "100"]
STYLE = {
    "VAST-GWO": dict(color="#b2182b", lw=2.0, ls="-"),
    "IGWO":     dict(color="#d95f02", lw=1.1, ls="-"),
    "HAGWO":    dict(color="#7570b3", lw=1.1, ls="-"),
    "PSO":      dict(color="#1b7837", lw=1.1, ls="-"),
    "CLPSO":    dict(color="#2166ac", lw=1.1, ls="-"),
    "AOGWO":    dict(color="#8c510a", lw=1.0, ls=(0, (4, 2))),
    "GWO":      dict(color="#666666", lw=1.1, ls="--"),
}

def convergence():
    import scipy.io as sio
    raw = pd.read_csv(os.path.join(SQ, "results", "d100_analysis", "raw_runs.csv"), low_memory=False)
    raw = raw[raw.Status == "ok"]
    curves = {}
    for _, r in raw.iterrows():
        if int(r.FunctionID) not in PANELS:
            continue
        pass
    # read traces from MAT (raw_runs keeps checkpoints only)
    dirs = {"new": os.path.join(SQ, "results", "d100_formal_20261018"),
            "old": os.path.join(SQ, "results", "fd100_20261016_232205")}
    for _, r in raw.iterrows():
        f = int(r.FunctionID)
        if f not in PANELS:
            continue
        d = dirs["old"] if str(r.Source).startswith("archived") else dirs["new"]
        m = sio.loadmat(os.path.join(d, "runs", "run_%05d.mat" % int(r.RunID)),
                        squeeze_me=True, struct_as_record=False)
        res = m["record"].result
        fe = np.asarray(res.TraceFE).ravel().astype(float)
        tr = np.asarray(res.Trace).ravel().astype(float) - 100.0 * f
        curves.setdefault((f, str(r.Algorithm)), []).append(np.interp(GRID, fe, tr))
    for f in PANELS:
        for a in ALGS:
            assert len(curves[(f, a)]) == 30, (f, a, len(curves[(f, a)]))

    # rank trajectory from checkpoint medians
    ranks = {}
    for c in CK:
        mat = np.column_stack([raw[raw.Algorithm == a].groupby("FunctionID")[c].median()
                               .reindex(sorted(raw.FunctionID.unique())).values for a in ALGS])
        ranks[c] = pd.DataFrame(mat, columns=ALGS).rank(axis=1).mean(axis=0)

    fig, axes = plt.subplots(2, 3, figsize=(7.4, 4.35))
    fam = {1: "unimodal", 4: "simple multimodal", 8: "simple multimodal",
           11: "hybrid", 28: "composition"}
    for k, (ax, f) in enumerate(zip(axes.ravel(), PANELS)):
        for a in ALGS:
            med = np.median(np.vstack(curves[(f, a)]), axis=0)
            ax.plot(GRID, np.maximum(med, 1e-14), **STYLE[a])
        ax.set_xscale("log"); ax.set_yscale("log")
        ax.set_xlim(10, 1e5)
        ax.set_title(f"({chr(97+k)}) F{f}, {fam[f]}", fontsize=8)
        ax.tick_params(labelsize=6.8)
        ax.grid(True, which="major", color="0.86", lw=0.45)
        ax.grid(True, which="minor", color="0.95", lw=0.25)
        for s in ("top", "right"):
            ax.spines[s].set_visible(False)
        if k % 3 == 0:
            ax.set_ylabel("Best-so-far error", fontsize=7.6)
        if k >= 3:
            ax.set_xlabel("True FE", fontsize=7.6)

    ax = axes[1, 2]
    for a in ALGS:
        y = [ranks[c][a] for c in CK]
        ax.plot(range(5), y, marker="o", ms=2.6, **STYLE[a])
    ax.set_xticks(range(5)); ax.set_xticklabels(CKL)
    ax.set_xlabel("FE checkpoint (%)", fontsize=7.6)
    ax.set_ylabel("Mean rank", fontsize=7.6)
    ax.set_title("(f) rank trajectory", fontsize=8)
    ax.tick_params(labelsize=6.8)
    ax.grid(True, color="0.86", lw=0.45)
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)

    handles = [Line2D([], [], label=a, **STYLE[a]) for a in ALGS]
    fig.legend(handles=handles, loc="lower center", ncol=7, frameon=False,
               fontsize=7.4, handlelength=2.0, columnspacing=1.2,
               bbox_to_anchor=(0.5, 0.005))
    fig.tight_layout(rect=(0, 0.06, 1, 1), pad=0.35, w_pad=0.5, h_pad=0.7)
    p = os.path.join(FIG, "figure_d100_convergence6.png")
    fig.savefig(p, dpi=600); fig.savefig(p.replace(".png", ".pdf"))
    plt.close(fig)
    print("saved", p)
    print(ranks[CK[0]].round(2).to_dict())

if __name__ == "__main__":
    framework()
    convergence()
