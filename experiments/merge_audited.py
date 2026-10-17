#!/usr/bin/env python3
"""Merge NEW_GWO_2026 runs with audited baseline rows for a formal comparison.

Usage:
  python merge_audited.py <our_runs.csv> --out merged.csv \
      --audited <csv1> --audited <csv2> \
      --map "HIDMS-PSO=HIDMS-PSO-IndexCorrected" ...

Rules (audited protocol, see reports/baseline_audit.md):
  * same FunctionID/Seed/D; audited rows are reused verbatim;
  * each mapping renames the audited algorithm label to the label used here;
  * overlapping (algorithm, function, seed) rows are rejected unless their
    FinalError matches within 1e-12 relative error (then ours is kept).
"""
import argparse
import pandas as pd


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ours")
    ap.add_argument("--audited", action="append", default=[])
    ap.add_argument("--map", action="append", default=[], help="OurName=AuditedName")
    ap.add_argument("--out", default="merged.csv")
    args = ap.parse_args()

    ours = pd.read_csv(args.ours)
    ours = ours[ours.Status == "ok"].copy()
    ours["Source"] = "new"
    aud = []
    for path in args.audited:
        t = pd.read_csv(path)
        t = t[t.Status == "ok"].copy() if "Status" in t.columns else t
        aud.append(t)
    aud = pd.concat(aud, ignore_index=True, sort=False) if aud else pd.DataFrame()
    if len(aud):
        aud = aud[aud.FunctionID != 2]

    merged = [ours]
    mapping = {}
    for spec in args.map:
        a, b = spec.split("=", 1)
        mapping[a] = b
    for our_name, aud_name in mapping.items():
        sel = aud[aud.Algorithm == aud_name].copy()
        if len(sel) == 0:
            raise SystemExit("audited rows missing for " + aud_name)
        sel["Algorithm"] = our_name
        sel["Source"] = "audited"
        merged.append(sel)
    out = pd.concat(merged, ignore_index=True, sort=False)

    key = ["Algorithm", "FunctionID", "Seed"]
    dup = out.duplicated(subset=key, keep=False)
    if dup.any():
        for gk, g in out[dup].groupby(key):
            if (g.Source == "audited").any() and (g.Source == "new").any():
                a = g[g.Source == "audited"].FinalError.iloc[0]
                n = g[g.Source == "new"].FinalError.iloc[0]
                if abs(a - n) > 1e-12 * max(1.0, abs(a)):
                    raise SystemExit(f"overlap mismatch for {gk}: {a} vs {n}")
        out = out[~((out.duplicated(subset=key, keep=False)) & (out.Source == "audited"))]
    out.to_csv(args.out, index=False)
    print(f"merged {len(out)} rows -> {args.out}")
    print(out.groupby("Algorithm").Source.value_counts().to_string())


if __name__ == "__main__":
    main()
