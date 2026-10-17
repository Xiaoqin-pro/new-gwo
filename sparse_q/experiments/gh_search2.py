import json, sys, time, urllib.request, urllib.parse
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass
def gh(q):
    url = "https://api.github.com/search/repositories?q=" + urllib.parse.quote(q) + "&per_page=8"
    req = urllib.request.Request(url, headers={"User-Agent": "research-agent", "Accept": "application/vnd.github+json"})
    with urllib.request.urlopen(req, timeout=45) as r:
        return json.loads(r.read().decode("utf-8"))
for q in ["MELGWO", "memory evolutionary local search grey wolf", "RL-LGWO", "reinforcement learning grey wolf optimizer"]:
    try:
        res = gh(q)
        print("="*80); print("Q:", q, "total:", res.get("total_count"))
        for it in res.get("items", [])[:8]:
            print(f"- {it['full_name']} stars={it['stargazers_count']} {str(it.get('description'))[:90]}")
    except Exception as e:
        print("Q:", q, "ERR", e)
    time.sleep(2)
