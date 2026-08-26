# Maintainer: Philippe Matray <phmatray@gmail.com>
pkgname=aikit-git
_pkgname=aikit
pkgver=0.1.0.r0.0000000
pkgrel=1
install=aikit.install
pkgdesc="Desktop launcher for the AI Migration Kit skills, backed by a local GitHub mirror"
arch=('any')
url="https://github.com/phmatray/aikit"
license=('MIT')
depends=('bash' 'git' 'jq' 'python' 'sqlite' 'tmux' 'github-cli')
optdepends=(
  'omarchy: menu entries and bar widget'
  'omarchy-aikit: Quickshell bar widget for Omarchy'
)
makedepends=('git')
provides=("$_pkgname")
conflicts=("$_pkgname")
source=("$_pkgname::git+https://github.com/phmatray/aikit.git")
sha256sums=('SKIP')

pkgver() {
  cd "$srcdir/$_pkgname"
  printf '0.1.0.r%s.%s' "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

check() {
  cd "$srcdir/$_pkgname"
  # La suite tourne sur un bac à sable bouchonné : ni réseau, ni fenêtre.
  ./bin/aikit-selftest
}

package() {
  cd "$srcdir/$_pkgname"

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
