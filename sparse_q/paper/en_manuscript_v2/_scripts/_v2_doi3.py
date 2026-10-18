import json, urllib.request, urllib.parse
q = urllib.parse.quote("Comprehensive learning particle swarm optimizer for global optimization of multimodal functions")
url = f"https://api.crossref.org/works?query.bibliographic={q}&rows=3&select=DOI,title,volume,page,issued,container-title"
with urllib.request.urlopen(url, timeout=30) as r:
    d = json.load(r)["message"]["items"]
for it in d:
    print(it.get("DOI"), "|", (it.get("title") or [""])[0][:80], "|", it.get("volume"), it.get("page"), (it.get("issued",{}).get("date-parts") or [[None]])[0][0])
