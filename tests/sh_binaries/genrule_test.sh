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
OUTPUT="$(cat "$(rlocation rules_sh_tests/sh_binaries/genrule_output_world)")"
assert_eq "$EXPECTED_OUTPUT" "$OUTPUT" "genrule_output_world"

EXPECTED_OUTPUT="Hello File"
OUTPUT="$(cat "$(rlocation rules_sh_tests/sh_binaries/genrule_output_data)")"
assert_eq "$EXPECTED_OUTPUT" "$OUTPUT" "genrule_output_data"

EXPECTED_OUTPUT="Hello World"$'\n'"Hello File"
OUTPUT="$(cat "$(rlocation rules_sh_tests/sh_binaries/genrule_output_by_path)")"
assert_eq "$EXPECTED_OUTPUT" "$OUTPUT" "genrule_output_by_path"
