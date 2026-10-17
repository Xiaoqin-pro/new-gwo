import json, re, sys, urllib.request, urllib.parse
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass
def fetch(url, timeout=45):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (research)"} )
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode("utf-8", "replace")
# 1) MELGWO File Exchange page
try:
    html = fetch("https://www.mathworks.com/matlabcentral/fileexchange/123675-melgwo-gwo-with-memory-evolutionary-operator-local-search")
    print("FEX page OK, len", len(html))
    m = re.findall(r'mlc-downloads/downloads/[^"\']+', html)
    print("download links:", m[:3])
    m2 = re.findall(r'/matlabcentral/fileexchange/123675[^"\']*', html)
    print("page links:", list(dict.fromkeys(m2))[:5])
except Exception as e:
    print("FEX fetch failed:", e)
# 2) SSRN preprint for RL-LGWO
try:
    html = fetch("https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5196138")
    print("\nSSRN page OK, len", len(html))
    m = re.findall(r'(https?://[^"\']+\.pdf[^"\']*)', html)
    print("pdf links:", m[:3])
except Exception as e:
    print("SSRN fetch failed:", e)
