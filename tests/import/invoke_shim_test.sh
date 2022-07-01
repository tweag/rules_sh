#!/usr/bin/env bash
# --- begin runfiles.bash initialization v2 ---
# Copy-pasted from the Bazel Bash runfiles library v2.
set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---
set -euo pipefail

assert_eq() {
  if [[ "$1" != "$2" ]]; then
    echo -e "Wrong output found in $3:\nExpected: '$1'\nGot: '$2'"
    return 1
  fi
}

EXPECTED_OUTPUT="Hello World"
OUTPUT="$(cat "$(rlocation "rules_sh/tests/import/invoke_shim.out")" | tr -d '\376\377')"  # Remove BOM
assert_eq "$EXPECTED_OUTPUT" "$OUTPUT" "invoke_shim"
