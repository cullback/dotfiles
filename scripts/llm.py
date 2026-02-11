#!/usr/bin/env python3
"""Simple CLI for making LLM requests via OpenRouter."""

import argparse
import base64
import json
import mimetypes
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

API_URL = "https://openrouter.ai/api/v1/chat/completions"
DEFAULT_MODEL = "google/gemini-3-flash-preview"


class LLMError(Exception):
    """Error from LLM API call."""

    pass


def get_mime_type(file_path: Path) -> str:
    """Get MIME type for a file based on extension."""
    mime_type, _ = mimetypes.guess_type(str(file_path))
    if mime_type is None:
        raise ValueError(f"Cannot determine MIME type for: {file_path}")
    return mime_type


def encode_file(file_path: Path) -> str:
    """Base64 encode a file's contents."""
    with open(file_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def build_content(
    prompt: str,
    attachments: list[Path] | None = None,
    stdin_text: str | None = None,
) -> list[dict]:
    """Build the content array for an API request."""
    content = []

    # Add attachments first (images/documents before text)
    if attachments:
        for file_path in attachments:
            mime_type = get_mime_type(file_path)
            encoded = encode_file(file_path)
            data_url = f"data:{mime_type};base64,{encoded}"

            if mime_type.startswith("image/"):
                content.append({"type": "image_url", "image_url": {"url": data_url}})
            else:
                content.append(
                    {
                        "type": "file",
                        "file": {
                            "filename": file_path.name,
                            "file_data": data_url,
                        },
                    }
                )

    # Combine stdin and prompt
    text = prompt
    if stdin_text:
        text = f"{stdin_text}\n\n{prompt}" if prompt else stdin_text

    content.append({"type": "text", "text": text})
    return content


def call_api(
    content: list[dict],
    model: str,
    api_key: str,
    schema: dict | None = None,
) -> str:
    """Call the OpenRouter API."""
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": content}],
    }

    if schema is not None:
        payload["response_format"] = {
            "type": "json_schema",
            "json_schema": {
                "name": schema.get("title", "response"),
                "strict": True,
                "schema": schema,
            },
        }

    request = urllib.request.Request(
        API_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            data = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        raise LLMError(f"API request failed ({e.code}): {body}") from e
    except urllib.error.URLError as e:
        raise LLMError(f"Network error: {e.reason}") from e

    try:
        return data["choices"][0]["message"]["content"]
    except (KeyError, IndexError) as e:
        raise LLMError(f"Unexpected API response format: {data}") from e


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
    attachments = [Path(p) for p in args.attach] if args.attach else None

    try:
        content = build_content(prompt, attachments, stdin_text)
        result = call_api(content, args.model, api_key, schema)
        print(result)
    except (LLMError, ValueError, FileNotFoundError) as e:
        sys.exit(f"Error: {e}")


if __name__ == "__main__":
    main()
