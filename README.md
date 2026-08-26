# omarchy-aikit

Widget de barre [Omarchy](https://omarchy.org/) pour
[AI Kit](https://github.com/phmatray/aikit) : les sessions Claude en cours, les
PR déjà atterries par une flotte `auto-dev`, et la santé de la synchronisation
GitHub — plus un clic vers la file de travail.

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

## Installation

```bash
omarchy plugin add https://github.com/phmatray/omarchy-aikit.git --enable
```

Le widget affiche la sortie de la commande `aikit-status`, fournie par
[AI Kit](https://github.com/phmatray/aikit) — **installe-le d'abord**, sinon le
widget affiche l'erreur au survol. Toute la logique (base locale, sessions,
santé) vit là-bas : ce dépôt ne contient que le rendu.

## Réglages

Dans `~/.config/omarchy/shell.json`, sur l'entrée du widget :

| Clé | Défaut | Effet |
|---|---|---|
| `interval` | `10` | secondes entre deux rafraîchissements |
| `exec` | `aikit-status` | commande qui produit le JSON `{text, tooltip, class}` |
| `launcher` | `aikit` | commande lancée par les clics |

## Licence

MIT — voir [LICENSE](LICENSE).
