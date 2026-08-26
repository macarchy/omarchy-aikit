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

## Installation

```bash
git clone <ce dépôt> ~/Data/Repositories/phmatray/public/aikit
cd aikit && ./install.sh          # liens symboliques, timer systemd, entrées Omarchy
aikit-selftest                    # 17 vérifications, sans réseau ni fenêtre
```

`./install.sh --dry-run` montre ce qui serait touché ; `./uninstall.sh` défait tout
(la base et le cache sont conservés). Chaque fichier remplacé est sauvegardé
avec un horodatage.

Prérequis : `gh` authentifié, `tmux`, `jq`, `python3`, `sqlite3`, Omarchy.

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
