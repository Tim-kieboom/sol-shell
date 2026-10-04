#!/usr/bin/env bash
# One-time setup so Zen uses the theme that sol-shell writes. It links three files
# of the profile to the generated ones in ~/.local/state/theme/:
#   chrome/userChrome.css   <- zen-userChrome.css   (Zen's own interface)
#   chrome/userContent.css  <- zen-userContent.css  (Zen's own pages: about:newtab, ...)
#   user.js                 <- zen-user.js          (lets Zen read the two css files, and
#                                                    sets the dark/light that websites see)
# Usage: export/zen-setup.sh [profile folder]
# Without an argument it uses the default profile listed in ~/.config/zen/profiles.ini.
# Close Zen first: it rewrites its prefs when it exits.
set -euo pipefail

state_dir="$HOME/.local/state/theme"
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

for name in zen-userChrome.css zen-userContent.css zen-user.js; do
    [ -f "$state_dir/$name" ] || { echo "$state_dir/$name does not exist yet: start sol-shell first" >&2; exit 1; }
done

# Firefox-based browsers keep a "lock" link in a profile that is in use, pointing at
# "<address>:+<pid>"; if that process is alive the profile is open
lock_target=$(readlink "$profile/lock" 2>/dev/null || true)
if [ -n "$lock_target" ] && kill -0 "${lock_target##*+}" 2>/dev/null; then
    echo "Zen is running with this profile: close it and run this again" >&2
    exit 1
fi

# link <generated file> <place in the profile>
# A real file there is never overwritten (it may be the user's own), except for
# user.js when it only holds the one line an earlier version of this script wrote.
status=0
link() {
    local source="$1" target="$2"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        if [ "$(basename "$target")" = user.js ] \
            && [ "$(grep -v '^[[:space:]]*\(//.*\)\?$' "$target")" = 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' ]; then
            rm "$target"
        else
            echo "$target is a real file: not overwriting it. Move it away and run this again." >&2
            status=1
            return
        fi
    fi
    ln -sfn "$source" "$target"
    echo "linked: $target -> $source"
}

mkdir -p "$profile/chrome"
echo "profile: $profile"
link "$state_dir/zen-userChrome.css" "$profile/chrome/userChrome.css"
link "$state_dir/zen-userContent.css" "$profile/chrome/userContent.css"
link "$state_dir/zen-user.js" "$profile/user.js"

[ "$status" -eq 0 ] && echo "Start Zen; after a theme change, restart it to see the new colors."
exit $status
