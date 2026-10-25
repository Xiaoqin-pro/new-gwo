#!/usr/bin/env python3
"""CMA-DE5 P0 analysis with preregistered gate."""
from pathlib import Path
import json, numpy as np, pandas as pd
from scipy.stats import wilcoxon
ROOT=Path(__file__).resolve().parents[2]
ARMS=['A-CMA','B-DE5','C-PermutedDE5','D-Random5','E-jSO']
FUNCS=[1,4,7,10,13,20,24,30]
def ratio(a,b):
    a=np.asarray(a,float); b=np.asarray(b,float); floor=1e-8
    out=(a+floor)/(b+floor); return out
def paired(df,a,b):
    x=df[df.Algorithm==a][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'ea'})
    y=df[df.Algorithm==b][['FunctionID','Seed','FinalError']].rename(columns={'FinalError':'eb'})
    j=x.merge(y,on=['FunctionID','Seed'],validate='one_to_one'); assert len(j)==40
    j['r']=ratio(j.ea,j.eb)
    j['dl']=np.log10(np.maximum(j.ea,1e-12))-np.log10(np.maximum(j.eb,1e-12))
    pf=j.groupby('FunctionID').r.median(); d=j.groupby('FunctionID').dl.median().to_numpy(float)
    try: pv=float(wilcoxon(d).pvalue)
    except ValueError: pv=float('nan')
    r=pf.to_numpy(float); rng=np.random.default_rng(20261023)
    boot=np.array([np.median(rng.choice(r,len(r),replace=True)) for _ in range(5000)])
    return dict(median=float(np.median(r)),wins=int((r<1).sum()),cats=int((r>1.2).sum()),max=float(r.max()),worst_f=int(pf.index[int(np.argmax(r))]),p=pv,ci95=[float(np.percentile(boot,2.5)),float(np.percentile(boot,97.5))]),pf
def main():
    p=sorted((ROOT/'sparse_q'/'results').glob('cma_de_p0_*'))[-1]
    df=pd.read_csv(p/'runs.csv')
    assert len(df)==200 and set(df.Algorithm.unique())==set(ARMS)
    assert (df.Status=='ok').all() and (df.Evaluations==100000).all()
    out={}; pf=pd.DataFrame(index=FUNCS)
    pairs=[('B_A','B-DE5','A-CMA'),('B_E','B-DE5','E-jSO'),('B_C','B-DE5','C-PermutedDE5'),('B_D','B-DE5','D-Random5'),('C_A','C-PermutedDE5','A-CMA'),('D_A','D-Random5','A-CMA'),('E_A','E-jSO','A-CMA')]
    for name,a,b in pairs:
        s,r=paired(df,a,b); out[name]=s; pf[name+'_ratio']=r
    sec=df.groupby('Algorithm').Seconds.mean(); rt=float(sec['B-DE5']/sec['A-CMA'])
    direct_gain=int(out['B_A']['wins']-out['C_A']['wins'])
    g1=bool(out['B_A']['median']<=.98 and out['B_A']['wins']>=6 and out['B_A']['cats']<=1)
    g2=bool(out['B_E']['median']<=.90 and out['B_E']['wins']>=6 and out['B_E']['cats']<=1)
    g3=bool(out['B_C']['median']<=.98 and direct_gain>=2)
    g4=bool(out['B_D']['median']<=.98)
    g5=bool(rt<=1.25)
    gate=bool(g1 and g2 and g3 and g4 and g5)
    verdict='PROMOTE_CMA_DE_TO_P1' if gate else 'STOP_CMA_DE_P0'
    rep=ROOT/'reports'/'cma_de_p0_analysis'; rep.mkdir(parents=True,exist_ok=True)
    obj=dict(results_dir=str(p),comparisons=out,runtime_B_over_A=rt,direct_gain_wins=direct_gain,gate_components=dict(vs_cma=g1,vs_jso=g2,direction=g3,random=g4,runtime=g5),gate=gate,verdict=verdict,seconds=sec.to_dict())
    (rep/'summary.json').write_text(json.dumps(obj,indent=2,ensure_ascii=False),encoding='utf-8'); pf.to_csv(rep/'per_function_ratio.csv')
    lines=['# CMA-DE5 P0（8 函数 × 5 新种子 4141–4145，100k FE）','',f'- 结果目录：`{p}`（200 次运行，0 失败）','- 预注册门槛：`sparse_q/docs/126_CMA_DE_P0_PREREG.md`','', '| 对比 | median | wins/8 | >1.20 | max | worst | p | 95% CI |','|---|---:|---:|---:|---:|---:|---:|---:|']
    labels=[('B_A','DE5/CMA'),('B_E','DE5/jSO'),('B_C','DE5/PermutedDE5'),('B_D','DE5/Random5'),('C_A','Permuted/CMA'),('D_A','Random/CMA'),('E_A','jSO/CMA')]
    for name,label in labels:
        s=out[name]; lines.append(f"| {label} | {s['median']:.4f} | {s['wins']} | {s['cats']} | {s['max']:.3g} | F{s['worst_f']} | {s['p']:.4f} | [{s['ci95'][0]:.3f}, {s['ci95'][1]:.3f}] |")
    lines += ['',f'- DE5/CMA 时间比：{rt:.3f}',f'- 方向对照胜函数增益：{direct_gain:+d}','', '## 门槛',f'- vs CMA: {g1}',f'- vs jSO: {g2}',f'- vs Permuted: {g3}',f'- vs Random: {g4}',f'- runtime: {g5}','',f'**判定：{verdict}**','']
    (rep/'report.md').write_text('\n'.join(lines),encoding='utf-8'); print('\n'.join(lines))
if __name__=='__main__': main()
