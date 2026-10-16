#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"

export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
swift build --disable-sandbox -c release --product PersonalNotSleep
bin_path="$(swift build --disable-sandbox -c release --show-bin-path)/PersonalNotSleep"
app_path="$PWD/dist/PersonalNotSleep.app"
rm -rf "$app_path"
mkdir -p "$app_path/Contents/MacOS"
cp "$bin_path" "$app_path/Contents/MacOS/PersonalNotSleep"
cat > "$app_path/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleDevelopmentRegion</key><string>ru</string>
<key>CFBundleExecutable</key><string>PersonalNotSleep</string>
<key>CFBundleIdentifier</key><string>com.execaus.PersonalNotSleep</string>
<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
<key>CFBundleName</key><string>Personal Not Sleep</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
</dict></plist>
PLIST
xattr -rc "$app_path"
codesign --force --sign - --identifier com.execaus.PersonalNotSleep "$app_path"
codesign --verify --strict "$app_path"
print "Готово: $app_path"
