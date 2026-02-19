#!/bin/sh

bd="build-release"
n="Arabic-Lexicons"
# ver=$(grep 'version' pubspec.yaml | sed 's/version: //; s/+.*//')
ver=$(grep 'version' pubspec.yaml | sed 's/version: //')
gc=$(git rev-parse --short HEAD)
gcm=$(git log -1 --pretty='%B' | tr '\n' ' ' | sed 's/^ *//; s/ *$//')

pre="$bd/$n"

[ -n "$ver" ] && pre="${pre}_v$ver"

[ -d "$bd" ] && rm -r "$bd"

set -ex

mkdir "$bd"

flutter build apk --release --split-per-abi \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=BUILD_UNIX_TIME=$(date +%s) \
  --dart-define=GIT_COMMIT="$gc" \
  --dart-define=GIT_COMMIT_MSG="$gcm"

mv 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk' "${pre}_arm64-v8a.apk"
mv 'build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk' "${pre}_armeabi-v7a.apk"
mv 'build/app/outputs/flutter-apk/app-x86_64-release.apk' "${pre}_x86_64.apk"

flutter build apk --release \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=BUILD_UNIX_TIME=$(date +%s) \
  --dart-define=GIT_COMMIT="$gc" \
  --dart-define=GIT_COMMIT_MSG="$gcm"

mv 'build/app/outputs/flutter-apk/app-release.apk' "${pre}_universal.apk"
