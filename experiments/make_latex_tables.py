#!/usr/bin/env python3
"""Generate LaTeX table fragments for the DCS-GWO draft from a merged runs.csv.

Usage:
  python make_latex_tables.py <merged_runs.csv> --outdir paper/angwo/tables \
      --final ANGWO-final --ref GWO

Outputs: main_table.tex, ablation_table.tex, behavior_table.tex, runtime_table.tex
"""
import argparse
import os

import numpy as np
import pandas as pd
from scipy import stats


def holm(p):
    p = np.asarray(p, float)
    order = np.argsort(p)
    adj = np.empty_like(p)
    cur = 0.0
    for i, idx in enumerate(order):
        cur = max(cur, p[idx] * (len(p) - i))
        adj[idx] = min(cur, 1.0)
    return adj


def pairwise_stats(piv, algs, ref):
    rows = {}
    funcs = sorted(piv.index.get_level_values(0).unique())
    for a in algs:
        if a == ref or a not in piv.columns:
            continue
        w = t = l = 0
        for f in funcs:
            ra = piv.loc[f, a].dropna()
            rb = piv.loc[f, ref].dropna()
            common = ra.index.intersection(rb.index)
            if len(common) == 0:
                continue
            ma, mb = ra.loc[common].mean(), rb.loc[common].mean()
            if ma < mb:
                w += 1
            elif ma > mb:
                l += 1
            else:
                t += 1
        ratios = (piv[a] / piv[ref]).dropna()
        medratio = float(np.median(ratios))
        try:
            pooled_p = stats.wilcoxon(np.log10(piv[ref]) - np.log10(piv[a])).pvalue
        except Exception:
            pooled_p = np.nan
        # per-function Holm
        ps, ds, fs = [], [], []
        for f in funcs:
            ra = piv.loc[f, a].dropna()
            rb = piv.loc[f, ref].dropna()
            common = ra.index.intersection(rb.index)
            if len(common) < 6:
                continue
            d = np.log10(rb.loc[common]) - np.log10(ra.loc[common])
            try:
                p = stats.wilcoxon(d).pvalue if np.any(d != 0) else 1.0
            except Exception:
                p = np.nan
            ps.append(p)
            ds.append(np.median(d))
            fs.append(f)
        sb = sw = 0
        if ps:
            q = holm(ps)
            for qi, di in zip(q, ds):
                if qi < 0.05:
                    if di > 0:
                        sb += 1
                    else:
                        sw += 1
        rows[a] = dict(W=w, T=t, L=l, ratio=medratio, p=pooled_p, sb=sb, sw=sw)
    return rows


def mean_rank(piv):
    med = piv.groupby(level=0).median()
    return med.rank(axis=1).mean(axis=0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("merged")
    ap.add_argument("--outdir", required=True)
    ap.add_argument("--final", default="ANGWO-final")
    ap.add_argument("--ref", default="GWO")
    args = ap.parse_args()
    os.makedirs(args.outdir, exist_ok=True)

    df = pd.read_csv(args.merged)
    df = df[df.Status == "ok"].copy()
    piv = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm",
                         values="FinalError", aggfunc="first")
    algs = list(piv.columns)
    rank = mean_rank(piv)
    pw = pairwise_stats(piv, algs, args.ref)

    # ---- main table (all algorithms, sorted by rank) ----
    order = rank.sort_values().index
    lines = [r"\begin{tabular}{lrrrrr}", r"\toprule",
             r"Algorithm & Mean rank & W/T/L vs GWO & Med.\ ratio & Sig.\ ($+/-$) & Time (s)\\",
             r"\midrule"]
    for a in order:
        secs = df[df.Algorithm == a]["Seconds"].mean()
        if a == args.ref:
            lines.append(f"{a} & {rank[a]:.2f} & -- & 1.000 & -- & {secs:.2f} \\\\")
        else:
            s = pw[a]
            lines.append(f"{a} & {rank[a]:.2f} & {s['W']}/{s['T']}/{s['L']} & "
                         f"{s['ratio']:.3f} & {s['sb']}/{s['sw']} & {secs:.2f} \\\\")
    lines += [r"\bottomrule", r"\end{tabular}"]
    open(os.path.join(args.outdir, "main_table.tex"), "w", encoding="utf-8").write("\n".join(lines))

    # ---- ablation table (our variants vs final) ----
    fam = ["GWO", "ANGWO-final", "ANGWO-self", "ANGWO-novdest", "ANGWO-adapt", "ANGWO-ES2"]
    fam = [a for a in fam if a in algs]
    pivf = piv[rank.index.tolist()]
    lines = [r"\begin{tabular}{lrrrrr}", r"\toprule",
             r"Variant & Mean rank & W/T/L vs GWO & Med.\ ratio vs GWO & vs final (ratio; W/T/L) & $p_{\mathrm{final}}$\\",
             r"\midrule"]
    for a in fam:
        secs = df[df.Algorithm == a]["Seconds"].mean()  # noqa: F841
        r_g = rank[a]
        if a == args.ref:
            lines.append(f"{a} & {r_g:.2f} & -- & 1.000 & -- & -- \\\\")
            continue
        s = pw[a]
        ra = piv[a]
        rf = piv[args.final]
        common = ra.dropna().index.intersection(rf.dropna().index)
        ratios = (ra.loc[common] / rf.loc[common])
        w = t = l = 0
        for f in sorted(piv.index.get_level_values(0).unique()):
            ma = piv.loc[f, a].mean()
            mb = piv.loc[f, args.final].mean()
            if ma < mb:
                w += 1
            elif ma > mb:
                l += 1
            else:
                t += 1
        try:
            p = stats.wilcoxon(np.log10(rf.loc[common]) - np.log10(ra.loc[common])).pvalue
        except Exception:
            p = np.nan
        lines.append(f"{a} & {r_g:.2f} & {s['W']}/{s['T']}/{s['L']} & {s['ratio']:.3f} & "
                     f"{np.median(ratios):.3f}; {w}/{t}/{l} & {p:.2e} \\\\")
    lines += [r"\bottomrule", r"\end{tabular}"]
    open(os.path.join(args.outdir, "ablation_table.tex"), "w", encoding="utf-8").write("\n".join(lines))

    # ---- behavior table ----
    lines = [r"\begin{tabular}{lrrrrr}", r"\toprule",
             r"Algorithm & Recov.\ prob. & Long-stag.\ share & Impr.\ rate Q4 & Useful nov. & Nov.\ rate Q4\\",
             r"\midrule"]
    for a in order:
        e = df[df.Algorithm == a]
        if "NStagEpisodes" not in e or e["NStagEpisodes"].isna().all():
            continue
        ep = e["NStagEpisodes"].sum()
        recw = e["NRecoveredWindow"].sum()
        lines.append(
            f"{a} & {(recw / ep if ep else float('nan')):.3f} & {e['LongStagShare'].mean():.3f} & "
            f"{e['ImprovRateQ4'].mean():.4f} & {e['NovelUsefulRate'].mean():.4f} & {e['NovRateQ4'].mean():.3f} \\\\")
    lines += [r"\bottomrule", r"\end{tabular}"]
    open(os.path.join(args.outdir, "behavior_table.tex"), "w", encoding="utf-8").write("\n".join(lines))

    # ---- runtime table ----
    lines = [r"\begin{tabular}{lrrr}", r"\toprule",
             r"Algorithm & Time (s) & Ratio vs GWO & Candidates / FE\\", r"\midrule"]
    gsec = df[df.Algorithm == args.ref]["Seconds"].mean()
    for a in order:
        e = df[df.Algorithm == a]
        cand = e["NCandidateGenerated"].mean()
        cpf = "n/a" if np.isnan(cand) else f"{cand / 100000.0:.3f}"
        lines.append(f"{a} & {e['Seconds'].mean():.2f} & {e['Seconds'].mean() / gsec:.2f} & {cpf} \\\\")
    lines += [r"\bottomrule", r"\end{tabular}"]
    open(os.path.join(args.outdir, "runtime_table.tex"), "w", encoding="utf-8").write("\n".join(lines))

    print("tables written to", args.outdir)
    print("algorithms:", order.tolist())


if __name__ == "__main__":
    main()
