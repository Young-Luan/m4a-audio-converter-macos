#!/bin/bash

set -u

usage() {
  cat <<'EOF'
用法：convert_audio.sh --format mp3|wav|flac --output-dir 输出目录 文件1.m4a [文件2.m4a ...]

转换不会覆盖原文件；如果目标文件已存在，会自动添加序号。
EOF
}

find_ffmpeg() {
  if command -v ffmpeg >/dev/null 2>&1; then
    command -v ffmpeg
    return 0
  fi

  for candidate in \
    "/Applications/Plaud.app/Contents/Resources/ffmpeg" \
    "/opt/homebrew/bin/ffmpeg" \
    "/usr/local/bin/ffmpeg"; do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

unique_output_path() {
  output_dir=$1
  base_name=$2
  extension=$3
  candidate="$output_dir/$base_name.$extension"
  sequence=2

  while [ -e "$candidate" ]; do
    candidate="$output_dir/${base_name}-${sequence}.$extension"
    sequence=$((sequence + 1))
  done

  printf '%s\n' "$candidate"
}

format=""
output_dir=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --format)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      format=$2
      shift 2
      ;;
    --output-dir)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      output_dir=$2
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -* )
      printf '不支持的参数：%s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

case "$format" in
  mp3|wav|flac) ;;
  *)
    printf '请选择输出格式：mp3、wav 或 flac。\n' >&2
    exit 2
    ;;
esac

if [ -z "$output_dir" ] || [ "$#" -eq 0 ]; then
  usage >&2
  exit 2
fi

ffmpeg_bin=$(find_ffmpeg) || {
  printf '没有找到可用的 FFmpeg。请保留 Plaud.app，或安装 FFmpeg。\n' >&2
  exit 3
}

mkdir -p "$output_dir" || {
  printf '无法创建输出文件夹：%s\n' "$output_dir" >&2
  exit 4
}

converted=0
failed=0

for input_path in "$@"; do
  if [ ! -f "$input_path" ]; then
    printf '跳过，不是有效文件：%s\n' "$input_path" >&2
    failed=$((failed + 1))
    continue
  fi

  input_name=$(basename "$input_path")
  input_extension=${input_name##*.}
  if [ "$input_extension" = "$input_name" ]; then
    base_name=$input_name
  else
    base_name=${input_name%.*}
  fi
  output_path=$(unique_output_path "$output_dir" "$base_name" "$format")

  case "$format" in
    mp3)
      codec_args="-c:a libmp3lame -b:a 256k"
      ;;
    wav)
      codec_args="-c:a pcm_s16le"
      ;;
    flac)
      codec_args="-c:a flac -compression_level 8"
      ;;
  esac

  # codec_args 只包含上方固定参数；这里有意进行单词拆分。
  # shellcheck disable=SC2086
  if ! "$ffmpeg_bin" -hide_banner -nostdin -loglevel error -i "$input_path" \
      -map 0:a:0 -vn -map_metadata 0 $codec_args "$output_path"; then
    printf '转换失败：%s\n' "$input_path" >&2
    rm -f "$output_path"
    failed=$((failed + 1))
    continue
  fi

  # 完整解码输出文件，确认它不只是“生成了”，而是真的能被读取。
  if ! "$ffmpeg_bin" -hide_banner -nostdin -v error -i "$output_path" -f null -; then
    printf '校验失败：%s\n' "$output_path" >&2
    rm -f "$output_path"
    failed=$((failed + 1))
    continue
  fi

  if [ ! -s "$output_path" ]; then
    printf '校验失败，输出文件为空：%s\n' "$output_path" >&2
    rm -f "$output_path"
    failed=$((failed + 1))
    continue
  fi

  printf '已完成：%s\n' "$output_path"
  converted=$((converted + 1))
done

printf '转换完成：成功 %d 个，失败 %d 个。\n' "$converted" "$failed"

[ "$failed" -eq 0 ]
