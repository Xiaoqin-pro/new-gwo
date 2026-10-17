import json, sys, urllib.parse, urllib.request, time
try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass
def crossref(q, rows=6):
    url = ("https://api.crossref.org/works?query.bibliographic=" + urllib.parse.quote(q)
           + f"&rows={rows}&select=title,author,issued,container-title,DOI,is-referenced-by-count")
    req = urllib.request.Request(url, headers={"User-Agent": "sparse-q-research/1.0 (mailto:research@example.com)"})
    with urllib.request.urlopen(req, timeout=45) as r:
        return json.loads(r.read().decode("utf-8"))["message"]["items"]
queries = [
 "Q-learning grey wolf optimizer adaptive",
 "improved grey wolf optimizer dimension learning Nadimi-Shahraki",
 "dynamic multi-strategy grey wolf optimizer",
 "reinforcement learning leadership grey wolf optimizer",
 "multiple populations grey wolf optimizer dimension learning Laplace mutation",
 "strengthened grey wolf optimization AutoML",
 "sparse evaluation expensive optimization particle swarm screening",
 "heterogeneous comprehensive learning particle swarm optimization",
]
out = {}
for q in queries:
    try:
        items = crossref(q)
    except Exception as e:
        print("ERR", q, e); items = []
    print("="*100); print("QUERY:", q)
    for it in items:
        title = (it.get("title") or [""])[0]
        au = ", ".join(f"{a.get('family','')} {a.get('given','')[:1]}." for a in (it.get("author") or [])[:3])
        yr = (it.get("issued", {}).get("date-parts", [[None]])[0][0])
        ven = (it.get("container-title") or [""])[0]
        print(f"- {yr} | {title}")
        print(f"    {au} | {ven} | doi:{it.get('DOI')} | cited:{it.get('is-referenced-by-count')}")
    out[q] = items
    time.sleep(2)
with open(r"D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\sparse_q\experiments\lit_results.json", "w", encoding="utf-8") as fh:
    json.dump(out, fh, ensure_ascii=False, indent=1)
print("\nsaved lit_results.json")

