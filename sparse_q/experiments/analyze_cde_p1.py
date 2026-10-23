#!/usr/bin/env python3
"""CDE P1: 15-function x 10-seed on differential refinement."""
from pathlib import Path
import json, numpy as np, pandas as pd
from scipy.stats import wilcoxon
ROOT=Path(__file__).resolve().parents[2]; FUNCS=[1,3,4,7,10,11,13,14,16,18,20,22,24,26,30]; SEEDS=list(range(3624,3634)); A,B='A-CDE-Off','B-CDE-On'
def main():
 p=sorted((ROOT/'sparse_q'/'results').glob('cde_p1_*'))[-1]; df=pd.read_csv(p/'runs.csv'); assert len(df)==300 and set(df.Algorithm.unique())=={A,B} and (df.Status=='ok').all() and (df.Evaluations==100000).all()
 x=df[df.Algorithm==A][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'}); y=df[df.Algorithm==B][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'}); j=x.merge(y,on=['FunctionID','Seed']); j['r']=j.ea/j.eb; j['dl']=np.log10(np.maximum(j.ea,1e-12))-np.log10(np.maximum(j.eb,1e-12)); pf=j.groupby('FunctionID').r.median(); r=pf.to_numpy(float); d=j.groupby('FunctionID').dl.median().to_numpy(float)
 try: pv=float(wilcoxon(d).pvalue)
 except ValueError: pv=float('nan')
 rng=np.random.default_rng(20261023); boot=np.array([np.median(rng.choice(r,len(r),replace=True)) for _ in range(5000)])
 s=dict(median=float(np.median(r)),wins=int((r<1).sum()),cats=int((r>1.2).sum()),max=float(r.max()),worst_f=int(pf.index[int(np.argmax(r))]),p=pv,ci95=[float(np.percentile(boot,2.5)),float(np.percentile(boot,97.5))])
 sec=df.groupby('Algorithm').Seconds.mean(); rt=float(sec[B]/sec[A]); gate=bool(s['median']<=.98 and s['wins']>=11 and s['cats']==0 and rt<=1.15); verdict='PROMOTE_CDE_TO_CONFIRM' if gate else 'STOP_CDE_P1'
 rep=ROOT/'reports'/'cde_p1_analysis'; rep.mkdir(parents=True,exist_ok=True); out=dict(results_dir=str(p),**s,runtime=rt,gate=gate,verdict=verdict); (rep/'summary.json').write_text(json.dumps(out,indent=2,ensure_ascii=False),encoding='utf-8'); pd.DataFrame({'B/A':pf}).to_csv(rep/'per_function_ratio.csv')
 lines=['# CDE P1（15 函数 × 10 新种子 3624–3633，100k FE）','',f'- 结果目录：`{p}`（300 次运行，0 失败）','','| 对比 | median | wins/15 | >1.20 | max | worst | p | 95% CI | time |','|---|---:|---:|---:|---:|---:|---:|---:|---:|',f"| on/off | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max']:.3f} | F{s['worst_f']} | {s['p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] | {rt:.3f} |",'',f'**判定：{verdict}**','']; (rep/'report.md').write_text('\n'.join(lines),encoding='utf-8'); print('\n'.join(lines))
if __name__=='__main__': main()
