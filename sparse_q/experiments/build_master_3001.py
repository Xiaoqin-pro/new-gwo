#!/usr/bin/env python3
"""Build the integrated 3001-3030 master matrix from every available result file.

Scan rule
---------
Look at every runs*.csv / *result*.csv under the two repositories
(new-gwo-g2tr-branch and its sibling 狼群), keep only CEC2017 D=50 runs with
seeds 3001-3030, and accept an (algorithm, file) pair only when it covers all
29 functions (F1, F3-F30) x 30 seeds.

Selection rule
--------------
When the same algorithm name appears in several files, the sources are
cross-checked run by run. Identical series are collapsed silently. When two
sources disagree (a genuine protocol difference such as CLPSO N=40 vs N=50),
the priority order below decides, and the choice is printed.

Output: sparse_q/reports/integrated_3001/master_3001.csv (870 x nArms)
"""
import sys, json
from pathlib import Path
import numpy as np, pandas as pd

FUNCS = [1] + list(range(3, 31))
SEEDS = list(range(3001, 3031))
SQ = Path(__file__).resolve().parents[1]          # sparse_q/
ROOT = SQ.parent                                   # new-gwo-g2tr-branch/
OUT = SQ/'reports'/'integrated_3001'
SIBLING = ROOT.parent/'狼群'

# Preference when two files disagree. Lower score wins.
def score(p):
    p = str(p).replace('\\','/')
    s = 0
    if p.startswith(str(ROOT).replace('\\','/')): s -= 100     # main repo first
    if 'audited' in p: s -= 40
    if 'd100' in p: s += 10000                                 # wrong dimension
    if 'clpso_20261017_213147' in p: s += 1000                 # CLPSO N=40
    if 'clpso_20261017_214939' in p: s -= 10                   # CLPSO N=50
    if 'merged' in p: s += 5                                   # prefer raw files
    return s

def scan():
    files = []
    for base in (ROOT, SIBLING):
        if not base.exists(): continue
        for p in base.rglob('*.csv'):
            n = p.name.lower()
            if 'runs' in n or 'result' in n: files.append(p)
    found = {}
    for p in files:
        try:
            df = pd.read_csv(p, low_memory=False)
        except Exception:
            continue
        need = {'Algorithm','FunctionID','Seed','FinalError'}
        if not need.issubset(df.columns): continue
        if 'D' in df.columns and df['D'].notna().any():
            df = df[df['D'] == 50]
        df = df[df['Seed'].between(3001,3030)]
        if df.empty: continue
        for alg, g in df.groupby('Algorithm'):
            g = g.drop_duplicates(subset=['FunctionID','Seed'])
            if g['FunctionID'].nunique()==29 and g['Seed'].nunique()==30:
                found.setdefault(str(alg), []).append((p, g))
    return found

def series(g):
    return g.set_index(['FunctionID','Seed'])['FinalError'].sort_index()

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    found = scan()
    print('algorithms with a complete 29x30 series: %d' % len(found))
    cols, notes = {}, []
    for alg, lst in sorted(found.items()):
        lst.sort(key=lambda t: score(t[0]))
        base_p, base_g = lst[0]
        base = series(base_g)
        for p, g in lst[1:]:
            other = series(g)
            j = pd.concat([base.rename('a'), other.rename('b')], axis=1).dropna()
            if len(j) == 0: continue
            rel = ((j.a-j.b).abs()/np.maximum(1, j.a.abs())).max()
            if rel > 1e-9:
                notes.append('%s: kept %s ; differs from %s (max rel %.3g)' % (alg, base_p, p, rel))
        cols[alg] = base
    m = pd.DataFrame(cols)
    assert m.shape[0] == 870, m.shape
    m.to_csv(OUT/'master_3001.csv')
    print('master: %d runs x %d arms' % m.shape)
    for n in notes: print('  NOTE', n)
    json.dump(notes, open(OUT/'build_notes.json','w'), indent=1)

if __name__ == '__main__':
    main()
