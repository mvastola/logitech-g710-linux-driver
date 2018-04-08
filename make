#!/bin/bash
declare -r SELF="$(readlink -e "$0")"
declare -r DIR="$(dirname "${SELF}")"
exec /usr/bin/env make -C "${DIR}" "$@"
