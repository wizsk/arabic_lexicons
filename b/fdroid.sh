#!/usr/bin/env bash

REQUIRED_FLUTTER_VERSION="3.44.4"

# Check if flutter exists
if ! command -v flutter &>/dev/null; then
    echo "Error: flutter not found in PATH" >&2
    exit 1
fi

# Get flutter version
FLUTTER_VERSION=$(flutter --version 2>/dev/null | awk 'NR==1 {print $2}')

if [[ "$FLUTTER_VERSION" != "$REQUIRED_FLUTTER_VERSION" ]]; then
    echo "Error: required Flutter $REQUIRED_FLUTTER_VERSION but found Flutter $FLUTTER_VERSION" >&2
    exit 1
fi

echo "Flutter $FLUTTER_VERSION found"

source ./b/common.sh
source ./b/confirm.sh

BUILD_DIR="/tmp/build"
OUT_DIR="build-fdroid"

version=$ver

echo "Version: $version"

echo "Preparing temp build dir: $BUILD_DIR"

[ -d "$BUILD_DIR" ] && rm -rf "$BUILD_DIR"

set -x

export SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)

mkdir "$BUILD_DIR"

cp -r android "$BUILD_DIR"
cp -r assets "$BUILD_DIR"
cp -r lib "$BUILD_DIR"
cp pubspec.lock "$BUILD_DIR"
cp pubspec.yaml "$BUILD_DIR"

# maybe not needed
cp analysis_options.yaml "$BUILD_DIR"
cp devtools_options.yaml "$BUILD_DIR"
cp flutter_launcher_icons.yaml "$BUILD_DIR"

cd "$BUILD_DIR"

export PUB_CACHE=$(pwd)/.pub-cache

[ -d "$OLDPWD/$OUT_DIR" ] && rm -rf "$OLDPWD/$OUT_DIR"
mkdir -p "$OLDPWD/$OUT_DIR"

flutter clean
flutter pub get

sed -i -e 's/-Wl,/-Wl,--build-id=none,/' ${PUB_CACHE}/hosted/*/jni-*/src/CMakeLists.txt

# 1
flutter build apk \
    --release \
    --split-per-abi \
    --target-platform="android-arm" \
    --dart-define="APP_VERSION=$version" \
    --dart-define=GIT_COMMIT="$gc"

cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk \
   "$OLDPWD/$bd/$n-v$version-x86_64.apk"

# 2
flutter build apk \
    --release \
    --split-per-abi \
    --target-platform="android-arm64" \
    --dart-define="APP_VERSION=$version" \
    --dart-define=GIT_COMMIT="$gc"


cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
   "$OLDPWD/$bd/$n-v$version-arm64-v8a.apk"

# 3
flutter build apk \
    --release \
    --split-per-abi \
    --target-platform="android-x64" \
    --dart-define="APP_VERSION=$version" \
    --dart-define=GIT_COMMIT="$gc"

cp build/app/outputs/flutter-apk/app-x86_64-release.apk \
   "$OLDPWD/$bd/$n-v$version-x86_64.apk"

flutter build apk --release \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=GIT_COMMIT="$gc"

cp 'build/app/outputs/flutter-apk/app-release.apk' \
    "$OLDPWD/$bd/$n-v$version-universal.apk"

echo "Done: APKs copied to $OLDPWD/$OUT_DIR/"
