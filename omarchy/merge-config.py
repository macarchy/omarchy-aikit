#!/usr/bin/env python3
"""Insère (ou met à jour) les entrées AI Kit dans la configuration d'Omarchy.

Touche deux fichiers de l'utilisateur, toujours de façon idempotente et avec
sauvegarde horodatée :

  ~/.config/omarchy/extensions/omarchy-menu.jsonc   lignes de menu
  ~/.config/omarchy/shell.json                      widget de barre
"""
import json
import pathlib
import re
import shutil
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
HOME = pathlib.Path.home()
MENU = HOME / ".config/omarchy/extensions/omarchy-menu.jsonc"
SHELL = HOME / ".config/omarchy/shell.json"
DRY = "--dry-run" in sys.argv
MARK = "// AI Kit — installé par aikit/install.sh"


def backup(path):
    if not DRY and path.exists():
        shutil.copy2(path, f"{path}.bak.{int(time.time())}")


def merge_menu():
    rows = (HERE / "fragments/menu-rows.jsonc").read_text().rstrip("\n")
    if not MENU.exists():
        print(f"  absent, ignoré : {MENU}")
        return
    text = MENU.read_text()
    kept = [l for l in text.splitlines()
            if not l.strip().startswith('"aikit') and l.strip() != MARK]
    while kept and not kept[-1].strip():
        kept.pop()
    if kept and kept[-1].strip() == "}":
        kept.pop()
    body = "\n".join(kept).rstrip()
    new = f"{body}\n\n  {MARK}\n{rows}\n}}\n"
    if new == text:
        print("  menu : déjà à jour")
        return
    backup(MENU)
    if not DRY:
        MENU.write_text(new)
    print("  menu : entrées AI Kit à jour")


def resolve(text):
    """Remplace les jetons par les chemins réellement installés."""
    binary = shutil.which("aikit") or str(HOME / ".local/bin/aikit")
    script = HOME / ".config/omarchy/bar/scripts/aikit-status"
    return text.replace("@AIKIT_BIN@", binary).replace("@AIKIT_BAR_SCRIPT@", str(script))


def merge_shell():
    widget = json.loads(resolve((HERE / "fragments/bar-widget.json").read_text()))
    if not SHELL.exists():
        print(f"  absent, ignoré : {SHELL}")
        return
    cfg = json.loads(SHELL.read_text())
    right = cfg.setdefault("bar", {}).setdefault("layout", {}).setdefault("right", [])
    before = json.dumps(right, sort_keys=True)
    right[:] = [w for w in right if w.get("id") != "aikit"]
    anchor = next((i for i, w in enumerate(right) if w.get("id") == "github"), len(right) - 1)
    right.insert(anchor + 1, widget)
    if json.dumps(right, sort_keys=True) == before:
        print("  barre : déjà à jour")
        return
    backup(SHELL)
    if not DRY:
        SHELL.write_text(json.dumps(cfg, indent=2, ensure_ascii=False) + "\n")
    print("  barre : widget AI Kit à jour")


merge_menu()
merge_shell()
