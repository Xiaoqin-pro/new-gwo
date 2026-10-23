#!/usr/bin/env python3
"""CR (crowding replacement) dev screen vs a REUSED frozen arm (docs/84)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 11, 13, 14, 16, 18, 20, 22, 24, 26, 30]
SEEDS = list(range(3071, 3081))
BASE_BATCH = 'steer_confirm2_20261022_063141'
BASE_ARM = 'B-Steer-Rand'
NEW = {'B': 'B-Crowd', 'C': 'C-RandSlot'}


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def main():
    p = latest('cr_dev_*')
    df = pd.read_csv(p / 'runs.csv')
    base = pd.read_csv(ROOT / 'sparse_q' / 'results' / BASE_BATCH / 'runs.csv')
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert set(df.Algorithm.unique()) == set(NEW.values()) and len(df) == 2 * 15 * 10
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all()
    rep = ROOT / 'reports' / 'cr_dev_analysis'; rep.mkdir(parents=True, exist_ok=True)

    def paired(a_df, a_arm, b_df, b_arm):
        a = a_df[a_df.Algorithm == a_arm][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'ea'})
        b = b_df[b_df.Algorithm == b_arm][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'eb'})
        j = a.merge(b, on=['FunctionID', 'Seed'])
        j['r'] = j.ea / j.eb
        j['dl'] = np.log10(np.maximum(j.ea, 1e-12)) - np.log10(np.maximum(j.eb, 1e-12))
        pf = j.groupby('FunctionID').r.median(); r = pf.to_numpy(float)
        d = j.groupby('FunctionID').dl.median().to_numpy(float)
        try:
            pv = float(wilcoxon(d).pvalue)
        except ValueError:
            pv = float('nan')
        rng = np.random.default_rng(20261023)
        boot = np.array([np.median(rng.choice(r, len(r), replace=True)) for _ in range(4000)])
        return dict(median=float(np.median(r)), wins=int((r < 1).sum()), cats=int((r > 1.20).sum()),
                    max_ratio=float(r.max()), worst_f=int(pf.index[int(np.argmax(r))]), wilcoxon_p=pv,
                    ci95=[float(np.percentile(boot, 2.5)), float(np.percentile(boot, 97.5))], per=pf)

    S = {'B/A': paired(df, NEW['B'], base, BASE_ARM), 'C/A': paired(df, NEW['C'], base, BASE_ARM),
         'B/C': paired(df, NEW['B'], df, NEW['C'])}
    sec = df.groupby('Algorithm').Seconds.mean(); base_rt = base[base.Algorithm == BASE_ARM].Seconds.mean()
    rt = {k: float(sec[v] / base_rt) for k, v in NEW.items()}
    gB = bool(S['B/A']['median'] <= 0.98 and S['B/A']['wins'] >= 11 and S['B/A']['cats'] == 0 and rt['B'] <= 1.15)
    gBC = bool(S['B/C']['median'] <= 0.98 and S['B/C']['wins'] >= 11)
    verdict = 'PROMOTE_CR' if (gB and gBC) else ('CR_UNATTRIBUTED' if gB else 'STOP_CR_DEV')
    out = dict(results_dir=str(p), base_batch=BASE_BATCH, base_arm=BASE_ARM,
               **{k.replace('/', '_'): {kk: vv for kk, vv in v.items() if kk != 'per'} for k, v in S.items()},
               runtime=rt, gate_B=gB, gate_BC=gBC, verdict=verdict)
    (rep / 'summary.json').write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding='utf-8')
    pd.DataFrame({k: v['per'] for k, v in S.items()}).to_csv(rep / 'per_function_ratio.csv')
    lines = ['# CR（拥挤替换）dev 结果（2 新臂 × 15 函数 × 10 种子 3071–3080；冻结臂复用 `steer_confirm2`）', '',
             f'- 结果目录：`{p}`（{len(df)} 次运行，0 失败）',
             f'- 冻结臂（`worst`，逐位一致）：复用 `{BASE_BATCH}` 的 `{BASE_ARM}`，同种子配对', '',
             '| 对比 | 中位比 | 胜/15 | >1.20 | 最大 | 最差函数 | Wilcoxon p | 95% CI | 时间比 |',
             '|---|---:|---:|---:|---:|---:|---:|---:|---:|']
    for lab, key in [('B 拥挤替换 / A', 'B'), ('C 随机槽位 / A', 'C')]:
        s = S['B/A'] if key == 'B' else S['C/A']
        lines.append(f"| {lab} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max_ratio']:.3f} | F{s['worst_f']} | "
                     f"{s['wilcoxon_p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] | {rt[key]:.3f} |")
    s = S['B/C']
    lines.append(f"| B 拥挤 / C 随机（归因） | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max_ratio']:.3f} | F{s['worst_f']} | "
                 f"{s['wilcoxon_p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] | — |")
    lines += ['', f'- 门槛 B/A **{"通过" if gB else "不通过"}**；归因 B/C **{"通过" if gBC else "不通过"}**',
              f'**判定：{verdict}**', '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
