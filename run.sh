#!/bin/sh

bd="build-release"
n="Arabic-Lexicons"
ver=$(grep 'version' pubspec.yaml | sed 's/version: //')
gc=$(git rev-parse --short HEAD)
gcm=$(git log -1 --pretty='%B' | tr '\n' ' ' | sed 's/^ *//; s/ *$//')

set -ex

flutter run $* \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=BUILD_UNIX_TIME=$(date +%s) \
  --dart-define=GIT_COMMIT="$gc" \
  --dart-define=GIT_COMMIT_MSG="$gcm"
