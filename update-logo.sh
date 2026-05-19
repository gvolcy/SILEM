#!/usr/bin/env bash
# Usage: place logo.png in this directory, then run ./update-logo.sh
# Covers: mainnet (haiti-bp), preprod-silem, preview-silem — all share extended.json
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -f logo.png ]; then
  echo "ERROR: logo.png not found. Save the Silem Foundation logo as logo.png first."
  exit 1
fi

echo "==> Generating 64x64 icon from logo.png..."
python3 - << 'PYEOF'
from PIL import Image

# Normalize full logo to RGBA PNG
img = Image.open("logo.png").convert("RGBA")
img.save("logo.png")

# Icon: center-crop to square then resize to 64x64
w, h = img.size
side = min(w, h)
left = (w - side) // 2
top  = (h - side) // 2
icon = img.crop((left, top, left + side, top + side))
icon = icon.resize((64, 64), Image.LANCZOS)
# White background (avoids transparency issues on some explorers)
bg = Image.new("RGBA", (64, 64), (255, 255, 255, 255))
bg.paste(icon, mask=icon.split()[3])
bg.convert("RGB").save("icon.png")
print(f"logo.png: {img.size[0]}x{img.size[1]}")
print("icon.png: 64x64 ✅")
PYEOF

echo "==> Updating extended.json (covers mainnet, preprod & preview — shared file)..."
python3 - << 'PYEOF'
import json, datetime

with open("extended.json") as f:
    d = json.load(f)

# GitHub raw URLs — main branch (what sp.json + sv.json reference)
LOGO_URL = "https://raw.githubusercontent.com/gvolcy/SILEM/main/logo.png"
ICON_URL = "https://raw.githubusercontent.com/gvolcy/SILEM/main/icon.png"

# Bump serial: YYYYMMDDNN
today = datetime.date.today().strftime("%Y%m%d")
d["serial"] = int(f"{today}01")

# Update all four logo references
d["info"]["url_png_icon_64x64"]          = ICON_URL
d["info"]["url_png_logo"]                = LOGO_URL
d["pool"]["media_assets"]["icon_png_64x64"] = ICON_URL
d["pool"]["media_assets"]["logo_png"]    = LOGO_URL

with open("extended.json", "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")

print("extended.json updated ✅")
print(f"  icon: {ICON_URL}")
print(f"  logo: {LOGO_URL}")
PYEOF

echo "==> Committing..."
TODAY=$(date +%Y%m%d)
git add logo.png icon.png extended.json
git commit -m "feat: update SILEM logo — official Silem Foundation branding

Covers all three SILEM pools (mainnet/preprod/preview) via shared extended.json:
- logo.png: official Silem Foundation logo (full size, RGBA PNG)
- icon.png: 64x64 center-cropped icon auto-generated from logo
- extended.json: url_png_icon_64x64 + url_png_logo → GitHub raw /main/ URLs
- serial bumped to ${TODAY}01
- Removed old developers.apexfusion.org logo URLs (wrong domain)"

echo "==> Pushing to main and master..."
git push origin master
git checkout main && git merge master --ff-only && git push origin main && git checkout master

echo ""
echo "✅ Logo live at:"
echo "   https://raw.githubusercontent.com/gvolcy/SILEM/main/logo.png"
echo "   https://raw.githubusercontent.com/gvolcy/SILEM/main/icon.png"
echo ""
echo "Pool metadata extended URL (already correct in all 3 metadata files):"
echo "   https://raw.githubusercontent.com/gvolcy/SILEM/main/extended.json"
echo ""
echo "⚠️  Next: re-register pool metadata on-chain for haiti-bp, preprod-silem, preview-silem"
echo "   s.json hash is unchanged — but re-submit so explorers pick up new extended logo"
echo "   Haiti BP:     CNTools → Pool → Metadata → Update (on main2 for haiti-bp)"
echo "   Preprod/Preview: same via CNTools on main2 preprod-silem / preview-silem pods"
