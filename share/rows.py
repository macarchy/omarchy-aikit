#!/usr/bin/env python3
"""Construit les lignes des menus AI Kit à partir de la base locale.

Tout est lu dans ~/.local/share/aikit/aikit.db, alimentée par aikit-sync : les
menus ne touchent jamais le réseau. Chaque ligne porte une clé opaque en tête :
"<clé>\\t<glyphe>\\t<libellé>\\t<sous-titre>". L'appelant renvoie la clé au menu et
ne redécoupe jamais l'affichage — c'est ce contrat qui évite de reconstituer un
chemin ou un numéro à partir du texte montré à l'utilisateur.

  rows.py repos  <db>          chemins sur l'entrée standard
  rows.py counts <db> <nwo>    compteurs shell (ISSUES=…, ELIGIBLE=…, AGE=…)
  rows.py issues <db> <nwo>
  rows.py prs    <db> <nwo>
"""

import json
import os
import pathlib
import re
import sqlite3
import sys
import time

L = os.environ.get("AIKIT_L", "en")
HOME = str(pathlib.Path.home())

# Glyphes vérifiés présents dans JetBrainsMono Nerd Font.
G_STAR, G_ISSUE, G_PR = "", "", ""
G_LIVE, G_GITHUB, G_FOLDER = "", "", ""
G_PLANNED = "\U000f05e0"
G_CI = {"ok": "", "fail": "", "pending": "", "": G_PR}

CATALOG = json.loads((pathlib.Path(__file__).with_name("strings.json")).read_text())
STR = CATALOG[L if L in CATALOG else "en"]


def T(key, *args):
    """Une chaîne du catalogue partagé (le même que celui de i18n.sh)."""
    fmt = STR.get(key, key)
    return fmt % args if args else fmt


EFFORT = {"effort: small": 0, "effort: medium": 1, "effort: large": 2, "effort: xl": 3}


def con(path):
    c = sqlite3.connect("file:%s?mode=ro" % path, uri=True, timeout=5)
    c.row_factory = sqlite3.Row
    return c


def ago(ts):
    if not ts:
        return ""
    try:
        import datetime
        d = datetime.datetime.now(datetime.timezone.utc) - datetime.datetime.fromisoformat(
            ts.replace("Z", "+00:00"))
    except Exception:
        return ""
    if d.days > 60:
        return T("row_months", d.days // 30)
    if d.days >= 1:
        return T("row_days", d.days)
    h = d.seconds // 3600
    return T("row_hours", h) if h else T("row_now")


def short(t, n=76):
    return t if len(t) <= n else t[: n - 1] + "…"


def tilde(p):
    return "~" + p[len(HOME):] if p.startswith(HOME) else p


def nwo_of(path):
    cfg = pathlib.Path(path) / ".git" / "config"
    try:
        m = re.search(r"github\.com[:/]([^/\s]+)/([^/\s]+?)(?:\.git)?\s", cfg.read_text(errors="ignore"))
    except OSError:
        return None
    return "%s/%s" % (m.group(1), m.group(2)) if m else None


SORTS = ("recent", "pushed", "name", "stars", "issues", "prs")


def cmd_repos(db, mode="recent"):
    """Entrée : "<mtime>\t<chemin>" par ligne. Le tri se fait ici, sur les
    données locales — l'ordre d'arrivée sert de repli (dépôt touché en dernier)."""
    stats, live = {}, set(os.environ.get("AIKIT_SESSIONS", "").split())
    try:
        for r in con(db).execute(
                "SELECT nwo, stars, open_issues, open_prs, pushed_at FROM repos"):
            stats[r["nwo"]] = r
    except sqlite3.Error:
        pass

    entries = []
    for line in sys.stdin:
        line = line.rstrip("\n")
        if not line.strip():
            continue
        mtime, _, path = line.partition("\t")
        if not path:
            mtime, path = "0", mtime
        name = os.path.basename(path)
        slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
        nwo = nwo_of(path)
        bits = []
        if nwo and nwo in stats:
            s = stats[nwo]
            if s["stars"]:
                bits.append("%s %d" % (G_STAR, s["stars"]))
            if s["open_issues"]:
                bits.append("%s %d" % (G_ISSUE, s["open_issues"]))
            if s["open_prs"]:
                bits.append("%s %d" % (G_PR, s["open_prs"]))
        bits.append(tilde(path))
        glyph = G_LIVE if slug in live else (G_GITHUB if nwo else G_FOLDER)
        st = stats.get(nwo) if nwo else None
        key = {
            "recent": (-float(mtime or 0),),
            "pushed": ((st["pushed_at"] or "") if st else "", ),
            "name":   (name.lower(),),
            "stars":  (-(st["stars"] if st else 0), name.lower()),
            "issues": (-(st["open_issues"] if st else 0), name.lower()),
            "prs":    (-(st["open_prs"] if st else 0), name.lower()),
        }[mode if mode in SORTS else "recent"]
        if mode == "pushed":
            key = (key[0] == "", ) + tuple(reversed(key))   # jamais poussé → à la fin
        entries.append((key, "%s\t%s\t%s\t%s" % (path, glyph, name, " · ".join(bits))))

    entries.sort(key=lambda e: e[0], reverse=(mode == "pushed"))
    if mode == "pushed":                      # remet les « jamais poussés » en queue
        entries = [e for e in entries if e[0][0] is False] + [e for e in entries if e[0][0] is True]
    for _, row in entries:
        print(row)


def cmd_counts(db, nwo):
    """Compteurs d'un dépôt. Sans étage 2 (jamais synchronisé en détail), on
    retombe sur les totaux de l'étage 1 et on signale l'inconnu par -1."""
    issues = prs = planned = eligible = red = 0
    age = -1
    detailed = False
    try:
        c = con(db)
        detailed = c.execute(
            "SELECT 1 FROM tracked WHERE nwo = ? AND synced_at > 0", (nwo,)).fetchone() is not None
        for r in c.execute("SELECT labels, planned FROM issues WHERE nwo = ?", (nwo,)):
            issues += 1
            if r["planned"]:
                planned += 1
                if set(json.loads(r["labels"])) & {"effort: small", "effort: medium"}:
                    eligible += 1
        for r in c.execute("SELECT ci FROM prs WHERE nwo = ?", (nwo,)):
            prs += 1
            red += r["ci"] == "fail"
        row = c.execute("SELECT synced_at FROM tracked WHERE nwo = ?", (nwo,)).fetchone()
        if row and row["synced_at"]:
            age = (int(time.time()) - row["synced_at"]) // 60
        if not detailed:
            row = c.execute("SELECT open_issues, open_prs FROM repos WHERE nwo = ?", (nwo,)).fetchone()
            issues, prs = (row["open_issues"], row["open_prs"]) if row else (0, 0)
            planned = eligible = red = -1
    except sqlite3.Error:
        pass
    for k, v in (("ISSUES", issues), ("PLANNED", planned), ("ELIGIBLE", eligible),
                 ("PRS", prs), ("PRS_RED", red), ("AGE", age)):
        print("%s=%d" % (k, v))


def cmd_issues(db, nwo):
    rows = []
    for r in con(db).execute("SELECT * FROM issues WHERE nwo = ?", (nwo,)):
        labels = json.loads(r["labels"])
        effort = next((l for l in labels if l.startswith("effort:")), None)
        prio = next((l for l in labels if l.startswith("priority:")), None)
        area = next((l for l in labels if l.startswith("area:")), None)
        bits = [T("row_plan") if r["planned"] else T("row_noplan")]
        if r["assigned"]:
            bits.append(T("row_assigned"))
        if effort:
            bits.append(effort.split(": ", 1)[-1])
        if prio:
            bits.append(T("row_prio", prio.split(": ", 1)[-1]))
        if area:
            bits.append(area.split(": ", 1)[-1])
        bits.append(ago(r["updated_at"]))
        rows.append(((0 if r["planned"] else 1, EFFORT.get(effort, 9), -r["number"]),
                     "%d\t%s\t#%d %s\t%s" % (r["number"], G_PLANNED if r["planned"] else G_ISSUE,
                                             r["number"], short(r["title"]),
                                             " · ".join(b for b in bits if b))))
    for _, row in sorted(rows):
        print(row)


def cmd_prs(db, nwo):
    rank = {"fail": 0, "pending": 1, "ok": 2, "": 3}
    rows = []
    for r in con(db).execute("SELECT * FROM prs WHERE nwo = ?", (nwo,)):
        ci = r["ci"] or ""
        bits = []
        if r["draft"]:
            bits.append(T("row_draft"))
        bits.append(T("ci_" + (ci or "none")))
        if r["conflicting"]:
            bits.append(T("row_conflicts"))
        bits.append(ago(r["updated_at"]))
        rows.append(((1 if r["draft"] else 0, rank.get(ci, 3), -r["number"]),
                     "%d\t%s\t#%d %s\t%s" % (r["number"], G_CI[ci], r["number"], short(r["title"]),
                                             " · ".join(b for b in bits if b))))
    for _, row in sorted(rows):
        print(row)


if __name__ == "__main__":
    cmd, db = sys.argv[1], sys.argv[2]
    if cmd == "repos":
        cmd_repos(db, sys.argv[3] if len(sys.argv) > 3 else "recent")
    elif cmd == "counts":
        cmd_counts(db, sys.argv[3])
    elif cmd == "issues":
        cmd_issues(db, sys.argv[3])
    elif cmd == "prs":
        cmd_prs(db, sys.argv[3])
    else:
        sys.exit("rows.py: unknown command %s" % cmd)
