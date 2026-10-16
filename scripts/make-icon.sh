#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p Resources/AppIcon.iconset
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
swift -module-cache-path "$PWD/.build/icon-module-cache" scripts/draw-icon.swift Resources/AppIcon-1024.png
for pixels in 16 32 128 256 512; do
    sips -s format png -z "$pixels" "$pixels" Resources/AppIcon-1024.png \
        --out "Resources/AppIcon.iconset/icon_${pixels}x${pixels}.png" >/dev/null
    double=$((pixels * 2))
    sips -s format png -z "$double" "$double" Resources/AppIcon-1024.png \
        --out "Resources/AppIcon.iconset/icon_${pixels}x${pixels}@2x.png" >/dev/null
done
python3 - <<'PYICNS'
from pathlib import Path
from struct import pack
root = Path('Resources/AppIcon.iconset')
entries = [('icp4', 'icon_16x16.png'), ('icp5', 'icon_32x32.png'),
           ('icp6', 'icon_32x32@2x.png'), ('ic07', 'icon_128x128.png'),
           ('ic08', 'icon_256x256.png'), ('ic09', 'icon_512x512.png'),
           ('ic10', 'icon_512x512@2x.png')]
chunks = []
for kind, filename in entries:
    payload = (root / filename).read_bytes()
    chunks.append(kind.encode('ascii') + pack('>I', len(payload) + 8) + payload)
body = b''.join(chunks)
Path('Resources/AppIcon.icns').write_bytes(b'icns' + pack('>I', len(body) + 8) + body)
PYICNS
rm -rf Resources/AppIcon.iconset
print "Готово: Resources/AppIcon.icns"
