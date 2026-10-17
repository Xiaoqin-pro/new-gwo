import re, sys
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass
html = open(r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\refs\dmsgwo_nature.html", encoding="utf-8", errors="replace").read()
text = re.sub(r"<script.*?</script>|<style.*?</style>", " ", html, flags=re.S)
text = re.sub(r"<[^>]+>", " ", text)
text = re.sub(r"\s+", " ", text)
# find method-ish keywords
for kw in ["exploration group", "exploitation group", "Levy", "dimension learning", "dynamic population", "n1", "multi-strategy"]:
    idxs = [m.start() for m in re.finditer(kw, text, re.I)][:3]
    for i in idxs:
        print(f"--- {kw} @ {i} ---")
        print(text[max(0,i-350):i+650])
        print()
