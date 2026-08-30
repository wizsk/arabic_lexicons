#!/bin/sh

APP_NAME="arabic_lexicons"

if pgrep -x "$APP_NAME" > /dev/null; then
    notify-send "Arabic Lexicons" "App is already running!"
else
    "$APP_NAME" &
fi
