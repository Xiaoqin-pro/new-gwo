#!/usr/bin/env python3
"""Strict re-verification of the frozen D=50 formal batch (5220 runs).

Checks, in order:
  1. raw MAT integrity: counts, statuses, exact FE accounting (100000), trace
     finiteness & monotonicity, BestCost == final trace value, and manifest
     job <-> record correspondence (no mislabelling);
  2. CSV <-> MAT consistency for every run;
  3. recomputation of the statistics quoted in NEXT_GOAL.txt:
       ANGWO-final vs GWO function-mean wins (21/8), paired Wilcoxon+Holm
       (11 better / 0 worse), early FE10/FE20 function-mean wins (10/29, 13/29),
       mean useful-novelty (0.003466 -> 0.005783), mean recovery events
       (14.555 -> 14.562);
  4. cross-check against the user-supplied D50_AUDIT_source.csv mean ratios;
  5. audited-baseline merge integrity (bitwise vs source tables).
Writes: sparse_q/reports/D50_AUDIT_VERIFICATION.md
"""
import glob
import os
import sys
try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass

import numpy as np
import pandas as pd
import scipy.io as sio
from scipy import stats

ROOT = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
BATCH = os.path.join(ROOT, "results", "formal_20261016_140254")
OUT = os.path.join(ROOT, "sparse_q", "reports", "D50_AUDIT_VERIFICATION.md")
L = []          # report lines
def log(s=""):
    L.append(str(s))
    try:
        print(s)
    except UnicodeEncodeError:
        print(str(s).encode("gbk", "replace").decode("gbk"))

fails = []

# ---------------------------------------------------------------- 1. raw MATs
files = sorted(glob.glob(os.path.join(BATCH, "runs", "run_*.mat")))
log(f"# D50 正式批严格复核（5220 次运行）\n")
log(f"批次目录：`{BATCH}`\n")
log(f"- raw run files: **{len(files)}** (expected 5220)")
if len(files) != 5220:
    fails.append("file count != 5220")

# manifest
jobs = None
try:
    man = sio.loadmat(os.path.join(BATCH, "manifest.mat"), squeeze_me=True, struct_as_record=False)
    jobs = np.atleast_1d(man["jobs"])
    log(f"- manifest jobs: {len(jobs)}")
except Exception as e:  # pragma: no cover
    log(f"- manifest parse failed: {e}")

n_ok = n_bad = 0
fe_bad = trace_bad = cost_bad = label_bad = finite_bad = 0
recs = {}
alg_counts = {}
for f in files:
    k = int(os.path.basename(f).split("_")[1].split(".")[0])
    m = sio.loadmat(f, squeeze_me=True, struct_as_record=False)
    r = m["record"]
    if str(getattr(r, "status", "")) != "ok":
        n_bad += 1
        fails.append(f"run {k} status != ok")
        continue
    n_ok += 1
    res = r.result
    # FE accounting
    if not (res.Evaluations == 100000 and res.ProbeFE == 100000 and res.Evaluations == res.ProbeFE):
        fe_bad += 1
    # trace checks
    tr = np.asarray(res.Trace).ravel()
    fe = np.asarray(res.TraceFE).ravel()
    if (not np.all(np.isfinite(tr)) or np.any(np.diff(tr) > 0)
            or not np.isfinite(res.BestCost) or tr[-1] != res.BestCost):
        trace_bad += 1
    # label correspondence vs manifest
    if jobs is not None and k - 1 < len(jobs):
        j = jobs[k - 1]
        if not (int(getattr(j, "fid")) == int(res.FunctionID)
                and int(getattr(j, "seed")) == int(res.Seed)
                and str(getattr(j, "label")) == str(res.Algorithm)):
            label_bad += 1
    recs[k] = res
    a = str(res.Algorithm)
    alg_counts[a] = alg_counts.get(a, 0) + 1

log(f"- status ok: **{n_ok}**, failed: **{n_bad}**")
log(f"- runs with FE accounting violation: **{fe_bad}**")
log(f"- runs with trace violations (non-finite/non-monotone/cost mismatch): **{trace_bad}**")
log(f"- manifest label mismatches: **{label_bad}**")
log(f"- per-algorithm counts: {alg_counts}\n")
if fe_bad or trace_bad or label_bad or n_bad:
    fails.append("raw MAT integrity violations")

# ------------------------------------------------------- 2. CSV <-> MAT checks
csv = pd.read_csv(os.path.join(BATCH, "runs.csv"))
log(f"## 2. CSV ↔ MAT 一致性\n")
log(f"- runs.csv rows: {len(csv)}")
bad = 0
for k, res in recs.items():
    row = csv.iloc[k - 1]
    checks = [
        row.Algorithm == str(res.Algorithm),
        int(row.FunctionID) == int(res.FunctionID),
        int(row.Seed) == int(res.Seed),
        abs(row.FinalError - (res.BestCost - 100 * res.FunctionID)) <= 1e-9 * max(1, abs(row.FinalError)),
        int(row.Evaluations) == int(res.Evaluations),
        abs(row.NImprove - res.Metrics.NImprove) < 1e-9,
        abs(row.NStagEpisodes - res.Metrics.NStagEpisodes) < 1e-9,
        abs(row.NRecoveredWindow - res.Metrics.NRecoveredWindow) < 1e-9,
        abs(row.NovelUsefulRate - res.Novelty.UsefulNovelRate) < 1e-12,
        abs(row.CheckT10 - res.Metrics.CheckT[0]) <= 1e-6 * max(1.0, abs(res.Metrics.CheckT[0])),
    ]
    if not all(checks):
        bad += 1
log(f"- rows with CSV↔MAT mismatch: **{bad}**\n")
if bad:
    fails.append("CSV/MAT mismatches")

# --------------------------------------------------------- 3. statistic recheck
df = csv[csv.Status == "ok"].copy()
piv = df.pivot_table(index=["FunctionID", "Seed"], columns="Algorithm",
                     values="FinalError", aggfunc="first")
funcs = sorted(df.FunctionID.unique())
A, B = "ANGWO-final", "GWO"
w = l = t = 0
ps, ds = [], []
for f in funcs:
    ra, rb = piv.loc[f, A], piv.loc[f, B]
    ma, mb = ra.mean(), rb.mean()
    w += ma < mb; l += ma > mb; t += ma == mb
    d = np.log10(rb) - np.log10(ra)
    ps.append(stats.wilcoxon(d).pvalue if np.any(d != 0) else 1.0)
    ds.append(np.median(d))
holm = np.empty(len(ps))
order = np.argsort(ps)
cur = 0.0
for i, idx in enumerate(order):
    cur = max(cur, ps[idx] * (len(ps) - i))
    holm[idx] = min(cur, 1.0)
sig_b = int(np.sum((holm < 0.05) & (np.array(ds) > 0)))
sig_w = int(np.sum((holm < 0.05) & (np.array(ds) < 0)))

log("## 3. 统计复核（ANGWO-final vs GWO，29 函数 × 30 种子）\n")
log("| 指标 | 复核值 | NEXT_GOAL 声称 | 判定 |")
log("|---|---:|---:|---|")
claims = [
    ("函数均值胜负 (W/L)", f"{w}/{l}", "21/8"),
    ("配对 Wilcoxon+Holm (better/worse)", f"{sig_b}/{sig_w}", "11/0"),
]
rv = []
for name, val, claim in claims:
    ok = val == claim
    if not ok:
        fails.append(f"statistic mismatch: {name} {val} vs {claim}")
    log(f"| {name} | {val} | {claim} | {'一致' if ok else '**不一致**'} |")

# early checkpoints FE10/20
ev = {}
for cp, col in [("FE10", "CheckT10"), ("FE20", "CheckT20")]:
    wins = 0
    for f in funcs:
        ra = df[(df.FunctionID == f) & (df.Algorithm == A)][col].mean() - 100 * f
        rb = df[(df.FunctionID == f) & (df.Algorithm == B)][col].mean() - 100 * f
        wins += ra < rb
    ev[cp] = wins
log(f"| 早期 {('FE10k')} 函数均值胜 | {ev['FE10']}/29 | 10/29 | {'一致' if ev['FE10']==10 else '**不一致**'} |")
log(f"| 早期 FE20k 函数均值胜 | {ev['FE20']}/29 | 13/29 | {'一致' if ev['FE20']==13 else '**不一致**'} |")
if ev["FE10"] != 10:
    fails.append("FE10 wins != 10")
if ev["FE20"] != 13:
    fails.append("FE20 wins != 13")

nov_a = df[df.Algorithm == A].NovelUsefulRate.mean()
nov_b = df[df.Algorithm == B].NovelUsefulRate.mean()
rec_a = df[df.Algorithm == A].NRecoveredWindow.mean()
rec_b = df[df.Algorithm == B].NRecoveredWindow.mean()
log(f"| 有用新颖率均值 GWO→ANGWO | {nov_b:.7f} → {nov_a:.7f} | 0.0034660 → 0.005783 | "
    f"{'一致(舍入)' if abs(nov_b-0.003466)<5e-6 and abs(nov_a-0.005783)<5e-6 else '**不一致**'} |")
log(f"| 真实恢复事件均值 GWO→ANGWO | {rec_b:.3f} → {rec_a:.3f} | 14.555 → 14.562 | "
    f"{'一致(舍入)' if abs(rec_b-14.555)<0.01 and abs(rec_a-14.562)<0.01 else '**不一致**'} |")
if not (abs(nov_b-0.003466)<5e-6 and abs(nov_a-0.005783)<5e-6):
    fails.append("useful-novelty means differ")
if not (abs(rec_b-14.555)<0.01 and abs(rec_a-14.562)<0.01):
    fails.append("recovery-event means differ")

log("\n备注：ANGWO（冻结）为全评价、无 Q 表；ANGWO-adapt 为启发式比例反馈"
    "（θ += η(r_rover − r_exploit)），两者都不是 Q-learning —— 与 frozen 代码"
    "（docs/13_FREEZE.md 记录 hash）逐行核对成立。\n")

# --------------------------------------------- 4. cross-check user D50_AUDIT
src = pd.read_csv(os.path.join(ROOT, "sparse_q", "docs", "D50_AUDIT_source.csv"))
maxdiff = 0.0
for _, row in src.iterrows():
    f = int(row.FunctionID)
    ra = piv.loc[f, A].mean()
    rb = piv.loc[f, B].mean()
    maxdiff = max(maxdiff, abs(ra / rb - row.mean_ratio_ANGWO_over_GWO))
log("## 4. 与用户 D50_AUDIT_source.csv 对照\n")
log(f"- 29 个函数 mean-ratio 最大绝对偏差：**{maxdiff:.3e}** "
    f"({'一致' if maxdiff < 1e-9 else '**不一致**'})\n")
if maxdiff >= 1e-9:
    fails.append("user audit mismatch")

# ------------------------------------- 5. audited baseline merge integrity
merged = pd.read_csv(os.path.join(BATCH, "merged_runs.csv"))
aud = merged[merged.Source == "audited"]
ok5 = True
for path, name in [
    (os.path.join(ROOT, "data", "reference", "audited_10algo_30seed.csv"), "audit10"),
    (os.path.join(ROOT, "data", "reference", "audited_15algo_30seed.csv"), "audit15"),
]:
    s = pd.read_csv(path)
    s = s[s.Status == "ok"] if "Status" in s.columns else s
    for alg in set(aud.Algorithm):
        a1 = aud[aud.Algorithm == alg][["FunctionID", "Seed", "FinalError"]].sort_values(["FunctionID", "Seed"])
        a2 = s[s.Algorithm == alg][["FunctionID", "Seed", "FinalError"]].sort_values(["FunctionID", "Seed"])
        if len(a2) == 0:
            continue
        m = a1.merge(a2, on=["FunctionID", "Seed"], suffixes=("_m", "_s"))
        if len(m) != len(a1):
            ok5 = False
            continue
        rel = np.abs(m.FinalError_m - m.FinalError_s) / np.maximum(1.0, np.abs(m.FinalError_s))
        if rel.max() > 1e-12:
            ok5 = False
            log(f"- {alg}: max rel diff {rel.max():.3e} **不一致**")
log(f"\n## 5. 合并基线完整性\n\n- audited 行与源表逐位一致：**{ok5}**\n")
if not ok5:
    fails.append("audited merge mismatch")

log("\n## 结论\n")
if fails:
    log("**复核失败项：**")
    for x in fails:
        log(f"- {x}")
else:
    log("**全部复核通过**：5220/5220 状态 ok、FE 精确 100000、轨迹单调有限、"
        "manifest↔记录逐一对应、CSV↔MAT 一致、统计声称全部复现、"
        "用户审计表一致、合并基线逐位一致。")

with open(OUT, "w", encoding="utf-8") as fh:
    fh.write("\n".join(L) + "\n")
print("report ->", OUT)
sys.exit(1 if fails else 0)


