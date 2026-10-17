import json, urllib.parse, urllib.request, time
def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "sparse-q-research/1.0 (mailto:research@example.com)"})
    with urllib.request.urlopen(req, timeout=40) as r:
        return r.read().decode("utf-8", "replace")
tests = {
 "crossref": "https://api.crossref.org/works?query.bibliographic=grey+wolf+optimizer+dimension+learning&rows=3",
 "arxiv": "http://export.arxiv.org/api/query?search_query=all:%22grey%20wolf%20optimizer%22&max_results=3",
 "openalex1": "https://api.openalex.org/works?search=grey%20wolf%20optimizer&per-page=2&mailto=sparseq@example.org",
}
for name, url in tests.items():
    try:
        t = fetch(url)
        print(f"{name}: OK ({len(t)} chars)")
        print(t[:400].replace("\n"," "))
    except Exception as e:
        print(f"{name}: FAIL {e}")
    print("-"*80)
    time.sleep(3)
