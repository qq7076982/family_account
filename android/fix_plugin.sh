#!/bin/bash
# Patch all Flutter plugin dependencies to upgrade compileSdkVersion to 34
# This runs AFTER flutter pub get to ensure all packages are downloaded

set -e

PUB_CACHE="${HOME}/.pub-cache"
PLUGINS_DIR="${PUB_CACHE}/hosted/pub.dev"

echo "[fix_plugin] Patching ALL plugins in ${PUB_CACHE}..."

TARGET_SDK=34

# Find all plugin directories that have an android/build.gradle
find "$PLUGINS_DIR" -maxdepth 2 -type d -name "android" 2>/dev/null | while read android_dir; do
    PLUGIN_DIR=$(dirname "$android_dir")
    BUILD_FILE="$PLUGIN_DIR/android/build.gradle"
    PLUGIN_NAME=$(basename "$PLUGIN_DIR")

    # Skip if no build.gradle
    [ -f "$BUILD_FILE" ] || continue

    # Inject namespace if missing
    if ! grep -q "namespace" "$BUILD_FILE"; then
        PKG=$(grep 'package="' "$PLUGIN_DIR/android/src/main/AndroidManifest.xml" 2>/dev/null | sed 's/.*package="\([^"]*\)".*/\1/')
        if [ -n "$PKG" ]; then
            sed -i "s/android {/android {\n    namespace '$PKG'/" "$BUILD_FILE"
            echo "[fix_plugin] [$PLUGIN_NAME] Injected namespace '$PKG'"
        fi
    fi

    # Upgrade compileSdkVersion if too low
    if grep -q "compileSdkVersion" "$BUILD_FILE"; then
        CURRENT=$(grep "compileSdkVersion" "$BUILD_FILE" | grep -o "[0-9]\+" | head -1)
        if [ -n "$CURRENT" ] && [ "$CURRENT" -lt "$TARGET_SDK" ]; then
            sed -i "s/compileSdkVersion $CURRENT/compileSdkVersion $TARGET_SDK/" "$BUILD_FILE"
            echo "[fix_plugin] [$PLUGIN_NAME] compileSdkVersion $CURRENT -> $TARGET_SDK"
        elif [ -n "$CURRENT" ]; then
            echo "[fix_plugin] [$PLUGIN_NAME] compileSdkVersion is $CURRENT (ok)"
        fi
    fi
done

echo "[fix_plugin] All plugins patched."
