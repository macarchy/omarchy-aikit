#!/bin/bash
# Retire AI Kit : liens, unités systemd, entrées Omarchy. Laisse la base et le
# cache (~/.local/share/aikit/aikit.db, ~/.cache/aikit) — à toi de les effacer.
set -euo pipefail

systemctl --user disable --now aikit-sync.timer 2>/dev/null || true
rm -f "$HOME"/.local/bin/{aikit,aikit-sync,aikit-selftest}
rm -f "$HOME"/.local/share/aikit/{rows.py,i18n.sh,strings.json}
rm -f "$HOME/.config/omarchy/bar/scripts/aikit-status"
rm -f "$HOME"/.config/systemd/user/aikit-sync.{service,timer}
systemctl --user daemon-reload

python3 - <<'PY'
import json, pathlib, shutil, time
home = pathlib.Path.home()
menu = home/".config/omarchy/extensions/omarchy-menu.jsonc"
if menu.exists():
    shutil.copy2(menu, f"{menu}.bak.{int(time.time())}")
    lines = [l for l in menu.read_text().splitlines()
             if not l.strip().startswith('"aikit') and "AI Kit — installé" not in l]
    menu.write_text("\n".join(lines) + "\n")
shell = home/".config/omarchy/shell.json"
if shell.exists():
    shutil.copy2(shell, f"{shell}.bak.{int(time.time())}")
    cfg = json.loads(shell.read_text())
    right = cfg["bar"]["layout"]["right"]
    right[:] = [w for w in right if w.get("id") != "aikit"]
    shell.write_text(json.dumps(cfg, indent=2, ensure_ascii=False) + "\n")
PY
echo "AI Kit retiré. La base et le cache sont conservés."
