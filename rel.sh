#!/bin/sh

set -ex

flutter build apk --release --split-per-abi
flutter build apk --release

bd="build-release"
n="Arabic-Lexicons"

pre="$bd/n"

[ -d "$bd" ] && rm -r "$bd"

mkdir "$bd"

mv 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk' "${pre}_arm64-v8a.apk"
mv 'build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk' "${pre}_armeabi-v7a.apk"
mv 'build/app/outputs/flutter-apk/app-release.apk' "${pre}_universal.apk"
mv 'build/app/outputs/flutter-apk/app-x86_64-release.apk' "${pre}_x86_64.apk"
