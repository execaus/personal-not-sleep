#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"

export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
zsh scripts/make-icon.sh
swift build --disable-sandbox -c release --product PersonalNotSleep
bin_path="$(swift build --disable-sandbox -c release --show-bin-path)/PersonalNotSleep"
app_path="$PWD/dist/PersonalNotSleep.app"
rm -rf "$app_path"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Frameworks" "$app_path/Contents/Resources"
cp "$bin_path" "$app_path/Contents/MacOS/PersonalNotSleep"
ditto .build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework \
    "$app_path/Contents/Frameworks/Sparkle.framework"
cp Resources/AppIcon.icns "$app_path/Contents/Resources/AppIcon.icns"
cp Vendor/Sparkle-LICENSE "$app_path/Contents/Resources/Sparkle-LICENSE"
install_name_tool -add_rpath @executable_path/../Frameworks "$app_path/Contents/MacOS/PersonalNotSleep"
cat > "$app_path/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleDevelopmentRegion</key><string>ru</string>
<key>CFBundleExecutable</key><string>PersonalNotSleep</string>
<key>CFBundleIdentifier</key><string>com.execaus.PersonalNotSleep</string>
<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
<key>CFBundleName</key><string>Personal Not Sleep</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.2.0</string>
<key>CFBundleVersion</key><string>2</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>SUFeedURL</key><string>https://github.com/execaus/personal-not-sleep/releases/latest/download/appcast.xml</string>
<key>SUPublicEDKey</key><string>jd2dzsBvwNVU1y5em5sVCpeofNic45HWNpW+JdoKQWU=</string>
<key>SUEnableAutomaticChecks</key><false/>
<key>SUAllowsAutomaticUpdates</key><false/>
<key>SUEnableSystemProfiling</key><false/>
<key>SUVerifyUpdateBeforeExtraction</key><true/>
<key>SURequireSignedFeed</key><true/>
<key>SUSignedFeedFailureExpirationInterval</key><integer>0</integer>
</dict></plist>
PLIST
xattr -rc "$app_path"
codesign --force --sign - --deep "$app_path/Contents/Frameworks/Sparkle.framework"
xattr -rc "$app_path"
codesign --force --sign - --identifier com.execaus.PersonalNotSleep "$app_path"
codesign --verify --strict "$app_path"
print "Готово: $app_path"
