# Environment report (NEW_GWO_2026)

Date: 2026-10-16 (America/New_York).

## MATLAB

| item | value |
|---|---|
| MATLAB | 25.2.0.2998904 (R2025b) |
| Path | D:\Program Files\MATLAB\R2025b\bin\matlab.exe |
| Parallel Computing Toolbox | licensed, present |
| Statistics and Machine Learning Toolbox | licensed, present |
| Optimization Toolbox | licensed, present |
| Local pool test | `parpool('local',4)` -> 4 workers confirmed (2026-10-16) |

All formal batches run through `+overnight/runBatch4.m` (parfor over
independent [algorithm x function x seed] jobs, exactly 4 local workers, no
serial fallback; each finished run is written immediately as
`results/<batch>/runs/run_%05d.mat` and can be resumed).

## CEC2017 harness (audited, copied read-only)

| item | value |
|---|---|
| Source | D:\111\Desktop\噜噜\9.29\data\cec2017 (audited batch harness) |
| Copied to | data/cec2017 (MEX + cec17_func.cpp + input_data D30/D50 + shift/shuffle) |
| cec17_func.mexw64 SHA-256 | 5395FC0C62CA028116C51161FAA4AC200402C275307BFCB300BFB0AB50EF35C9 |
| CWD requirement | MEX opens `input_data/...` relative to the working directory; runner_cec always cd's into data/cec2017 |
| Function set | F1, F3..F30 (F2 excluded per CEC2017 convention); optima offset 100*fid |

## Result protocol (identical to audited historical batches)

* initSeed  = 261013000 + fid*10000 + seed; `rng(initSeed)` -> pool = -100+200*rand(50,D);
  every algorithm consumes the first N rows (shared paired prefix).
* searchSeed: wolf-pack family (GWO/IGWO/ANGWO) = seed+1000000;
  9.29 family (strong PSO/CSO baselines) = initSeed+1000000.
  Both families were audited on the same init pools; see reports/baseline_audit.md.
* TRUE-evaluation budget includes initialization; every objective call passes
  through EvalProbe, which counts evaluations independently of the algorithm
  (run fails on mismatch). No extra, uncounted or duplicate evaluations
  anywhere; module candidates that are not evaluated cost no FE (their CPU
  cost is reported via NCandidateGenerated / NDistanceOps).

## Pipeline validation (2026-10-16)

| test | result |
|---|---|
| tests/test_gwo_unit.m | PASS (FE count, monotone trace, bounds, determinism, seed sensitivity) |
| tests/test_angwo_equivalence.m | PASS (ANGWO with modules off == GWO bitwise; modules on keep budget & monotone trace) |
| tests/test_pipeline_cec.m | PASS (GWO reproduces audited rows, rel. err <= 2.1e-15) |
| tests/test_pipeline_external.m | PASS (IGWO / HIDMS-PSO / HCLPSO / DMS-PSO / SAQ-CSO reproduce audited rows, rel. err <= 2.7e-15) |
