#!/bin/sh

source ./b/common.sh

set -ex

flutter build linux --release \
  --dart-define=APP_VERSION="$ver" \
  --dart-define=GIT_COMMIT="$gc"

dest="$HOME/.local/arabic_lexicons"

[ -d "$dest" ] && rm -r "$dest"

cp -r build/linux/x64/release/bundle "$dest"

cp assets/icons/icon_rounded.png "$dest/icon.png"

sed "s/user/$(whoami)/" arabic_lexicons.desktop > ~/.local/share/applications/arabic_lexicons.desktop
