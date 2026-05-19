#!/usr/bin/env bash
# Run after placing logo.png in this directory
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -f logo.png ]; then
  echo "ERROR: logo.png not found. Save the Silem Foundation logo as logo.png first."
  exit 1
fi

echo "==> Generating 64x64 icon from logo.png..."
python3 - << 'PYEOF'
from PIL import Image

# Full logo (keep aspect ratio, pad to square with white background)
img = Image.open("logo.png").convert("RGBA")
img.save("logo.png")  # normalize to RGBA PNG

# Icon: crop to square center then resize to 64x64
w, h = img.size
side = min(w, h)
left = (w - side) // 2
top = (h - side) // 2
icon = img.crop((left, top, left + side, top + side))
icon = icon.resize((64, 64), Image.LANCZOS)
# Paste onto white background (avoid transparent PNG issues on some explorers)
bg = Image.new("RGBA", (64, 64), (255, 255, 255, 255))
bg.paste(icon, mask=icon.split()[3])
bg.convert("RGB").save("icon.png")
print(f"logo.png: {img.size[0]}x{img.size[1]}")
print("icon.png: 64x64 ✅")
PYEOF

echo "==> Updating extended.json..."
python3 - << 'PYEOF'
import json, datetime

with open("extended.json") as f:
    d = json.load(f)

LOGO_URL = "https://raw.githubusercontent.com/gvolcy/SILEM/master/logo.png"
ICON_URL = "https://raw.githubusercontent.com/gvolcy/SILEM/master/icon.png"

# Bump serial: YYYYMMDDNN
today = datetime.date.today().strftime("%Y%m%d")
d["serial"] = int(f"{today}01")

# Update all logo references
d["info"]["url_png_icon_64x64"] = ICON_URL
d["info"]["url_png_logo"] = LOGO_URL
d["pool"]["media_assets"]["icon_png_64x64"] = ICON_URL
d["pool"]["media_assets"]["logo_png"] = LOGO_URL

with open("extended.json", "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")

print("extended.json updated ✅")
PYEOF

echo "==> Committing to git..."
git add logo.png icon.png extended.json
git commit -m "feat: update SILEM pool logo to official Silem Foundation branding

- logo.png: official Silem Foundation logo (full size)
- icon.png: 64x64 icon auto-generated from logo
- extended.json: updated url_png_icon_64x64 + url_png_logo to GitHub raw URLs
- serial bumped to $(date +%Y%m%d)01
- Previously pointed to developers.apexfusion.org (wrong domain)"
git push origin master

echo ""
echo "✅ Done! Logo live at:"
echo "   https://raw.githubusercontent.com/gvolcy/SILEM/master/logo.png"
echo "   https://raw.githubusercontent.com/gvolcy/SILEM/master/icon.png"
echo ""
echo "Next: re-hash s.json and re-register pool metadata on-chain"
echo "   cardano-signer sign --cip36 ..."
echo "   (or use CNTools > Pool > Metadata > Update)"
