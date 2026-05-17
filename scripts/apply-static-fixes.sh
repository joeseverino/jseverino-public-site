#!/usr/bin/env bash
# Reapply fixes that are specific to the Cloudflare Pages static mirror.
#
# `wp-static` regenerates public/ from WordPress, so changes made only in the
# generated export can be overwritten. Keep those mirror-only fixes here.

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

nav_js="public/wp-content/themes/severino-labs-extendable/assets/js/mobile-nav.js"

html_files=()
if command -v rg >/dev/null; then
    while IFS= read -r file; do
        html_files+=("$file")
    done < <(rg -l 'https://jseverino\.com/wp-includes/js/dist/script-modules/interactivity/index\.min\.js' public -g '*.html')
else
    while IFS= read -r file; do
        html_files+=("$file")
    done < <(find public -name '*.html' -type f -print0 | xargs -0 grep -l 'https://jseverino\.com/wp-includes/js/dist/script-modules/interactivity/index\.min\.js' || true)
fi

if ((${#html_files[@]})); then
    perl -pi -e 's#https://jseverino\.com/wp-includes/js/dist/script-modules/interactivity/index\.min\.js\?ver=66c613f68580994bb00a#/wp-includes/js/dist/script-modules/interactivity/index.min.js?ver=66c613f68580994bb00a#g' "${html_files[@]}"
fi

if [[ ! -f "$nav_js" ]]; then
    echo "Missing expected mobile nav script: $nav_js" >&2
    exit 1
fi

if ! grep -q 'function setMenuState(container, isOpen)' "$nav_js"; then
    perl -0pi -e 's#\n    function closeMenu\(container\) \{\n        var btn = container\.querySelector\(\n            '"'"'\.wp-block-navigation__responsive-container-close'"'"'\n        \);\n        if \(btn\) btn\.click\(\);\n    \}\n#\n    function setMenuState(container, isOpen) {\n        if (!container) return;\n\n        container.classList.toggle('"'"'has-modal-open'"'"', isOpen);\n        container.classList.toggle('"'"'is-menu-open'"'"', isOpen);\n        document.documentElement.classList.toggle('"'"'has-modal-open'"'"', isOpen);\n\n        var dialog = container.querySelector('"'"'.wp-block-navigation__responsive-dialog'"'"');\n        if (dialog) {\n            if (isOpen) {\n                dialog.setAttribute('"'"'aria-modal'"'"', '"'"'true'"'"');\n                dialog.setAttribute('"'"'aria-label'"'"', '"'"'Menu'"'"');\n                dialog.setAttribute('"'"'role'"'"', '"'"'dialog'"'"');\n            } else {\n                dialog.removeAttribute('"'"'aria-modal'"'"');\n                dialog.removeAttribute('"'"'aria-label'"'"');\n                dialog.removeAttribute('"'"'role'"'"');\n            }\n        }\n\n        if (isOpen) {\n            container.focus({ preventScroll: true });\n        }\n    }\n\n    function openMenu(container) {\n        setMenuState(container, true);\n    }\n\n    function closeMenu(container) {\n        var btn = container.querySelector(\n            '"'"'.wp-block-navigation__responsive-container-close'"'"'\n        );\n        if (btn) btn.click();\n\n        /* Static export fallback: WordPress'"'"'s interactivity module can fail to\n           load on Pages preview/custom-domain mismatches, leaving the data-wp\n           click handlers inert. If WP did not close it, mirror the same state. */\n        setTimeout(function () {\n            if (container.classList.contains('"'"'is-menu-open'"'"')) {\n                setMenuState(container, false);\n            }\n        }, 0);\n    }\n#s' "$nav_js"
fi

if ! grep -q 'Let WordPress handle the click first' "$nav_js"; then
    perl -0pi -e 's#(\n            \} else if \(Date\.now\(\) - lastClosed < 350\) \{\n                /\* Ghost click guard: kill reopening after a just-closed menu \*/\n                e\.stopPropagation\(\);\n                e\.stopImmediatePropagation\(\);\n            \})#$1 else {\n                /* Let WordPress handle the click first. If its module is absent\n                   or blocked, open the menu with the static fallback. */\n                setTimeout(function () {\n                    if (!container.classList.contains('"'"'is-menu-open'"'"')) {\n                        openMenu(container);\n                    }\n                }, 0);\n            }#s' "$nav_js"
fi

if ! grep -q 'function setMenuState(container, isOpen)' "$nav_js" ||
   ! grep -q 'Let WordPress handle the click first' "$nav_js"; then
    echo "Failed to apply mobile nav static fallback to $nav_js" >&2
    exit 1
fi

node --check "$nav_js" >/dev/null
