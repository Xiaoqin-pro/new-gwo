# -*- coding: utf-8 -*-
import re, json, time, urllib.request
p = r"D:\111\Desktop\噜噜\基础版狼群\文章\VAST-GWO_EN_v2\references.bib"
t = open(p, encoding="utf-8").read()
blocks = re.split(r"(?=@\w+\{)", t)
blocks = [b for b in blocks if b.strip().startswith("@")]
print("entries:", len(blocks))
def norm(s): return re.sub(r"[^a-z0-9 ]", " ", s.lower())
for b in blocks:
    key = re.match(r"@\w+\{([^,]+),", b).group(1)
    doi = re.search(r"doi\s*=\s*\{([^}]+)\}", b)
    title = re.search(r"title\s*=\s*\{(.+?)\}\s*,\s*\n", b, re.S) or re.search(r"title\s*=\s*\{(.+?)\},", b, re.S)
    ttl = " ".join(title.group(1).split()) if title else "?"
    if not doi:
        print(f"{'NO-DOI':10s} {key:26s} {ttl[:70]}"); continue
    try:
        with urllib.request.urlopen("https://api.crossref.org/works/"+doi.group(1), timeout=25) as r:
            m = json.load(r)["message"]
        ct = (m.get("title") or [""])[0]
        ok = norm(ttl)[:35] in norm(ct) or norm(ct)[:35] in norm(ttl)
        yr = (m.get("issued",{}).get("date-parts") or [[None]])[0][0]
        vol = m.get("volume"); pg = m.get("page") or m.get("article-number")
        flag = "OK" if ok else "MISMATCH"
        print(f"{flag:10s} {key:26s} cr_year={yr} vol={vol} page={pg} | bib: {ttl[:55]} | cr: {ct[:55]}")
    except Exception as e:
        print(f"{'ERR':10s} {key:26s} {str(e)[:70]}")
    time.sleep(0.12)
