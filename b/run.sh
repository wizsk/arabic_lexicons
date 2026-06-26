#!/bin/sh

source ./b/common.sh

set -ex

flutter run $* \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=GIT_COMMIT="$gc"
