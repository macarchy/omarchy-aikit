# Maintainer: Philippe Matray <phmatray@gmail.com>
pkgname=aikit
_pkgname=aikit
# Rewritten from the tag by the packaging job before makepkg runs. This value is
# the fallback for a manual makepkg from a checkout.
pkgver=0.3.1
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
# Was aikit-git, built from HEAD with a pkgver() running `git describe`. It is a
# release package now: the source is the tag's tarball, so the artifact attached
# to a release matches that release. The -git variant is retired, not kept beside
# this one -- two packages for one program is how they drift.
conflicts=("$_pkgname-git")   # retiring the VCS variant, not living beside it
source=("$_pkgname-$pkgver.tar.gz::$url/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('SKIP')

check() {
  cd "$srcdir/omarchy-aikit-$pkgver"
  # La suite tourne sur un bac à sable bouchonné : ni réseau, ni fenêtre.
  ./bin/aikit-selftest
}

package() {
  cd "$srcdir/omarchy-aikit-$pkgver"

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
