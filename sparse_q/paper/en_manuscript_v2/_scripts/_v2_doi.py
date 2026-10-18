import json, urllib.request
def q(doi):
    url = "https://api.crossref.org/works/" + doi
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            d = json.load(r)["message"]
        return dict(doi=d.get("DOI"), title=(d.get("title") or [""])[0], journal=(d.get("container-title") or [""])[0],
                    vol=d.get("volume"), page=d.get("page"), year=(d.get("issued",{}).get("date-parts") or [[None]])[0][0])
    except Exception as e:
        return {"doi": doi, "error": str(e)}
for doi in ["10.1016/j.eswa.2020.114170","10.1016/j.eswa.2020.113917","10.1038/s41598-025-33301-2","10.3390/math14163011","10.1016/j.iot.2024.101135"]:
    print(q(doi))
