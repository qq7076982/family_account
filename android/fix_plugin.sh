#!/bin/bash
# Patch cloudbase_ce plugin to add namespace and upgrade compileSdkVersion
# This runs AFTER flutter pub get to ensure package is downloaded

set -e

PUB_CACHE="${HOME}/.pub-cache"
CLOUD_DIR=$(find "${PUB_CACHE}/hosted/pub.dev" -maxdepth 1 -type d -name "cloudbase_ce-*" 2>/dev/null | head -1)

if [ -z "$CLOUD_DIR" ]; then
    echo "[fix_plugin] ERROR: cloudbase_ce not found in pub-cache at ${PUB_CACHE}/hosted/pub.dev"
    echo "[fix_plugin] Available packages:"
    ls "${PUB_CACHE}/hosted/pub.dev/" | grep cloudbase || echo "none"
    exit 1
fi

BUILD_FILE="$CLOUD_DIR/android/build.gradle"

echo "[fix_plugin] Patching cloudbase_ce at $CLOUD_DIR"
echo "[fix_plugin] BUILD_FILE: $BUILD_FILE"

# Inject namespace if missing
if ! grep -q "namespace" "$BUILD_FILE"; then
    PKG=$(grep 'package="' "$CLOUD_DIR/android/src/main/AndroidManifest.xml" 2>/dev/null | sed 's/.*package="\([^"]*\)".*/\1/')
    if [ -n "$PKG" ]; then
        sed -i "s/android {/android {\n    namespace '$PKG'/" "$BUILD_FILE"
        echo "[fix_plugin] Injected namespace '$PKG'"
    else
        echo "[fix_plugin] WARNING: Could not extract package from AndroidManifest.xml"
    fi
else
    echo "[fix_plugin] namespace already exists"
fi

# Upgrade compileSdkVersion if too low
CURRENT=$(grep "compileSdkVersion" "$BUILD_FILE" 2>/dev/null | grep -o "[0-9]\+" | head -1)
if [ -n "$CURRENT" ] && [ "$CURRENT" -lt 30 ]; then
    sed -i "s/compileSdkVersion $CURRENT/compileSdkVersion 30/" "$BUILD_FILE"
    echo "[fix_plugin] Upgraded compileSdkVersion $CURRENT -> 30"
elif [ -n "$CURRENT" ]; then
    echo "[fix_plugin] compileSdkVersion is $CURRENT (ok)"
fi

echo "[fix_plugin] Done. Final build.gradle:"
cat "$BUILD_FILE"