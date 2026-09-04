# Publishing `aikit-git` to the AUR

The package is **prepared but not published**. Everything the AUR needs lives at
the repository root:

| File | Role |
|---|---|
| `PKGBUILD` | the recipe — `git+https://github.com/macarchy/omarchy-aikit.git`, `arch=('any')` |
| `.SRCINFO` | the generated metadata the AUR parses; must match `PKGBUILD` |
| `aikit.install` | the post-install note (`aikit doctor`, `aikit setup`, the timer) |

## What was already checked

* `makepkg -f --nodeps` builds cleanly on aarch64 Arch: `pkgver()` resolved to
  `0.1.0.r11.gd092f81` from the `v0.1.0` tag, `check()` ran `bin/aikit-selftest`
  (60 checks passed), and `package()` produced
  `aikit-git-0.1.0.r11.gd092f81-1-any.pkg.tar.xz` containing exactly what
  `install.sh` installs — the four `bin/` commands, the three `share/`
  resources, `omarchy/merge-config.py` and its two fragments, and the two
  systemd user units.
* `--nodeps` was needed only because `github-cli` is not installed on the build
  machine (`gh` comes from mise here). The dependency itself is correct.
* `namcap` is **not installed** on this machine, so the package was never linted.
  Run `namcap PKGBUILD` and `namcap aikit-git-*.pkg.tar.*` before the first push.

## The remaining steps — yours to run

They need your own AUR account and SSH key; nothing here can do them for you.

1. **Account and key.** Create an account on <https://aur.archlinux.org>, then add
   your public key under *My Account → SSH Public Key*.

2. **Check the name is free.**

   ```bash
   curl -s 'https://aur.archlinux.org/rpc/v5/info?arg[]=aikit-git' | jq '.resultcount'
   ```

   `0` means the name is available.

3. **Clone the (empty) AUR repository.**

   ```bash
   git clone ssh://aur@aur.archlinux.org/aikit-git.git ~/Work/aur-aikit-git
   ```

4. **Copy the three files in, regenerate `.SRCINFO`, and lint.**

   ```bash
   cd ~/Work/aur-aikit-git
   cp ~/Work/omarchy-aikit/{PKGBUILD,aikit.install} .
   makepkg --printsrcinfo > .SRCINFO
   namcap PKGBUILD                       # pacman -S namcap first
   makepkg -si                           # last dry run, installs locally
   ```

5. **Commit and push.** The AUR only accepts these files; never `git add -A` a
   built package or a `src/` directory.

   ```bash
   git add PKGBUILD .SRCINFO aikit.install
   git commit -m "aikit-git: initial import"
   git push origin master        # the AUR branch is master, not main
   ```

6. **Then update the README.** The Installation section still says an AUR package
   is *pending*; replace it with `yay -S aikit-git` once the push succeeds.

## Keeping the two copies in sync

A `-git` package tracks `main`, so the recipe rarely changes — but when it does
(a new dependency, a new file in `package()`), edit `PKGBUILD` **here** first,
then repeat steps 4 and 5. `.SRCINFO` must be regenerated in the same commit or
the AUR rejects the push.
