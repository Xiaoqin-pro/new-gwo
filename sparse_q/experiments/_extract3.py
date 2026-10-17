import re, sys
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass
html = open(r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\refs\dmsgwo_nature.html", encoding="utf-8", errors="replace").read()
# find latex-like equation payloads
cands = re.findall(r'<span class="mathjax-tex">(.*?)</span>', html, flags=re.S)
if not cands:
    cands = re.findall(r'\\\((.*?)\\\)', html, flags=re.S)
if not cands:
    cands = re.findall(r'<math[^>]*>(.*?)</math>', html, flags=re.S)
print("equations found:", len(cands))
clean = []
for c in cands:
    c2 = re.sub(r"<[^>]+>", "", c)
    c2 = c2.replace("&nbsp;", " ").strip()
    if c2 and c2 not in clean:
        clean.append(c2)
for i, c in enumerate(clean[:80]):
    print(f"[{i}] {c[:160]}")
