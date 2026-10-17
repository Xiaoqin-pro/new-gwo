import json, sys, time, urllib.request, urllib.parse
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass
def gh(q):
    url = "https://api.github.com/search/repositories?q=" + urllib.parse.quote(q) + "&per_page=5"
    req = urllib.request.Request(url, headers={"User-Agent": "research-agent", "Accept": "application/vnd.github+json"})
    with urllib.request.urlopen(req, timeout=45) as r:
        return json.loads(r.read().decode("utf-8"))
for q in ["MELGWO", "QLFDGWO", "DMSGWO grey wolf", "grey wolf optimizer memory evolutionary operator local search"]:
    try:
        res = gh(q)
        print("="*90); print("QUERY:", q, "| total:", res.get("total_count"))
        for it in res.get("items", [])[:5]:
            print(f"- {it['full_name']}  stars={it['stargazers_count']}  {it.get('description','')[:110]}")
            print(f"    {it['html_url']}")
    except Exception as e:
        print("QUERY:", q, "FAILED:", e)
    time.sleep(3)
