#!/bin/bash

OUT=$(amixer sset Line toggle)
RESULT=$(echo $OUT | grep "Left:" | cut -d'[' -f4 | cut -d ']' -f 1)
#notify-send pulls icons from /usr/share/icons/gnome/32x32
notify-send "Toggling Line In" "Line in is now: $RESULT" -i audio-volume-low
