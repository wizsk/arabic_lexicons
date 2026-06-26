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

echo "Starting build..."

set -ex

flutter build apk --release --split-per-abi \
  --target-platform="android-arm" \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=GIT_COMMIT="$gc"

flutter build apk --release --split-per-abi \
  --target-platform="android-arm64" \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=GIT_COMMIT="$gc"

flutter build apk --release --split-per-abi \
  --target-platform="android-x64" \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=GIT_COMMIT="$gc"


cp 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk' "${pre}_arm64-v8a.apk"
cp 'build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk' "${pre}_armeabi-v7a.apk"
cp 'build/app/outputs/flutter-apk/app-x86_64-release.apk' "${pre}_x86_64.apk"

flutter build apk --release \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=GIT_COMMIT="$gc" \

cp 'build/app/outputs/flutter-apk/app-release.apk' "${pre}_universal.apk"

# linux
flutter build linux --release \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=GIT_COMMIT="$gc" \


linux_zip="${n}_${ver}_linux.zip"
linux_dest="build/linux/x64/release/$linux_zip"

cp assets/icons/icon_rounded.png build/linux/x64/release/bundle/icon.png
cp arabic_lexicons.desktop build/linux/x64/release/bundle/

cd build/linux/x64/release/
  [ -d "arabic_lexicons" ] && rm -r "arabic_lexicons"
  mv bundle arabic_lexicons
  zip -r "$linux_zip" arabic_lexicons
cd -

mv "$linux_dest" "$bd"
