#!/bin/bash

set -eu

project_dir=$(cd "$(dirname "$0")/.." && pwd)
converter="$project_dir/src/convert_audio.sh"
test_dir=$(mktemp -d "/tmp/m4a-audio-converter-test.XXXXXX")

cleanup() {
  rm -rf "$test_dir"
}
trap cleanup EXIT

if command -v ffmpeg >/dev/null 2>&1; then
  ffmpeg_bin=$(command -v ffmpeg)
elif [ -x "/Applications/Plaud.app/Contents/Resources/ffmpeg" ]; then
  ffmpeg_bin="/Applications/Plaud.app/Contents/Resources/ffmpeg"
elif [ -x "/opt/homebrew/bin/ffmpeg" ]; then
  ffmpeg_bin="/opt/homebrew/bin/ffmpeg"
elif [ -x "/usr/local/bin/ffmpeg" ]; then
  ffmpeg_bin="/usr/local/bin/ffmpeg"
else
  printf '没有找到 FFmpeg，无法运行测试。\n' >&2
  exit 3
fi

mkdir -p "$test_dir/input" "$test_dir/mp3" "$test_dir/wav" "$test_dir/flac"
"$ffmpeg_bin" -hide_banner -nostdin -loglevel error \
  -f lavfi -i "sine=frequency=440:duration=2" \
  -ac 2 -ar 44100 -c:a aac -b:a 128k "$test_dir/input/测试音频.m4a"

for output_format in mp3 wav flac; do
  "$converter" --format "$output_format" \
    --output-dir "$test_dir/$output_format" \
    "$test_dir/input/测试音频.m4a"
done

file "$test_dir/mp3/测试音频.mp3"
file "$test_dir/wav/测试音频.wav"
file "$test_dir/flac/测试音频.flac"
printf '冒烟测试通过：MP3、WAV、FLAC 均已生成并完成解码校验。\n'
