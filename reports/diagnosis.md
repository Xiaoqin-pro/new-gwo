# Diagnosis report (Phase 1) — 2026-10-16

Batch: `results/diag1_20261016_134411` (240 runs, 0 failures, 4 workers).
Protocol: CEC2017 D=30, 30000 true FE, 8 stratified functions
(F1, F3, F4, F6, F9, F13, F18, F24), seeds 3001-3005, all algorithms
instrumented identically (EvalProbe: FE audit + novelty archive).
Full tables: `REPORT.md`, `summary.csv`, `stagnation.csv`, `novelty.csv`
inside the batch directory.

## 1. Dev-set ranking (context only)

| rank (mean rank / fn) | algorithm | median error | mean rank (per run) |
|---:|---|---:|---:|
| 1–2 | HIDMS-PSO | 4.85e2 | 2.43 |
| 1–2 | DMS-PSO | 4.65e2 | 2.33 |
| 3 | HCLPSO | 4.59e2 | 2.60 |
| 4 | IGWO (2021) | 6.25e3 | 3.90 |
| 5 | SAQ-CSO | 2.65e3 | 4.15 |
| 6 | **GWO** | 2.14e4 | 5.60 |

The externals' reproduction checks (bit-level vs audited rows) are in
`reports/baseline_audit.md`.

## 2. Failure mode of standard GWO (A: stagnation)

| metric | GWO | HIDMS-PSO | HCLPSO | DMS-PSO | SAQ-CSO |
|---|---:|---:|---:|---:|---:|
| stagnation episodes (>=300 FE) | 790 | 681 | 730 | 318 | 1115 |
| recovery probability within W+4W | **0.775** | 0.893 | **0.966** | 0.855 | 0.898 |
| median extra FE to recover | **502** | 207 | **145** | 159 | 325 |
| long-stagnation share of budget | **0.862** | 0.470 | 0.359 | **0.234** | 0.734 |
| late-quarter improvement rate | 0.0071 | 0.0321 | 0.0148 | **0.0829** | 0.0053 |

GWO spends 86% of its budget inside >=1% stagnation stretches and needs
~3.5x more FE than HCLPSO to break out. The strong PSO variants do not
"探索得更多" - they **recover faster and stagnate less**.

## 3. Failure mode of standard GWO (B: exploration efficiency)

| metric | GWO | HIDMS-PSO | HCLPSO | DMS-PSO | SAQ-CSO |
|---|---:|---:|---:|---:|---:|
| novel-evaluation rate (overall) | **0.891** | 0.775 | 0.682 | 0.546 | 0.817 |
| useful-novelty rate | **0.0095** | 0.051 | 0.057 | **0.092** | 0.030 |
| novel rate, last quarter | 0.570 | 0.473 | 0.374 | 0.295 | 0.626 |
| novel evaluations that improve gbest | 9.3 | 17.9 | 16.4 | 27.7 | 17.2 |

GWO has the HIGHEST pure novelty rate and the LOWEST useful-novelty rate:
its evaluations are far from history but almost never connect to an
improvement ("wasteful wandering", doc 02 taxonomy). DMS-PSO converts
novelty into improvements ~10x more often.

## 4. Consequences for the hypotheses (pre-registered in docs/08)

* The stagnation axis needs a **cheap, targeted redeployment rule**, not more
  randomness: GWO is already maximally "random-novel" (0.89).
* The exploration axis needs **fewer useless novel evaluations and more
  productive ones per FE**, i.e. an allocation/filtering change, not a larger
  perturbation.
* Both must keep the same true-FE budget (module candidates that are not
  evaluated cost no FE; their CPU cost is reported separately).

## 5. Notes and limitations

* 5 seeds x 8 functions is a screening protocol; no significance claims.
* Recovery metrics are computed from per-FE best-so-far traces; "recovery" is
  an operational definition (docs/01 of the starter protocol), not a proof of
  escaping a mathematical local optimum.
* The novelty threshold tau=0.01 is pre-registered; continuous novelty
  distributions are reported alongside all thresholded rates.
