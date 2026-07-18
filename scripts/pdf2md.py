#!/usr/bin/env python3
"""Convert PDFs to markdown via the Datalab Marker API.

Usage: pdf2md [-o DIR] <file.pdf> [more.pdf ...]

Writes <stem>.md (plus an images/ directory when the document has
figures) into the output directory, printing each markdown path to
stdout. Requires DATALAB_API_KEY in the environment or
~/.config/datalab/key. Stdlib only; curl does the HTTP.
"""

import argparse
import base64
import json
import os
import subprocess
import sys
import time
from pathlib import Path

SUBMIT_URL = "https://www.datalab.to/api/v1/marker"
POLL_SECONDS = 10
TIMEOUT_MINUTES = 30


def api_key() -> str:
    if key := os.environ.get("DATALAB_API_KEY"):
        return key
    keyfile = Path.home() / ".config" / "datalab" / "key"
    if keyfile.exists():
        return keyfile.read_text().strip()
    sys.exit("DATALAB_API_KEY not set (env var or ~/.config/datalab/key)")


def curl_json(args: list[str], key: str) -> dict:
    result = subprocess.run(
        ["curl", "-s", "--fail-with-body", "-H", f"X-Api-Key: {key}", *args],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        sys.exit(f"datalab request failed: {result.stdout[:300]}")
    return json.loads(result.stdout)


def main() -> None:
    parser = argparse.ArgumentParser(description="PDF to markdown via Datalab Marker")
    parser.add_argument("pdfs", type=Path, nargs="+", metavar="pdf")
    parser.add_argument("-o", "--output-dir", type=Path, default=Path("."))
    args = parser.parse_args()
    key = api_key()
    for pdf in args.pdfs:
        convert(pdf, args.output_dir, key)


def convert(pdf: Path, output_dir: Path, key: str) -> None:
    submitted = curl_json(
        [
            "-F", f"file=@{pdf};type=application/pdf",
            "-F", "output_format=markdown",
            "-F", "mode=accurate",
            SUBMIT_URL,
        ],
        key,
    )
    check_url = submitted.get("request_check_url") or sys.exit(
        f"unexpected submit response: {submitted}"
    )

    print(f"{pdf.name}: submitted, polling every {POLL_SECONDS}s...", file=sys.stderr)
    poll: dict = {}
    for _ in range(TIMEOUT_MINUTES * 60 // POLL_SECONDS):
        time.sleep(POLL_SECONDS)
        poll = curl_json([check_url], key)
        if poll.get("status") == "complete":
            break
    else:
        sys.exit("conversion timed out")
    if poll.get("success") is False or not poll.get("markdown"):
        sys.exit(f"conversion failed: {poll.get('error') or poll.get('status')}")

    markdown = poll["markdown"]
    output_dir.mkdir(parents=True, exist_ok=True)
    images = poll.get("images") or {}
    if images:
        image_dir = output_dir / "images"
        image_dir.mkdir(exist_ok=True)
        for name, encoded in images.items():
            (image_dir / Path(name).name).write_bytes(base64.b64decode(encoded))
            markdown = markdown.replace(f"]({name})", f"](images/{Path(name).name})")
            markdown = markdown.replace(
                f'src="{name}"', f'src="images/{Path(name).name}"'
            )

    out = output_dir / f"{pdf.stem}.md"
    out.write_text(markdown)
    # Best-effort formatting; unformatted markdown is still markdown.
    formatted = subprocess.run(
        ["dprint", "fmt", "--stdin", "md"],
        input=out.read_text(),
        capture_output=True,
        text=True,
    )
    if formatted.returncode == 0 and formatted.stdout:
        out.write_text(formatted.stdout)
    print(out)


if __name__ == "__main__":
    main()
