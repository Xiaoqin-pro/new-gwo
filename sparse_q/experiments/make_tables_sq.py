#!/usr/bin/env python3
"""LaTeX tables for the sparse_q paper (final tier)."""
import os
import numpy as np
import pandas as pd
from scipy import stats

SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
B = os.path.join(SQ, "results", "final_20261016_215309")
OUT = os.path.join(SQ, "paper", "tables")
os.makedirs(OUT, exist_ok=True)
L = []
def w(s):
    L.append(s)
    open(os.path.join(OUT, "table_main.tex"), "w", encoding="utf-8").write("\n".join(L) + "\n") if False else None

df = pd.read_csv(os.path.join(B, "merged_runs.csv"), low_memory=False)
df = df[df.Status == "ok"]
piv = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
rank = piv.groupby(level=0).median().rank(axis=1).mean(axis=0).sort_values()

def ratio(A, Bn):
    rs = []
    for f in sorted(set(piv.index.get_level_values(0))):
        ra, rb = piv.loc[f, A].dropna(), piv.loc[f, Bn].dropna()
        c = ra.index.intersection(rb.index)
        if len(c):
            rs.append(np.median(ra.loc[c] / rb.loc[c]))
    return float(np.median(rs))

def wl(A, Bn):
    w = l = 0
    for f in sorted(set(piv.index.get_level_values(0))):
        ra, rb = piv.loc[f, A].dropna(), piv.loc[f, Bn].dropna()
        c = ra.index.intersection(rb.index)
        if len(c) == 0: continue
        ma, mb = ra.loc[c].mean(), rb.loc[c].mean()
        w += ma < mb; l += ma > mb
    return w, l

lines = [r"\begin{tabular}{lrrrrr}", r"\toprule",
         r"Method & Mean rank & W-L vs GWO & Med.\ ratio vs GWO & Time (s) & Source\\",
         r"\midrule"]
srcmap = {"S-star": "this work", "S1-pool38": "this work (K=50)", "S3p-q25": "this work (quota)",
          "S5p-q": "this work (Q)", "B1-dense-sync": "this work (blank)",
          "B0-ANGWO": "frozen reuse", "GWO": "audited", "RASE-GWO": "audited (historical)"}
for a in rank.index:
    t = df[df.Algorithm == a]["Seconds"].mean()
    if a == "GWO":
        lines.append(f"{a} & {rank[a]:.2f} & -- & 1.000 & {t:.2f} & audited \\\\")
    else:
        r = ratio(a, "GWO"); win, los = wl(a, "GWO")
        lines.append(f"{a} & {rank[a]:.2f} & {win}-{los} & {r:.3f} & {t:.2f} & {srcmap.get(a,'audited')} \\\\")
lines += [r"\bottomrule", r"\end{tabular}"]
open(os.path.join(OUT, "table_main.tex"), "w", encoding="utf-8").write("\n".join(lines))

# behaviour table
lines = [r"\begin{tabular}{lrrrrr}", r"\toprule",
         r"Method & Recovery prob. & Long-stag.\ share & Useful novelty & Nov.\ rate Q4 & Impr.\ rate Q4\\",
         r"\midrule"]
for a in ["S-star", "S1-pool38", "S3p-q25", "S5p-q", "B0-ANGWO", "GWO"]:
    e = df[df.Algorithm == a]
    if "NStagEpisodes" not in e:
        continue
    ep = e["NStagEpisodes"].sum(); rec = e["NRecoveredWindow"].sum() / ep if ep else float("nan")
    lines.append(f"{a} & {rec:.3f} & {e.LongStagShare.mean():.3f} & {e.NovelUsefulRate.mean():.5f} & "
                 f"{e.NovRateQ4.mean():.3f} & {e.ImprovRateQ4.mean():.5f} \\\\")
lines += [r"\bottomrule", r"\end{tabular}"]
open(os.path.join(OUT, "table_behaviour.tex"), "w", encoding="utf-8").write("\n".join(lines))
print("tables written")
