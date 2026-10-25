#!/usr/bin/env python3
"""Q12 P0 at 20k FE with preregistered gate."""
from pathlib import Path
import json, numpy as np, pandas as pd
from scipy.stats import wilcoxon
ROOT=Path(__file__).resolve().parents[2]
ARMS=['A-Standard','B-Q12','C-Random12','D-DiffAll','E-NoSTEER']; FUNCS=[1,4,7,10,13,20,24,30]
def ratio(a,b):
 a=np.asarray(a,float); b=np.asarray(b,float); return (a+1e-8)/(b+1e-8)
def paired(df,a,b):
 x=df[df.Algorithm==a][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'}); y=df[df.Algorithm==b][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'}); j=x.merge(y,on=['FunctionID','Seed'],validate='one_to_one'); assert len(j)==40
 j['r']=ratio(j.ea,j.eb); j['dl']=np.log10(np.maximum(j.ea,1e-12))-np.log10(np.maximum(j.eb,1e-12)); pf=j.groupby('FunctionID').r.median(); d=j.groupby('FunctionID').dl.median().to_numpy(float)
 try: pv=float(wilcoxon(d).pvalue)
 except ValueError: pv=float('nan')
 r=pf.to_numpy(float); rng=np.random.default_rng(20261023); boot=np.array([np.median(rng.choice(r,len(r),replace=True)) for _ in range(5000)])
 return dict(median=float(np.median(r)),wins=int((r<1).sum()),cats=int((r>1.2).sum()),max=float(r.max()),worst_f=int(pf.index[int(np.argmax(r))]),p=pv,ci95=[float(np.percentile(boot,2.5)),float(np.percentile(boot,97.5))]),pf
def main():
 p=sorted((ROOT/'sparse_q'/'results').glob('q12_p0_*'))[-1]; df=pd.read_csv(p/'runs.csv'); assert len(df)==200 and set(df.Algorithm.unique())==set(ARMS); assert (df.Status=='ok').all() and (df.Evaluations==20000).all()
 out={}; pf=pd.DataFrame(index=FUNCS)
 for name,a,b in [('B_A','B-Q12','A-Standard'),('B_C','B-Q12','C-Random12'),('B_D','B-Q12','D-DiffAll'),('C_A','C-Random12','A-Standard'),('D_A','D-DiffAll','A-Standard'),('E_A','E-NoSTEER','A-Standard')]:
  s,r=paired(df,a,b); out[name]=s; pf[name+'_ratio']=r
 sec=df.groupby('Algorithm').Seconds.mean(); rt=float(sec['B-Q12']/sec['A-Standard'])
 g1=bool(out['B_A']['median']<=.90 and out['B_A']['wins']>=6 and out['B_A']['cats']<=1)
 g2=bool(out['B_C']['median']<=.95 and out['B_C']['wins']>=5)
 g3=bool(out['B_D']['median']<=.95 and out['B_D']['wins']>=5 and out['B_D']['cats']<=out['B_D']['cats'])
 g4=bool(rt<=1.25)
 # Correct tail comparison is B/A cats <= D/A cats.
 g3=bool(out['B_D']['median']<=.95 and out['B_D']['wins']>=5 and out['B_A']['cats']<=out['D_A']['cats'])
 gate=bool(g1 and g2 and g3 and g4); verdict='PROMOTE_Q12_TO_P1' if gate else 'STOP_Q12_P0'
 rep=ROOT/'reports'/'q12_p0_analysis'; rep.mkdir(parents=True,exist_ok=True); obj=dict(results_dir=str(p),comparisons=out,runtime_Q_over_Standard=rt,gate_components=dict(vs_standard=g1,vs_random=g2,vs_diff_and_tail=g3,runtime=g4),gate=gate,verdict=verdict,seconds=sec.to_dict()); (rep/'summary.json').write_text(json.dumps(obj,indent=2,ensure_ascii=False),encoding='utf-8'); pf.to_csv(rep/'per_function_ratio.csv')
 q=df[df.Algorithm=='B-Q12'].groupby('FunctionID')[['OpAct1Pct','OpAct2Pct']].median(); q.to_csv(rep/'q12_action_distribution.csv')
 lines=['# Q12 P0（8 函数 × 5 新种子 4222–4226，20k FE）','',f'- 结果目录：`{p}`（200 次运行，0 失败）','- 预注册：`sparse_q/docs/129_Q12_P0_PREREG.md`','', '| 对比 | median | wins/8 | >1.20 | max | worst | p | 95% CI |','|---|---:|---:|---:|---:|---:|---:|---:|']
 for name,label in [('B_A','Q12/Standard'),('B_C','Q12/Random12'),('B_D','Q12/DiffAll'),('C_A','Random12/Standard'),('D_A','DiffAll/Standard'),('E_A','NoSTEER/Standard')]:
  s=out[name]; lines.append(f"| {label} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max']:.3g} | F{s['worst_f']} | {s['p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] |")
 lines += ['',f'- Q12/Standard 时间比：{rt:.3f}','', '## 门槛',f'- vs standard: {g1}',f'- vs random12: {g2}',f'- vs diff all / tail: {g3}',f'- runtime: {g4}','',f'**判定：{verdict}**','','## Q12 动作分布（1=standard, 2=differential）','']
 for fid,row in q.iterrows(): lines.append(f"- F{fid}: {row['OpAct1Pct']:.3f}, {row['OpAct2Pct']:.3f}")
 (rep/'report.md').write_text('\n'.join(lines),encoding='utf-8'); print('\n'.join(lines))
if __name__=='__main__': main()
