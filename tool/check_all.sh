#!/usr/bin/env bash
# tool/check_all.sh: every check, one PASS or FAIL line each, then ALL PASSED or
# "N FAILED". Keeps going after a failure so one run shows everything. The full
# output of each check goes to a log file in a temp dir (its path is printed on
# a FAIL). Run from anywhere.
#
#   tool/check_all.sh

cd "$(dirname "$0")/.." || exit 1

LOG_DIR="$(mktemp -d)" || exit 1
FAILED=0

# test_count <log>: `00:03 +46: All tests passed!` -> "46 tests".
test_count() {
  local line
  line="$(grep -E '^[0-9][0-9:]* \+[0-9]+( ~[0-9]+)?: All tests passed' "$1" | tail -n 1)"
  [ -n "$line" ] && printf '%s tests' "$(printf '%s\n' "$line" | sed -E 's/^[0-9][0-9:]* \+([0-9]+).*/\1/')"
}

# run <name> <command...>
run() {
  local name="$1" log start secs rc count last
  shift
  log="$LOG_DIR/$(printf '%s' "$name" | tr -c 'A-Za-z0-9._-' '_').log"
  start=$(date +%s)
  "$@" </dev/null >"$log" 2>&1
  rc=$?
  secs=$(( $(date +%s) - start ))
  if [ "$rc" -eq 0 ]; then
    count="$(test_count "$log")"
    printf 'PASS  %s  (%ss%s)\n' "$name" "$secs" "${count:+, $count}"
  else
    last="$(grep -v '^[[:space:]]*$' "$log" | tail -n 1)"
    printf 'FAIL  %s  (%ss)  log: %s\n      last line: %s\n' "$name" "$secs" "$log" "$last"
    FAILED=$((FAILED + 1))
  fi
}

# Dart sources that are hand-written: the generated l10n files are not formatted
# by us, and copied kits under packages/ keep the formatting they came with.
format_dart() {
  local files
  files="$(find lib test tool -name '*.dart' ! -path 'lib/l10n/app_localizations*' 2>/dev/null)"
  # shellcheck disable=SC2086
  dart format --output=none --set-exit-if-changed $files
}

run "architecture" dart run tool/check_architecture.dart
run "analyze" flutter analyze
run "test" flutter test
run "format" format_dart

if [ "$FAILED" -eq 0 ]; then
  echo "ALL PASSED"
  exit 0
fi
echo "$FAILED FAILED"
exit 1
