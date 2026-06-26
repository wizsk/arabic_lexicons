#!/bin/sh

source ./b/common.sh
source ./b/confirm.sh

set -ex

flutter build appbundle --release \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=GIT_COMMIT="$gc" \
  --dart-define=GPLAY=true

cp 'build/app/outputs/bundle/release/app-release.aab' "$bd/$n-v$ver.aab"
