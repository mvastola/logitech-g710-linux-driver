#!/bin/bash

[ $# -eq 1 ] || [ -n "$1" ] || (echo "Module (.ko) file path required." 1>&2 && exec /bin/false) 
declare -r MOD_PATH="$(modinfo -n "$1")"
declare -r MOD_NAME="$(basename "${MOD_PATH}" '.ko')"
modinfo -0 -F alias "${MOD_PATH}" | xargs -0 -n1 -i echo "alias {} ${MOD_NAME}"

