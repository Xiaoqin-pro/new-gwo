#!/usr/bin/env python3
"""SHA P0: mechanism actuation audit."""
from pathlib import Path
import json
import numpy as np, pandas as pd
from scipy.stats import wilcoxon
ROOT=Path(__file__).resolve().parents[2]
FUNCS=[1,4,7,10,13,20,24,30]; A,B,C='A-SHA-Linear','B-SHA-History','C-SHA-Placebo'
def main():
 p=sorted((ROOT/'sparse_q'/'results').glob('sha_p0_*'))[-1]; df=pd.read_csv(p/'runs.csv')
 assert len(df)==120 and set(df.Algorithm.unique())=={A,B,C} and (df.Status=='ok').all()
 assert sorted(df.FunctionID.unique().tolist())==FUNCS
 h=df[df.Algorithm==B]
 per=h.groupby('FunctionID')[['ShaFactorMean','ShaAUpPct','ShaADownPct','ShaEvals','ShaSuccess']].median()
 per['actuated']=((per.ShaFactorMean-1).abs()>=.01)&(per.ShaAUpPct>0)&(per.ShaADownPct>0)
 def stats(a,b):
  x=df[df.Algorithm==a][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'})
  y=df[df.Algorithm==b][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'})
  j=x.merge(y,on=['FunctionID','Seed']); j['r']=j.ea/j.eb; pf=j.groupby('FunctionID').r.median(); r=pf.to_numpy(float)
  return dict(median=float(np.median(r)),wins=int((r<1).sum()),cats=int((r>1.2).sum()),max=float(r.max()),per=pf)
 S={'B/A':stats(B,A),'C/A':stats(C,A),'B/C':stats(B,C)}
 rep=ROOT/'reports'/'sha_p0_analysis'; rep.mkdir(parents=True,exist_ok=True)
 gate=int(per.actuated.sum()); verdict='PROMOTE_SHA_TO_P1' if gate>=6 else 'STOP_SHA_P0'
 out=dict(results_dir=str(p),actuation_functions=gate,gate=gate>=6,per_function=per.to_dict('index'),performance={k:{kk:vv for kk,vv in v.items() if kk!='per'} for k,v in S.items()},verdict=verdict)
 (rep/'summary.json').write_text(json.dumps(out,indent=2,ensure_ascii=False),encoding='utf-8')
 per.to_csv(rep/'actuation.csv'); pd.DataFrame({k:v['per'] for k,v in S.items()}).to_csv(rep/'per_function_ratio.csv')
 lines=['# SHA P0（8 函数 × 5 新种子 3619–3623，100k FE）','',f'- 结果目录：`{p}`（120 次运行，0 失败）',f'- 机制触发函数：**{gate}/8**（门槛 ≥6）','',
        '| F | factor mean | a-up% | a-down% | G1 eval | G1 success | actuated |','|---:|---:|---:|---:|---:|---:|:--:|']
 for f,x in per.iterrows(): lines.append(f"| {int(f)} | {x.ShaFactorMean:.4f} | {x.ShaAUpPct:.3f} | {x.ShaADownPct:.3f} | {x.ShaEvals:.0f} | {x.ShaSuccess:.0f} | {'yes' if x.actuated else 'no'} |")
 lines += ['','| 对比 | median | wins/8 | >1.20 | max |','|---|---:|---:|---:|---:|']
 for k,s in S.items(): lines.append(f"| {k} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max']:.3f} |")
 lines += ['',f'**判定：{verdict}**','']
 (rep/'report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8'); print('\n'.join(lines))
if __name__=='__main__': main()
