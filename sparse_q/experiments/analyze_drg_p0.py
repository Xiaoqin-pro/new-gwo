#!/usr/bin/env python3
"""DRG P0 performance screen."""
from pathlib import Path
import json, numpy as np, pandas as pd
ROOT=Path(__file__).resolve().parents[2]; FUNCS=[1,4,7,10,13,20,24,30]; A,B='A-DRG-Off','B-DRG-On'
def main():
 p=sorted((ROOT/'sparse_q'/'results').glob('drg_p0_*'))[-1]; df=pd.read_csv(p/'runs.csv'); assert len(df)==80 and set(df.Algorithm.unique())=={A,B} and (df.Status=='ok').all()
 x=df[df.Algorithm==A][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'}); y=df[df.Algorithm==B][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'}); j=x.merge(y,on=['FunctionID','Seed']); j['r']=j.ea/j.eb; pf=j.groupby('FunctionID').r.median(); r=pf.to_numpy(float)
 s=dict(median=float(np.median(r)),wins=int((r<1).sum()),cats=int((r>1.2).sum()),max=float(r.max()),worst_f=int(pf.index[int(np.argmax(r))]))
 gate=bool(s['median']<=.98 and s['wins']>=6 and s['cats']==0); verdict='PROMOTE_DRG_TO_P1' if gate else 'STOP_DRG_P0'
 rep=ROOT/'reports'/'drg_p0_analysis'; rep.mkdir(parents=True,exist_ok=True); out=dict(results_dir=str(p),**s,gate=gate,verdict=verdict); (rep/'summary.json').write_text(json.dumps(out,indent=2,ensure_ascii=False),encoding='utf-8'); pd.DataFrame({'B/A':pf}).to_csv(rep/'per_function_ratio.csv')
 lines=['# DRG P0（8 函数 × 5 新种子 3619–3623，100k FE）','',f'- 结果目录：`{p}`（80 次运行，0 失败）','','| 对比 | median | wins/8 | >1.20 | max | worst |','|---|---:|---:|---:|---:|---:|',f"| on/off | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max']:.3f} | F{s['worst_f']} |",'',f'**判定：{verdict}**','']; (rep/'report.md').write_text('\n'.join(lines),encoding='utf-8'); print('\n'.join(lines))
if __name__=='__main__': main()
