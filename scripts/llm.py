#!/usr/bin/env python3
"""Simple CLI for making LLM requests via OpenRouter."""

import argparse
import base64
import json
import os
import sys
from urllib.request import Request, urlopen
from urllib.error import HTTPError

API_URL = "https://openrouter.ai/api/v1/chat/completions"
DEFAULT_MODEL = "google/gemini-3-flash-preview"


def get_mime_type(path: str) -> str:
    ext = path.lower().rsplit(".", 1)[-1]
    return {
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "gif": "image/gif",
        "webp": "image/webp",
        "pdf": "application/pdf",
    }.get(ext, "application/octet-stream")


def encode_file(path: str) -> tuple[str, str]:
    with open(path, "rb") as f:
        data = base64.b64encode(f.read()).decode()
    return get_mime_type(path), data


def build_content(prompt: str, attachments: list[str], stdin_text: str | None):
    parts = []

    if stdin_text:
        prompt = f"{stdin_text}\n\n{prompt}"

    parts.append({"type": "text", "text": prompt})

    for path in attachments:
        mime, data = encode_file(path)
        if mime.startswith("image/"):
            parts.append(
                {
                    "type": "image_url",
                    "image_url": {"url": f"data:{mime};base64,{data}"},
                }
            )
        elif mime == "application/pdf":
            parts.append(
                {
                    "type": "file",
                    "file": {
                        "filename": os.path.basename(path),
                        "file_data": f"data:{mime};base64,{data}",
                    },
                }
            )

    return parts


def call_api(content, model: str, api_key: str, schema: dict | None = None) -> str:
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": content}],
    }

    if schema:
        payload["response_format"] = {
            "type": "json_schema",
            "json_schema": {
                "name": schema.get("title", "response"),
                "strict": True,
                "schema": schema,
            },
        }

    req = Request(
        API_URL,
        data=json.dumps(payload).encode(),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
    )

    try:
        with urlopen(req) as resp:
            result = json.loads(resp.read())
            return result["choices"][0]["message"]["content"]
    except HTTPError as e:
        body = e.read().decode()
        sys.exit(f"API error {e.code}: {body}")


def main():
    parser = argparse.ArgumentParser(description="Query LLMs via OpenRouter")
    parser.add_argument("prompt", nargs="?", default="", help="The prompt to send")
    parser.add_argument(
        "-a", "--attach", action="append", default=[], help="Attach file (image or PDF)"
    )
    parser.add_argument(
        "-m",
        "--model",
        default=DEFAULT_MODEL,
        help=f"Model to use (default: {DEFAULT_MODEL})",
    )
    parser.add_argument(
        "--schema",
        metavar="FILE",
        help="JSON schema file for structured output",
    )
    args = parser.parse_args()

    api_key = os.environ.get("OPENROUTER_API_KEY")
    if not api_key:
        sys.exit("Error: OPENROUTER_API_KEY environment variable not set")

    stdin_text = None
    if not sys.stdin.isatty():
        stdin_text = sys.stdin.read()

    if not args.prompt and not stdin_text and not args.attach:
        sys.exit("Error: No prompt, stdin, or attachments provided")

    schema = None
    if args.schema:
        try:
            with open(args.schema) as f:
                schema = json.load(f)
        except (OSError, json.JSONDecodeError) as e:
            sys.exit(f"Error loading schema: {e}")

    prompt = args.prompt or ("Describe this" if args.attach else "")
    content = build_content(prompt, args.attach, stdin_text)
    result = call_api(content, args.model, api_key, schema)
    print(result)


if __name__ == "__main__":
    main()
