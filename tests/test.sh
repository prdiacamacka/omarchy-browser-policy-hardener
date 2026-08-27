#!/bin/bash

set -euo pipefail

PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TEST_ROOT"' EXIT

export OMARCHY_HARDENER_TEST_ROOT=$TEST_ROOT
export OMARCHY_HARDENER_TESTING=1
export OMARCHY_HARDENER_TEST_VERSION=4.0.1-1

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_mode_owner() {
  local expected=$1 path=$2 actual
  actual=$(stat -c '%u:%g:%a' -- "$path")
  [[ $actual == "$expected" ]] || fail "$path is $actual, expected $expected"
}

mkdir -p \
  "$TEST_ROOT/etc/chromium/policies/managed" \
  "$TEST_ROOT/etc/brave/policies/managed" \
  "$TEST_ROOT/usr/lib/firefox/distribution" \
  "$TEST_ROOT/usr/share/omarchy/default/firefox" \
  "$TEST_ROOT/usr/bin" \
  "$TEST_ROOT/home/tester/.local/state/omarchy/current/theme"

chmod 0777 \
  "$TEST_ROOT/etc/chromium/policies/managed" \
  "$TEST_ROOT/etc/brave/policies/managed" \
  "$TEST_ROOT/usr/lib/firefox/distribution"

printf '{"BrowserThemeColor":"#000000"}\n' >"$TEST_ROOT/etc/chromium/policies/managed/color.json"
printf '{"ProxyMode":"fixed_servers"}\n' >"$TEST_ROOT/etc/chromium/policies/managed/unsafe.json"
chmod 0666 "$TEST_ROOT/etc/chromium/policies/managed/unsafe.json"
printf '{"SafePolicy":true}\n' >"$TEST_ROOT/etc/chromium/policies/managed/admin.json"
chmod 0644 "$TEST_ROOT/etc/chromium/policies/managed/admin.json"

printf '{"policies":{}}\n' >"$TEST_ROOT/usr/lib/firefox/distribution/policies.json"
chmod 0666 "$TEST_ROOT/usr/lib/firefox/distribution/policies.json"
printf '{"policies":{"DisableTelemetry":true}}\n' >"$TEST_ROOT/usr/share/omarchy/default/firefox/policies.json"
chmod 0644 "$TEST_ROOT/usr/share/omarchy/default/firefox/policies.json"
printf '26,27,38\n' >"$TEST_ROOT/home/tester/.local/state/omarchy/current/theme/chromium.theme"

printf '#!/bin/bash\necho original-theme\n' >"$TEST_ROOT/usr/bin/omarchy-theme-set-browser"
printf '#!/bin/bash\necho original-installer\n' >"$TEST_ROOT/usr/bin/omarchy-install-browser"
chmod 0755 "$TEST_ROOT/usr/bin/omarchy-theme-set-browser" "$TEST_ROOT/usr/bin/omarchy-install-browser"

if "$PROJECT_DIR/omarchy-browser-policy-hardener" --audit >/dev/null 2>&1; then
  fail "audit accepted vulnerable directories"
fi

"$PROJECT_DIR/omarchy-browser-policy-hardener" --install >/dev/null

assert_mode_owner 0:0:755 "$TEST_ROOT/etc/chromium/policies/managed"
assert_mode_owner 0:0:644 "$TEST_ROOT/etc/chromium/policies/managed/color.json"
assert_mode_owner 0:0:755 "$TEST_ROOT/etc/brave/policies/managed"
assert_mode_owner 0:0:644 "$TEST_ROOT/etc/brave/policies/managed/color.json"
assert_mode_owner 0:0:755 "$TEST_ROOT/usr/lib/firefox/distribution"
assert_mode_owner 0:0:644 "$TEST_ROOT/usr/lib/firefox/distribution/policies.json"

grep -q '#1a1b26' "$TEST_ROOT/etc/chromium/policies/managed/color.json" || fail "theme color was not retained"
grep -q 'DisableTelemetry' "$TEST_ROOT/usr/lib/firefox/distribution/policies.json" || fail "Firefox policy was not restored"
[[ ! -e $TEST_ROOT/etc/chromium/policies/managed/unsafe.json ]] || fail "unsafe Chromium policy survived"
[[ -e $TEST_ROOT/etc/chromium/policies/managed/admin.json ]] || fail "safe admin policy was removed"
[[ -e $TEST_ROOT/etc/pacman.d/hooks/95-omarchy-browser-policy-hardener.hook ]] || fail "pacman hook missing"

"$PROJECT_DIR/omarchy-browser-policy-hardener" --audit >/dev/null

# Simulate a same-version package update overwriting the patched scripts. The
# installed pacman-hook target must restore the mitigation idempotently.
printf '#!/bin/bash\necho vulnerable-update\n' >"$TEST_ROOT/usr/bin/omarchy-theme-set-browser"
printf '#!/bin/bash\necho vulnerable-installer-update\n' >"$TEST_ROOT/usr/bin/omarchy-install-browser"
"$TEST_ROOT/usr/local/libexec/omarchy-browser-policy-hardener" --repair >/dev/null
grep -q 'omarchy-theme-browser-policy' "$TEST_ROOT/usr/bin/omarchy-theme-set-browser" || fail "same-version repair did not restore theme patch"
grep -q 'setup_policy_directory' "$TEST_ROOT/usr/bin/omarchy-install-browser" || fail "same-version repair did not restore installer patch"

# Unknown versions may have changed their scripts. Harden policy paths, but do
# not overwrite unknown package code with the 4.0.1 payload.
export OMARCHY_HARDENER_TEST_VERSION=4.0.2-1
printf '#!/bin/bash\necho future-version\n' >"$TEST_ROOT/usr/bin/omarchy-theme-set-browser"
"$TEST_ROOT/usr/local/libexec/omarchy-browser-policy-hardener" --repair >/dev/null 2>&1
grep -q future-version "$TEST_ROOT/usr/bin/omarchy-theme-set-browser" || fail "unknown Omarchy version was overwritten"
export OMARCHY_HARDENER_TEST_VERSION=4.0.1-1

"$PROJECT_DIR/omarchy-browser-policy-hardener" --uninstall >/dev/null
grep -q original-theme "$TEST_ROOT/usr/bin/omarchy-theme-set-browser" || fail "theme script was not restored"
grep -q original-installer "$TEST_ROOT/usr/bin/omarchy-install-browser" || fail "browser installer was not restored"
[[ ! -e $TEST_ROOT/etc/sudoers.d/omarchy-theme-browser-policy ]] || fail "sudoers rule survived uninstall"
[[ ! -e $TEST_ROOT/etc/pacman.d/hooks/95-omarchy-browser-policy-hardener.hook ]] || fail "hook survived uninstall"
assert_mode_owner 0:0:755 "$TEST_ROOT/etc/chromium/policies/managed"

SYMLINK_ROOT=$(mktemp -d)
mkdir -p "$SYMLINK_ROOT/etc/chromium/policies" "$SYMLINK_ROOT/usr/bin" "$SYMLINK_ROOT/target"
ln -s "$SYMLINK_ROOT/target" "$SYMLINK_ROOT/etc/chromium/policies/managed"
export OMARCHY_HARDENER_TEST_ROOT=$SYMLINK_ROOT
if "$PROJECT_DIR/omarchy-browser-policy-hardener" --repair >/dev/null 2>&1; then
  fail "repair accepted a symlinked policy directory"
fi
[[ -L $SYMLINK_ROOT/etc/chromium/policies/managed ]] || fail "symlink was replaced"
rm -rf -- "$SYMLINK_ROOT"

echo "All functional tests passed"
