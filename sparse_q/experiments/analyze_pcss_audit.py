#!/usr/bin/env python3
"""Analyze the passive PCSS P0 surrogate-prediction audit (40 runs, 100k FE)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat
from scipy.stats import spearmanr
ROOT=Path(__file__).resolve().parents[2]
FUNCS=[1,3,4,7,10,13,20,30]; SEEDS=list(range(3316,3321)); NPERM=1000
def latest(pat):
    ds=sorted((ROOT/'sparse_q'/'results').glob(pat))
    if not ds: raise SystemExit('missing results: '+pat)
    return ds[-1]
def main():
    p=latest('pcss_audit_*'); df=pd.read_csv(p/'runs.csv')
    rep=ROOT/'reports'/'pcss_p0_audit'; rep.mkdir(parents=True,exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed mismatch'
    assert len(df)==40 and (df.Status=='ok').all(),'incomplete audit'
    assert (df.Evaluations==100000).all(),'FE mismatch'
    rows=[]
    for _,r in df.iterrows():
        rid=int(r.RunID); f=int(r.FunctionID); s=int(r.Seed)
        mat=p/'runs'/f'run_{rid:05d}.mat'
        if not mat.exists(): continue
        m=loadmat(mat,struct_as_record=False,squeeze_me=True); S=m['record'].result.SGWO
        pred=np.asarray(getattr(S,'PcssPred',[]),float).ravel(); true=np.asarray(getattr(S,'PcssTrue',[]),float).ravel()
        if len(pred)<100 or len(pred)!=len(true): continue
        obs=spearmanr(pred,true).statistic
        if not np.isfinite(obs): continue
        rng=np.random.default_rng(20261022+s); place=np.empty(NPERM)
        for k in range(NPERM):
            s2=spearmanr(rng.permutation(pred),true).statistic
            place[k]=abs(float(s2)) if np.isfinite(s2) else 0.0
        p95=float(np.percentile(place,95)); pval=float((1+np.sum(place>=abs(obs)))/(NPERM+1))
        rows.append(dict(FunctionID=f,Seed=s,n=len(pred),spearman=float(obs),placebo95=p95,p=pval,significant=bool(abs(obs)>p95)))
    pr=pd.DataFrame(rows); pr.to_csv(rep/'per_run_prediction.csv',index=False)
    per=pr.groupby('FunctionID').agg(median_spearman=('spearman','median'),median_p=('p','median'),
                                     sig_seeds=('significant','sum'),runs=('spearman','size')).reindex(FUNCS)
    per.to_csv(rep/'per_function_prediction.csv')
    g1=int(((per.median_spearman>0.20)).sum())>=6
    g2=int(((per.sig_seeds>=3)).sum())>=6
    gate=bool(g1 and g2)
    summary=dict(results_dir=str(p),runs=len(df),valid_runs=len(pr),functions=FUNCS,seeds=SEEDS,
                 functions_median_gt020=int((per.median_spearman>0.20).sum()),
                 functions_sig3=int((per.sig_seeds>=3).sum()),
                 gate_median=bool(g1),gate_significance=bool(g2),gate_pass=gate)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    lines=['# PCSS P0 代理预测性审计结果','',f'- 结果目录：`{p}`','- 40 次运行，8 函数 × 5 新种子，100k FE，0 失败','- 审计模式与冻结 G1+E 逐位一致（合约测试）','',
           '## 预测性','',
           f'- 有效运行：**{len(pr)}/40**',
           f'- Spearman 中位数 >0.20 的函数：**{summary["functions_median_gt020"]}/8**',
           f'- 至少 3/5 种子显著高于安慰剂的函数：**{summary["functions_sig3"]}/8**','',
           '## 分函数结果','',
           '| F | median Spearman | median p | significant seeds |','|---:|---:|---:|---:|']
    for f,row in per.iterrows():
        lines.append(f"| {int(f)} | {row.median_spearman:.4f} | {row.median_p:.4f} | {int(row.sig_seeds)}/5 |")
    lines += ['','## P0 判定','',
              f"- 至少 6/8 函数 Spearman 中位数 >0.20：**{'通过' if g1 else '不通过'}**（{summary['functions_median_gt020']}/8）",
              f"- 至少 6/8 函数在 3/5 种子上显著：**{'通过' if g2 else '不通过'}**（{summary['functions_sig3']}/8）",'',
              f"**最终判定：{'PROMOTE_PCSS_TO_ACTIVE' if gate else 'STOP_PCSS_P0'}**"]
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)
if __name__=='__main__': main()
