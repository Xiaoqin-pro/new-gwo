# -*- coding: utf-8 -*-
"""Emit LaTeX tables for the D=100 supplement (paper-ready)."""
import os, json
import pandas as pd
SQ=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.join(SQ,"results","d100_analysis")
main=pd.read_csv(os.path.join(OUT,"table_d100_main.csv"))
S=json.load(open(os.path.join(OUT,"stats_d100.json"),encoding="utf-8"))
L=[]
L.append("% Auto-generated from raw_runs.csv; do not edit by hand.\n")
L.append("\\begin{tabular}{lrrrrrr}\n\\toprule\n")
L.append("Method & Mean rank & Med.\\ ratio & W--L & Holm $(+/-)$ & Time (s) & Rel.\\ GWO\\\\\n\\midrule\n")
for _,r in main.iterrows():
    name=r.Algorithm.replace("VAST-GWO","\\textbf{VAST-GWO}")
    ratio="--" if r.Algorithm=="VAST-GWO" else f"{r.MedianRatio_vs_VAST:.3f}"
    wl="--" if r.Algorithm=="VAST-GWO" else f"{r.FunctionsWin}--{r.FunctionsLoss}"
    hs="--" if r.Algorithm=="VAST-GWO" else f"+{r.HolmSigWin}/$-${r.HolmSigLoss}"
    L.append(f"{name} & {r.MeanRank:.2f} & {ratio} & {wl} & {hs} & {r.RuntimeMedian_s:.2f} & {r.RuntimeRel_GWO:.2f}$\\times$\\\\\n")
L.append("\\bottomrule\n\\end{tabular}\n")
open(os.path.join(OUT,"table_d100_main.tex"),"w",encoding="utf-8",newline="\n").write("".join(L))
print("wrote table_d100_main.tex")
