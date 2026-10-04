#!/usr/bin/env bash
# One-time setup so Zen uses the theme that sol-shell writes. It
#   1. links <profile>/chrome/userChrome.css to ~/.local/state/theme/zen-userChrome.css
#   2. turns on the Zen setting that makes it read userChrome.css at all
#      (toolkit.legacyUserProfileCustomizations.stylesheets, off by default).
# Usage: export/zen-setup.sh [profile folder]
# Without an argument it uses the default profile listed in ~/.config/zen/profiles.ini.
# Close Zen first: it rewrites its prefs when it exits.
set -euo pipefail

source_css="$HOME/.local/state/theme/zen-userChrome.css"
zen_dir="$HOME/.config/zen"

profile="${1:-}"
if [ -z "$profile" ]; then
    # the profile marked Default=1; IsRelative=1 means the path is inside ~/.config/zen
    rel_path=$(awk -F= '
        /^\[/ { if (isdef && path != "") { print rel "|" path; exit } path=""; rel=""; isdef=0 }
        $1 == "Path" { path = substr($0, 6) }
        $1 == "IsRelative" { rel = $2 }
        $1 == "Default" && $2 == "1" { isdef = 1 }
        END { if (isdef && path != "") print rel "|" path }
    ' "$zen_dir/profiles.ini")
    [ -n "$rel_path" ] || { echo "no default profile found in $zen_dir/profiles.ini" >&2; exit 1; }
    if [ "${rel_path%%|*}" = "1" ]; then
        profile="$zen_dir/${rel_path#*|}"
    else
        profile="${rel_path#*|}"
    fi
fi
[ -d "$profile" ] || { echo "profile folder not found: $profile" >&2; exit 1; }
[ -f "$source_css" ] || { echo "$source_css does not exist yet: start sol-shell first" >&2; exit 1; }

# Firefox-based browsers keep a "lock" link in a profile that is in use, pointing at
# "<address>:+<pid>"; if that process is alive the profile is open
lock_target=$(readlink "$profile/lock" 2>/dev/null || true)
if [ -n "$lock_target" ] && kill -0 "${lock_target##*+}" 2>/dev/null; then
    echo "Zen is running with this profile: close it and run this again" >&2
    exit 1
fi

mkdir -p "$profile/chrome"
link="$profile/chrome/userChrome.css"
if [ -e "$link" ] && [ ! -L "$link" ]; then
    echo "$link is a real file: not overwriting it, move it away first" >&2
    exit 1
fi
ln -sfn "$source_css" "$link"

pref='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
if ! grep -qsF -- "$pref" "$profile/user.js"; then
    echo "$pref" >> "$profile/user.js"
fi

echo "profile: $profile"
echo "linked:  $link -> $source_css"
echo "Start Zen; after a theme change, restart it to see the new colors."
