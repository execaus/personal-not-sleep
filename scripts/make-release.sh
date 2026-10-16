#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
zsh scripts/make-app.sh
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' dist/PersonalNotSleep.app/Contents/Info.plist)"
archive="release/PersonalNotSleep-${version}-macos-arm64.zip"
notes="release/PersonalNotSleep-${version}-macos-arm64.md"
mkdir -p release
cp "release/v${version}.md" "$notes"
trap 'rm -f "$notes"' EXIT
rm -f "$archive"
ditto --norsrc --noextattr --noqtn --noacl -c -k --keepParent \
    dist/PersonalNotSleep.app "$archive"
verification="$(mktemp -d /private/tmp/personal-not-sleep-release.XXXXXX)"
trap 'rm -rf "$verification"; rm -f "$notes"' EXIT
ditto -x -k "$archive" "$verification"
xattr -rc "$verification/PersonalNotSleep.app"
codesign --verify --deep --strict "$verification/PersonalNotSleep.app"
.build/artifacts/sparkle/Sparkle/bin/generate_appcast \
    --account personal-not-sleep \
    --download-url-prefix "https://github.com/execaus/personal-not-sleep/releases/download/v${version}/" \
    --embed-release-notes \
    -o release/appcast.xml release
.build/artifacts/sparkle/Sparkle/bin/sign_update --verify \
    --account personal-not-sleep release/appcast.xml
signature="$(python3 - <<'PYSIGNATURE'
import xml.etree.ElementTree as ET
root = ET.parse('release/appcast.xml').getroot()
enclosure = root.find('./channel/item/enclosure')
if enclosure is None:
    raise SystemExit('No update archive in appcast')
print(enclosure.attrib['{http://www.andymatuschak.org/xml-namespaces/sparkle}edSignature'])
PYSIGNATURE
)"
.build/artifacts/sparkle/Sparkle/bin/sign_update --verify \
    --account personal-not-sleep "$archive" "$signature"
shasum -a 256 "$archive" > release/SHA256SUMS
print "Готово: $archive и подписанная release/appcast.xml"
