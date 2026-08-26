#!/bin/bash
# ---------------------------------------------------------------------------
# Installe AI Kit : liens symboliques vers ce dépôt, unités systemd, entrées
# Omarchy. Idempotent — relançable après un `git pull` sans rien casser.
#
#   ./install.sh            installe ou met à jour
#   ./install.sh --dry-run  montre ce qui serait fait
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

link() { # link <source> <destination> — sauvegarde un vrai fichier existant
  local src="$1" dst="$2"
  if [[ -L $dst ]]; then
    [[ $(readlink -f "$dst") == "$src" ]] && { say "à jour   $dst"; return 0; }
  elif [[ -e $dst ]]; then
    run mv "$dst" "$dst.bak.$(date +%s)"
    say "sauvegardé $dst"
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -sfn "$src" "$dst"
  say "lié      $dst"
}

echo "AI Kit — installation depuis $SRC"

for f in aikit aikit-sync aikit-selftest; do link "$SRC/bin/$f" "$BIN/$f"; done
for f in rows.py i18n.sh strings.json; do link "$SRC/share/$f" "$SHARE/$f"; done
link "$SRC/omarchy/bar-scripts/aikit-status" "$BAR/aikit-status"
for u in aikit-sync.service aikit-sync.timer; do link "$SRC/systemd/$u" "$UNITS/$u"; done

echo "Entrées Omarchy"
python3 "$SRC/omarchy/merge-config.py" ${DRY:+--dry-run}

echo "Service de synchronisation"
if [[ $DRY != --dry-run ]]; then
  systemctl --user daemon-reload
  systemctl --user enable --now aikit-sync.timer
  say "$(systemctl --user is-active aikit-sync.timer) — aikit-sync.timer"
fi

echo
echo "Fait. Vérifie avec :  aikit-selftest    puis    aikit-sync --status"
echo "Raccourci clavier : ajoute à ~/.config/hypr/bindings.lua"
echo '  o.bind("SUPER + CTRL + M", "AI Kit", "aikit")'
