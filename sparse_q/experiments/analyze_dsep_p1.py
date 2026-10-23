#!/usr/bin/env python3
"""DSEP P1: 15-function x 10-seed development screen."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1,3,4,7,10,11,13,14,16,18,20,22,24,26,30]
SEEDS = list(range(3624, 3634))
A_ARM, B_ARM, C_ARM = 'A-DSEP-Box', 'B-DSEP-Pop', 'C-DSEP-Half'

def main():
    ds = sorted((ROOT / 'sparse_q' / 'results').glob('dsep_p1_*'))
    if not ds: raise SystemExit('missing dsep_p1_*')
    p = ds[-1]; df = pd.read_csv(p / 'runs.csv')
    assert len(df) == 450 and set(df.Algorithm.unique()) == {A_ARM, B_ARM, C_ARM}
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all()
    rep = ROOT / 'reports' / 'dsep_p1_analysis'; rep.mkdir(parents=True, exist_ok=True)
    def stats(a, b):
        x = df[df.Algorithm == a][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'})
        y = df[df.Algorithm == b][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'})
        j = x.merge(y, on=['FunctionID','Seed']); j['r'] = j.ea / j.eb
        j['dl'] = np.log10(np.maximum(j.ea,1e-12)) - np.log10(np.maximum(j.eb,1e-12))
        pf = j.groupby('FunctionID').r.median(); r = pf.to_numpy(float)
        d = j.groupby('FunctionID').dl.median().to_numpy(float)
        try: pv = float(wilcoxon(d).pvalue)
        except ValueError: pv = float('nan')
        rng = np.random.default_rng(20261023)
        boot = np.array([np.median(rng.choice(r,len(r),replace=True)) for _ in range(5000)])
        return dict(median=float(np.median(r)), wins=int((r<1).sum()), cats=int((r>1.2).sum()),
                    max_ratio=float(r.max()), worst_f=int(pf.index[int(np.argmax(r))]),
                    wilcoxon_p=pv, ci95=[float(np.percentile(boot,2.5)),float(np.percentile(boot,97.5))], per=pf)
    S = {'B/A':stats(B_ARM,A_ARM), 'C/A':stats(C_ARM,A_ARM), 'B/C':stats(B_ARM,C_ARM)}
    sec = df.groupby('Algorithm').Seconds.mean()
    rtB = float(sec[B_ARM]/sec[A_ARM]); rtC = float(sec[C_ARM]/sec[A_ARM])
    gBA = bool(S['B/A']['median'] <= .98 and S['B/A']['wins'] >= 11 and S['B/A']['cats'] == 0 and rtB <= 1.15)
    gBC = bool(S['B/C']['median'] <= .98 and S['B/C']['wins'] >= 11)
    verdict = 'PROMOTE_DSEP_TO_CONFIRM' if (gBA and gBC) else ('DSEP_UNATTRIBUTED' if gBA else 'STOP_DSEP_P1')
    out = dict(results_dir=str(p), **{k.replace('/','_'):{kk:vv for kk,vv in v.items() if kk!='per'} for k,v in S.items()},
               runtime=dict(B=rtB,C=rtC), gate_BA=gBA, gate_BC=gBC, verdict=verdict)
    (rep/'summary.json').write_text(json.dumps(out,indent=2,ensure_ascii=False),encoding='utf-8')
    pd.DataFrame({k:v['per'] for k,v in S.items()}).to_csv(rep/'per_function_ratio.csv')
    lines = ['# DSEP P1（15 函数 × 10 种子 3624–3633，100k FE）','',
             f'- 结果目录：`{p}`（450 次运行，0 失败）','',
             '| 对比 | 中位比 | 胜/15 | >1.20 | 最大 | 最差函数 | p | 95% CI | 时间比 |',
             '|---|---:|---:|---:|---:|---:|---:|---:|---:|']
    for lab,key in [('B 自适应 / A','B'),('C 常数半尺 / A','C')]:
        s=S['B/A'] if key=='B' else S['C/A']; rt=rtB if key=='B' else rtC
        lines.append(f"| {lab} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max_ratio']:.3f} | F{s['worst_f']} | {s['wilcoxon_p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] | {rt:.3f} |")
    s=S['B/C']; lines.append(f"| **B 自适应 / C 常数半尺（归因）** | **{s['median']:.4f}** | **{s['wins']}** | {s['cats']} | {s['max_ratio']:.3f} | F{s['worst_f']} | {s['wilcoxon_p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] | — |")
    lines += ['', f'- 主假设 B/A **{"通过" if gBA else "不通过"}**；归因 B/C **{"通过" if gBC else "不通过"}**', f'**判定：{verdict}**','']
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines))
if __name__=='__main__': main()
