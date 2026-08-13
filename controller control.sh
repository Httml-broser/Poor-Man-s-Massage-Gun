#!/bin/sh
printf '\033c\033]0;%s\a' controller control
base_path="$(dirname "$(realpath "$0")")"
"$base_path/controller control.x86_64" "$@"
