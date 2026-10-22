#!/usr/bin/env python3
"""Analyze the passive TSD-R P0 recovery audit (40 runs, 100k FE)."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat

ROOT=Path(__file__).resolve().parents[2]
FUNCS=[1,3,4,7,10,13,20,30]
SEEDS=list(range(3281,3286))
BUDGET=100000
NPERM=1000

def latest(pat):
    ds=sorted((ROOT/'sparse_q'/'results').glob(pat))
    if not ds: raise SystemExit('missing results: '+pat)
    return ds[-1]
def wmean(v,w):
    v=np.asarray(v,float); w=np.asarray(w,float)
    if w.sum()<=0: return float('nan')
    return float(np.sum(v*w)/np.sum(w))
def phase(fe):
    x=fe/BUDGET
    return 0 if x<1/3 else (1 if x<2/3 else 2)

def traces_for_run(df,p):
    rows=[]
    for _,r in df.iterrows():
        rid=int(r.RunID); f=int(r.FunctionID); s=int(r.Seed)
        mat=p/'runs'/f'run_{rid:05d}.mat'
        if not mat.exists(): continue
        m=loadmat(mat,struct_as_record=False,squeeze_me=True)
        tr=getattr(m['record'].result.SGWO,'TsdrTrace',None)
        if tr is None: continue
        tr=np.asarray(tr,float)
        if tr.ndim!=2 or tr.shape[0]<6: continue
        for i in range(tr.shape[0]):
            rows.append(dict(FunctionID=f,Seed=s,row=i,fe=tr[i,0],slot=int(tr[i,1]),
                             cR=tr[i,2],g=tr[i,3],trig=int(tr[i,4]),didP=int(tr[i,5]),
                             arcDist=tr[i,6],recDist=tr[i,7],recCovered=tr[i,8]))
    return pd.DataFrame(rows)

def add_next3(ev):
    if len(ev)==0: return ev
    ev=ev.sort_values(['FunctionID','Seed','slot','fe','row']).copy()
    ev['next3']=np.nan
    for (f,s,slot),g in ev.groupby(['FunctionID','Seed','slot'],sort=False):
        idx=g.index.to_numpy(); vals=g.didP.to_numpy(float)
        if len(idx)>=4:
            for k in range(len(idx)-3):
                ev.loc[idx[k],'next3']=np.sum(vals[k+1:k+4])
    ev['phase']=[phase(x) for x in ev.fe]
    return ev

def main():
    p=latest('tsdr_audit_*'); df=pd.read_csv(p/'runs.csv')
    rep=ROOT/'reports'/'tsdr_p0_audit'; rep.mkdir(parents=True,exist_ok=True)
    assert sorted(df.FunctionID.unique().tolist())==FUNCS,'function mismatch'
    assert sorted(df.Seed.unique().tolist())==SEEDS,'seed mismatch'
    assert len(df)==40 and (df.Status=='ok').all(),'incomplete audit'
    assert (df.Evaluations==100000).all(),'FE mismatch'
    per=df.groupby('FunctionID')[['TsdrG1Eval','TsdrTriggers','TsdrEarly','TsdrMid','TsdrLate','TsdrArcEvents']].sum()
    per['trigger_rate']=per.TsdrTriggers/per.TsdrG1Eval.replace(0,np.nan)
    per['arc_covered_rate']=[wmean(g.TsdrArcCoveredRate,g.TsdrArcEvents) for _,g in df.groupby('FunctionID')]
    per['rec_covered_rate']=[wmean(g.TsdrRecCoveredRate,g.TsdrArcEvents) for _,g in df.groupby('FunctionID')]
    per['rec_dist_mean']=[wmean(g.TsdrRecDistMean,g.TsdrArcEvents) for _,g in df.groupby('FunctionID')]
    # event-level trace analysis
    ev=traces_for_run(df,p); ev=add_next3(ev)
    ev.to_csv(rep/'event_trace.csv',index=False)
    evt=ev[ev.trig==1].dropna(subset=['next3']).copy()
    ctl=ev[(ev.trig==0)&(ev.g>=1)].dropna(subset=['next3']).copy()
    # function-level phase-matched comparison
    frows=[]
    for f in FUNCS:
        a=evt[evt.FunctionID==f]; b=ctl[ctl.FunctionID==f]
        if len(a)<5 or len(b)<5: continue
        ma=a.next3.mean(); mb=b.next3.mean()
        frows.append(dict(FunctionID=f,n_trigger=len(a),n_control=len(b),trigger_mean=ma,control_mean=mb,
                          ratio=(ma/mb if mb>0 else np.nan),trigger_worse=bool(ma<mb)))
    fdf=pd.DataFrame(frows)
    if len(fdf): fdf.to_csv(rep/'per_function_recovery.csv',index=False)
    # pooled phase-stratified permutation
    groups=[]
    for (f,ph),g in ev.dropna(subset=['next3']).groupby(['FunctionID','phase']):
        tr=g[g.trig==1].next3.to_numpy(float); ct=g[(g.trig==0)&(g.g>=1)].next3.to_numpy(float)
        if len(tr)>0 and len(ct)>0: groups.append((tr,ct))
    if groups:
        tr_all=np.concatenate([g[0] for g in groups]); ct_all=np.concatenate([g[1] for g in groups])
        mt=float(tr_all.mean()); mc=float(ct_all.mean()); ratio=mt/mc if mc>0 else np.nan
        rng=np.random.default_rng(20261021); place=np.empty(NPERM)
        for k in range(NPERM):
            ts=[]; cs=[]
            for tr,ct in groups:
                pool=np.concatenate([tr,ct]); rng.shuffle(pool)
                ts.append(pool[:len(tr)]); cs.append(pool[len(tr):])
            mt2=np.concatenate(ts).mean(); mc2=np.concatenate(cs).mean()
            place[k]=mt2/mc2 if mc2>0 else np.inf
        pval=float((1+np.sum(place<=ratio))/(NPERM+1)) if np.isfinite(ratio) else np.nan
    else:
        mt=mc=ratio=pval=np.nan
    n_enough=int((per.TsdrTriggers>=20).sum())
    n_worse=int(fdf.trigger_worse.sum()) if len(fdf) else 0
    rec_cov=wmean(df.TsdrRecCoveredRate,df.TsdrArcEvents)
    g1=n_enough>=6
    g2=n_worse>=4
    g3=np.isfinite(ratio) and ratio<=0.80 and np.isfinite(pval) and pval<0.05
    g4=np.isfinite(rec_cov) and rec_cov<=0.80
    gate=bool(g1 and g2 and g3 and g4)
    summary=dict(results_dir=str(p),runs=len(df),functions=FUNCS,seeds=SEEDS,
                 total_g1_eval=int(df.TsdrG1Eval.sum()),total_triggers=int(df.TsdrTriggers.sum()),
                 trigger_functions_enough=n_enough,function_trigger_worse=n_worse,
                 pooled_trigger_mean=float(mt) if np.isfinite(mt) else None,
                 pooled_control_mean=float(mc) if np.isfinite(mc) else None,
                 pooled_ratio=float(ratio) if np.isfinite(ratio) else None,
                 permutation_p=float(pval) if np.isfinite(pval) else None,
                 recovery_covered_rate=float(rec_cov) if np.isfinite(rec_cov) else None,
                 gate_trigger_count=bool(g1),gate_future_improvement=bool(g2),
                 gate_ratio_permutation=bool(g3),gate_not_duplicate_E=bool(g4),gate_pass=gate)
    (rep/'summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    lines=['# TSD-R P0 被动恢复审计结果','',f'- 结果目录：`{p}`','- 40 次运行，8 函数 × 5 新种子，100k FE，0 失败','- 审计模式与冻结 G1+E 逐位一致（合约测试）','',
           '## 触发事件','',
           f'- 真实评价 G1 候选：**{summary["total_g1_eval"]}**',
           f'- 恢复触发：**{summary["total_triggers"]}**',
           f'- 触发次数 ≥20 的函数：**{n_enough}/8**',
           f'- 下一三评价改善低于对照的函数：**{n_worse}/8**',
           f'- 汇总触发 next-3 均值：**{mt:.6g}**；对照均值：**{mc:.6g}**；比值：**{ratio:.6g}**',
           f'- 分层置换 p：**{pval:.6g}**',
           f'- 恢复候选落入 E 覆盖区域比例：**{rec_cov:.2%}**','',
           '## 分函数触发与未来改善','',
           '| F | triggers | trigger rate | next3 trigger | next3 control | ratio | trigger worse | rec E-covered% |','|---:|---:|---:|---:|---:|---:|---|---:|']
    for f in FUNCS:
        row=per.loc[f]
        fr=fdf[fdf.FunctionID==f]
        if len(fr):
            q=fr.iloc[0]
            lines.append(f"| {f} | {row.TsdrTriggers:.0f} | {row.trigger_rate:.2%} | {q.trigger_mean:.3f} | {q.control_mean:.3f} | {q.ratio:.3f} | {'yes' if q.trigger_worse else 'no'} | {row.rec_covered_rate:.1%} |")
        else:
            lines.append(f"| {f} | {row.TsdrTriggers:.0f} | {row.trigger_rate:.2%} | NA | NA | NA | NA | {row.rec_covered_rate:.1%} |")
    lines += ['','## P0 判定','',
              f"- 至少 6/8 函数触发次数充足：**{'通过' if g1 else '不通过'}**（{n_enough}/8）",
              f"- 至少 4/8 函数触发后更差：**{'通过' if g2 else '不通过'}**（{n_worse}/8）",
              f"- 比值 ≤0.80 且置换 p<0.05：**{'通过' if g3 else '不通过'}**（ratio={ratio:.4g}, p={pval:.4g}）" if np.isfinite(ratio) and np.isfinite(pval) else "- 比值/置换检验：**不通过**（数据不足）",
              f"- 恢复候选 E 覆盖 ≤80%：**{'通过' if g4 else '不通过'}**（{rec_cov:.2%}）" if np.isfinite(rec_cov) else "- 恢复候选 E 覆盖：**不通过**（数据不足）",'',
              f"**最终判定：{'PROMOTE_TSDR_TO_CONFIRMATION' if gate else 'STOP_TSDR_P0'}**"]
    (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('\n'.join(lines)); print('[analysis] wrote',rep)

if __name__=='__main__': main()
