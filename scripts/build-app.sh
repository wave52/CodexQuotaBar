#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
app_dir="$project_dir/dist/Codex Quota Bar.app"
binary_dir="$app_dir/Contents/MacOS"

cd "$project_dir"
swift build -c release

bash scripts/build-icon.sh
mkdir -p "$binary_dir" "$app_dir/Contents/Resources"
cp "$project_dir/Resources/AppIcon.icns" "$app_dir/Contents/Resources/AppIcon.icns"
cp ".build/release/CodexQuotaBar" "$binary_dir/CodexQuotaBar"
cp "$project_dir/Resources/Info.plist" "$app_dir/Contents/Info.plist"

codesign --force --deep --sign - "$app_dir"
codesign --verify --strict "$app_dir"
echo "$app_dir"
