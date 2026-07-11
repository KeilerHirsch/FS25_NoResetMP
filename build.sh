#!/usr/bin/env bash
#
# Build the shippable FS25 mod zip.
#
# FS25 requires modDesc.xml at the ROOT of the zip. This script zips the
# individual mod files (NOT the containing folder), which is the #1 mistake
# to avoid: `zip -r out.zip FS25_NoResetMP` would nest everything under
# FS25_NoResetMP/ and the game would fail with "Failed to open modDesc.xml".
#
# Dev files (tests/, .luacheckrc, README, CHANGELOG, .github, build.sh) are
# intentionally excluded from the shipped mod.
#
set -euo pipefail

cd "$(dirname "$0")"

OUT="FS25_NoResetMP.zip"
rm -f "$OUT"

zip -r "$OUT" \
    modDesc.xml \
    scripts/ \
    icon_noResetMP.dds \
    LICENSE

echo
echo "Built $OUT:"
unzip -l "$OUT"
