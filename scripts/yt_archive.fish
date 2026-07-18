#!/usr/bin/env fish

# Archival-quality youtube download: one mkv with max-quality streams
# and thumbnail, metadata, chapters, subtitles, and info-json embedded,
# plus the standard info.json sidecar. Mirrors the capture project's
# yt-dlp settings.
#
# Usage: yt-archive <url> [extra yt-dlp args...]

if test (count $argv) -eq 0
    echo "usage: yt-archive <url> [extra yt-dlp args...]" >&2
    exit 2
end

set -l cookies "$HOME/.config/capture/youtube-cookies.txt"
set -l cookie_args
if test -f $cookies
    set cookie_args --cookies $cookies
end

yt-dlp --no-warnings $cookie_args \
    -f 'bestvideo*+bestaudio/best' \
    --merge-output-format mkv \
    --remux-video mkv \
    --embed-thumbnail \
    --embed-metadata \
    --embed-chapters \
    --embed-subs \
    --embed-info-json \
    --write-info-json \
    --sub-langs 'en,en-orig' \
    --write-auto-subs \
    --sponsorblock-mark all \
    -o '%(uploader)s - %(upload_date>%Y-%m-%d)s - %(title)s.%(ext)s' \
    $argv
