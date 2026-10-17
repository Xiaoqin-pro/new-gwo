import json, sys, time, urllib.parse, urllib.request
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass
def crossref(q, rows=6):
    url = ("https://api.crossref.org/works?query.bibliographic=" + urllib.parse.quote(q)
           + f"&rows={rows}&select=title,author,issued,container-title,DOI,is-referenced-by-count")
    req = urllib.request.Request(url, headers={"User-Agent": "sparse-q-research/1.0 (mailto:research@example.com)"})
    with urllib.request.urlopen(req, timeout=45) as r:
        return json.loads(r.read().decode("utf-8"))["message"]["items"]
for q in ["QLFDGWO", "strengthened grey wolf optimization AutoML", "grey wolf optimizer expensive optimization surrogate"]:
    for attempt in range(3):
        try:
            items = crossref(q); break
        except Exception as e:
            print("retry", e); time.sleep(20); items=[]
    print("="*100); print("QUERY:", q)
    for it in items:
        title=(it.get("title") or [""])[0]
        au=", ".join(f"{a.get('family','')} {a.get('given','')[:1]}." for a in (it.get("author") or [])[:3])
        yr=(it.get("issued",{}).get("date-parts",[[None]])[0][0])
        ven=(it.get("container-title") or [""])[0]
        print(f"- {yr} | {title}")
        print(f"    {au} | {ven} | doi:{it.get('DOI')} | cited:{it.get('is-referenced-by-count')}")
    time.sleep(15)
