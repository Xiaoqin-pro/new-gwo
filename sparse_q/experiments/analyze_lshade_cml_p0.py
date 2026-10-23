#!/usr/bin/env python3
"""LSHADE-CML P0."""
from pathlib import Path
import json, numpy as np, pandas as pd
from scipy.stats import wilcoxon
ROOT=Path(__file__).resolve().parents[2]; ARMS=['A-LSHADE','B-jSO','C-CML','D-CMA']; FUNCS=[1,4,7,10,13,20,24,30]
def ratio(a,b):
 a=np.asarray(a,float); b=np.asarray(b,float); out=np.ones_like(a); nz=(a!=0)|(b!=0); out[nz]=a[nz]/np.maximum(b[nz],1e-300); return out
def paired(df,a,b):
 x=df[df.Algorithm==a][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'}); y=df[df.Algorithm==b][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'}); j=x.merge(y,on=['FunctionID','Seed'],validate='one_to_one'); assert len(j)==40; j['r']=ratio(j.ea,j.eb); j['dl']=np.log10(np.maximum(j.ea,1e-12))-np.log10(np.maximum(j.eb,1e-12)); pf=j.groupby('FunctionID').r.median(); d=j.groupby('FunctionID').dl.median().to_numpy(float)
 try:pv=float(wilcoxon(d).pvalue)
 except ValueError:pv=float('nan')
 r=pf.to_numpy(float); rng=np.random.default_rng(20261023); boot=np.array([np.median(rng.choice(r,len(r),replace=True)) for _ in range(5000)]); return dict(median=float(np.median(r)),wins=int((r<1).sum()),cats=int((r>1.2).sum()),max=float(r.max()),worst_f=int(pf.index[int(np.argmax(r))]),p=pv,ci95=[float(np.percentile(boot,2.5)),float(np.percentile(boot,97.5))]),pf
def main():
 p=sorted((ROOT/'sparse_q'/'results').glob('lshade_cml_p0_*'))[-1]; df=pd.read_csv(p/'runs.csv'); assert len(df)==160 and set(df.Algorithm.unique())==set(ARMS) and (df.Status=='ok').all() and (df.Evaluations==100000).all(); out={}; pf=pd.DataFrame(index=FUNCS)
 for name,a,b in [('C_A','C-CML','A-LSHADE'),('C_B','C-CML','B-jSO'),('C_D','C-CML','D-CMA'),('D_A','D-CMA','A-LSHADE')]:
  s,r=paired(df,a,b); out[name]=s; pf[name+'_ratio']=r
 sec=df.groupby('Algorithm').Seconds.mean(); rt=float(sec['C-CML']/sec['A-LSHADE']); gate=bool(out['C_A']['median']<=.98 and out['C_A']['wins']>=6 and out['C_A']['cats']<=1 and out['C_B']['median']<=.98 and out['C_B']['wins']>=6 and out['C_B']['cats']<=1 and out['C_D']['median']<=1.05 and out['C_D']['wins']>=5 and rt<=1.25); verdict='PROMOTE_LSHADE_CML_TO_P1' if gate else 'STOP_LSHADE_CML_P0'; rep=ROOT/'reports'/'lshade_cml_p0_analysis'; rep.mkdir(parents=True,exist_ok=True); obj=dict(results_dir=str(p),comparisons=out,runtime_C_over_A=rt,gate=gate,verdict=verdict,seconds=sec.to_dict()); (rep/'summary.json').write_text(json.dumps(obj,indent=2,ensure_ascii=False),encoding='utf-8'); pf.to_csv(rep/'per_function_ratio.csv')
 lines=['# LSHADE-CML P0（8 函数 × 5 新种子 4114–4118，100k FE）','',f'- 结果目录：`{p}`（160 次运行，0 失败）','','| 对比 | median | wins/8 | >1.20 | max | worst | p | 95% CI |','|---|---:|---:|---:|---:|---:|---:|---:|']
 for name,label in [('C_A','CML/LSHADE'),('C_B','CML/jSO'),('C_D','CML/CMA'),('D_A','CMA/LSHADE')]:
  s=out[name]; lines.append(f"| {label} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max']:.3f} | F{s['worst_f']} | {s['p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] |")
 lines += ['',f'- CML/LSHADE 时间比：{rt:.3f}','',f'**判定：{verdict}**','']; (rep/'report.md').write_text('\n'.join(lines),encoding='utf-8'); print('\n'.join(lines))
if __name__=='__main__':main()
