#!/bin/sh

bd="build-release"
n="Arabic-Lexicons"
# ver=$(grep 'version' pubspec.yaml | sed 's/version: //; s/+.*//')
ver=$(grep 'version' pubspec.yaml | sed 's/version: //')

set -ex

flutter run $* \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=BUILD_UNIX_TIME=$(date +%s)
