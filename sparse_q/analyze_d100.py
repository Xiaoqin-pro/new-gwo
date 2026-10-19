# -*- coding: utf-8 -*-
"""D=100 generalization analysis: rebuild every table/figure from raw_runs.csv.

Protocol frozen in docs/17_D100_PREREG.md. Analysis unit = function-level paired
seeds (29 functions x 30 seeds); never pools 870 runs as independent samples.
"""
import os, sys, json, glob
import numpy as np, pandas as pd
from scipy import stats
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass

SQ = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(SQ, "results", "d100_analysis")
os.makedirs(OUT, exist_ok=True)
RNG = np.random.default_rng(20261018)

ALGS = ["VAST-GWO", "GWO", "IGWO", "HAGWO", "PSO", "CLPSO", "AOGWO"]
BASE = [a for a in ALGS if a != "VAST-GWO"]
FUNCS = [1] + list(range(3, 31))
CATS = {"unimodal": [1, 3], "simple_multimodal": list(range(4, 11)),
        "hybrid": list(range(11, 21)), "composition": list(range(21, 31))}
CK = [("10%", "CheckT10"), ("20%", "CheckT20"), ("50%", "CheckT50"),
      ("80%", "CheckT80"), ("100%", "CheckT100")]

def holm(p):
    p = np.asarray(p, float); o = np.argsort(p); adj = np.empty_like(p); cur = 0.0
    for i, ix in enumerate(o):
        cur = max(cur, p[ix] * (len(p) - i)); adj[ix] = min(cur, 1.0)
    return adj

def wilcoxon_p(d):
    d = np.asarray(d, float); d = d[np.isfinite(d)]
    if d.size == 0: return 1.0
    if np.all(d == 0): return 1.0
    try: return float(stats.wilcoxon(d, alternative="two-sided").pvalue)
    except Exception: return 1.0

def boot_ci(vals, stat=np.median, n=10000):
    v = np.asarray(vals, float); v = v[np.isfinite(v)]
    if v.size == 0: return (np.nan, np.nan)
    s = [stat(RNG.choice(v, size=v.size, replace=True)) for _ in range(n)]
    return (float(np.percentile(s, 2.5)), float(np.percentile(s, 97.5)))

def load_raw():
    p = os.path.join(OUT, "raw_runs.csv")
    assert os.path.isfile(p), "raw_runs.csv missing"
    df = pd.read_csv(p, low_memory=False)
    df = df[df.Status == "ok"].copy()
    return df

def main():
    df = load_raw()
    # ---- integrity ----
    issues = []
    dup = df.duplicated(["Algorithm", "FunctionID", "Seed"], keep=False)
    if dup.any(): issues.append(f"duplicate records: {int(dup.sum())}")
    for a in ALGS:
        d = df[df.Algorithm == a]
        nf, ns = d.FunctionID.nunique(), d.Seed.nunique()
        if nf != 29 or ns != 30 or len(d) != 870:
            issues.append(f"{a}: fn={nf} seeds={ns} rows={len(d)} (expected 29/30/870)")
    nonfinite = df[~np.isfinite(df.FinalError.astype(float))]
    if len(nonfinite): issues.append(f"non-finite errors: {len(nonfinite)}")
    zero = df[df.FinalError.astype(float) == 0]
    if len(zero): issues.append(f"zero errors: {len(zero)} (kept as-is; ratio pairs excluded)")
    for a in ALGS:
        d = df[df.Algorithm == a]
        if not (d.Evaluations.astype(float) == 100000).all():
            issues.append(f"{a}: FE != 100000 somewhere")
    print("integrity issues:", issues if issues else "none")

    piv = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm",
                         values="FinalError", aggfunc="first")
    missing = {a: int(piv[a].isna().sum()) for a in ALGS}
    print("missing cells:", missing)

    # ================= main table =================
    med_by_fn = piv.groupby(level=0).median()
    ranks = med_by_fn[ALGS].rank(axis=1, method="average")
    mean_rank = ranks.mean(axis=0)
    rank_ci = {a: boot_ci(ranks[a].values, np.mean) for a in ALGS}

    rd = {}
    for a in ALGS:
        x = df[(df.Algorithm == a) & (df.Seed >= 3011)]
        per = x.groupby("FunctionID").Seconds.median()
        iqr = x.groupby("FunctionID").Seconds.quantile(.75) - x.groupby("FunctionID").Seconds.quantile(.25)
        rd[a] = {"run_median": float(x.Seconds.median()),
                 "run_iqr": float(x.Seconds.quantile(.75) - x.Seconds.quantile(.25)),
                 "fn_med_of_med": float(per.median()),
                 "fn_q1": float(per.quantile(.25)), "fn_q3": float(per.quantile(.75)),
                 "within_fn_iqr_median": float(iqr.median())}

    rows = []
    holm_rows = []
    detail = {}
    for b in BASE:
        per_ratio, ds, ps, w, l = {}, [], [], 0, 0
        for f in FUNCS:
            ra = piv.loc[f, "VAST-GWO"].astype(float)
            rb = piv.loc[f, b].astype(float)
            c = ra.index.intersection(rb.index)
            ra, rb = ra.loc[c], rb.loc[c]
            ok = np.isfinite(ra) & np.isfinite(rb) & (rb != 0)
            ra2, rb2 = ra[ok], rb[ok]
            ratio = float(np.median(ra2 / rb2)) if len(ra2) else np.nan
            per_ratio[f] = ratio
            d = np.log10(rb2) - np.log10(ra2)
            ds.append(float(np.median(d)) if len(d) else np.nan)
            ps.append(wilcoxon_p(d))
            ma, mb = float(np.median(ra2)), float(np.median(rb2))
            if ma < mb: w += 1
            elif ma > mb: l += 1
        adj = holm(ps)
        sb = int(sum((q < 0.05 and d > 0) for q, d in zip(adj, ds)))
        sw = int(sum((q < 0.05 and d < 0) for q, d in zip(adj, ds)))
        med_ratio = float(np.median([v for v in per_ratio.values() if np.isfinite(v)]))
        ci = boot_ci([v for v in per_ratio.values() if np.isfinite(v)], np.median)
        detail[b] = dict(per_ratio=per_ratio, p=ps, adj=adj, d=ds)
        for i, f in enumerate(FUNCS):
            holm_rows.append(dict(Baseline=b, FunctionID=f,
                MedianRatio=per_ratio[f], MedianLog10Diff=ds[i],
                P_raw=ps[i], P_holm=adj[i],
                Significant=("VAST better" if (adj[i] < 0.05 and ds[i] > 0)
                             else "Baseline better" if (adj[i] < 0.05 and ds[i] < 0)
                             else "ns"),
                FunctionWin=("VAST" if per_ratio[f] < 1 else
                             "Baseline" if per_ratio[f] > 1 else "Tie")))
        rt = df[(df.Algorithm == b) & (df.Seed >= 3011)]
        rows.append(dict(Algorithm=b, MedianRatio_vs_VAST=med_ratio,
            RatioCI_low=ci[0], RatioCI_high=ci[1],
            FunctionsWin=w, FunctionsLoss=29 - w - sum(1 for v in per_ratio.values() if v == 1),
            HolmSigWin=sb, HolmSigLoss=sw,
            MeanRank=float(mean_rank[b]),
            MeanRankCI_low=rank_ci[b][0], MeanRankCI_high=rank_ci[b][1],
            RuntimeMedian_s=float(rt.Seconds.median()),
            RuntimeIQR_s=float(rt.Seconds.quantile(.75) - rt.Seconds.quantile(.25)),
            FnMedianOfMedians_s=rd[b]["fn_med_of_med"],
            FnMedQ1_s=rd[b]["fn_q1"], FnMedQ3_s=rd[b]["fn_q3"]))
    # global Holm (6 baselines x 29 functions) as a sensitivity analysis
    gp = [q for b in BASE for q in detail[b]["p"]]
    gadj = holm(gp)
    gi = 0
    for b in BASE:
        for i, f in enumerate(FUNCS):
            holm_rows_idx = [j for j, r in enumerate(holm_rows)
                             if r["Baseline"] == b and r["FunctionID"] == f][0]
            holm_rows[holm_rows_idx]["P_holm_global"] = float(gadj[gi])
            holm_rows[holm_rows_idx]["Significant_global"] = (
                "VAST better" if (gadj[gi] < 0.05 and detail[b]["d"][i] > 0)
                else "Baseline better" if (gadj[gi] < 0.05 and detail[b]["d"][i] < 0)
                else "ns")
            gi += 1

    # per-function median errors (paper appendix)
    pf = med_by_fn[ALGS].copy()
    pf.index.name = "FunctionID"
    pf.to_csv(os.path.join(OUT, "table_d100_per_function.csv"))

    rt0 = df[(df.Algorithm == "VAST-GWO") & (df.Seed >= 3011)]
    main_rows = [dict(Algorithm="VAST-GWO", MedianRatio_vs_VAST=1.0,
        RatioCI_low=1.0, RatioCI_high=1.0, FunctionsWin=0, FunctionsLoss=0,
        HolmSigWin=0, HolmSigLoss=0, MeanRank=float(mean_rank["VAST-GWO"]),
        MeanRankCI_low=rank_ci["VAST-GWO"][0], MeanRankCI_high=rank_ci["VAST-GWO"][1],
        RuntimeMedian_s=float(rt0.Seconds.median()),
        RuntimeIQR_s=float(rt0.Seconds.quantile(.75) - rt0.Seconds.quantile(.25)),
        FnMedianOfMedians_s=rd["VAST-GWO"]["fn_med_of_med"],
        FnMedQ1_s=rd["VAST-GWO"]["fn_q1"], FnMedQ3_s=rd["VAST-GWO"]["fn_q3"])] + rows
    mt = pd.DataFrame(main_rows).sort_values("MeanRank")
    gwo_med = float(mt.loc[mt.Algorithm == "GWO", "RuntimeMedian_s"].iloc[0])
    mt["RuntimeRel_GWO"] = mt.RuntimeMedian_s / gwo_med
    mt.to_csv(os.path.join(OUT, "table_d100_main.csv"), index=False)
    pd.DataFrame(holm_rows).to_csv(os.path.join(OUT, "table_d100_holm.csv"), index=False)

    # ================= category table =================
    cat_rows = []
    for cname, fl in CATS.items():
        for b in BASE:
            vals = [detail[b]["per_ratio"][f] for f in fl if np.isfinite(detail[b]["per_ratio"][f])]
            idx = [FUNCS.index(f) for f in fl]
            adj = [detail[b]["adj"][i] for i in idx]; dd = [detail[b]["d"][i] for i in idx]
            sb = sum((q < .05 and d > 0) for q, d in zip(adj, dd))
            sw = sum((q < .05 and d < 0) for q, d in zip(adj, dd))
            w = sum(v < 1 for v in vals)
            cat_rows.append(dict(Category=cname, nFunctions=len(fl), Baseline=b,
                MedianRatio=float(np.median(vals)) if vals else np.nan,
                FunctionsWin=w, FunctionsLoss=len(vals) - w,
                HolmSigWin=sb, HolmSigLoss=sw))
    pd.DataFrame(cat_rows).to_csv(os.path.join(OUT, "table_d100_categories.csv"), index=False)

    # ================= convergence =================
    # Common per-function scale: divide by the best algorithm median at 10% FE
    # for that function, so all seven curves share one scale.
    ck_med = {a: {f: [float(df[(df.Algorithm==a)&(df.FunctionID==f)][c].median()) for _, c in CK]
                  for f in FUNCS} for a in ALGS}
    conv = {}
    for a in ALGS:
        curves = []
        for f in FUNCS:
            m = ck_med[a][f]
            ref = min(ck_med[b][f][0] for b in ALGS if np.isfinite(ck_med[b][f][0]) and ck_med[b][f][0] > 0)
            curves.append([v / ref if np.isfinite(ref) and ref > 0 else np.nan for v in m])
        conv[a] = np.array(curves)
    # rank at each checkpoint
    rank_ck = {}
    for j, (lab, col) in enumerate(CK):
        mat = np.column_stack([df[df.Algorithm == a].groupby("FunctionID")[col].median().reindex(FUNCS).values
                               for a in ALGS])
        rank_ck[lab] = pd.DataFrame(mat, columns=ALGS).rank(axis=1).mean(axis=0)
    pd.DataFrame(rank_ck).to_csv(os.path.join(OUT, "table_d100_convergence_ranks.csv"))

    # ================= figures =================
    plt.rcParams.update({"font.size": 9, "axes.spines.top": False, "axes.spines.right": False})

    # ranks
    fig, ax = plt.subplots(figsize=(6.2, 3.0))
    order = mt.sort_values("MeanRank")
    x = np.arange(len(order))
    ax.bar(x, order.MeanRank, color=["#c0392b" if a == "VAST-GWO" else "#7f8c8d" for a in order.Algorithm])
    ax.errorbar(x, order.MeanRank,
                yerr=[order.MeanRank - order.MeanRankCI_low, order.MeanRankCI_high - order.MeanRank],
                fmt="none", ecolor="k", capsize=3, lw=.8)
    ax.set_xticks(x); ax.set_xticklabels(order.Algorithm, rotation=30, ha="right")
    ax.set_ylabel("Mean rank (lower = better)")
    ax.set_title("CEC2017, D=100, 100k FE: mean rank over 29 functions")
    fig.tight_layout(); fig.savefig(os.path.join(OUT, "figure_d100_ranks.png"), dpi=220); plt.close(fig)

    # convergence: panel a mean rank; panel b normalised error
    fig, axs = plt.subplots(1, 2, figsize=(9.0, 3.2))
    for a in ALGS:
        y = [rank_ck[lab][a] for lab, _ in CK]
        axs[0].plot(range(5), y, marker="o", ms=3, lw=1.6 if a == "VAST-GWO" else 1.0,
                    label=a, color="#c0392b" if a == "VAST-GWO" else None)
    axs[0].set_xticks(range(5)); axs[0].set_xticklabels([l for l, _ in CK])
    axs[0].set_xlabel("FE checkpoint"); axs[0].set_ylabel("Mean rank")
    axs[0].set_title("(a) Rank trajectory"); axs[0].legend(fontsize=7, ncol=2)
    for a in ALGS:
        y = np.nanmedian(conv[a], axis=0)
        axs[1].plot(range(5), y, marker="o", ms=3, lw=1.6 if a == "VAST-GWO" else 1.0,
                    label=a, color="#c0392b" if a == "VAST-GWO" else None)
    axs[1].set_yscale("log"); axs[1].set_xticks(range(5))
    axs[1].set_xticklabels([l for l, _ in CK]); axs[1].set_xlabel("FE checkpoint")
    axs[1].set_ylabel("Error / error@10% (median)")
    axs[1].set_title("(b) Convergence relative to best@10% FE")
    fig.tight_layout(); fig.savefig(os.path.join(OUT, "figure_d100_convergence.png"), dpi=220); plt.close(fig)

    # win/loss
    fig, ax = plt.subplots(figsize=(6.4, 3.0))
    x = np.arange(len(BASE)); wd = .38
    wins = [sum(1 for f in FUNCS if detail[b]["per_ratio"][f] < 1) for b in BASE]
    loss = [sum(1 for f in FUNCS if detail[b]["per_ratio"][f] > 1) for b in BASE]
    sw = [sum((q < .05 and d > 0) for q, d in zip(detail[b]["adj"], detail[b]["d"])) for b in BASE]
    sl = [sum((q < .05 and d < 0) for q, d in zip(detail[b]["adj"], detail[b]["d"])) for b in BASE]
    ax.bar(x - wd/2, wins, wd, label="VAST wins", color="#c0392b")
    ax.bar(x - wd/2, loss, wd, bottom=wins, label="VAST loses", color="#bdc3c7")
    ax.bar(x + wd/2, sw, wd, label="Holm-significant win", color="#922b21")
    ax.bar(x + wd/2, sl, wd, bottom=sw, label="Holm-significant loss", color="#7f8c8d")
    ax.set_xticks(x); ax.set_xticklabels(BASE, rotation=25, ha="right")
    ax.set_ylabel("Number of functions (of 29)"); ax.set_ylim(0, 33)
    ax.set_title("Per-function win/loss vs VAST-GWO (D=100)")
    ax.legend(fontsize=7, ncol=4, loc="upper center", bbox_to_anchor=(0.5, 1.02),
              frameon=False, columnspacing=1.0)
    fig.tight_layout(); fig.savefig(os.path.join(OUT, "figure_d100_winloss.png"), dpi=220); plt.close(fig)

    # runtime
    fig, ax = plt.subplots(figsize=(6.0, 3.0))
    data = [df[(df.Algorithm == a) & (df.Seed >= 3011)].groupby("FunctionID").Seconds.median().reindex(FUNCS).values
            for a in ALGS]
    bp = ax.boxplot(data, tick_labels=ALGS, showfliers=False, patch_artist=True)
    for i, patch in enumerate(bp["boxes"]):
        patch.set_facecolor("#c0392b" if ALGS[i] == "VAST-GWO" else "#d5dbdb")
    ax.set_ylabel("Median seconds per function (100k FE)")
    ax.set_title("Runtime (new seeds 3011:3030; 29 function medians)")
    plt.setp(ax.get_xticklabels(), rotation=25, ha="right")
    fig.tight_layout(); fig.savefig(os.path.join(OUT, "figure_d100_runtime.png"), dpi=220); plt.close(fig)

    # ================= console summary =================
    print("\n=== MAIN (sorted by mean rank) ===")
    print(mt.to_string(index=False, float_format=lambda x: f"{x:.3f}"))
    print("\n=== per-baseline summary ===")
    for b in BASE:
        d = detail[b]
        print(f"{b:>8}: ratio {np.median([v for v in d['per_ratio'].values() if np.isfinite(v)]):.3f} "
              f"W-L {sum(1 for f in FUNCS if d['per_ratio'][f]<1)}-{sum(1 for f in FUNCS if d['per_ratio'][f]>1)} "
              f"Holm +{sum((q<.05 and x>0) for q,x in zip(d['adj'],d['d']))}/-{sum((q<.05 and x<0) for q,x in zip(d['adj'],d['d']))} "
              f"minHolm {min(d['adj']):.2g}")
    # ================= machine-readable stats dump =================
    stats_dump = {
        "n_rows": int(len(df)),
        "integrity_issues": issues,
        "mean_rank": {a: float(mean_rank[a]) for a in ALGS},
        "mean_rank_ci": {a: list(map(float, rank_ci[a])) for a in ALGS},
        "baselines": {b: {
            "median_ratio": float(np.median([v for v in detail[b]["per_ratio"].values() if np.isfinite(v)])),
            "median_ratio_ci": list(map(float, boot_ci([v for v in detail[b]["per_ratio"].values() if np.isfinite(v)], np.median))),
            "functions_win": int(sum(1 for f in FUNCS if detail[b]["per_ratio"][f] < 1)),
            "functions_loss": int(sum(1 for f in FUNCS if detail[b]["per_ratio"][f] > 1)),
            "holm_sig_win": int(sum((q < .05 and d > 0) for q, d in zip(detail[b]["adj"], detail[b]["d"]))),
            "holm_sig_loss": int(sum((q < .05 and d < 0) for q, d in zip(detail[b]["adj"], detail[b]["d"]))),
            "min_holm_p": float(min(detail[b]["adj"])),
            "per_function": {str(f): {
                "ratio": (None if not np.isfinite(detail[b]["per_ratio"][f]) else float(detail[b]["per_ratio"][f])),
                "median_log10_diff": (None if not np.isfinite(detail[b]["d"][i]) else float(detail[b]["d"][i])),
                "p_raw": float(detail[b]["p"][i]), "p_holm": float(detail[b]["adj"][i])}
                for i, f in enumerate(FUNCS)},
        } for b in BASE},
        "global_holm_sensitivity": {
            "family_size": len(gp),
            "sig_win": {b: int(sum(1 for i, f in enumerate(FUNCS)
                if gadj[BASE.index(b)*29 + i] < 0.05 and detail[b]["d"][i] > 0)) for b in BASE},
            "sig_loss": {b: int(sum(1 for i, f in enumerate(FUNCS)
                if gadj[BASE.index(b)*29 + i] < 0.05 and detail[b]["d"][i] < 0)) for b in BASE}},
        "runtime_detail": rd,
        "categories": cat_rows,
        "convergence_ranks": {lab: {a: float(rank_ck[lab][a]) for a in ALGS} for lab, _ in CK},
        "runtime": {a: {"median": float(df[(df.Algorithm==a)&(df.Seed>=3011)].Seconds.median()),
                        "iqr": float(df[(df.Algorithm==a)&(df.Seed>=3011)].Seconds.quantile(.75)-df[(df.Algorithm==a)&(df.Seed>=3011)].Seconds.quantile(.25))}
                    for a in ALGS},
        "rounds_median": {a: (None if df[df.Algorithm==a].Rounds.isna().all() else float(df[df.Algorithm==a].Rounds.median())) for a in ALGS},
    }
    import json
    with open(os.path.join(OUT, "stats_d100.json"), "w", encoding="utf-8") as f:
        json.dump(stats_dump, f, indent=2, ensure_ascii=False, default=lambda o: o.item() if hasattr(o,"item") else str(o))

    print("\nconvergence ranks:\n", pd.DataFrame(rank_ck).round(2).to_string())
    print("\nfigures written to", OUT)

if __name__ == "__main__":
    main()
