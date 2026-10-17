#!/usr/bin/env python3
"""Analyze one NEW_GWO_2026 batch (runs.csv).

Outputs (into the batch directory):
  summary.csv        per-algorithm error / rank / runtime summary
  pairwise.csv       paired comparisons vs the reference algorithm
  stagnation.csv     stagnation & recovery aggregates
  novelty.csv        novelty / useful-novelty aggregates
  checkpoints.csv    median error ratio vs reference at 10/20/50/80/100%
  REPORT.md          human-readable report

Conventions (pre-registered, see docs/08_HYPOTHESES_AND_GATES.md):
  * error metric: FinalError = BestCost - 100*fid
  * paired unit: (FunctionID, Seed); comparisons use log10(error) differences
  * pairwise tests: Wilcoxon signed-rank (paired), Holm across functions
  * mean rank: rank algorithms inside each function (by median error over
    seeds), then average; a second rank uses per-(fn,seed) ranks
"""
import argparse
import os

import numpy as np
import pandas as pd
from scipy import stats


def holm(p):
    p = np.asarray(p, dtype=float)
    n = len(p)
    order = np.argsort(p)
    adj = np.empty(n)
    cur = 0.0
    for i, idx in enumerate(order):
        val = p[idx] * (n - i)
        cur = max(cur, val)
        adj[idx] = min(cur, 1.0)
    return adj


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("batch_dir")
    ap.add_argument("--file", default="runs.csv")
    ap.add_argument("--ref", default=None)
    ap.add_argument("--out", default="REPORT.md")
    args = ap.parse_args()

    path = os.path.join(args.batch_dir, args.file)
    df = pd.read_csv(path)
    if "Status" in df.columns:
        df = df[df.Status == "ok"].copy()
    if len(df) == 0:
        raise SystemExit("no ok runs in " + path)
    df["Err"] = df["FinalError"]
    df["ErrSafe"] = df["Err"].clip(lower=1e-12)

    algs = list(pd.unique(df["Algorithm"]))
    ref = args.ref or ("GWO" if "GWO" in algs else None)
    piv = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm",
                         values="ErrSafe", aggfunc="first")

    # ---- ranks ----
    med = df.groupby(["FunctionID", "Algorithm"])["ErrSafe"].median().unstack("Algorithm")
    rank_fn = med.rank(axis=1)
    rank_run = piv.rank(axis=1)

    # ---- summary ----
    rows = []
    for a in algs:
        e = df[df.Algorithm == a]
        rows.append(dict(
            Algorithm=a, NRuns=len(e),
            MeanErr=e.Err.mean(), MedianErr=e.Err.median(),
            MeanRankFn=rank_fn[a].mean(), MeanRankRun=rank_run[a].mean(),
            SecondsMean=e["Seconds"].mean() if "Seconds" in e else np.nan,
            ImprovRate=e["ImprovingFERate"].mean() if "ImprovingFERate" in e else np.nan,
        ))
    summary = pd.DataFrame(rows).sort_values("MeanRankFn")
    summary.to_csv(os.path.join(args.batch_dir, "summary.csv"), index=False)

    # ---- pairwise vs reference ----
    pair_rows = []
    if ref in algs:
        funcs = sorted(df.FunctionID.unique())
        p_raw = []
        for a in algs:
            if a == ref:
                pair_rows.append(dict(Algorithm=a, WL="ref", FuncWins=np.nan, FuncLosses=np.nan,
                                      MedianRatio=np.nan, SigBetter=np.nan, SigWorse=np.nan,
                                      PooledP=np.nan, PooledLogDiff=np.nan))
                p_raw.append(np.nan)
                continue
            wins = losses = 0
            ratios = []
            for f in funcs:
                ra = piv.loc[f, a].dropna() if f in piv.index.get_level_values(0) else pd.Series(dtype=float)
                rb = piv.loc[f, ref].dropna() if f in piv.index.get_level_values(0) else pd.Series(dtype=float)
                common = ra.index.intersection(rb.index)
                if len(common) == 0:
                    continue
                ra = ra.loc[common]; rb = rb.loc[common]
                if ra.mean() < rb.mean():
                    wins += 1
                elif ra.mean() > rb.mean():
                    losses += 1
                ratios.extend((ra / rb).values)
            ratios = np.asarray(ratios)
            ra_all = piv[a].dropna(); rb_all = piv[ref].dropna()
            common = ra_all.index.intersection(rb_all.index)
            d = np.log10(rb_all.loc[common]) - np.log10(ra_all.loc[common])  # >0 = a better
            try:
                pooled_p = stats.wilcoxon(d).pvalue if np.any(d != 0) else 1.0
            except Exception:
                pooled_p = np.nan
            pair_rows.append(dict(Algorithm=a, WL="", FuncWins=wins, FuncLosses=losses,
                                  MedianRatio=float(np.median(ratios)) if len(ratios) else np.nan,
                                  SigBetter=np.nan, SigWorse=np.nan,
                                  PooledP=pooled_p, PooledLogDiff=float(np.median(d))))
            p_raw.append(np.nan)
        pairwise = pd.DataFrame(pair_rows)
        # per-function Wilcoxon + Holm (only meaningful with enough seeds)
        if piv[ref].notna().any():
            funcs = sorted(df.FunctionID.unique())
            pvals, tests = [], []
            for a in algs:
                if a == ref:
                    continue
                for f in funcs:
                    ra = piv.loc[f, a].dropna(); rb = piv.loc[f, ref].dropna()
                    common = ra.index.intersection(rb.index)
                    if len(common) < 6:
                        continue
                    d = np.log10(rb.loc[common]) - np.log10(ra.loc[common])
                    try:
                        p = stats.wilcoxon(d).pvalue if np.any(d != 0) else 1.0
                    except Exception:
                        p = np.nan
                    tests.append((a, f, p, np.median(d)))
            if tests:
                padj = holm([t[2] for t in tests])
                for (a, f, p, md), q in zip(tests, padj):
                    if q < 0.05:
                        if md > 0:
                            pairwise.loc[pairwise.Algorithm == a, "SigBetter"] = (
                                pairwise.loc[pairwise.Algorithm == a, "SigBetter"].fillna(0) + 1)
                        else:
                            pairwise.loc[pairwise.Algorithm == a, "SigWorse"] = (
                                pairwise.loc[pairwise.Algorithm == a, "SigWorse"].fillna(0) + 1)
                pairwise["SigBetter"] = pairwise["SigBetter"].fillna(0)
                pairwise["SigWorse"] = pairwise["SigWorse"].fillna(0)
        pairwise.to_csv(os.path.join(args.batch_dir, "pairwise.csv"), index=False)
    else:
        pairwise = pd.DataFrame()

    # ---- stagnation ----
    st_rows = []
    if "NStagEpisodes" in df.columns:
        for a in algs:
            e = df[df.Algorithm == a]
            ep = e["NStagEpisodes"].sum()
            recw = e.get("NRecoveredWindow", pd.Series(np.nan, index=e.index)).sum()
            rece = e.get("NRecoveredEventual", pd.Series(np.nan, index=e.index)).sum()
            st_rows.append(dict(
                Algorithm=a,
                StagEpisodesTotal=ep,
                RecoveryProbWindow=(recw / ep) if ep else np.nan,
                RecoveryProbEventual=(rece / ep) if ep else np.nan,
                RecoveryMedExtraFE=e["RecoveryMedExtraFE"].median(),
                LongStagShare=e["LongStagShare"].mean(),
                FinalStagLenMedian=e["FinalStagLen"].median(),
                NImprove=e["NImprove"].mean(),
                ImprovRateQ1=e.get("ImprovRateQ1", pd.Series(np.nan)).mean(),
                ImprovRateQ2=e.get("ImprovRateQ2", pd.Series(np.nan)).mean(),
                ImprovRateQ3=e.get("ImprovRateQ3", pd.Series(np.nan)).mean(),
                ImprovRateQ4=e.get("ImprovRateQ4", pd.Series(np.nan)).mean(),
            ))
        stagnation = pd.DataFrame(st_rows)
        stagnation.to_csv(os.path.join(args.batch_dir, "stagnation.csv"), index=False)
    else:
        stagnation = pd.DataFrame()

    # ---- novelty ----
    nv_rows = []
    if "NovMean" in df.columns:
        for a in algs:
            e = df[df.Algorithm == a]
            nv_rows.append(dict(
                Algorithm=a, NovMean=e["NovMean"].mean(), NovMedian=e["NovMedian"].median(),
                NovRate=e["NovRate"].mean(), NovelUsefulRate=e["NovelUsefulRate"].mean(),
                NovelStrictImprove=e["NovelStrictImprove"].mean(),
                NovRateQ1=e.get("NovRateQ1", pd.Series(np.nan)).mean(),
                NovRateQ2=e.get("NovRateQ2", pd.Series(np.nan)).mean(),
                NovRateQ3=e.get("NovRateQ3", pd.Series(np.nan)).mean(),
                NovRateQ4=e.get("NovRateQ4", pd.Series(np.nan)).mean(),
            ))
        novelty = pd.DataFrame(nv_rows)
        novelty.to_csv(os.path.join(args.batch_dir, "novelty.csv"), index=False)
    else:
        novelty = pd.DataFrame()

    # ---- checkpoints (median ratio vs ref) ----
    cp_rows = []
    if ref is not None:
        for a in algs:
            if a == ref:
                continue
            row = dict(Algorithm=a)
            for cp in ["CheckT10", "CheckT20", "CheckT50", "CheckT80", "CheckT100"]:
                if cp not in df.columns:
                    row[cp] = np.nan
                    continue
                da = df[(df.Algorithm == a)][["FunctionID", "Seed", cp]]
                db = df[(df.Algorithm == ref)][["FunctionID", "Seed", cp]]
                m = da.merge(db, on=["FunctionID", "Seed"], suffixes=("_a", "_b"))
                if len(m) == 0:
                    row[cp] = np.nan
                    continue
                # per-function median error ratio using checkpoint value minus offset
                m["ea"] = (m[cp + "_a"] - 100 * m.FunctionID).clip(lower=1e-12)
                m["eb"] = (m[cp + "_b"] - 100 * m.FunctionID).clip(lower=1e-12)
                r = m.groupby("FunctionID").apply(
                    lambda g: np.median(g.ea / g.eb), include_groups=False)
                row[cp] = r.median()
            cp_rows.append(row)
        checkpoints = pd.DataFrame(cp_rows)
        checkpoints.to_csv(os.path.join(args.batch_dir, "checkpoints.csv"), index=False)
    else:
        checkpoints = pd.DataFrame()

    # ---- report ----
    lines = []
    lines.append(f"# Batch report: {os.path.basename(os.path.normpath(args.batch_dir))}\n")
    lines.append(f"file: `{args.file}` | runs: {len(df)} | reference: **{ref}**\n")
    lines.append("## Summary\n")
    lines.append(summary.to_markdown(index=False, floatfmt=".4g"))
    if len(pairwise):
        lines.append("\n## Pairwise vs reference\n")
        lines.append(pairwise.to_markdown(index=False, floatfmt=".4g"))
    if len(stagnation):
        lines.append("\n## Stagnation / recovery\n")
        lines.append(stagnation.to_markdown(index=False, floatfmt=".4g"))
    if len(novelty):
        lines.append("\n## Novelty\n")
        lines.append(novelty.to_markdown(index=False, floatfmt=".4g"))
    if len(checkpoints):
        lines.append("\n## Median error ratio vs reference at checkpoints\n")
        lines.append(checkpoints.to_markdown(index=False, floatfmt=".4g"))
    with open(os.path.join(args.batch_dir, args.out), "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
