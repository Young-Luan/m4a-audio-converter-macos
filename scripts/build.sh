#!/bin/bash

set -eu

project_dir=$(cd "$(dirname "$0")/.." && pwd)
source_dir="$project_dir/src"
dist_dir="$project_dir/dist"
temporary_dir=$(mktemp -d "/tmp/m4a-audio-converter-build.XXXXXX")
temporary_app="$temporary_dir/M4A音频转换器.app"
temporary_zip="$temporary_dir/M4A音频转换器-Mac.zip"
final_zip="$dist_dir/M4A音频转换器-Mac.zip"

cleanup() {
  rm -rf "$temporary_dir"
}
trap cleanup EXIT

bash -n "$source_dir/convert_audio.sh"
osacompile -l JavaScript -o "$temporary_app" "$source_dir/M4A音频转换器.js"
cp "$source_dir/convert_audio.sh" "$temporary_app/Contents/Resources/convert_audio.sh"
chmod +x "$temporary_app/Contents/Resources/convert_audio.sh"

/usr/libexec/PlistBuddy -c 'Add :CFBundleIdentifier string com.yangyang.m4a-audio-converter' "$temporary_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleShortVersionString string 1.0.0' "$temporary_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleVersion string 1' "$temporary_app/Contents/Info.plist"

xattr -cr "$temporary_app"
codesign --force --deep --sign - "$temporary_app"
codesign --verify --deep --strict "$temporary_app"

mkdir -p "$dist_dir"
rm -f "$final_zip"

package_dir="$temporary_dir/M4A音频转换器"
mkdir -p "$package_dir"
ditto --noextattr --noacl --norsrc "$temporary_app" "$package_dir/M4A音频转换器.app"
cp "$project_dir/使用说明.txt" "$package_dir/使用说明.txt"
ditto -c -k --keepParent --norsrc "$package_dir" "$temporary_zip"
unzip -t "$temporary_zip" >/dev/null

verification_dir="$temporary_dir/verification"
mkdir -p "$verification_dir"
ditto -x -k "$temporary_zip" "$verification_dir"
codesign --verify --deep --strict "$verification_dir/M4A音频转换器/M4A音频转换器.app"

cp "$temporary_zip" "$final_zip"
unzip -t "$final_zip" >/dev/null

printf '构建完成：\n%s\n' "$final_zip"
shasum -a 256 "$final_zip"
