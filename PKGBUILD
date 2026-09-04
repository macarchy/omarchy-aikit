# Maintainer: Philippe Matray <phmatray@gmail.com>
pkgname=aikit-git
_pkgname=aikit
pkgver=0.1.0.r11.gd092f81
pkgrel=1
install=aikit.install
pkgdesc="Desktop launcher for the AI Migration Kit skills, backed by a local GitHub mirror"
arch=('any')
url="https://github.com/macarchy/omarchy-aikit"
license=('MIT')
# Ce que « aikit doctor » exige : tmux, jq, python3, sqlite3, git, gh.
depends=('bash' 'git' 'github-cli' 'jq' 'python' 'sqlite' 'tmux')
optdepends=(
  'omarchy: menu entries, bar widget and the menu picker (omarchy-menu-select)'
  'libnotify: desktop notification when a session finishes'
)
makedepends=('git')
provides=("$_pkgname=$pkgver")
conflicts=("$_pkgname")
source=("$_pkgname::git+https://github.com/macarchy/omarchy-aikit.git")
sha256sums=('SKIP')

pkgver() {
  cd "$srcdir/$_pkgname"
  # Depuis la dernière étiquette (v0.1.0 → 0.1.0.r12.gabcdef1) ; sans étiquette,
  # on retombe sur le seul compte de commits.
  git describe --long --tags --abbrev=7 2>/dev/null |
    sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g' ||
    printf '0.r%s.g%s' "$(git rev-list --count HEAD)" "$(git rev-parse --short=7 HEAD)"
}

check() {
  cd "$srcdir/$_pkgname"
  # La suite tourne sur un bac à sable bouchonné : ni réseau, ni fenêtre.
  ./bin/aikit-selftest
}

package() {
  cd "$srcdir/$_pkgname"

  # Les mêmes fichiers que ./install.sh, mais à l'échelle du système.
  for bin in aikit aikit-status aikit-sync aikit-selftest; do
    install -Dm755 "bin/$bin" "$pkgdir/usr/bin/$bin"
  done

  for res in rows.py i18n.sh strings.json; do
    install -Dm644 "share/$res" "$pkgdir/usr/share/$_pkgname/$res"
  done

  install -Dm755 omarchy/merge-config.py "$pkgdir/usr/share/$_pkgname/omarchy/merge-config.py"
  install -Dm644 omarchy/fragments/menu-rows.jsonc "$pkgdir/usr/share/$_pkgname/omarchy/fragments/menu-rows.jsonc"
  install -Dm644 omarchy/fragments/bar-widget.json "$pkgdir/usr/share/$_pkgname/omarchy/fragments/bar-widget.json"

  install -Dm644 systemd/aikit-sync.service "$pkgdir/usr/lib/systemd/user/aikit-sync.service"
  install -Dm644 systemd/aikit-sync.timer "$pkgdir/usr/lib/systemd/user/aikit-sync.timer"

  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
}
