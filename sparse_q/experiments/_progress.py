import scipy.io as sio, glob, os
from collections import Counter
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
b = sorted(glob.glob(os.path.join(root, 'results', 'freshv2_*')))[-1]
files = glob.glob(os.path.join(b, 'runs', 'run_*.mat'))
cnt = Counter(); 
for f in files:
    try:
        m = sio.loadmat(f, squeeze_me=True, struct_as_record=False)
        r = m['record']
        if str(getattr(r,'status',''))=='ok':
            cnt[int(r.result.FunctionID)] += 1
    except Exception:
        pass
print("completed runs by function (expected 180 per function):")
print(' '.join(f"F{k}:{v}" for k,v in sorted(cnt.items())))
print("remaining functions/estimated runs:", sum(180-v for k,v in cnt.items()), "of 5220-total", sum(cnt.values()))
