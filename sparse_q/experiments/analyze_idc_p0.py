#!/usr/bin/env python3
"""Identity-Credit P0 (docs/77): defect materiality + actuation of each fix."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 13, 20, 30]
SEEDS = list(range(3549, 3554))
ARMS = {'A': 'A-Audit', 'B': 'B-ID+Reset', 'C': 'C-IDonly', 'D': 'D-ResetOnly'}


def latest(pat):
    ds = sorted((ROOT / 'sparse_q' / 'results').glob(pat))
    if not ds:
        raise SystemExit('missing results: ' + pat)
    return ds[-1]


def main():
    p = latest('idc_p0_*')
    df = pd.read_csv(p / 'runs.csv')
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS and sorted(df.Seed.unique().tolist()) == SEEDS
    assert set(df.Algorithm.unique()) == set(ARMS.values()) and len(df) == 4 * 8 * 5
    assert (df.Status == 'ok').all() and (df.Evaluations == 100000).all()
    rep = ROOT / 'reports' / 'idc_p0_audit'; rep.mkdir(parents=True, exist_ok=True)
    aud = df[df.Algorithm == ARMS['A']]
    per = aud.groupby('FunctionID').agg(wrong_rate=('IdcWrongRate', 'median'),
                                        stale_rate=('IdcStaleRate', 'median'),
                                        leak_rate=('IdcLeakRate', 'median'),
                                        leak_mass_ratio=('IdcLeakMassRatio', 'median'),
                                        cred=('IdcCredTotal', 'median'),
                                        refresh=('IdcRefresh', 'median')).reindex(FUNCS)
    g1 = int((per.wrong_rate >= 0.01).sum()); g2 = int((per.stale_rate >= 0.01).sum())
    g3 = int((per.leak_rate >= 0.05).sum()); g4 = int((per.leak_mass_ratio >= 0.05).sum())
    # actuation: fraction of (function, seed) cells whose BestCost differs from the audit arm
    piv = df.pivot_table(index=['FunctionID', 'Seed'], columns='Algorithm', values='BestCost')
    act = {}
    for k in ['B', 'C', 'D']:
        d = ~np.isclose(piv[ARMS[k]], piv[ARMS['A']], rtol=0, atol=0)
        act[k] = float(d.mean())
    gate_act = bool(act['B'] >= 0.5 and act['C'] >= 0.5 and act['D'] >= 0.10)
    promote = bool(g1 >= 5 and g2 >= 5 and g3 >= 5 and g4 >= 5 and gate_act)  # >=5/8 functions material
    verdict = 'PROMOTE_IDC_TO_P1' if promote else 'STOP_IDC_P0'
    per.to_csv(rep / 'per_function_audit.csv')
    summary = dict(results_dir=str(p), runs=len(df), functions=FUNCS, seeds=SEEDS,
                   gate_wrong=g1, gate_stale=g2, gate_leak=g3, gate_leakmass=g4, actuation=act,
                   gate_actuation=gate_act, verdict=verdict,
                   medians={c: float(aud[c].median()) for c in
                            ['IdcCredTotal', 'IdcWrongRate', 'IdcStaleRate', 'IdcRefresh', 'IdcLeakRate', 'IdcLeakMassRatio']})
    (rep / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# Identity-Credit P0 结果（当前冻结终版，8 函数 × 5 新种子 3549–3553 × 100k FE，4 臂）', '',
             f'- 结果目录：`{p}`（{len(df)} 次运行，0 失败）',
             '- A=审计（行为与冻结终版逐位一致）；B=ID+重置；C=仅 ID 路由；D=仅刷新重置', '',
             '## 缺陷 material 性（审计臂，逐函数中位）', '',
             '| F | 信用事件 | 路由错配率 | 失效反馈率 | 刷新次数 | 泄漏事件率 | 泄漏/总增量 |', '|---:|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        r = per.loc[f]
        lines.append(f"| {f} | {r.cred:.0f} | {r.wrong_rate:.4f} | {r.stale_rate:.4f} | {r.refresh:.0f} | "
                     f"{r.leak_rate:.3f} | {r.leak_mass_ratio:.3f} |")
    lines += ['', f"- 门槛1 路由错配 ≥1%：**{g1}/8**；门槛2 失效反馈 ≥1%：**{g2}/8**；"
                  f"门槛3 泄漏事件率 ≥5%：**{g3}/8**；门槛4 泄漏占比 ≥5%：**{g4}/8**",
              '', '## 触发检查（与审计臂 BestCost 不一致的单元比例）', '',
              f"- B（ID+重置）：**{act['B']:.2f}**（门槛 ≥0.50）",
              f"- C（仅 ID）：**{act['C']:.2f}**（门槛 ≥0.50）",
              f"- D（仅重置）：**{act['D']:.2f}**（门槛 ≥0.10）", '',
              f'**判定：{verdict}**', '']
    (rep / 'report.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
