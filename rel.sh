#!/bin/sh

set -ex

bd="build-release"
n="Arabic-Lexicons"
ver=$(grep 'version' pubspec.yaml | sed 's/version: //; s/+.*//')

pre="$bd/$n"

[ -n "$ver" ] && pre="${pre}_v$ver"

[ -d "$bd" ] && rm -r "$bd"

mkdir "$bd"

flutter build apk --release --split-per-abi
mv 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk' "${pre}_arm64-v8a.apk"
mv 'build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk' "${pre}_armeabi-v7a.apk"
mv 'build/app/outputs/flutter-apk/app-x86_64-release.apk' "${pre}_x86_64.apk"

flutter build apk --release
mv 'build/app/outputs/flutter-apk/app-release.apk' "${pre}_universal.apk"
