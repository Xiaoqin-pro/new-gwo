# Nightly report — NEW_GWO_2026 (2026-10-16)

Living document; updated after every completed batch. Detailed tables live in
the batch directories (`results/<batch>/REPORT.md`), the decision log in
`experiments/registry.csv`, gates in `docs/08`–`docs/13`.

## 0. What was built

A greenfield, GNN-free, lightweight GWO variant (`src/ANGWO.m`, working name)
with two separable modules, a standard GWO reference (`src/GWO.m`), a
uniform true-FE / novelty probe (`src/EvalProbe.m`), a four-worker batch
runner (`+overnight`, `experiments/runner_cec.m`, `run_batch_new.m`), an
audited-baseline merge and a statistics pipeline (Python; paired Wilcoxon +
Holm + Friedman-style ranks).

Protocol: CEC2017; true FE counted through the probe and cross-checked against
each algorithm's own counter; shared init pool per (function, seed);
search-seed conventions of the two audited batch families preserved;
baselines from `D:\...\狼群` and `D:\...\9.29` used read-only and reproduced
bit-for-bit (max relative difference <= 2.7e-15).

## 1. Pipeline validation (P0)

| check | result |
|---|---|
| fresh GWO reproduces audited GWO rows | PASS (rel <= 2.1e-15; F1/F6/F13) |
| IGWO/HIDMS/HCLPSO/DMS/SAQ reproduce audited rows | PASS (rel <= 2.7e-15) |
| ANGWO(modules off) == GWO bitwise | PASS (`test_angwo_equivalence`) |
| module scheduling shapes (fixed/random/adaptive) | PASS (`test_angwo_modes`) |
| cross-batch reruns (GWO, S-stag-nov, E-f10-self-r) | bitwise identical |
| FE audit: 0 violations in 4+ batches (0 failed runs) | PASS |

## 2. Diagnosis (DIAG1, D=30, 30k FE, 8 functions, 5 seeds, 240 runs)

Standard GWO is the worst of six algorithms on the dev set (mean rank 5.6)
and fails on both audit axes: 86% of its budget inside >=1% stagnation
episodes with ~3.5x slower recovery than HCLPSO, and a useful-novelty rate
of 0.95% versus 9.2% for DMS-PSO while having the HIGHEST raw novelty rate.
Full tables: `reports/diagnosis.md`.

## 3. Module screens (all pre-registered; see registry.csv)

* **RD1a (invalid in part, bug fixed)**: novelty-pool destination LOSES to a
  random destination (1.115 vs 0.938 median ratio); a struct-padding bug made
  random/adaptive runs degenerate — fixed, regression-tested, recorded.
* **RD1b/RD1c (E module)**: alpha-centred shell sampling wins; 20% share
  beats 10%/30%; random destination beats the novelty filter; adaptive quota
  fails B3. **E\* = fixed 20%, alpha-centred, random destination.**
  At 10 seeds: median error ratio vs GWO **0.634**, function wins **7/8**,
  pooled p=2.4e-7, 2 functions Holm-significant better, 0 worse.
* **RD2a/RD2b (S module)**: six stagnation-triggered re-deployment rules
  (far novelty, uniform random, periodic, elite-memory shell, alpha-shell
  x1/x3) all fail the pre-registered recovery gate A1: recovery probability
  0.748-0.794 vs GWO 0.775, even when a third of the budget is spent on
  re-deployment. Per docs/11 the S line is stopped; the negative result is
  kept and will be reported.
* **RD3 (promotion)**: E\* confirmed at 10 seeds; E\*+S2 (0.601) marginally
  better than E\* (0.634) but with equal-or-worse recovery/productivity
  metrics; per docs/12 the frozen main method remains **E\*** and the
  combination is kept as a documented control.

## 4. Formal batch (COMPLETE)

`results/formal_20261016_140254` — six variants x 29 functions x 30 seeds =
5220 runs at D=50 / 100k FE; 4 workers; **5220/5220 ok, 0 failures** in
90 minutes. The 870 GWO runs reproduce the audited GWO table **bitwise**
(max rel diff 0.000e+00). Merged table: 13050 rows, 15 algorithms.
Headline results (median error ratio vs GWO / mean rank):

| algorithm | rank | ratio vs GWO | note |
|---|---:|---:|---|
| HIDMS-PSO | 1 | 0.342 | |
| HCLPSO | 2 | 0.397 | |
| DMS-PSO | 3 | 0.389 | |
| IGWO | 4 | 0.465 | |
| SAQ-CSO | 5 | 0.578 | 2.5x GWO runtime |
| SPSO-2011 | 6 | 0.552 | |
| **ANGWO-final** | **7** | **0.792** | 21/29 wins vs GWO; 11 Holm-sig better, 0 worse; 1.04x GWO runtime |
| ANGWO-ES2 | 8 | 0.807 | S2 adds nothing (p=0.48) |
| HPSO-TVAC | 9 | 0.799 | |
| ANGWO-adapt | 10 | 0.825 | adaptive rejected (fixed better) |
| CLPSO | 11 | 0.789 | |
| ANGWO-novdest | 12 | 0.830 | novelty filter rejected |
| GWO | 13 | 1.000 | |
| ANGWO-self | 14 | 1.013 | alpha-centre is essential (ablation) |
| Original-CSO | 15 | 3.336 | |

Behaviour (formal): useful-novelty 0.0058 vs GWO 0.0035 (+64% paired median,
p=5e-94); long-stag share 0.831 vs 0.844; recovery prob 0.768 vs 0.757
(no gate pass); improving-FE rate median ratio 0.99. Family pattern of the
error gain: unimodal 0.102, hybrid 0.614, composition 0.896, simple
multimodal 1.024.

## 4b. Scalability tier (D=100, COMPLETE)

`results/d100_20261016_153544` — GWO vs ANGWO-final, 29 functions x 10
seeds, 580/580 ok, 0 failures (~25 min); the audited D=100 IGWO row is
reproduced (rel 4.0e-16). Results: 18/11 function wins vs GWO, median error
ratio 0.878 (no Holm-significant function at 10 seeds); vs audited IGWO and
RASE-GWO on the 12-function overlap: ratios 1.371 (5/12 wins) and 1.444
(1/12 wins). Runtime ratio 1.01. Interpretation: the mechanism transfers
partially to $D=100$; reported as a limitation.

## 5. Next steps

1. Merge with audited strong baselines (`merge_audited.py`, 10- and 15-algo
   tables), run `analyze_batch.py`, generate paper tables
   (`make_latex_tables.py`).
2. Fill `paper/angwo/main.tex` (tables + discussion), compile PDF with
   MiKTeX.
3. Write `reports/SCI_READINESS.md` with the A/B verdicts and the reviewer
   risk list; update this file.

## 6. Evidence summary (dual axis)

| axis | verdict | evidence |
|---|---|---|
| B: exploration efficiency | **supported** | formal: median error ratio 0.792 (21/29 wins, 11 Holm-sig better / 0 worse), useful-novelty +64% (p=5e-94), novelty-rate Q4 +15%; improving-FE-rate itself unchanged (median 0.99) |
| A: stagnation recovery | **not supported** | six re-deployment designs fail the +0.05 recovery gate (dev 0.748-0.794 vs 0.775; formal +0.011); long-stagnation share only -0.013 |
| equal-FE integrity | supported | 0 FE violations; all runs exactly 100k FE; probe-audited; GWO rows bitwise-identical to audited table |


