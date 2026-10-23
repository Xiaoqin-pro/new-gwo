#!/usr/bin/env python3
"""Uniform tail-risk synthesis over every closed mechanism line that has result files on disk.

For each (line, arm) it computes, against that line's own frozen/reference arm,
  median per-function ratio, wins, #functions with ratio > 1.20 (cats), max ratio, runtime ratio.
Baselines: either an in-batch frozen arm, or the shared 29x30 A2-G1E block (ablcore_20261017_062209,
seeds 3071-3100) when the mechanism batch reused it.
"""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / 'sparse_q' / 'results'
ABL = 'ablcore_20261017_062209'
EST = 'esteer_p1_20261022_211024'
A2ARM = 'A2-G1E'
A0ARM = 'A0-GWOonly'

LINES = [
    # (line label, batch, arm, baseline mode, change class)
    ('E: archive slots vs GWO-only pool', ABL, A2ARM, ('batch', ABL, A0ARM), 'ADD'),
    ('E: single-centre vs multi-region (doc)', 'freshv2_20261017_000252', 'V1-frozen', ('doc',), 'BIAS'),
    ('STEER: random direction', 'steer_confirm2_20261022_063141', 'B-Steer-Rand', ('batch', ABL, A2ARM), 'ADD'),
    ('STEER: success direction', 'steer_confirm2_20261022_063141', 'C-Steer-Dir', ('batch', ABL, A2ARM), 'ADD'),
    ('STJ: stagnation-gated steer', 'stj_confirm_20261022_083504', 'C-STJ', ('batch', ABL, A2ARM), 'GATE'),
    ('TSD-R: trajectory recovery', 'tsdr_confirm_20261021_232608', 'C-TSDR', ('batch', ABL, A2ARM), 'REPLACE'),
    ('RGI: rank-gated restart', 'rgi_confirm_20261022_003633', 'B-RGI', ('batch', ABL, A2ARM), 'REPLACE'),
    ('RGI: stall restart (no rank gate)', 'rgi_confirm_20261022_003633', 'C-StallRestart', ('batch', ABL, A2ARM), 'REPLACE'),
    ('VGA: greedy parent acceptance', 'tsd_p1_20261021_092454', 'B-VGA', ('batch', 'tsd_p1_20261021_092454', 'A-Frozen'), 'GATE'),
    ('TSD-base: state decoupling', 'tsd_p1_20261021_092454', 'C-TSDbase', ('batch', 'tsd_p1_20261021_092454', 'A-Frozen'), 'REPLACE'),
    ('TSD-full: E cursor-only admission', 'tsd_p1_20261021_092454', 'D-TSDfull', ('batch', 'tsd_p1_20261021_092454', 'A-Frozen'), 'REPLACE'),
    ('VGA (P1, G2 off)', 'vga_p1_20261021_075401', 'B-VGA-G2off', ('batch', 'vga_p1_20261021_075401', 'A-Std-G2off'), 'GATE'),
    ('DLH: neighbourhood fillers', 'dlh_p1_20261022_105805', 'B-DLH', ('batch', 'dlh_p1_20261022_105805', 'A-Frozen-Final'), 'REPLACE'),
    ('DLH control: global difference', 'dlh_p1_20261022_105805', 'C-GlobalDiff', ('batch', 'dlh_p1_20261022_105805', 'A-Frozen-Final'), 'REPLACE'),
    ('SALS: post-selection LHS redraw', 'sals_p1_20261022_203039', 'C-SALS', ('batch', 'sals_p1_20261022_203039', 'A-Frozen-Final'), 'REPLACE'),
    ('SALS control: post-selection IID', 'sals_p1_20261022_203039', 'B-PostIID', ('batch', 'sals_p1_20261022_203039', 'A-Frozen-Final'), 'REPLACE'),
    ('LLT: local leader topology', 'llt_p1_20261022_043703', 'B-LLT-Ring', ('batch', 'llt_p1_20261022_043703', 'A-FrozenG1E'), 'REPLACE'),
    ('PCSS: surrogate-guided screening', 'pcss_p1_20261022_035251', 'B-PCSS-Active', ('batch', 'pcss_p1_20261022_035251', 'A-FrozenG1E'), 'GATE'),
    ('REF: diversity filler', 'ref_p1_20261022_023258', 'B-REF', ('batch', 'ref_p1_20261022_023258', 'A-FrozenFill'), 'REPLACE'),
    ('NEL: neighbourhood exemplar filler', 'nel_p1_20261022_021413', 'B-NEL', ('batch', 'nel_p1_20261022_021413', 'A-FrozenFill'), 'REPLACE'),
    ('RED: duplicate rejection', 'red_dev_20261022_054609', 'B-RED-002', ('batch', 'red_dev_20261022_054609', 'A-RED-Audit'), 'GATE'),
    ('ECPS: evaluation-credit screening', 'ecps_p1_20261021_070443', 'B-ECPS', ('batch', 'ecps_p1_20261021_070443', 'A-TwoRoute'), 'GATE'),
    ('nE sweep: NE19 composition', 'nesweep_steer_20261022_095524', 'NE19-STEER', ('batch', 'nesweep_steer_20261022_095524', 'NE38-STEER'), 'COMPOSE'),
    ('nE sweep: NE00 composition', 'nesweep_steer_20261022_095524', 'NE00-STEER', ('batch', 'nesweep_steer_20261022_095524', 'NE38-STEER'), 'COMPOSE'),
    ('E-STEER on the final algorithm (C/A)', EST, 'C-G1on-Eon', ('batch', EST, 'A-G1on-Eoff'), 'ADD'),
    ('E-STEER alone (B/D)', EST, 'B-G1off-Eon', ('batch', EST, 'D-G1off-Eoff'), 'ADD'),
    ('G1-STEER alone, fresh 15x10 block (A/D)', EST, 'A-G1on-Eoff', ('batch', EST, 'D-G1off-Eoff'), 'ADD'),
]


def load(batch):
    return pd.read_csv(RES / batch / 'runs.csv')


def paired_ratios(df, arm, bdf, base_arm):
    """Repo-standard estimator: for every function take the median over seeds of the PAIRED
    per-seed ratio err_mech/err_base (matcher: FunctionID + Seed), then analyse across functions."""
    m = df[df.Algorithm == arm][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'e1'})
    b = bdf[bdf.Algorithm == base_arm][['FunctionID', 'Seed', 'FinalError']].rename(columns={'FinalError': 'e0'})
    j = m.merge(b, on=['FunctionID', 'Seed'], how='inner')
    j['r'] = j.e1 / j.e0
    return j.groupby('FunctionID').r.median()


def compare(line, batch, arm, base_spec, cls):
    df = load(batch)
    if base_spec[0] == 'batch':
        bdf = load(base_spec[1]); r_ser = paired_ratios(df, arm, bdf, base_spec[2])
    else:
        return None
    if not len(r_ser):
        return None
    common = sorted(r_ser.index.tolist())
    r = r_ser.to_numpy(float)
    # runtime is only meaningful for same-batch baselines (cross-batch timing is not comparable;
    # the earlier cross-batch +24.4% STEER figure was retracted in reports/runtime_optimization.md)
    if base_spec[0] == 'batch' and base_spec[1] == batch:
        rt_m = df[df.Algorithm == arm].Seconds.mean()
        rt_b = df[df.Algorithm == base_spec[2]].Seconds.mean()
        rt = float(rt_m / rt_b)
    else:
        rt = float('nan')
    return dict(line=line, batch=batch, arm=arm, cls=cls, n_func=len(common),
                median=float(np.median(r)), wins=int((r < 1).sum()), cats=int((r > 1.20).sum()),
                max_ratio=float(r.max()), worst_f=int(common[int(np.argmax(r))]),
                best_f=int(common[int(np.argmin(r))]), runtime=rt)


def main():
    rows = [c for c in (compare(*L) for L in LINES) if c]
    t = pd.DataFrame(rows)
    out = ROOT / 'reports' / 'mechanism_safety_synthesis.csv'
    t.to_csv(out, index=False)
    td = t[t.cls != 'doc']
    safe = td[td.cats == 0]
    unsafe = td[td.cats > 0]
    lines = ['# 机制安全性综合（统一重算）', '',
             '对磁盘上每个已关闭机制线的机制臂，按各自批次的冻结/参照臂统一重算函数级中位比、胜场、',
             '**>1.20 灾难函数数（cats）**、最大比值与运行时间比。基线为批内冻结臂，或该线复用的共享 29×30 `A2-G1E` 块。',
             '', f'- 纳入臂：**{len(td)}** 条（{td.batch.nunique()} 个批次）', '',
             '| 机制（臂） | 类别 | 函数 | 中位比 | 胜 | **>1.20** | 最大 | 最差函数 |',
             '|---|---|---:|---:|---:|---:|---:|---:|']
    for _, r in td.sort_values(['cls', 'median']).iterrows():
        lines.append(f"| {r.line} | {r.cls} | {r.n_func} | {r['median']:.4f} | {r.wins} | "
                     f"{'**'+str(r.cats)+'**' if r.cats else '0'} | {r.max_ratio:.3f} | F{r.worst_f} |")
    zerocat = td[td.cats == 0].line.tolist()
    lines += ['', '## 统一重算得到的模式', '',
              f"- 统一采用**配对比值中位**口径（每函数先取同种子配对比值的中位，再跨函数取中位），与本仓库",
              f"  SALS / DLH / STEER 确认的预注册主口径一致；个别线报告里另有'比值比'口径，数值会小幅不同",
              f"  （例：STEER B/A2 配对 **0.9663**、比值比 0.9769；STJ 配对 0.9977、比值比 1.0055）；",
              f"- 纳入 {len(td)} 条机制臂，**零灾难函数（cats=0）** 的只有 {len(zerocat)} 条：{', '.join(zerocat)}；",
              "- 其中**通过各自预注册 P1 主门槛的只有 E 与 STEER（随机方向）**；STJ 与 NEL 虽然零灾难，",
              "  但分别在胜场/归因（STJ/A2 17 胜但 STJ/B 1.0230、7/22）与运行时间（5.28×）上失败 →",
              "  **安全是必要不充分条件**；",
              f"- 出现 ≥1 个 >1.20 的臂占多数（{len(unsafe)}/{len(td)}），最极端的是无门控停滞重启 "
              f"（C-StallRestart：中位 1.438、**21 个 >1.20**、最大 168×）与 NE00（6 个 >1.20、最大 5.50×）；",
              "- **中位比好看 ≠ 可采纳**：LLT 0.794 但 2 个 >1.20；ECPS 0.890 但 4 个 >1.20；"
              "NEL 0.928（6/8 胜、0 灾难）但 5.28× 时间；STEER 的成功方向变体 0.954 但 2 个 >1.20"
              "（只有随机方向变体零灾难）；SALS 0.9965 但 F14 1.234；",
              "- 运行时间只在同批内可比：REF 1.01、DLH 1.23、PCSS 1.45、NEL **5.28**（跨批次基线的比值一律不参与，",
              "  以免重复已被撤回的跨批次 +24.4% 口径）。",
              '',
              '## 设计规则（待前瞻检验的假设，不是已证定律）', '',
              '> **合规改动 = 只增不减 + 零均值有界**：机制只能给候选池/评价名额**增加**新提案，',
              '> 或沿**零均值、幅度由现有步长界定**的方向延伸已有候选；不得削减、门控或以历史统计量',
              '> **重写/重加权**领导驱动流（G1）的几何。',
              '',
              '证据：两个通过确认的机制 E（+38 个多区域档案槽位）与 STEER-随机方向（等步长零均值延伸）都属于合规类，',
              '且都是零灾难；反过来，GATE（门控：STJ/RED/VGA/PCSS）、REPLACE（替换：DLH/NEL/REF/TSD/SALS/LLT/RGI）、',
              'COMPOSE（配比：nE 扫描）三类中共 22 条臂，只有 STJ 与 NEL 零灾难，且两者都在其它门槛失败。',
              '也就是说：**合规类目前 2/2 安全且 2/2 通过；不合规类无一通过，且多数带尾部灾难。**',
              '',
              '**前瞻检验结果（E-STEER 2×2 因子，`docs/70`，600 次运行）**：',
              '- 主比较 C/A（E-STEER 叠加在冻结终版上）中位比 1.0021、7/15 胜、**0 个 >1.20**（最大 1.191）→ 规则的安全预测成立；',
              '- 但次级臂 B/D（E-STEER 单独 vs 冻结 G1+E）中位比 0.9539、11/15 胜、**2 个 >1.20（F13 1.809）**→',
              '  同一合规算子在没有 G1-STEER 时仍出现尾部灾难；',
              '- 因此"合规 ⇒ 安全"在本轮是**部分支持、部分否证**（主比较安全、次级比较不安全）。诚实结论：',
              '  合规性是"只增不减"类改动的**弱安全提示**，不是充分条件；15 函数 × 10 种子的 dev 尺度上 cats 本身也不稳定',
              '  （参照：确认尺度上 STEER-随机方向 0 个 >1.20，而几乎同族的成功方向变体有 2 个）。',
              '- 该批次的有效性检查也未通过：A/D（G1-STEER 单独 vs 冻结 G1+E）中位比 1.0745、4/15 胜',
              '  → 已确认的 STEER 效应（29×30 上 0.9663、20/29 胜）在这个 15×10 块上**未能复现**，',
              '  说明 dev 块对 ~3% 量级效应的检验力不足（详细见结论 §三十一）。',
              '',
              '## 限制（必须写进论文）', '',
              '- 分类是**事后归纳**（post-hoc），各线协议不完全一致（8 函数 × 30k/100k dev、15 函数 × 100k、29 函数 × 100k），',
              '  部分线的基线跨批次复用（同种子配对）；只能作为"设计边界"叙事与未来预注册门槛的依据，不能作为统计推断；',
              '- 两种比值口径会给出不同的小数（配对比值中位 vs 比值比），本表已统一为前者并注明；',
              '- Tier B（本工作区无 runs.csv、仅在各自分支有报告）：SSSA、CD-VACG、AMC、CALA、ENAC 的数字',
              '  见 `reports/mechanism_exploration_conclusion.md` §四 与各自 nightly 报告：SSSA 1.0306（4-4、2 个 >1.20，',
              '  Swap 对照在 F7 反超 1.633）、CD-VACG 1.0656（2-6、F13 22.5×）、AMC 1.2178（1/15 胜、9 个 >1.20）、',
              '  CALA 0.9557（9/15、3 个 >1.20）、ENAC B/A 1.0155（6/15、F20 1.52）；',
              '- E 行的基线是 A0（无 E 的 GWO 候选池），其"运行时间比"与其它行不可比。']

    (ROOT / 'reports' / 'mechanism_safety_synthesis.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(t.to_string(index=False))
    print()
    print('\n'.join(lines[-16:]))


if __name__ == '__main__':
    main()
