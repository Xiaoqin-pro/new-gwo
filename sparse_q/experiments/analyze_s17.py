#!/usr/bin/env python3
"""最终方向归因轮（finalaud, docs/12 Addendum B）——严格按预注册门槛判定。"""
import os, sys, glob
import numpy as np, pandas as pd
from scipy import stats
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass
SQ = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
RNG = np.random.default_rng(20261017)

def holm(p):
    p=np.asarray(p,float); order=np.argsort(p); adj=np.empty_like(p); cur=0.0
    for i,idx in enumerate(order):
        cur=max(cur,p[idx]*(len(p)-i)); adj[idx]=min(cur,1.0)
    return adj

def boot_ci(x, n=10000):
    x=np.asarray(x,float); meds=[]
    for _ in range(n): meds.append(np.median(RNG.choice(x,size=len(x),replace=True)))
    return np.percentile(meds,[2.5,97.5])

def fn_stats(piv,A,B):
    """per-function + pooled paired stats between arms A (ours) and B (opponent)."""
    funcs=sorted(set(piv.index.get_level_values(0)))
    per={}; ps=[]; ds=[]; w=l=0
    for f in funcs:
        ra,rb=piv.loc[f,A].dropna(),piv.loc[f,B].dropna()
        c=ra.index.intersection(rb.index)
        if len(c)==0: continue
        ra,rb=ra.loc[c],rb.loc[c]
        r=float(np.median(ra/rb)); per[int(f)]=r
        w+=ra.mean()<rb.mean(); l+=ra.mean()>rb.mean()
        d=np.log10(rb)-np.log10(ra)
        ps.append(stats.wilcoxon(d).pvalue if np.any(d!=0) else 1.0); ds.append(np.median(d))
    q=holm(ps)
    sb=int(sum((qi<0.05) and (di>0) for qi,di in zip(q,ds)))
    sw=int(sum((qi<0.05) and (di<0) for qi,di in zip(q,ds)))
    pooled=(np.log10(piv[B])-np.log10(piv[A])).dropna().values
    lo,hi=boot_ci(pooled)
    return dict(med=float(np.median(list(per.values()))), per=per, w=w, l=l, sb=sb, sw=sw,
                pooled=pooled, ci=(lo,hi), pp=stats.wilcoxon(pooled).pvalue if np.any(pooled!=0) else 1.0)

def fmt(r):
    return (f"medRatio {r['med']:.3f}  W-L {r['w']}-{r['l']}  Holm +{r['sb']}/-{r['sw']}  "
            f"medLog10 {np.median(r['pooled']):+.4f} [CI {r['ci'][0]:+.4f},{r['ci'][1]:+.4f}]  pooled p={r['pp']:.3g}")

def main():
    cands=[d for d in sorted(glob.glob(os.path.join(SQ,"results","finalaud_*"))) if os.path.exists(os.path.join(d,"runs.csv"))]
    if not cands: print("no finalaud batch yet"); return
    d=cands[-1]; df=pd.read_csv(os.path.join(d,"runs.csv")); df=df[df.Status=="ok"]
    print(f"batch {os.path.basename(d)}  ok runs={len(df)}  seeds={sorted(df.Seed.unique())}")
    piv=df.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="FinalError",aggfunc="first")
    arms=["V1-ref","V2-steer50","V2-G1","V2-Random"]
    print("\n=== 最终误差（配对，同函数同种子） ===")
    res={}
    for A in arms[1:]:
        for B in ["V1-ref","V2-Random"]:
            if A==B: continue
            r=fn_stats(piv,A,B); res[(A,B)]=r
            print(f"{A:11s} vs {B:9s}: {fmt(r)}")
    print("\n逐函数中位比（A vs V1-ref）:")
    print(f"{'F':>3} {'steer50':>8} {'G1':>7} {'Random':>7}   (越小越好)")
    for f in sorted(res[("V2-steer50","V1-ref")]["per"]):
        print(f"F{f:<2} {res[('V2-steer50','V1-ref')]['per'][f]:8.3f} {res[('V2-G1','V1-ref')]['per'][f]:7.3f} {res[('V2-Random','V1-ref')]['per'][f]:7.3f}")
    print("\n=== 早期 FE 轨迹（vs V1-ref 与 vs V2-Random 中位比） ===")
    for ck in ["CheckT10","CheckT20","CheckT50","CheckT80","CheckT100"]:
        if ck not in df.columns: continue
        p2=df.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values=ck,aggfunc="first")
        line=f"{ck:9s} "
        for A in ["V2-steer50","V2-G1","V2-Random"]:
            m=float(np.median(p2[A]/p2["V1-ref"]))
            line+=f"{A}={m:.3f}  "
        print(line)
    print("\n=== 运行时间（配对中位比 vs V1-ref） ===")
    p3=df.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="Seconds",aggfunc="first")
    for A in arms[1:]:
        print(f"{A:11s} {np.median(p3[A]/p3['V1-ref']):.3f}x   (mean {p3[A].mean():.2f}s vs {p3['V1-ref'].mean():.2f}s)")
    rank=piv.groupby(level=0).median().rank(axis=1).mean(axis=0).sort_values()
    print("\n平均排名:", {k: round(float(v),2) for k,v in rank.items()})

    print("\n=== 预注册门槛判定（docs/12 Addendum B，不修改） ===")
    def med_vs_random(A): return res[(A,"V2-Random")]["med"]
    best=min(["V2-steer50","V2-G1"], key=lambda A: (med_vs_random(A), 0 if A=="V2-steer50" else 1))
    r_rand=res[(best,"V2-Random")]; r_ref=res[(best,"V1-ref")]
    g_i = (r_rand["med"]<=0.98) or (r_rand["w"]>=18)
    g_ii= (r_ref["med"]<=1.02) and (r_ref["w"]>=15)
    print(f"best arm = {best}")
    print(f"(i)   vs Random: med={r_rand['med']:.3f} (<=0.98?) W={r_rand['w']} (>=18?) -> {'PASS' if g_i else 'FAIL'}")
    print(f"(ii)  vs V1-ref: med={r_ref['med']:.3f} (<=1.02?) W={r_ref['w']} (>=15?) -> {'PASS' if g_ii else 'FAIL'}")
    rt_over = float(np.median(p3[best]/p3["V1-ref"]))
    if g_i and g_ii:
        small_gain = r_rand["med"]>0.95
        slow = rt_over>1.20
        if small_gain and slow:
            verdict="方向有效但收益极小且时间明显增加 -> 仍选 V1（简洁与效率优先）"
        else:
            verdict="方向信息具有独立贡献 -> V2 仅列为[待独立基准确认的候选]，不改论文主版本、不加参数扫描"
    elif (r_rand["med"]>1.0) or (r_rand["l"]>=18):
        verdict="Random 更好 -> V1 为论文主算法；方向假设不成立或未获支持；V2 与随机对照进补充材料"
    else:
        verdict="与 Random 基本持平 -> V1 为论文主算法；V2 仅作增强对照；进补充材料"
    print("判决:", verdict)
    print(f"(运行时增幅 {best} vs V1-ref = {rt_over:.3f}x)")

if __name__=="__main__":
    main()
