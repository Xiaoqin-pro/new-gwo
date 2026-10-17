import pandas as pd, numpy as np
from scipy import stats
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
df = pd.read_csv(root + r"\sparse_q\results\final_20261016_215309\merged_runs.csv", low_memory=False)
df = df[df.Status=="ok"]
piv = df.pivot_table(index=["FunctionID","Seed"], columns="Algorithm", values="FinalError", aggfunc="first")
A, B = "S-star", "IGWO"
funcs = sorted(df.FunctionID.unique())
ps, ds = [], []
for f in funcs:
    ra, rb = piv.loc[f,A].dropna(), piv.loc[f,B].dropna()
    c = ra.index.intersection(rb.index)
    d = np.log10(rb.loc[c]) - np.log10(ra.loc[c])
    p = stats.wilcoxon(d).pvalue if np.any(d!=0) else 1.0
    ps.append(p); ds.append(np.median(d))
# Holm
order = np.argsort(ps); q = np.empty(len(ps)); cur=0
for i, idx in enumerate(order):
    cur = max(cur, ps[idx]*(len(ps)-i)); q[idx] = min(cur,1)
print(f"{'F':>3} {'median_ratio':>12} {'p_raw':>10} {'p_holm':>10}  verdict")
for f, p, qq, d in zip(funcs, ps, q, ds):
    ra, rb = piv.loc[f,A], piv.loc[f,B]
    r = np.median(ra/rb)
    v = ''
    if qq < 0.05:
        v = "ANGWO-BETTER(sig)" if d > 0 else "IGWO-BETTER(sig)"
    else:
        v = "(n.s.)"
    print(f"{int(f):>3} {r:12.3f} {p:10.2e} {qq:10.2e}  {v}")
sig_b = sum((qq<0.05) and (d>0) for qq,d in zip(q,ds))
sig_w = sum((qq<0.05) and (d<0) for qq,d in zip(q,ds))
print(f"\nHolm summary vs IGWO: significant better {sig_b}, worse {sig_w}")
