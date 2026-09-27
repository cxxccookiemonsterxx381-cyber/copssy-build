#!/usr/bin/env bash
# =============================================================
#  build.sh — compile CritOpsCheat.dylib for iOS ARM64
#  Requirements: Xcode + Command Line Tools installed on macOS
#
#  Usage:
#    chmod +x build.sh
#    ./build.sh
#
#  Output: CritOpsCheat.dylib (ready to inject + sign)
# =============================================================

set -e

DYLIB_NAME="CritOpsCheat"
SOURCE="CritOpsCheat.mm"
OUTPUT="${DYLIB_NAME}.dylib"

# ── Xcode SDK path ─────────────────────────────────────────────
SDK=$(xcrun --sdk iphoneos --show-sdk-path)
if [ -z "$SDK" ]; then
    echo "❌  Xcode iOS SDK not found. Install Xcode from the App Store."
    exit 1
fi
echo "✅  Using SDK: $SDK"

# ── Clang flags ────────────────────────────────────────────────
CLANG=$(xcrun --sdk iphoneos --find clang++)

CFLAGS=(
    -arch arm64
    -isysroot "$SDK"
    -miphoneos-version-min=14.0
    -std=c++17
    -ObjC++
    -O2
    -fvisibility=hidden
    -fno-objc-arc          # manual retain: faster, no ARC overhead in hot path
    -dynamiclib
    -install_name "@executable_path/Frameworks/${OUTPUT}"
    -framework UIKit
    -framework Foundation
    -framework CoreGraphics
    -lc++
    -lobjc
)

echo "🔨  Compiling ${SOURCE} → ${OUTPUT} ..."
"$CLANG" "${CFLAGS[@]}" -o "$OUTPUT" "$SOURCE"

echo "✅  Build complete: ${OUTPUT}"
ls -lh "$OUTPUT"

# ── Optional: strip debug symbols to reduce size ───────────────
strip -x "$OUTPUT"
echo "✅  Stripped: $(ls -lh $OUTPUT | awk '{print $5}')"

# =============================================================
#  INJECT GUIDE (run these after build)
# =============================================================
cat <<'GUIDE'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  INJECT GUIDE — non-JB IPA injection (esign / ksign)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1 — Get a DECRYPTED Critical Ops IPA
  • Use an already-decrypted IPA from a trusted source, OR
  • Dump from a JB device with frida-ios-dump / bfdecrypt
  (The App Store IPA is encrypted — inject won't work on it)

STEP 2 — Unpack the IPA
  unzip CriticalOps.ipa -d COUnpacked

STEP 3 — Copy the dylib into the Frameworks folder
  mkdir -p COUnpacked/Payload/CriticalOps.app/Frameworks
  cp CritOpsCheat.dylib COUnpacked/Payload/CriticalOps.app/Frameworks/

STEP 4 — Install insert_dylib (if not already)
  brew install insert_dylib
  # OR build from source:
  # git clone https://github.com/Tyilo/insert_dylib && cd insert_dylib
  # xcodebuild && cp build/Release/insert_dylib /usr/local/bin/

STEP 5 — Inject dylib path into the Mach-O binary
  insert_dylib \
    --strip-codesig \
    --inplace \
    @executable_path/Frameworks/CritOpsCheat.dylib \
    COUnpacked/Payload/CriticalOps.app/CriticalOps

STEP 6 — Repack the IPA
  cd COUnpacked
  zip -qr ../CriticalOps_Cheated.ipa Payload
  cd ..

STEP 7 — Sign + Install
  • Open esign / ksign on your iPhone
  • Import CriticalOps_Cheated.ipa
  • Sign with any available certificate
  • Install → done ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  IN-GAME
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  • Launch Critical Ops — wait ~8 s for scan to complete
  • Tap the ☕ floating button (top-right) to open the menu
  • Toggle cheats on/off with switches
  • Use sliders for Fly / Jump / Time levels (1–10)
  • ✅ "X/10 addresses found" = scan succeeded
  • 🛡️ Safe Mode = disables server-visible cheats (anti-ban)
  • Re-scan button if addresses not found after map load

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ANTI-BAN TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  • Enable Safe Mode in casual matches
  • Keep Fly / Jump at level 2-3 max (not 10)
  • NoSmoke + NoFlash = completely safe (client-side only)
  • HeadHitbox / BodyHitbox = low risk but don't abuse
  • Gravity / Walls / FastTime = risky, use sparingly
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GUIDE
