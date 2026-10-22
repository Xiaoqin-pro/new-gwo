#!/usr/bin/env python3
"""Analyze the passive VSSM P0 audit (40 runs, 100k FE)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat
from scipy.stats import spearmanr

ROOT=Path(__file__).resolve().parents[2]
FUNCS=[1,3,4,7,10,13,20,30]
SEEDS=list(range(3276,3281))
NPERM=1000

def latest(pat):
    ds=sorted((ROOT/'sparse_q'/'results').glob(pat))
    if not ds: raise SystemExit('missing results: '+pat)
    return ds[-1]
def wmean(v,w):
    v=np.asarray(v,float); w=np.asarray(w,float)
    if w.sum()<=0: return float('nan')
    return float(np.sum(v*w)/np.sum(w))

def run_spearman(trace, seed):
    tr=np.asarray(trace,float)
    if tr.ndim!=2 or tr.shape[0]<3: return None
    x=[]; y=[]
    for t in range(tr.shape[0]-1):
        if tr[t,7]==1 and np.isfinite(tr[t,1]) and np.isfinite(tr[t+1,5]):
            x.append(tr[t,1]); y.append(tr[t+1,5])
    if len(x)<20: return None
    x=np.asarray(x); y=np.asarray(y)
    if np.std(x)==0 or np.std(y)==0: return None
    obs=spearmanr(x,y).statistic
    if not np.isfinite(obs): return None
    obs=abs(float(obs))
    rng=np.random.default_rng(20261021+int(seed))
    place=np.empty(NPERM)
    for k in range(NPERM):
        xp=rng.permutation(x)
        s=spearmanr(xp,y).statistic
        place[k]=abs(float(s)) if np.isfinite(s) else 0.0
    p95=float(np.percentile(place,95))
    pval=float((1+np.sum(place>=obs))/(NPERM+1))
    return dict(n_pairs=len(x),obs=obs,placebo95=p95,p=pval,rho_std=float(np.std(x)))

def main():
    p=latest('vssm_audit_*'); df=pd.read_csv(p/'runs.csv')
    rep=ROOT/'reports'/'vssm_p0_audit'; rep.mkdir(parents=True,exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed mismatch'
    assert len(df)==40 and (df.Status=='ok').all(),'incomplete audit'
    assert (df.Evaluations==100000).all(),'FE mismatch'
    per=df.groupby('FunctionID')[['VssmG1Eval','VssmSuccess','VssmEligibleUpdates','VssmFallbackUpdates']].sum()
    per['success_rate']=per.VssmSuccess/per.VssmG1Eval.replace(0,np.nan)
    per['dev10_rate']=[wmean(g.VssmRhoDev10Rate,g.VssmEligibleUpdates) for _,g in df.groupby('FunctionID')]
    per['boundary_rate']=[wmean(g.VssmBoundaryRate,g.VssmEligibleUpdates) for _,g in df.groupby('FunctionID')]
    per['median_success_r']=df.groupby('FunctionID').VssmMedianSuccessR.mean()
    per['iqr_success_r']=df.groupby('FunctionID').VssmIQRSuccessR.mean()
    # prediction per run
    rows=[]
    for _,r in df.iterrows():
        f=int(r.FunctionID); s=int(r.Seed); rid=int(r.RunID)
        mat=p/'runs'/f'run_{rid:05d}.mat'
        if not mat.exists(): continue
        m=loadmat(mat,struct_as_record=False,squeeze_me=True)
        S=m['record'].result.SGWO
        st=run_spearman(getattr(S,'VssmTrace',None),s)
        if st is not None:
            st.update(FunctionID=f,Seed=s,RunID=rid); rows.append(st)
    pr=pd.DataFrame(rows)
    if len(pr):
        pr.to_csv(rep/'per_run_prediction.csv',index=False)
        pg=pr.groupby('FunctionID').agg(valid_seeds=('obs','size'),mean_obs=('obs','mean'),
                                        mean_placebo95=('placebo95','mean'),median_p=('p','median'),
                                        mean_rho_std=('rho_std','mean'))
        pg['pred_ok']=(pg.valid_seeds>=3)&(pg.mean_obs>pg.mean_placebo95)&(pg.mean_obs>0.10)
    else:
        pg=pd.DataFrame()
    # ensure all functions have rows in tables
    per=per.reindex(FUNCS); pg=pg.reindex(FUNCS)
    enough=(per.VssmSuccess>=100)&(per.VssmEligibleUpdates>=20)
    enough_count=int(enough.sum())
    dev10=wmean(df.VssmRhoDev10Rate,df.VssmEligibleUpdates)
    boundary=wmean(df.VssmBoundaryRate,df.VssmEligibleUpdates)
    pred_count=int(pg.pred_ok.fillna(False).sum()) if len(pg) else 0
    g1=enough_count>=6
    g2=np.isfinite(dev10) and dev10>=0.20
    g3=np.isfinite(boundary) and boundary<=0.25
    g4=pred_count>=4
    gate=bool(g1 and g2 and g3 and g4)
    summary=dict(results_dir=str(p),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 total_g1_eval=int(df.VssmG1Eval.sum()),total_success=int(df.VssmSuccess.sum()),
                 total_eligible_updates=int(df.VssmEligibleUpdates.sum()),
                 enough_success_functions=enough_count,mean_success_rate=float(df.VssmSuccessRate.mean()),
                 mean_median_success_r=float(df.VssmMedianSuccessR.mean()),
                 mean_iqr_success_r=float(df.VssmIQRSuccessR.mean()),
                 dev10_rate=float(dev10),boundary_rate=float(boundary),
                 predictive_functions=pred_count,
                 gate_enough_success=bool(g1),gate_deviation=bool(g2),
                 gate_boundary=bool(g3),gate_predictive=bool(g4),gate_pass=gate)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    lines=['# VSSM P0 被动尺度审计结果','',f'- 结果目录：`{p}`','- 40 次运行，8 函数 × 5 新种子，100k FE，0 失败','- 审计模式与冻结 G1+E 逐位一致（合约测试）','',
           '## 全局尺度信息','',
           f'- 真实评价 G1 候选：**{summary["total_g1_eval"]}**；成功移动：**{summary["total_success"]}**（{summary["mean_success_rate"]:.2%}）',
           f'- 有资格的影子尺度更新：**{summary["total_eligible_updates"]}**',
           f'- 成功相对尺度中位数均值：**{summary["mean_median_success_r"]:.6g}**；IQR 均值：**{summary["mean_iqr_success_r"]:.6g}**',
           f'- \\(|\\rho-1|\\ge0.1\\) 比例：**{dev10:.2%}**',
           f'- 触及上下界比例：**{boundary:.2%}**',
           f'- 满足成功样本门槛的函数：**{enough_count}/8**','',
           '## 分函数尺度信息','',
           '| F | success | eligible | median r | IQR r | dev10% | boundary% |','|---:|---:|---:|---:|---:|---:|---:|']
    for f in FUNCS:
        row=per.loc[f]
        lines.append(f"| {f} | {row.VssmSuccess:.0f} | {row.VssmEligibleUpdates:.0f} | {row.median_success_r:.4g} | {row.iqr_success_r:.4g} | {row.dev10_rate:.1%} | {row.boundary_rate:.2%} |")
    lines += ['','## 预测性与安慰剂','',
              '| F | valid seeds | observed |Spearman| | placebo 95% | median p | predictive |','|---:|---:|---:|---:|---:|---|']
    for f in FUNCS:
        if len(pg) and f in pg.index and np.isfinite(pg.loc[f,'mean_obs']):
            row=pg.loc[f]
            lines.append(f"| {f} | {int(row.valid_seeds)} | {row.mean_obs:.4f} | {row.mean_placebo95:.4f} | {row.median_p:.4f} | {'yes' if row.pred_ok else 'no'} |")
        else:
            lines.append(f"| {f} | 0 | NA | NA | NA | no |")
    lines += ['','## P0 判定','',
              f"- 至少 6/8 函数成功样本充足：**{'通过' if g1 else '不通过'}**（{enough_count}/8）",
              f"- \\(|\\rho-1|\\ge0.1\\) 比例 ≥20%：**{'通过' if g2 else '不通过'}**（{dev10:.2%}）",
              f"- 上下界触发比例 ≤25%：**{'通过' if g3 else '不通过'}**（{boundary:.2%}）",
              f"- 至少 4/8 函数有预测信息：**{'通过' if g4 else '不通过'}**（{pred_count}/8）",'',
              f"**最终判定：{'PROMOTE_VSSM_TO_FACTORIAL' if gate else 'STOP_VSSM_P0'}**"]
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)

if __name__=='__main__': main()
