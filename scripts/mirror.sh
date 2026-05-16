#!/usr/bin/env bash
# Publish the static mirror of jseverino.com.
#
# Workflow:
#   1. Regenerate public/ from the live WordPress site (via wp-static).
#   2. Show what changed in the working tree.
#   3. On confirmation, commit + push. Cloudflare Pages auto-deploys
#      from the push (typically live within 60-90 seconds).
#
# wp-static lives in the personal tools repo at $TOOLS_HOME/. The
# named-site config for jseverino is in $TOOLS_HOME/config/wp-static.sh
# (gitignored).
#
# Run from the repo root:  ./scripts/mirror.sh

set -euo pipefail

: "${TOOLS_HOME:?set TOOLS_HOME in your shell — points at the personal tools repo}"

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

command -v wp-static >/dev/null \
    || PATH="$TOOLS_HOME:$PATH"

# 1. Regenerate the mirror.
wp-static jseverino "$@"

# 2. Inspect what changed.
echo ""
echo "==> Working tree status after mirror:"

if git diff --quiet HEAD && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
    echo "    (no changes — public/ is identical to last commit)"
    echo "    Nothing to publish."
    exit 0
fi

git -c color.status=always status --short
echo ""
git diff --stat HEAD | tail -30 || true
echo ""

# 3. Confirm + publish.
read -r -p "Publish to static.jseverino.com? [y/N] " ans
case "$ans" in
    y|Y|yes|YES) ;;
    *)
        echo ""
        echo "Aborted. Working tree has uncommitted changes from the mirror."
        echo "  Inspect:        git status / git diff"
        echo "  Commit later:   git add -A && git commit -m 'publish: ...' && git push"
        echo "  Discard mirror: git checkout -- public/ && git clean -fd public/"
        exit 1
        ;;
esac

ts="$(date -u '+%Y-%m-%d %H:%M UTC')"
git add -A
git commit -m "publish: $ts"

echo ""
echo "==> Pushing to GitHub..."
git push

echo ""
echo "✨ Pushed. Cloudflare Pages will deploy in ~60-90s."
echo "   Live URL: https://static.jseverino.com"
