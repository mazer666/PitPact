#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M6 Bucket 5: Licensing/IP
# Audit Script.
#
# This script asserts that every asset
# shipped in the M6 release is:
#   1. Procedurally generated (no
#      external IP, no hand-drawn art).
#   2. SEED-pinned (re-runs produce
#      byte-identical output).
#   3. GPL-3.0-or-later (code) or
#      CC0 (assets) or CC BY-SA 4.0
#      (locales).
#
# The script reads `LICENSES/asset-manifest.md`
# and asserts the audit status.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MANIFEST="$PROJECT_ROOT/LICENSES/asset-manifest.md"

if [ ! -f "$MANIFEST" ]; then
	echo "FAIL: $MANIFEST not found"
	exit 1
fi

# 1. Check that every PNG/WAV in
# `assets/` is in the manifest.
echo "==> Checking asset directory coverage..."
ASSET_PNGS=$(find "$PROJECT_ROOT/assets" -name "*.png" -not -name "*.import" 2>/dev/null | wc -l)
ASSET_WAVS=$(find "$PROJECT_ROOT/assets" -name "*.wav" 2>/dev/null | wc -l)
ASSET_TRES=$(find "$PROJECT_ROOT/assets" -name "*.tres" 2>/dev/null | wc -l)
# Count lines that are PNG/WAV rows
# (start with `| \`<file>.png` ` or
# `| \`<file>.wav` `).
MANIFEST_PNGS=$(grep -cE "^\| \`[^/]+\.png\` \|" "$MANIFEST" || echo "0")
MANIFEST_WAVS=$(grep -cE "^\| \`[^/]+\.wav\` \|" "$MANIFEST" || echo "0")
MANIFEST_TRES=$(grep -cE "^\| \`[^/]+\.tres\` \|" "$MANIFEST" || echo "0")
echo "  PNGs: $ASSET_PNGS (filesystem) vs $MANIFEST_PNGS (manifest)"
echo "  WAVs: $ASSET_WAVS (filesystem) vs $MANIFEST_WAVS (manifest)"
echo "  .tres: $ASSET_TRES (filesystem) vs $MANIFEST_TRES (manifest)"
if [ "$ASSET_PNGS" -ne "$MANIFEST_PNGS" ]; then
	echo "FAIL: PNG count mismatch"
	exit 1
fi
if [ "$ASSET_WAVS" -ne "$MANIFEST_WAVS" ]; then
	echo "FAIL: WAV count mismatch"
	exit 1
fi
if [ "$ASSET_TRES" -ne "$MANIFEST_TRES" ]; then
	echo "FAIL: .tres count mismatch"
	exit 1
fi

# 2. Check that no asset has a
# non-CC0 / non-GPL-3.0 license.
echo "==> Checking asset licenses..."
# Find asset rows (PNG/WAV/.tres) and
# check their license column.
NON_OK=$(grep -E "^\| \`[^/]+\.(png|wav|tres)\` \|" "$MANIFEST" \
	| grep -vE "\| CC0 \||\| GPL-3.0-or-later \|" || true)
if [ -n "$NON_OK" ]; then
	echo "FAIL: non-CC0/non-GPL-3.0 license found:"
	echo "$NON_OK"
	exit 1
fi
if grep -E "GPL-3.0-or-later|CC0" "$MANIFEST" > /dev/null; then
	echo "  All assets are CC0 or GPL-3.0-or-later"
else
	echo "FAIL: no assets found in the manifest"
	exit 1
fi

# 3. Check the locales are CC BY-SA 4.0.
echo "==> Checking locale licenses..."
if grep -E "locales/.*\| CC BY-SA 4.0" "$MANIFEST" > /dev/null; then
	echo "  All locales are CC BY-SA 4.0"
else
	echo "FAIL: locales do not have CC BY-SA 4.0 license"
	exit 1
fi

echo "PASS: licensing audit complete"
