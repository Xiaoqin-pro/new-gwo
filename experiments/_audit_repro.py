import pandas as pd, numpy as np, glob, os
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026"
a = pd.read_csv(os.path.join(sorted(glob.glob(os.path.join(root,'results','rd1_2026*')))[-1],'runs.csv'))
b = pd.read_csv(os.path.join(sorted(glob.glob(os.path.join(root,'results','rd1b_*')))[-1],'runs.csv'))
ka = a[a.Algorithm=='E-fixed10-nofilter'][['FunctionID','Seed','FinalCost']].sort_values(['FunctionID','Seed']).reset_index(drop=True)
kb = b[b.Algorithm=='E-f10-self-r'][['FunctionID','Seed','FinalCost']].sort_values(['FunctionID','Seed']).reset_index(drop=True)
same = np.array_equal(ka.FinalCost.values, kb.FinalCost.values)
print('rd1a E-fixed10-nofilter vs rd1b E-f10-self-r bitwise identical:', same)
print('max abs diff:', np.max(np.abs(ka.FinalCost.values-kb.FinalCost.values)))
