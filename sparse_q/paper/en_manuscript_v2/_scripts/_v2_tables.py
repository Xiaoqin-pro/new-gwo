# -*- coding: utf-8 -*-
"""VAST-GWO v2 (single-column) tables + number ledger. All from frozen result files."""
import os, sys, glob, json
import numpy as np, pandas as pd
from scipy import stats
try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception: pass

SQ   = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
ROOT = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
OUT  = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\tables"
os.makedirs(OUT, exist_ok=True)
RNG = np.random.default_rng(20261018)

MAIN7 = [("S-star","VAST-GWO"),("IGWO","I-GWO"),("HAGWO","HAGWO"),
         ("PSO(classic)","PSO"),("CLPSO","CLPSO"),("AOGWO","AOGWO"),("GWO","GWO")]
FAM = {"Unimodal":[1,3], "Simple multimodal":list(range(4,11)),
       "Hybrid":list(range(11,21)), "Composition":list(range(21,31))}

def holm(p):
    p=np.asarray(p,float); o=np.argsort(p); adj=np.empty_like(p); cur=0.0
    for i,ix in enumerate(o): cur=max(cur,p[ix]*(len(p)-i)); adj[ix]=min(cur,1.0)
    return adj

def boot_ci(x,n=10000):
    x=np.asarray(x,float); m=[np.median(RNG.choice(x,size=len(x),replace=True)) for _ in range(n)]
    return float(np.percentile(m,2.5)), float(np.percentile(m,97.5))

def load_main7():
    base = pd.read_csv(os.path.join(SQ,"results","final_20261016_215309","merged_runs.csv"), low_memory=False)
    base = base[base.Status=="ok"]
    parts=[base]
    for pat in ["new3_*","pso_*"]:
        cands=[d for d in sorted(glob.glob(os.path.join(SQ,"results",pat))) if os.path.exists(os.path.join(d,"runs.csv"))]
        dd = pd.read_csv(os.path.join(cands[-1],"runs.csv")); dd=dd[dd.Status=="ok"]
        parts.append(dd)
    both = pd.concat(parts, ignore_index=True, sort=False)
    both = both[both.Algorithm!="EDGWO"]
    return both

def stats_vs(piv, A, B):
    funcs=sorted(set(piv.index.get_level_values(0)))
    per={}; ps=[]; ds=[]; w=l=0
    for f in funcs:
        ra,rb=piv.loc[f,A].dropna(), piv.loc[f,B].dropna()
        c=ra.index.intersection(rb.index)
        if len(c)==0: continue
        ra,rb=ra.loc[c],rb.loc[c]
        per[int(f)]=float(np.median(ra/rb))
        w+= ra.mean()<rb.mean(); l+= ra.mean()>rb.mean()
        d=np.log10(rb)-np.log10(ra)
        ps.append(stats.wilcoxon(d).pvalue if np.any(d!=0) else 1.0); ds.append(float(np.median(d)))
    q=holm(ps)
    sb=int(sum((a<0.05 and d>0) for a,d in zip(q,ds)))
    sw=int(sum((a<0.05 and d<0) for a,d in zip(q,ds)))
    pooled=(np.log10(piv[B])-np.log10(piv[A])).dropna().values
    lo,hi=boot_ci(pooled)
    return dict(med=float(np.median(list(per.values()))), per=per, w=int(w), l=int(l),
                sb=sb, sw=sw, pp=float(stats.wilcoxon(pooled).pvalue) if np.any(pooled!=0) else 1.0,
                mlog=float(np.median(pooled)), ci=(lo,hi))

def main():
    both = load_main7()
    piv = both.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
    have=[(a,lab) for a,lab in MAIN7 if a in piv.columns]
    assert len(have)==7, have
    med = piv.groupby(level=0).median()
    rank = med[[a for a,_ in have]].rank(axis=1).mean(axis=0)
    L = {"ranks": {lab: round(float(rank[a]),2) for a,lab in have}}

    print("=== mean ranks ===")
    for a,lab in have: print(f"  {lab:10s} {rank[a]:.2f}")

    # ---- per-baseline statistics ----
    vs={}
    print("\n=== vs VAST-GWO ===")
    for a,lab in have:
        if a=="S-star": continue
        r=stats_vs(piv,"S-star",a); vs[lab]=r
        print(f"  {lab:8s} ratio {r['med']:.3f}  W-L {r['w']}-{r['l']}  Holm +{r['sb']}/-{r['sw']}  "
              f"pooled p {r['pp']:.3g}  medlog {r['mlog']:+.4f} [{r['ci'][0]:+.4f},{r['ci'][1]:+.4f}]")
    L["vs"]={k:{kk:(vv if kk!='per' else {str(x):round(y,4) for x,y in vv.items()}) for kk,vv in v.items()} for k,v in vs.items()}

    # ---- family statistics ----
    fam_rows={}
    for a,lab in have:
        if a=="S-star": continue
        row={}
        for fam,fs in FAM.items():
            rs=[]; w=l=0
            for f in fs:
                ra,rb=piv.loc[f,"S-star"].dropna(), piv.loc[f,a].dropna()
                c=ra.index.intersection(rb.index)
                if len(c)==0: continue
                rs.append(float(np.median(ra.loc[c]/rb.loc[c])))
                w+= ra.loc[c].mean()<rb.loc[c].mean(); l+= ra.loc[c].mean()>rb.loc[c].mean()
            row[fam]=(float(np.median(rs)), int(w), int(l))
        fam_rows[lab]=row
    # best-count per family (median per function, min across 7)
    best={}
    for fam,fs in FAM.items():
        cnt=0
        for f in fs:
            vals={a: med.loc[f,a] for a,_ in have}
            if min(vals, key=vals.get)=="S-star": cnt+=1
        best[fam]=(cnt, len(fs))
    L["family"]={k:{kk:vv for kk,vv in v.items()} for k,v in fam_rows.items()}
    L["best_count"]=best
    print("\n=== family median ratios (W-L) ===")
    for lab,row in fam_rows.items():
        print(f"  {lab:8s} " + "  ".join(f"{f[:6]}:{row[f][0]:.3f}({row[f][1]}-{row[f][2]})" for f in FAM))
    print("  best-count:", best)

    # ---- per-function appendix table ----
    rows=[]
    for f in sorted(set(piv.index.get_level_values(0))):
        vals={a: med.loc[f,a] for a,_ in have}
        besta=min(vals,key=vals.get)
        cells=[]
        for a,lab in have:
            v=vals[a]
            s=("\\textbf{%s}"%f"{v:.4g}") if a==besta else f"{v:.4g}"
            cells.append(s)
        rows.append(f"F{f} & " + " & ".join(cells) + r" \\")
    tex=[r"\begin{tabular}{lrrrrrrr}", r"\toprule",
         r"Fn. & VAST-GWO & I-GWO & HAGWO & PSO & CLPSO & AOGWO & GWO\\", r"\midrule"]
    tex+=rows
    tex+=[r"\bottomrule", r"\end{tabular}"]
    open(os.path.join(OUT,"table_perfunction.tex"),"w",encoding="utf-8").write("\n".join(tex)+"\n")

    # ---- family LaTeX ----
    tex=[r"\begin{tabular}{lrrrr}", r"\toprule",
         r"Baseline & Unimodal & Simple multim. & Hybrid & Composition\\", r"\midrule"]
    for a,lab in have:
        if a=="S-star": continue
        row=fam_rows[lab]
        cells=[f"{row[f][0]:.3f} ({row[f][1]}-{row[f][2]})" for f in FAM]
        tex.append(f"{lab} & " + " & ".join(cells) + r" \\")
    tex+=[r"\bottomrule", r"\end{tabular}"]
    open(os.path.join(OUT,"table_family.tex"),"w",encoding="utf-8").write("\n".join(tex)+"\n")

    # ---- runtime ----
    rt={}
    for a,lab in have:
        e=both[both.Algorithm==a]
        rt[lab]=dict(mean=float(e.Seconds.mean()), med=float(e.Seconds.median()))
    L["runtime"]=rt
    print("\n=== runtime (s/run, D=50, 100k FE) ===")
    for k,v in rt.items(): print(f"  {k:10s} mean {v['mean']:.2f}  median {v['med']:.2f}")

    # ---- main table with time ----
    tex=[r"\begin{tabular}{lrrrrrr}", r"\toprule",
         r"Method & Med.\ ratio & W--L & Holm $+/-$ & Pooled $p$ & Mean rank & Time (s)\\",
         r"\midrule"]
    for a,lab in have:
        t=rt[lab]["mean"]
        if a=="S-star":
            tex.append(f"\\textbf{{{lab}}} & -- & -- & -- & -- & \\textbf{{{rank[a]:.2f}}} & {t:.2f}\\\\")
        else:
            r=vs[lab]
            p=f"{r['pp']:.2g}".replace("e-","\\times10^{-")+("}" if "e-" in f"{r['pp']:.2g}" else "")
            tex.append(f"{lab} & {r['med']:.3f} & {r['w']}-{r['l']} & $+{r['sb']}/-{r['sw']}$ & ${p}$ & {rank[a]:.2f} & {t:.2f}\\\\")
    tex+=[r"\bottomrule", r"\end{tabular}"]
    open(os.path.join(OUT,"table_main7.tex"),"w",encoding="utf-8").write("\n".join(tex)+"\n")

    # ---- D=100 tier ----
    b=sorted([d for d in os.listdir(os.path.join(SQ,"results")) if d.startswith("fd100_")])[-1]
    d100=pd.read_csv(os.path.join(SQ,"results",b,"runs.csv")); d100=d100[d100.Status=="ok"]
    aud=pd.read_csv(os.path.join(ROOT,"data","reference","audited_d100_12fn.csv")); aud=aud[aud.Status=="ok"]
    parts=[d100]
    for new,old in {"IGWO":"IGWO","RASE-GWO":"RASE-IGWO"}.items():
        s=aud[aud.Algorithm==old].copy(); s["Algorithm"]=new; parts.append(s)
    alld=pd.concat(parts,ignore_index=True,sort=False)
    pivd=alld.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="FinalError",aggfunc="first")
    rd=pivd.groupby(level=0).median().rank(axis=1).mean(axis=0)
    print("\n=== D=100 ranks ===", {k:round(float(v),2) for k,v in rd.sort_values().items()})
    t100={}
    for Bn in ["B1-dense-sync","S1-pool38","IGWO","RASE-GWO"]:
        if Bn in pivd.columns:
            r=stats_vs(pivd,"S-star",Bn); t100[Bn]=dict(med=r["med"],w=r["w"],l=r["l"],sb=r["sb"],sw=r["sw"])
    L["d100"]={"ranks":{k:round(float(v),2) for k,v in rd.items()}, "vs":t100}
    print("  vs:", json.dumps(t100, indent=0))

    # ---- 20k tier ----
    b=sorted([d for d in os.listdir(os.path.join(SQ,"results")) if d.startswith("f20k_")])[-1]
    d20=pd.read_csv(os.path.join(SQ,"results",b,"runs.csv")); d20=d20[d20.Status=="ok"]
    piv20=d20.pivot_table(index=["FunctionID","Seed"],columns="Algorithm",values="FinalError",aggfunc="first")
    r20=piv20.groupby(level=0).median().rank(axis=1).mean(axis=0)
    print("=== 20k ranks ===", {k:round(float(v),2) for k,v in r20.sort_values().items()})
    t20={}
    for Bn in ["GWO","B0-ANGWO","B1-dense-sync","S1-pool38"]:
        if Bn in piv20.columns:
            r=stats_vs(piv20,"S-star",Bn); t20[Bn]=dict(med=r["med"],w=r["w"],l=r["l"],sb=r["sb"],sw=r["sw"])
    L["f20k"]={"ranks":{k:round(float(v),2) for k,v in r20.items()}, "vs":t20}
    print("  vs:", json.dumps(t20, indent=0))

    # ---- tiers LaTeX ----
    name={"S-star":"VAST-GWO","S1-pool38":"S1-K50","B1-dense-sync":"B1-dense",
          "B0-ANGWO":"ANGWO","IGWO":"I-GWO","RASE-GWO":"RASE-GWO","GWO":"GWO"}
    tex=[r"\begin{tabular}{lrr}", r"\toprule",
         r"Method & Mean rank & Med.\ ratio vs VAST-GWO \\", r"\midrule"]
    tex.append(r"\multicolumn{3}{l}{\emph{(a) $D=100$, 100k FE, 29 functions, 10 seeds}}\\")
    for k,v in rd.sort_values().items():
        if k=="S-star": tex.append(f"{name.get(k,k)} & \\textbf{{{v:.2f}}} & -- \\\\")
        else:
            r=t100.get(k)
            tex.append(f"{name.get(k,k)} & {v:.2f} & " + (f"{r['med']:.3f} ({r['w']}-{r['l']})\\\\" if r else r"--\\"))
    tex.append(r"\midrule")
    tex.append(r"\multicolumn{3}{l}{\emph{(b) 20k FE, $D=50$, 29 functions, 10 seeds}}\\")
    for k,v in r20.sort_values().items():
        if k=="S-star": tex.append(f"{name.get(k,k)} & \\textbf{{{v:.2f}}} & -- \\\\")
        else:
            r=t20.get(k); tex.append(f"{name.get(k,k)} & {v:.2f} & " + (f"{r['med']:.3f} ({r['w']}-{r['l']})\\\\" if r else r"--\\"))
    tex+=[r"\bottomrule", r"\end{tabular}"]
    open(os.path.join(OUT,"table_tiers.tex"),"w",encoding="utf-8").write("\n".join(tex)+"\n")

    json.dump(L, open(os.path.join(OUT,"_numbers.json"),"w",encoding="utf-8"), indent=1, ensure_ascii=False)
    print("\nTABLES ->", OUT)

if __name__=="__main__":
    main()
