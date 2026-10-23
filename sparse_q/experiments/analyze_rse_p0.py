#!/usr/bin/env python3
"""RSE P0 performance screen."""
from pathlib import Path
import json, numpy as np, pandas as pd
ROOT=Path(__file__).resolve().parents[2]
FUNCS=[1,4,7,10,13,20,24,30]; A,B,C='A-RSE-Off','B-RSE-Fixed','C-RSE-RandStrat'
def main():
 p=sorted((ROOT/'sparse_q'/'results').glob('rse_p0_*'))[-1]; df=pd.read_csv(p/'runs.csv')
 assert len(df)==120 and set(df.Algorithm.unique())=={A,B,C} and (df.Status=='ok').all() and (df.Evaluations==100000).all()
 def st(a,b):
  x=df[df.Algorithm==a][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'}); y=df[df.Algorithm==b][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'})
  j=x.merge(y,on=['FunctionID','Seed']); j['r']=j.ea/j.eb; pf=j.groupby('FunctionID').r.median(); r=pf.to_numpy(float)
  return dict(median=float(np.median(r)),wins=int((r<1).sum()),cats=int((r>1.2).sum()),max=float(r.max()),per=pf)
 S={'B/A':st(B,A),'C/A':st(C,A),'B/C':st(B,C)}
 gBA=S['B/A']['median']<=.98 and S['B/A']['wins']>=6 and S['B/A']['cats']==0
 gBC=S['B/C']['median']<=.98 and S['B/C']['wins']>=6
 verdict='PROMOTE_RSE_TO_P1' if gBA and gBC else ('RSE_UNATTRIBUTED' if gBA else 'STOP_RSE_P0')
 rep=ROOT/'reports'/'rse_p0_analysis'; rep.mkdir(parents=True,exist_ok=True)
 out=dict(results_dir=str(p),**{k.replace('/','_'):{kk:vv for kk,vv in v.items() if kk!='per'} for k,v in S.items()},gate_BA=gBA,gate_BC=gBC,verdict=verdict)
 (rep/'summary.json').write_text(json.dumps(out,indent=2,ensure_ascii=False),encoding='utf-8'); pd.DataFrame({k:v['per'] for k,v in S.items()}).to_csv(rep/'per_function_ratio.csv')
 lines=['# RSE P0（8 函数 × 5 新种子 3619–3623，100k FE）','',f'- 结果目录：`{p}`（120 次运行，0 失败）','','| 对比 | median | wins/8 | >1.20 | max |','|---|---:|---:|---:|---:|']
 for k,s in S.items(): lines.append(f"| {k} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max']:.3f} |")
 lines+=['',f'- 主假设 B/A **{"通过" if gBA else "不通过"}**；归因 B/C **{"通过" if gBC else "不通过"}**',f'**判定：{verdict}**','']
 (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8'); print('\n'.join(lines))
if __name__=='__main__': main()
