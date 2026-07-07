#!/bin/sh

source ./b/common.sh
source ./b/confirm.sh

set -ex

flutter build apk \
    --release \
    --split-per-abi \
    --target-platform="android-arm64" \
    --dart-define="APP_VERSION=$version" \
    --dart-define=GIT_COMMIT="$gc"

cp 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk' "$bd/$n-v$version-arm64-v8a.apk"
