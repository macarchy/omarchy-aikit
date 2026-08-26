# AI Kit

Lanceur graphique des skills de l'[AI Migration Kit](https://github.com/phmatray/ai-migration-kit)
pour [Omarchy](https://omarchy.org/) : on choisit un dépôt, puis une skill, et la
session Claude démarre dans un terminal tmux. Les menus lisent une base SQLite
locale tenue à jour en tâche de fond — aucun appel réseau dans le parcours.

```
SUPER + CTRL + M   ou   clic sur 󱓞 dans la barre
  → dépôt (243 clones, triables, avec étoiles / issues / PR)
  → skill (compteurs du dépôt : issues éligibles, PR en CI rouge…)
  → paramètre (issue ou PR choisie dans une liste, nombre d'agents…)
  → tmux + claude "/ai-migration-kit:<skill> …"
```

## File de travail

`aikit work` (clic milieu sur 󱓞, ou « AI Kit · work queue » dans le menu) répond à
« sur quoi je bosse ? » **sans choisir de dépôt** : une seule liste, tous dépôts
confondus, dans l'ordre où ça compte.

```
  #433 Per-exam accommodation opt-in…     CI failing · Atypical-Consulting/Lectio · 2 months ago
  #217 fix(loader): standalone project…   review requested · Atypical-Consulting/RoselineMCP · 4h ago
ᛦ #218 fix(website): per-kind tool counts your PR · Atypical-Consulting/RoselineMCP · just now
⊙ #61  Wire the audit marker              assigned to you · phmatray/Koine · 2d ago
✔ #271 Lever 4 never priced the top tier  planned, ready to build · phmatray/ai-migration-kit · 2d ago
```

Choisir une ligne ouvre directement la bonne session dans le bon clone :
`merge-pr` pour une PR à toi, `/code-review` pour une review demandée,
`implement-issue` pour une issue. Sans clone local, la page GitHub s'ouvre.

## Navigation

`↑` `↓` parcourent la liste, la frappe filtre, `→` ou `Entrée` valident.
`Échap`, la ligne « Back » ou `←` **reviennent d'un cran** — du choix de l'issue
au menu des skills, du menu des skills au choix du dépôt — au lieu de tout
annuler. Depuis le choix du dépôt, `Échap` ferme.

Une session par lancement : deux dépôts qui portent le même nom de dossier chez
des propriétaires différents (`phmatray/.github` et `Atypical-Consulting/.github`)
ont des sessions distinctes, et relancer une skill sur un dépôt déjà ouvert crée
une session neuve plutôt que de rattacher silencieusement la précédente. Quand
claude a rendu la main, le pane reste ouvert pour que la sortie soit lisible :
la session est alors marquée *terminée* et ne compte plus comme travail en cours.

## Installation

**Arch / Omarchy — paquet :**

```bash
omarchy pkg aur add aikit-git      # ou : yay -S aikit-git
aikit doctor                       # prérequis
aikit setup                        # entrées de menu Omarchy
systemctl --user enable --now aikit-sync.timer
omarchy plugin add https://github.com/phmatray/omarchy-aikit.git --enable   # widget de barre
```

**Depuis les sources** (n'importe quelle distribution, ou pour bricoler) :

```bash
git clone https://github.com/phmatray/aikit && cd aikit
./install.sh                       # liens symboliques, timer systemd, entrées Omarchy
aikit-selftest                     # 32 vérifications, sans réseau ni fenêtre
```

`./install.sh --dry-run` montre ce qui serait touché ; `./uninstall.sh` défait tout
(la base et le cache sont conservés). Chaque fichier remplacé est sauvegardé
avec un horodatage.

## Le widget de barre

Ce dépôt **est aussi un plugin Omarchy** : `manifest.json` et `BarWidget.qml`
sont à la racine, là où `omarchy plugin add` les attend.

```
󱓞          rien en cours
󱓞 2 · 7✓   deux sessions, sept PR mergées
󱓞 2 !      une session détachée et silencieuse : un agent attend une décision
󱓞          la synchronisation est en échec (détail au survol)
```

| Geste | Action |
|---|---|
| clic gauche | choisir un dépôt, puis une skill |
| clic milieu | la file de travail, tous dépôts confondus |
| clic droit | reprendre une session en cours |

Le QML ne fait que le rendu : tout vient de la commande `aikit-status`, au format
JSON Waybar (`{text, tooltip, class}`). Réglages possibles sur l'entrée du widget
dans `shell.json` : `interval` (10 s), `exec` (`aikit-status`), `launcher` (`aikit`).

Sans le plugin, `aikit setup` pose une entrée `type: command` équivalente — il ne
pose jamais les deux.

`aikit doctor` vérifie les prérequis un par un et dit quoi installer :
`gh` authentifié, `tmux`, `jq`, `python3`, `sqlite3`, `git`, `claude`, Omarchy,
et le plugin [ai-migration-kit](https://github.com/phmatray/ai-migration-kit)
côté Claude Code — sans lui, les skills n'existent pas.

Les racines de dépôts sont devinées au premier lancement parmi les emplacements
courants (`~/src`, `~/code`, `~/dev`, `~/git`, `~/repos`, `~/Projects`, `~/Work`,
`~/Development`) ; `AIKIT_ROOTS` les remplace, dans l'environnement ou dans
`~/.config/aikit/config`.

## Ce que la base contient, et où elle reste

`~/.local/share/aikit/aikit.db` stocke des **noms de dépôts, des titres d'issues
et de PR, des labels et des états CI — y compris pour tes dépôts privés**. Elle
est écrite par `aikit-sync` depuis ton `gh` authentifié, elle vit sous ton compte
et **elle ne quitte jamais la machine** : aucun composant ne l'envoie ailleurs.
`uninstall.sh` la laisse en place ; supprime `~/.local/share/aikit` et
`~/.cache/aikit` pour tout effacer.

## Les morceaux

| Chemin | Rôle |
|---|---|
| `bin/aikit` | le parcours : dépôt → skill → paramètres → session tmux |
| `bin/aikit-sync` | remplit la base depuis GitHub (timer systemd, 5 min) |
| `bin/aikit-selftest` | joue les parcours sur un bac à sable bouchonné |
| `share/rows.py` | construit les lignes de menu depuis la base |
| `share/strings.json` | catalogue de chaînes EN/FR, source unique |
| `omarchy/` | widget de barre, fragments de configuration, fusion idempotente |

## La base

`~/.local/share/aikit/aikit.db`, deux étages pour ne payer que ce qui sert :

* **étage 1** — un `gh repo list` par compte : étoiles, issues et PR ouvertes de
  tous les dépôts. Rafraîchi s'il a plus de 30 min.
* **étage 2** — issues et PR détaillées (titres, labels, plan d'implémentation,
  état CI) des seuls dépôts *suivis* : ceux ouverts au moins une fois par aikit,
  pendant 30 jours.

* **étage 3** — la boîte de travail : quatre recherches GitHub (`review-requested`,
  `author:@me`, `status:failure`, `assignee:@me`) qui couvrent *tous* les dépôts,
  plus les issues planifiées et calibrées des dépôts suivis.

`aikit-sync --status` affiche l'âge des données et la santé de la synchronisation.
Une panne (jeton expiré, réseau coupé) est consignée dans la base et remonte dans
la barre :  suivi du message d'erreur — une base qui ne se met plus à jour
ne doit jamais mentir en silence.

## Conventions

**Contrat des menus.** Chaque ligne est `<clé>\t<glyphe>\t<libellé>\t<sous-titre>` ;
`menu_pick` n'envoie que l'affichage au menu et rend la clé. Rien n'est jamais
reconstitué en redécoupant le texte montré à l'utilisateur — c'est ce qui permet
qu'un dépôt s'appelle « gamma · delta » ou qu'une issue s'intitule « #999 crash ».

**Icônes.** Toujours par point de code (`$''`, `chr(0x…)`), jamais en collant
le glyphe : les glyphes du plan multilingue de base se perdent en route. Vérifier
la présence avec `fc-list "JetBrainsMono Nerd Font" charset`, puis le sens en
rendant un échantillon.

**Langue.** `strings.json` porte l'anglais et le français ; la langue suit la
locale, `AIKIT_LANG=fr` la force.

## Réglages

| Variable | Défaut | Effet |
|---|---|---|
| `AIKIT_ROOTS` | `~/Data/Repositories ~/Work ~/Projects` | où chercher les clones |
| `AIKIT_CLAUDE_FLAGS` | `--permission-mode acceptEdits` | options passées à `claude` |
| `AIKIT_LANG` | locale | `en` ou `fr` |
| `AIKIT_STALL_SECS` | `300` | silence au-delà duquel un agent est réputé bloqué |
| `AIKIT_SYNC_STALE_SECS` | `1200` | âge au-delà duquel la synchro est signalée en retard |
