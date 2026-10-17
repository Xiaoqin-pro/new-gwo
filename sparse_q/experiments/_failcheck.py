import scipy.io as sio, glob, os
from collections import Counter
root = r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q"
b = sorted(glob.glob(os.path.join(root, 'results', 'freshv2_*')))[-1]
files = sorted(glob.glob(os.path.join(b, 'runs', 'run_*.mat')))
errs = Counter(); err_alg = Counter()
import numpy as np
T = None
for f in files:
    m = sio.loadmat(f, squeeze_me=True, struct_as_record=False)
    r = m['record']
    if str(getattr(r, 'status', '')) != 'ok':
        msg = str(getattr(r, 'error', ''))[:150]
        errs[msg] += 1
print("distinct errors:", len(errs))
for msg, c in errs.most_common(5):
    print(f"[{c}x] {msg}")
