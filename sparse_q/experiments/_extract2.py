import re, sys
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass
html = open(r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\refs\dmsgwo_nature.html", encoding="utf-8", errors="replace").read()
text = re.sub(r"<script.*?</script>|<style.*?</style>", " ", html, flags=re.S)
text = re.sub(r"<[^>]+>", " ", text)
text = re.sub(r"&nbsp;|&#x[0-9a-fA-F]+;?", " ", text)
text = re.sub(r"\s+", " ", text)
# find the method sections: nonlinear convergence factor, grouping, exploration update, exploitation update
for kw in ["adaptive disturbance", "adaptive perturbation position update strategy", "exploration group", "N_{1}", "nonlinear convergence factor is", "probability"]:
    for m in list(re.finditer(re.escape(kw), text, re.I))[:2]:
        i = m.start()
        print(f"===== {kw} @ {i} =====")
        print(text[max(0,i-500):i+1500])
        print()
