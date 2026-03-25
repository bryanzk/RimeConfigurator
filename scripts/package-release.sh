#!/usr/bin/env bash
# 构建 Release 并打包为可双击运行的 .app（当前架构，通常为 Apple Silicon）。
set -euo pipefail
export COPYFILE_DISABLE=1
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-0.1.1}"
ARCH="$(uname -m)"
OUT_ROOT="$ROOT/dist/RimeConfigurator-${VERSION}-macos-${ARCH}"
APP="$OUT_ROOT/RimeConfigurator.app"

swift build -c release

CANDIDATES=(
  "$ROOT/.build/arm64-apple-macosx/release/RimeConfigurator"
  "$ROOT/.build/x86_64-apple-macosx/release/RimeConfigurator"
  "$ROOT/.build/release/RimeConfigurator"
)
BIN=""
for p in "${CANDIDATES[@]}"; do
  if [[ -x "$p" ]]; then BIN="$p"; break; fi
done
if [[ -z "$BIN" ]]; then
  echo "error: release binary not found" >&2
  exit 1
fi

rm -rf "$OUT_ROOT"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/RimeConfigurator"
chmod +x "$APP/Contents/MacOS/RimeConfigurator"

ICONSET="$ROOT/dist/AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
SRC_ICON="$ROOT/Assets/app-icon-1024.png"
if [[ -f "$SRC_ICON" ]]; then
  for s in 16 32 128 256 512; do
    s2=$((s * 2))
    sips -z "$s" "$s" "$SRC_ICON" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null 2>&1
    sips -z "$s2" "$s2" "$SRC_ICON" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null 2>&1
  done
  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
fi

PLIST="$APP/Contents/Info.plist"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>zh-Hans</string>
	<key>CFBundleExecutable</key>
	<string>RimeConfigurator</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>dev.bryanzk.RimeConfigurator</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>RimeConfigurator</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION}</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
EOF

if [[ ! -f "$APP/Contents/Resources/AppIcon.icns" ]]; then
  /usr/libexec/PlistBuddy -c "Delete :CFBundleIconFile" "$PLIST" 2>/dev/null || true
fi

ZIP="$ROOT/dist/RimeConfigurator-${VERSION}-macos-${ARCH}.zip"
rm -f "$ZIP"
mkdir -p "$ROOT/dist"
find "$OUT_ROOT" -name '.DS_Store' -delete
find "$OUT_ROOT" -name '._*' -delete
xattr -cr "$OUT_ROOT" 2>/dev/null || true
(cd "$OUT_ROOT" && ditto -c -k --norsrc --keepParent RimeConfigurator.app "$ZIP")
echo "Built: $ZIP"
