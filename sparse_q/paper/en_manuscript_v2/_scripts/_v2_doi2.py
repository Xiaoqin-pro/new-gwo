import json, urllib.request
url = "https://api.crossref.org/works/10.1038/s41598-025-33301-2"
with urllib.request.urlopen(url, timeout=30) as r:
    m = json.load(r)["message"]
for k in ["article-number","alternative-id","volume","issue","page","published","published-online","issued","URL"]:
    print(k, "=", m.get(k))
