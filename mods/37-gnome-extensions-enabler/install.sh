#!/usr/bin/env bash
# Shell-version compatibility shim for GNOME Shell extensions.
#
# Some upstream extensions lag behind Ubuntu's GNOME release.  Append
# the current shell version to metadata.json so they load correctly.
# Remove this mod entirely when all extensions support the target
# GNOME Shell version.
#
# Extensions are installed via apt (mod 27) and enabled via system-wide
# dconf defaults (anduinos-dconf-defaults package).  This mod only
# handles the temporary compatibility patch.
set -euo pipefail

source /root/mods/shared.sh
source /root/mods/args.sh

TARGET_SHELL="50"   # GNOME Shell major version shipped with Ubuntu resolute

print_ok "Patching extension metadata.json for GNOME Shell $TARGET_SHELL compatibility..."

apt install -y jq --no-install-recommends
judge "Install jq"

find /usr/share/gnome-shell/extensions -type f -name metadata.json | while IFS= read -r file; do
    if jq -e 'has("shell-version")' "$file" > /dev/null; then
        if jq -e --arg v "$TARGET_SHELL" '.["shell-version"] | index($v)' "$file" > /dev/null; then
            print_info "  OK: $file already supports $TARGET_SHELL"
        else
            print_warn "  PATCH: $file ← add shell-version $TARGET_SHELL"
            tmpfile=$(mktemp)
            jq --arg v "$TARGET_SHELL" '.["shell-version"] += [$v]' "$file" > "$tmpfile" && mv "$tmpfile" "$file"
            chmod 644 "$file"
        fi
    else
        print_error "  SKIP: $file has no shell-version key"
    fi
done

judge "Patch metadata.json shell-version"
