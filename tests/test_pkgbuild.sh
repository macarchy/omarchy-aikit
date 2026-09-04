#!/bin/bash
# tests/test_pkgbuild.sh — this repo shipped a PKGBUILD that nothing built.
#
# It was `aikit-git`: sourced from git+https, versioned by a pkgver() running
# `git describe`, and published nowhere. A release carried only GitHub's source
# zip. It is a release package now — the source is the tag's tarball, so the
# artifact attached to a release is built from that release. macarchy-install#17.
set -uo pipefail
cd "$(dirname "$0")/.."

fails=0
check() { local name=$1; shift; if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails+1)); fi; }
# Comments name every artefact, so a whole-file grep passes even when the line is
# gone. Read the code.
code() { grep -v '^[[:space:]]*#' PKGBUILD; }

check "it is aikit, not aikit-git"        grep -q '^pkgname=aikit$' <(code)
check "sourced from the release tarball"  grep -q 'archive/refs/tags/v\$pkgver.tar.gz' <(code)
check "not from git"                      bash -c '! grep -q "git+https" <(grep -v "^[[:space:]]*#" PKGBUILD)'
check "no pkgver() left"                  bash -c '! grep -q "^pkgver()" <(grep -v "^[[:space:]]*#" PKGBUILD)'
check "the -git variant is retired"       grep -q 'conflicts=("\$_pkgname-git")' <(code)
check "it does not provide its own name"  bash -c '! grep -q "^provides=" <(grep -v "^[[:space:]]*#" PKGBUILD)'

# What made the original PKGBUILD good, and must survive the conversion.
check "check() still runs the selftest"   grep -q 'aikit-selftest' <(code)
check "the post-install note survives"    grep -q 'install=aikit.install' <(code)

# The workflow lessons from macarchy-install#16, each a real failure there.
WF=.github/workflows/release-please.yml
check "no standalone package workflow"    [ ! -e .github/workflows/package.yml ]
check "the job hangs off release_created" grep -q 'release_created' "$WF"
check "not a release: published trigger"  bash -c '! grep -q "types: \[published\]" '"$WF"
check "pkgver is rewritten from the tag"  grep -q 'pkgver=\${TAG#v}' "$WF"
check "and the rewrite is verified"       grep -q 'grep -q "\^pkgver=\${TAG#v}\$" PKGBUILD' "$WF"
check "extra-files is not used"           bash -c '! grep -q "extra-files" release-please-config.json'
check "the upload globs"                  grep -q '\*.pkg.tar.\*' "$WF"
check "gh is installed in the container"  grep -q 'github-cli' "$WF"
# check() runs the selftest, which needs tmux/sqlite/gh and a session; in a build
# container it fails for want of an environment. ci.yml runs it properly and has
# to be green before main -- running it twice, the second time somewhere it
# cannot work, only ever produces a false red.
check "the build skips check() in CI"     grep -q -- '--nocheck' "$WF"
check "but the selftest is still a gate"  grep -q 'aikit-selftest' .github/workflows/ci.yml

(( fails == 0 )) && echo "all ok" || echo "$fails failed"
exit $(( fails > 0 ))
