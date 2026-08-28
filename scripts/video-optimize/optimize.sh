#!/usr/bin/env bash
# Inspect a local MP4 and write a new remuxed/transcoded file. Never overwrites the input.
set -euo pipefail

usage() {
  echo "Usage: $0 <input.mp4> <output.mp4> [--transcode]" >&2
  exit 2
}

[[ $# -lt 2 ]] && usage
input=$1
output=$2
transcode=0
[[ "${3:-}" == "--transcode" ]] && transcode=1

if [[ ! -f "$input" ]]; then
  echo "input missing: $input" >&2
  exit 1
fi
if [[ -e "$output" ]]; then
  echo "refusing to overwrite $output" >&2
  exit 1
fi

command -v ffprobe >/dev/null
command -v ffmpeg >/dev/null

video_codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$input")
audio_codec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$input" || true)

if [[ $transcode -eq 0 && "$video_codec" == "h264" && ( -z "$audio_codec" || "$audio_codec" == "aac" ) ]]; then
  ffmpeg -hide_banner -loglevel error -i "$input" -c copy -movflags +faststart "$output"
else
  ffmpeg -hide_banner -loglevel error -i "$input" \
    -vf "scale=-2:'min(1080,ih)'" -c:v libx264 -preset veryfast -b:v 3M \
    -c:a aac -b:a 128k -movflags +faststart "$output"
fi

python3 - "$input" "$output" <<'PY'
import sys
from pathlib import Path
src = Path(sys.argv[1]).stat().st_size
dst = Path(sys.argv[2]).stat().st_size
data = Path(sys.argv[2]).read_bytes()
print(f"ok input={src} output={dst} moov={data.find(b'moov')} mdat={data.find(b'mdat')}")
if dst > src * 1.25:
    raise SystemExit("output unexpectedly larger than input")
PY
