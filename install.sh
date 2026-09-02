#!/bin/bash
# ---------------------------------------------------------------------------
# Installs AI Kit: symlinks into this repository, systemd units, Omarchy
# entries. Idempotent — safe to re-run after a `git pull`.
#
#   ./install.sh            install or update
#   ./install.sh --dry-run  show what would be done
# ---------------------------------------------------------------------------
set -euo pipefail

SRC=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DRY=${1:-}
BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/aikit"
BAR="$HOME/.config/omarchy/bar/scripts"
UNITS="$HOME/.config/systemd/user"

say() { printf '  %s\n' "$*"; }
run() { [[ $DRY == --dry-run ]] && { say "→ $*"; return 0; }; "$@"; }

link() { # link <source> <destination> — backs up a real file if one exists
  local src="$1" dst="$2"
  if [[ -L $dst ]]; then
    [[ $(readlink -f "$dst") == "$src" ]] && { say "current  $dst"; return 0; }
  elif [[ -e $dst ]]; then
    run mv "$dst" "$dst.bak.$(date +%s)"
    say "backed up $dst"
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -sfn "$src" "$dst"
  say "linked   $dst"
}

echo "AI Kit — installing from $SRC"

for f in aikit aikit-status aikit-sync aikit-selftest; do link "$SRC/bin/$f" "$BIN/$f"; done
for f in rows.py i18n.sh strings.json; do link "$SRC/share/$f" "$SHARE/$f"; done
link "$SRC/bin/aikit-status" "$BAR/aikit-status"   # Omarchy "command" widget
for u in aikit-sync.service aikit-sync.timer; do link "$SRC/systemd/$u" "$UNITS/$u"; done

echo "Omarchy entries"
python3 "$SRC/omarchy/merge-config.py" ${DRY:+--dry-run}

echo "Sync service"
if [[ $DRY != --dry-run ]]; then
  systemctl --user daemon-reload
  systemctl --user enable --now aikit-sync.timer
  say "$(systemctl --user is-active aikit-sync.timer) — aikit-sync.timer"
fi

echo
if [[ $DRY != --dry-run ]]; then
  echo "Prerequisites"
  "$BIN/aikit" doctor || say "some prerequisites are missing — see above"
fi
echo
echo "Done. Check with:  aikit-selftest"
echo "Keybindings: add to ~/.config/hypr/bindings.lua"
echo '  o.bind("SUPER + CTRL + M", "AI Kit", "aikit")'
echo '  hl.unbind("SUPER + SHIFT + CTRL + A")   -- Omarchy: omarchy-agent --pick'
echo '  o.bind("SUPER + SHIFT + CTRL + A", "Claude (worktree)", "aikit claude")'
