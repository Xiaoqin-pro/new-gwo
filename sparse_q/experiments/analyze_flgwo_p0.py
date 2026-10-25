#!/usr/bin/env python3
"""FL-GWO P0 with preregistered gate."""
from pathlib import Path
import json, numpy as np, pandas as pd
from scipy.stats import wilcoxon
ROOT=Path(__file__).resolve().parents[2]
ARMS=['A-Global','B-FL10','C-FL30','D-RandAll10','E-GLL20']; FUNCS=[1,4,7,10,13,20,24,30]
def ratio(a,b):
 a=np.asarray(a,float); b=np.asarray(b,float); return (a+1e-8)/(b+1e-8)
def paired(df,a,b):
 x=df[df.Algorithm==a][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'}); y=df[df.Algorithm==b][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'}); j=x.merge(y,on=['FunctionID','Seed'],validate='one_to_one'); assert len(j)==40
 j['r']=ratio(j.ea,j.eb); j['dl']=np.log10(np.maximum(j.ea,1e-12))-np.log10(np.maximum(j.eb,1e-12)); pf=j.groupby('FunctionID').r.median(); d=j.groupby('FunctionID').dl.median().to_numpy(float)
 try: pv=float(wilcoxon(d).pvalue)
 except ValueError: pv=float('nan')
 r=pf.to_numpy(float); rng=np.random.default_rng(20261024); boot=np.array([np.median(rng.choice(r,len(r),replace=True)) for _ in range(5000)])
 return dict(median=float(np.median(r)),wins=int((r<1).sum()),cats=int((r>1.2).sum()),max=float(r.max()),worst_f=int(pf.index[int(np.argmax(r))]),p=pv,ci95=[float(np.percentile(boot,2.5)),float(np.percentile(boot,97.5))]),pf
def main():
 p=sorted((ROOT/'sparse_q'/'results').glob('flgwo_p0_*'))[-1]; df=pd.read_csv(p/'runs.csv'); assert len(df)==200 and set(df.Algorithm.unique())==set(ARMS); assert (df.Status=='ok').all() and (df.Evaluations==100000).all()
 out={}; pf=pd.DataFrame(index=FUNCS)
 for name,a,b in [('B_A','B-FL10','A-Global'),('B_D','B-FL10','D-RandAll10'),('B_E','B-FL10','E-GLL20'),('C_A','C-FL30','A-Global'),('D_A','D-RandAll10','A-Global')]:
  s,r=paired(df,a,b); out[name]=s; pf[name+'_ratio']=r
 sec=df.groupby('Algorithm').Seconds.mean(); rt=float(sec['B-FL10']/sec['A-Global'])
 g1=bool(out['B_A']['median']<=.95 and out['B_A']['wins']>=6 and out['B_A']['cats']<=1)
 g2=bool(out['B_D']['median']<=1.02 and out['B_D']['wins']>=5)
 g3=bool(out['B_E']['median']<=1.02 and out['B_E']['wins']>=5)
 g4=bool(rt<=1.50); gate=bool(g1 and g2 and g3 and g4); verdict='PROMOTE_FLGWO_TO_P1' if gate else 'STOP_FLGWO_P0'
 rep=ROOT/'reports'/'flgwo_p0_analysis'; rep.mkdir(parents=True,exist_ok=True); obj=dict(results_dir=str(p),comparisons=out,runtime_FL_over_Global=rt,gate_components=dict(vs_global=g1,vs_random_local=g2,vs_gll=g3,runtime=g4),gate=gate,verdict=verdict,seconds=sec.to_dict()); (rep/'summary.json').write_text(json.dumps(obj,indent=2,ensure_ascii=False),encoding='utf-8'); pf.to_csv(rep/'per_function_ratio.csv')
 lines=['# FL-GWO P0（8 函数 × 5 新种子 4266–4270，100k FE）','',f'- 结果目录：`{p}`（200 次运行，0 失败）','- 预注册：`sparse_q/docs/135_FLGWO_P0_PREREG.md`','', '| 对比 | median | wins/8 | >1.20 | max | worst | p | 95% CI |','|---|---:|---:|---:|---:|---:|---:|---:|']
 for name,label in [('B_A','FL10/Global'),('B_D','FL10/RandAll10'),('B_E','FL10/GLL20'),('C_A','FL30/Global'),('D_A','RandAll10/Global')]:
  s=out[name]; lines.append(f"| {label} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max']:.3g} | F{s['worst_f']} | {s['p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] |")
 lines += ['',f'- FL10/Global 时间比：{rt:.3f}','', '## 门槛',f'- vs global: {g1}',f'- vs random local: {g2}',f'- vs GLL20: {g3}',f'- runtime: {g4}','',f'**判定：{verdict}**','']
 (rep/'report.md').write_text('\n'.join(lines),encoding='utf-8'); print('\n'.join(lines))
if __name__=='__main__': main()
