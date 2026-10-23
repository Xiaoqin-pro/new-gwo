#!/usr/bin/env python3
"""OCMA P0."""
from pathlib import Path
import json, numpy as np, pandas as pd
from scipy.stats import wilcoxon
ROOT=Path(__file__).resolve().parents[2]; ARMS=['A-CMA','B-OCMA','C-OMCMA']; FUNCS=[1,4,7,10,13,20,24,30]
def ratio(a,b):
 a=np.asarray(a,float); b=np.asarray(b,float); out=np.ones_like(a); nz=(a!=0)|(b!=0); out[nz]=a[nz]/np.maximum(b[nz],1e-300); return out
def paired(df,a,b):
 x=df[df.Algorithm==a][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'}); y=df[df.Algorithm==b][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'}); j=x.merge(y,on=['FunctionID','Seed'],validate='one_to_one'); assert len(j)==40; j['r']=ratio(j.ea,j.eb); j['dl']=np.log10(np.maximum(j.ea,1e-12))-np.log10(np.maximum(j.eb,1e-12)); pf=j.groupby('FunctionID').r.median(); d=j.groupby('FunctionID').dl.median().to_numpy(float)
 try:pv=float(wilcoxon(d).pvalue)
 except ValueError:pv=float('nan')
 r=pf.to_numpy(float); rng=np.random.default_rng(20261023); boot=np.array([np.median(rng.choice(r,len(r),replace=True)) for _ in range(5000)]); return dict(median=float(np.median(r)),wins=int((r<1).sum()),cats=int((r>1.2).sum()),max=float(r.max()),worst_f=int(pf.index[int(np.argmax(r))]),p=pv,ci95=[float(np.percentile(boot,2.5)),float(np.percentile(boot,97.5))]),pf
def main():
 p=sorted((ROOT/'sparse_q'/'results').glob('ocma_p0_*'))[-1]; df=pd.read_csv(p/'runs.csv'); assert len(df)==120 and set(df.Algorithm.unique())==set(ARMS) and (df.Status=='ok').all() and (df.Evaluations==100000).all(); out={}; pf=pd.DataFrame(index=FUNCS)
 for name,a,b in [('B_A','B-OCMA','A-CMA'),('C_A','C-OMCMA','A-CMA')]:
  s,r=paired(df,a,b); out[name]=s; pf[name+'_ratio']=r
 sec=df.groupby('Algorithm').Seconds.mean(); rt=float(sec['B-OCMA']/sec['A-CMA']); gate=bool(out['B_A']['median']<=.98 and out['B_A']['wins']>=5 and out['B_A']['cats']<=2 and out['C_A']['median']<=.98 and out['C_A']['wins']>=5 and out['C_A']['cats']<=2 and rt<=1.25); verdict='PROMOTE_OCMA_TO_P1' if gate else 'STOP_OCMA_P0'; rep=ROOT/'reports'/'ocma_p0_analysis'; rep.mkdir(parents=True,exist_ok=True); obj=dict(results_dir=str(p),comparisons=out,runtime_B_over_A=rt,gate=gate,verdict=verdict,seconds=sec.to_dict()); (rep/'summary.json').write_text(json.dumps(obj,indent=2,ensure_ascii=False),encoding='utf-8'); pf.to_csv(rep/'per_function_ratio.csv')
 lines=['# Orthogonal CMA P0（8 函数 × 5 新种子 4095–4099，100k FE）','',f'- 结果目录：`{p}`（120 次运行，0 失败）','','| 对比 | median | wins/8 | >1.20 | max | worst | p | 95% CI |','|---|---:|---:|---:|---:|---:|---:|---:|']
 for name,label in [('B_A','OCMA/CMA'),('C_A','OMCMA/CMA')]:
  s=out[name]; lines.append(f"| {label} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max']:.3f} | F{s['worst_f']} | {s['p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] |")
 lines += ['',f'- OCMA/CMA 时间比：{rt:.3f}','',f'**判定：{verdict}**','']; (rep/'report.md').write_text('\n'.join(lines),encoding='utf-8'); print('\n'.join(lines))
if __name__=='__main__':main()
