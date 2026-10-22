#!/usr/bin/env python3
"""Analyze the passive PCSS surrogate-prediction audits.

Two statistics are reported:

1. pooled Spearman between kNN prediction and true fitness over the whole run
   (the statistic pre-registered for PCSS-P0a).  This statistic is confounded:
   both series decrease monotonically with the FE index, so a large pooled
   rho can appear even with no within-generation ranking skill.  We therefore
   also report the correlation of each series with the evaluation index.

2. within-generation mean Spearman (WMS, pre-registered for PCSS-P0b): for each
   macro-generation (K real evaluations), rank the K candidates by prediction
   and by truth inside that generation, take Spearman, and average over
   generations.  The matched placebo shuffles predictions within each
   generation.  WMS is the decision-relevant quantity for an active
   surrogate-guided screening rule.

Usage:
  python analyze_pcss_audit.py --batch p0a            # pooled gate (confounded, exploratory)
  python analyze_pcss_audit.py --batch p0b --dir <results_dir>
"""
from __future__ import annotations
import argparse, json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat
from scipy.stats import spearmanr, rankdata
ROOT = Path(__file__).resolve().parents[2]
FUNCS = [1, 3, 4, 7, 10, 13, 20, 30]
SEEDS = { "p0a": list(range(3316, 3321)), "p0b": list(range(3321, 3326)) }
NPERM = 1000
CHUNK = 50          # permutations evaluated per vectorised block
POOL_GATE = 0.20    # P0a: median pooled Spearman per function
WMS_GATE = 0.15     # P0b: median within-generation mean Spearman per function
SIG_SEEDS = 3       # >=3/5 seeds must beat the placebo 95th percentile
MIN_FUNCS = 6       # of 8 functions


def latest(pattern: str) -> Path:
    ds = sorted((ROOT / "sparse_q" / "results").glob(pattern))
    if not ds:
        raise SystemExit("missing results: " + pattern)
    return ds[-1]


def zranks(v: np.ndarray) -> np.ndarray:
    r = rankdata(v)
    r = r - r.mean()
    s = np.sqrt((r ** 2).mean())
    return r / s if s > 0 else r


def zranks_rows(M: np.ndarray) -> np.ndarray:
    """Rank-transform each row independently and standardise it per row."""
    R = np.apply_along_axis(rankdata, 1, M)
    R = R - R.mean(axis=1, keepdims=True)
    s = np.sqrt((R ** 2).mean(axis=1, keepdims=True))
    return R / np.where(s > 0, s, 1.0)


def net_rho(a: np.ndarray, b: np.ndarray) -> float:
    """Spearman of two 1-D samples (Pearson of their z-scored ranks)."""
    za, zb = zranks(a), zranks(b)
    return float(za @ zb / len(a))


def permutation_rho(zp: np.ndarray, zt: np.ndarray, rng) -> float:
    return float(zp[rng.permutation(len(zp))] @ zt / len(zp))


def within_generation(gen: np.ndarray, pred: np.ndarray, true: np.ndarray, K: int, rng):
    """Return (mean_rho, frac_pos, ng, placebos) using complete generations only."""
    keep = np.zeros(len(gen), bool)
    for g, cnt in zip(*np.unique(gen, return_counts=True)):
        if cnt == K:
            keep |= gen == g
    if keep.sum() < K * 100:
        return np.nan, np.nan, 0, np.array([])
    A = zranks_rows(pred[keep].reshape(-1, K))
    B = zranks_rows(true[keep].reshape(-1, K))
    ng = A.shape[0]
    rho_g = (A * B).sum(1) / K
    mean_rho = float(rho_g.mean())
    frac_pos = float((rho_g > 0).mean())
    nblock = int(np.ceil(NPERM / CHUNK))
    out = np.empty(nblock * CHUNK)
    for b in range(nblock):
        idx = rng.random((CHUNK, ng, K)).argsort(axis=2)
        Ap = np.take_along_axis(A[None, :, :], idx, axis=2)
        out[b * CHUNK:(b + 1) * CHUNK] = (Ap * B[None, :, :]).sum(2).mean(1) / K
    return mean_rho, frac_pos, ng, out[:NPERM]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--batch", choices=["p0a", "p0b"], default="p0a")
    ap.add_argument("--dir", default=None)
    args = ap.parse_args()
    seeds = SEEDS[args.batch]
    p = Path(args.dir) if args.dir else latest("pcss_audit_*" if args.batch == "p0a" else "pcss_p0b_*")
    outdir = ROOT / "reports" / ("pcss_p0_audit" if args.batch == "p0a" else "pcss_p0b_audit")
    outdir.mkdir(parents=True, exist_ok=True)
    df = pd.read_csv(p / "runs.csv")
    assert sorted(df.FunctionID.unique().tolist()) == FUNCS, "function mismatch"
    assert sorted(df.Seed.unique().tolist()) == seeds, "seed mismatch"
    assert len(df) == 8 * len(seeds) and (df.Status == "ok").all(), "incomplete audit"
    assert (df.Evaluations == 100000).all(), "FE mismatch"
    rows = []
    for _, r in df.iterrows():
        rid, f, s = int(r.RunID), int(r.FunctionID), int(r.Seed)
        mat = p / "runs" / f"run_{rid:05d}.mat"
        if not mat.exists():
            continue
        S = loadmat(mat, struct_as_record=False, squeeze_me=True)["record"].result.SGWO
        pred = np.asarray(getattr(S, "PcssPred", []), float).ravel()
        true = np.asarray(getattr(S, "PcssTrue", []), float).ravel()
        if len(pred) < 1000 or len(pred) != len(true):
            continue
        K = int(getattr(S, "K", 10))
        fe = np.asarray(getattr(S, "PcssFE", []), float).ravel()
        gex = np.asarray(getattr(S, "PcssGen", []), float).ravel()
        if len(fe) == len(pred) and len(fe) > 0:
            # The first pcssK+1 = 6 main-loop evaluations are unlogged (kNN
            # warm-up needs k+1 samples); with K = 10 the first logged sample is
            # evaluation 51+6 = 57, i.e. generation 1.  Verified bitwise on
            # pcss_xcheck_20261022_034257, where PcssGen was logged directly.
            warm = 6
            assert (int(fe.min()) - 1) % K == warm % K, "unexpected PcssFE offset"
            gen = ((fe - (fe.min() - warm)) // K).astype(int)
            if len(gex) == len(pred):
                assert np.array_equal(gen - gen.min(), gex - gex.min()), \
                    "PcssGen disagrees with the FE-based segmentation"
        else:
            # Fallback segmentation when PcssFE was not logged (PCSS-P0a runs):
            # the first complete logged generation starts at logged offset
            # (K - 6) % K = 4 and every generation has K logged samples.
            lead = (K - 6) % K
            gen = ((np.arange(len(pred)) - lead) // K).astype(int)
        rng = np.random.default_rng(20261022 + s)
        rho_pool = float(spearmanr(pred, true).statistic)
        zp, zt = zranks(pred), zranks(true)
        pool_place = np.array([permutation_rho(zp, zt, rng) for _ in range(NPERM)])
        pool95 = float(np.percentile(np.abs(pool_place), 95))
        rho_t_pred = float(spearmanr(pred, np.arange(len(pred))).statistic)
        rho_t_true = float(spearmanr(true, np.arange(len(pred))).statistic)
        wms, frac_pos, ng, place = within_generation(gen, pred, true, K, rng)
        wms95 = float(np.percentile(place, 95)) if place.size else np.nan
        wms_p = float((1 + np.sum(place >= wms)) / (NPERM + 1)) if place.size else np.nan
        rows.append(dict(FunctionID=f, Seed=s, n=len(pred), generations=ng,
                         rho_pool=rho_pool, rho_pool_placebo95=pool95,
                         rho_pred_vs_fe=rho_t_pred, rho_true_vs_fe=rho_t_true,
                         wms=wms, wms_placebo95=wms95, wms_p=wms_p,
                         frac_gen_positive=frac_pos,
                         pool_significant=bool(abs(rho_pool) > pool95),
                         wms_significant=bool(wms > wms95)))
    pr = pd.DataFrame(rows)
    pr.to_csv(outdir / "per_run_prediction.csv", index=False)
    per = pr.groupby("FunctionID").agg(
        median_spearman=("rho_pool", "median"), sig_seeds=("pool_significant", "sum"),
        median_wms=("wms", "median"), wms_sig_seeds=("wms_significant", "sum"),
        median_frac_gen_positive=("frac_gen_positive", "median"),
        runs=("rho_pool", "size")).reindex(FUNCS)
    per.to_csv(outdir / "per_function_prediction.csv")
    g_pool = bool((per.median_spearman > POOL_GATE).sum() >= MIN_FUNCS and (per.sig_seeds >= SIG_SEEDS).sum() >= MIN_FUNCS)
    g_wms = bool((per.median_wms > WMS_GATE).sum() >= MIN_FUNCS and (per.wms_sig_seeds >= SIG_SEEDS).sum() >= MIN_FUNCS)
    summary = dict(results_dir=str(p), batch=args.batch, runs=len(df), valid_runs=len(pr),
                   functions=FUNCS, seeds=seeds, nperm=NPERM,
                   functions_median_pool_gt020=int((per.median_spearman > POOL_GATE).sum()),
                   functions_sig3_pool=int((per.sig_seeds >= SIG_SEEDS).sum()),
                   functions_median_wms_gt015=int((per.median_wms > WMS_GATE).sum()),
                   functions_sig3_wms=int((per.wms_sig_seeds >= SIG_SEEDS).sum()),
                   gate_pooled=bool(g_pool), gate_within=bool(g_wms))
    summary["gate_pass"] = bool(g_pool if args.batch == "p0a" else g_wms)
    summary["verdict"] = ("PROMOTE_PCSS_TO_ACTIVE" if summary["gate_pass"] else "STOP_PCSS_P0")
    (outdir / "summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
    lines = [f"# PCSS {args.batch.upper()} 代理预测性审计结果", "",
             f"- 结果目录：`{p}`",
             f"- {len(df)} 次运行，8 函数 x {len(seeds)} 新种子，100k FE，0 失败",
             "- 审计模式与冻结 G1+E 逐位一致（合约测试）", "",
             "## 1. 汇总指标（预注册口径）", "",
             f"- 有效运行：**{len(pr)}/{len(df)}**",
             f"- 汇总 Spearman 中位数 >{POOL_GATE} 的函数：**{summary['functions_median_pool_gt020']}/8**"
             f"（安慰剂显著种子 >=3 的函数：{summary['functions_sig3_pool']}/8）",
             f"- 同代平均 Spearman (WMS) 中位数 >{WMS_GATE} 的函数：**{summary['functions_median_wms_gt015']}/8**"
             f"（安慰剂显著种子 >=3 的函数：{summary['functions_sig3_wms']}/8）", "",
             "**注意**：汇总 Spearman 受“预测值与真实值都随 FE 单调下降”的共同趋势影响，"
             "本报告同时给出两个序列各自与 FE 的相关系数，用于识别这一混淆。"
             "同代 WMS 不受该趋势影响，是主动筛选机制真正需要的统计量。", "",
             "## 2. 分函数结果", "",
             "| F | pooled rho | rho(pred,FE) | rho(true,FE) | WMS | WMS 安慰剂显著种子 | 同代正相关比例 |",
             "|---:|---:|---:|---:|---:|---:|---:|"]
    for f, row in per.iterrows():
        rr = pr[pr.FunctionID == f]
        lines.append(f"| {int(f)} | {row.median_spearman:.4f} | {rr.rho_pred_vs_fe.median():.3f} | "
                     f"{rr.rho_true_vs_fe.median():.3f} | {row.median_wms:.4f} | "
                     f"{int(row.wms_sig_seeds)}/{int(row.runs)} | {row.median_frac_gen_positive:.3f} |")
    lines += ["", "## 3. 判定", "",
              f"- 预注册口径（{'汇总 Spearman' if args.batch == 'p0a' else '同代 WMS'}）："
              f"**{'通过' if summary['gate_pass'] else '不通过'}**",
              f"- 参考口径（{'同代 WMS' if args.batch == 'p0a' else '汇总 Spearman'}）："
              f"**{'通过' if (g_wms if args.batch == 'p0a' else g_pool) else '不通过'}**", "",
              f"**最终判定：{summary['verdict']}**"]
    (outdir / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    print("[analysis] wrote", outdir)


if __name__ == "__main__":
    main()
