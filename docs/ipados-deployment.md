# PitPact — iPadOS Deployment Guide

> Per ADR-0020 §Bucket 3. This document
> describes the iPadOS deployment
> process for PitPact. The M8 closeout
> ships a build script and an export
> preset; the M8 closeout does NOT
> include the actual iOS build (no
> Apple hardware in CI).

## Overview

PitPact is a Godot 4.7 game. The iPadOS
build is a standard Godot-iOS export
that produces an `.xcframework` bundle
ready for Xcode.

## Prerequisites

To build for iPadOS, you need:

1. **Godot 4.7** (the canonical version;
   see `tools/README.md`).
2. **iOS export template** from
   <https://godotengine.org/download>
   (extract to `~/.local/share/godot/
   export_templates/4.7.stable/`).
3. **Xcode 15+** (for `.xcframework`
   processing + code signing).
4. **Apple Developer Account** (for
   code signing + App Store
   submission).
5. **macOS** (Linux/Windows can run the
   build script but cannot produce a
   signed iOS app).

## Build steps

### 1. Generate assets + audio

```bash
# These are deterministic (per ADR-0005).
godot --headless --path . \
	-s res://tools/assets/generate_assets.gd
godot --headless --path . \
	-s res://tools/assets/generate_audio.gd
```

### 2. Run the quality gate

```bash
bash tools/run_quality.sh
```

The quality gate must report
**ALL CHECKS PASSED** before the
build can proceed.

### 3. Build the iOS xcframework

```bash
./tools/build/build_ios.sh
```

The script:
- Verifies Godot 4.7.
- Runs the asset pipeline.
- Runs the quality gate.
- Exports to `build/ios/pitpact.xcframework`.
- Computes SHA-256 checksums in
  `build/checksums/`.

### 4. Process with Xcode

1. Open `build/ios/pitpact.xcframework`
   in Xcode 15+.
2. Create a new Xcode iOS App
   project.
3. Embed the `.xcframework` in
   "Frameworks, Libraries, and
   Embedded Content".
4. Configure the Bundle ID
   (e.g. `com.mazer666.pitpact`).
5. Configure the Team + signing
   certificate.
6. Set the Deployment Target to
   iOS 16.0+ (Godot 4.7 minimum).

### 5. App Store submission

1. Archive the build in Xcode
   (Product → Archive).
2. Validate the archive (Organizer
   → Validate App).
3. Distribute the archive
   (Organizer → Distribute App →
   App Store Connect → Upload).
4. Submit for review in App Store
   Connect.

## Bundle ID

The M8 closeout uses
`com.mazer666.pitpact` as the canonical
Bundle ID. The M8.1 closeout can change
this for App Store Connect.

## iOS version support

| iOS version | Status |
|-------------|--------|
| 17.0+ | ✅ fully supported |
| 16.0-16.x | ✅ supported (Godot 4.7 minimum) |
| 15.x and below | ❌ not supported (Godot 4.7 requires iOS 14+; the M8 closeout tests 16+) |

## Known issues

The M8 closeout ships with 1 known
issue for iOS:

- **iOS template may be missing in
  CI**: the build script detects this
  and exits 0 (with a warning). The
  M8.1 closeout can add a CI matrix
  that always installs the iOS
  template.

## Performance

Per ADR-0018 §Bucket 1, the M6
benchmark (`tools/benchmarks/run_perf.gd`)
runs 100 sim-ticks in **1.11ms**
(headless). The M8 closeout does not
have a separate iOS benchmark
(iOS profiling requires Xcode
Instruments on a real device).

## References

- ADR-0020 — M8: iPadOS & Mobile UI
- ADR-0018 — M6: Release Readiness
- Godot iOS export:
  <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html>
- Apple iOS HIG:
  <https://developer.apple.com/design/human-interface-guidelines/>
- `tools/build/build_ios.sh` — the
  canonical iOS build script
- `tools/build/build_release.sh` —
  the M6 cross-platform build script
  (Linux/Mac/Win/Web)
