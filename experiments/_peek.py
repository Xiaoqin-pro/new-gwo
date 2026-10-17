import pandas as pd
p = r"D:\111\Desktop\噜噜\9.29\CEC2017_8Algorithm_30Seed\results\main_8algorithms\convergence_nodes.csv"
df = pd.read_csv(p)
print(df.shape, df.columns.tolist())
print(df[df.FunctionID==1].groupby("Condition").size())
print(df[(df.FunctionID==1)&(df.Condition=="HCLPSO-AuthorSource")].head(8))
print("FE nodes:", sorted(df[df.FunctionID==1].FE.unique())[:12], "... n=", df[df.FunctionID==1].FE.nunique())
