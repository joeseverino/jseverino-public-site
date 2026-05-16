#!/usr/bin/env bash
# Regenerate the static mirror of jseverino.com into ./public.
#
# Thin wrapper around the `wp-static` tool. Site URL, output path, and
# preserved files are configured in:
#
#   $TOOLS_HOME/config/wp-static.sh (gitignored)
#
# Run from the repo root:  ./scripts/mirror.sh
set -euo pipefail

: "${TOOLS_HOME:?set TOOLS_HOME in your shell — points at the personal tools repo}"

command -v wp-static >/dev/null \
    || PATH="$TOOLS_HOME:$PATH"

exec wp-static jseverino "$@"
