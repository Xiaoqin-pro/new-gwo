# Baseline audit (NEW_GWO_2026)

Goal: every comparison algorithm must be (i) traceable to an audited
implementation, (ii) runnable under the SAME protocol as our algorithm, and
(iii) verifiable by bit-level or near-bit-level reproduction against the
audited 30-seed result tables that were produced earlier by the same machine.

## Audited reference tables (read-only, copied in)

| file | content |
|---|---|
| data/reference/audited_10algo_30seed.csv | wolf-pack batch: GWO, IGWO (faithful 2021), RASE-GWO family - D=50, 100k FE, 29 fn, seeds 3001-3030 |
| data/reference/audited_15algo_30seed.csv | merged: adds Original-CSO, CLPSO, HPSO-TVAC, SPSO-2011, SAQ-CSO, HCLPSO, HIDMS-PSO, DMS-PSO |

Both tables were audited in the source projects (identical init pools verified
bitwise on F1/seed3001; I-GWO corrected to the author implementation; SAQ-CSO
framework frozen and validated). They are reused ONLY for the final 30-seed
comparison, never for tuning (`docs/08_HYPOTHESES_AND_GATES.md`).

## Algorithm-by-algorithm audit

| algorithm | entry (read-only external) | origin / provenance | population | protocol family (search seed) | reproduction check |
|---|---|---|---|---|---|
| GWO | our src/GWO.m (fresh paper implementation) | Mirjalili et al. 2014 | 50 | wolf-pack (seed+1e6) | F1/3001, F6/3002, F13/3005 reproduce audited rows, rel.err <= 2.1e-15 |
| IGWO (2021, DLH) | D:\...\狼群\src\IGWO.m | Nadimi-Shahraki et al. 2021, corrected per docs/04_IGWO_CORRECTION.md (4 fixes, author source) | 50 | wolf-pack | F1/3001 reproduces audited IGWO row, rel.err 1.7e-16 |
| HIDMS-PSO | 9.29\src\HIDMS_PSO_CEC.m | Varna & Husbands 2020, author code + index correction | 40 | 9.29 (initSeed+1e6) | F1/3001 reproduces, rel.err 1.3e-15 |
| HCLPSO | 9.29\src\HCLPSO_CEC_AuthorSource.m | author archive (HCLPSO_PS_15_35.m) | 50 | 9.29 | F6/3002 reproduces, rel.err 1.9e-16 |
| DMS-PSO | 9.29\src\DMS_PSO_SIS_CEC.m | SIS2005 base DMS-PSO paper reconstruction (documented as reconstruction, not author file) | 30 | 9.29 | F13/3005 reproduces, rel.err 2.6e-15 |
| SAQ-CSO | 9.29\src\SAQ_CSO_AblationVariant.m (variant 'Full') | teacher-material line, frozen framework + Q quota | 50 | 9.29 | F1/3001 reproduces, rel.err 1.8e-16 |
| SPSO-2011 | 9.29\src\SPSO2011_CEC.m + native MEX | official C SPSO2011 profile | 40 | 9.29 | audited table reused (not re-run for diagnosis) |
| HPSO-TVAC | 9.29\src\HPSO_TVAC_CEC.m | 2017 EPSO code package | 50 | 9.29 | audited table reused |
| CLPSO | 9.29\src\CLPSO_CEC_AuthorSource.m | author source | 50 | 9.29 | audited table reused |
| Original-CSO | 9.29 batch | MR=0.2 baseline | 50 | 9.29 | audited table reused |

Reproduction tests (2026-10-16): `tests/test_pipeline_cec.m`,
`tests/test_pipeline_external.m` - all PASS.

## Explicit statements

* External algorithm sources are used READ-ONLY; no external file was modified
  (verified: nothing under D:\...\狼群 or D:\...\9.29 is written by this
  project; all outputs go to NEW_GWO_2026/results).
* DMS-PSO is a paper reconstruction (SIS2005); the audited merged table labels
  it `DMS-PSO-SIS2005`. Any claim about "DMS-PSO" is scoped to that audited
  implementation.
* Baseline hyperparameters are untouched; populations are the audited originals
  (HIDMS 40, SPSO 40, DMS 30, others 50).
* The old RASE-GWO code is NOT used as a starting point for the new method and
  is not part of any new-method code path; it appears only as historical
  context in the audited tables (and may be cited as an external comparison).
