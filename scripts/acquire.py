"""Download NHIS public-use files and documentation from CDC's annual pages.

Standard-library downloader; pypdf is used only for searchable documentation.
No restricted data, acceptance clicks, or authenticated services are used.
"""
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from hashlib import sha256
from html import unescape
from pathlib import Path
from urllib.parse import urljoin, urlparse
from urllib.request import Request, urlopen
from urllib.error import HTTPError
import json
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
YEARS = range(2019, 2026)


def get(url, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        with urlopen(Request(url, headers={"User-Agent": "NHIS-public-research/1.0"}), timeout=90) as response:
            payload = response.read()
        temp = path.with_suffix(path.suffix + ".part")
        temp.write_bytes(payload)
        temp.replace(path)
    payload = path.read_bytes()
    if path.suffix == ".zip":
        with zipfile.ZipFile(path) as z:
            if z.testzip():
                raise ValueError(f"Corrupt ZIP: {path}")
    if path.suffix == ".pdf" and not payload.startswith(b"%PDF"):
        raise ValueError(f"Not a PDF: {path}")
    return {"url": url, "path": path.relative_to(ROOT).as_posix(),
            "bytes": len(payload), "sha256": sha256(payload).hexdigest()}


def discover(year):
    url = f"https://www.cdc.gov/nchs/nhis/documentation/{year}-nhis.html"
    page = ROOT / "data" / "documentation" / str(year) / "index.html"
    try:
        receipt = get(url, page)
    except HTTPError as error:
        if error.code != 403:
            raise
        # CDC's HTML front end may block command-line clients. Its public FTP
        # HTTPS endpoints are the documented distribution route for the files.
        base = "https://ftp.cdc.gov/pub/Health_Statistics/NCHS/"
        yy = str(year)[-2:]
        return year, {"url": url, "status": "HTML returned HTTP 403; direct public distribution URLs used"}, {
            "adult": f"{base}Datasets/NHIS/{year}/adult{yy}csv.zip",
            "income": f"{base}Datasets/NHIS/{year}/adultinc{yy}csv.zip",
            "codebook": f"{base}Dataset_Documentation/NHIS/{year}/adult-codebook.pdf",
            "survey_description": f"{base}Dataset_Documentation/NHIS/{year}/srvydesc-508.pdf"}
    html = page.read_text(encoding="utf-8")
    links = [(urljoin(url, unescape(h)), re.sub("<[^>]+>", "", t).strip())
             for h, t in re.findall(r'<a\b[^>]*href=[\"\']([^\"\']+)[\"\'][^>]*>(.*?)</a>', html, re.S | re.I)]
    selected = {}
    for link, title in links:
        name = Path(urlparse(link).path).name.lower()
        if urlparse(link).hostname != "ftp.cdc.gov":
            continue
        if name == f"adult{str(year)[-2:]}csv.zip":
            selected["adult"] = link
        elif name == f"adultinc{str(year)[-2:]}csv.zip":
            selected["income"] = link
        elif name == "adult-codebook.pdf":
            selected["codebook"] = link
        elif name == "srvydesc-508.pdf":
            selected["survey_description"] = link
        elif name.startswith("imputed-income") and name.endswith(".pdf"):
            selected["income_documentation"] = link
    if "adult" not in selected or "codebook" not in selected:
        raise ValueError(f"Required links not found for {year}: {selected}; links={links}")
    return year, receipt, selected


def main():
    receipts, downloads = [], []
    with ThreadPoolExecutor(max_workers=4) as pool:
        for future in as_completed([pool.submit(discover, y) for y in YEARS]):
            year, receipt, selected = future.result()
            receipts.append({"year": year, "kind": "index", **receipt})
            print(f"Discovered {year}: {', '.join(selected)}", flush=True)
            for kind, url in selected.items():
                folder = "raw" if kind in ("adult", "income") else "documentation"
                path = ROOT / "data" / folder / str(year) / Path(urlparse(url).path).name
                downloads.append((year, kind, url, path))
        pending = {pool.submit(get, url, path): (year, kind) for year, kind, url, path in downloads}
        for future in as_completed(pending):
            year, kind = pending[future]
            result = future.result()
            receipts.append({"year": year, "kind": kind, **result})
            print(f"Ready {year} {kind}: {result['bytes']:,} bytes", flush=True)
    out = ROOT / "outputs"
    out.mkdir(exist_ok=True)
    (out / "source_manifest.json").write_text(json.dumps({
        "checked_utc": datetime.now(timezone.utc).isoformat(),
        "files": sorted(receipts, key=lambda x: (x["year"], x["kind"]))}, indent=2), encoding="utf-8")
    print("Acquisition complete. Run extract_crosswalk.py for searchable documentation.", flush=True)


if __name__ == "__main__":
    main()
