#!/bin/bash
# Patch cloudbase_ce plugin to add namespace and upgrade compileSdkVersion
# This runs BEFORE flutter build to fix AGP 9.0+ compatibility

PUB_CACHE="${HOME}/.pub-cache"
CLOUD_DIR=$(find "${PUB_CACHE}/hosted/pub.dev" -maxdepth 1 -type d -name "cloudbase_ce-*" 2>/dev/null | head -1)

if [ -z "$CLOUD_DIR" ]; then
    echo "[fix_plugin] cloudbase_ce not found in pub-cache"
    exit 0
fi

BUILD_FILE="$CLOUD_DIR/android/build.gradle"

if [ ! -f "$BUILD_FILE" ]; then
    echo "[fix_plugin] build.gradle not found at $BUILD_FILE"
    exit 0
fi

echo "[fix_plugin] Patching cloudbase_ce at $CLOUD_DIR"

# Inject namespace if missing
if ! grep -q "namespace" "$BUILD_FILE"; then
    PKG=$(grep 'package="' "$CLOUD_DIR/android/src/main/AndroidManifest.xml" 2>/dev/null | sed 's/.*package="\([^"]*\)".*/\1/')
    if [ -n "$PKG" ]; then
        sed -i "s/android {/android {\n    namespace '$PKG'/" "$BUILD_FILE"
        echo "[fix_plugin] Injected namespace '$PKG'"
    fi
fi

# Upgrade compileSdkVersion if too low
if grep -q "compileSdkVersion [0-9]\+" "$BUILD_FILE"; then
    CURRENT=$(grep "compileSdkVersion" "$BUILD_FILE" | grep -o "[0-9]\+" | head -1)
    if [ -n "$CURRENT" ] && [ "$CURRENT" -lt 30 ]; then
        sed -i "s/compileSdkVersion $CURRENT/compileSdkVersion 30/" "$BUILD_FILE"
        echo "[fix_plugin] Upgraded compileSdkVersion $CURRENT -> 30"
    fi
fi

echo "[fix_plugin] Done. Final build.gradle:"
cat "$BUILD_FILE"