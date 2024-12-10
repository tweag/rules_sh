#!/usr/bin/env bash

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
    source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
    source "$0.runfiles/$f" 2>/dev/null || \
    source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
    source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
    { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---

set -euo pipefail

SHIM_EXE="$(rlocation "$1")"
EMPTY_EXE="$(rlocation "$2")"

SHIMMED_EXE="$(rlocation "$3")"
SHIMMED_SHIM="$(rlocation "$4")"

ANOTHER_EXE="$(rlocation "$5")"
ANOTHER_SHIM="$(rlocation "$6")"

assert_file_eq() {
  comm "$1" "$2" || {
    echo "Expected files to be equal, but they are different: '$1' and '$2'". >&2
    return 1
  }
}

# Test that the shims use the correct shim.exe.

assert_file_eq "$SHIM_EXE" "$SHIMMED_EXE"
assert_file_eq "$SHIM_EXE" "$ANOTHER_EXE"

parse_shim() {
  local line
  read -r line <"$1" || true
  if [[ $line =~ ^path\ \=\ (.*)$ ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo "Malformed shim file: '$1'" >&2
    return 1
  fi
}

# Test that the target of the shim matches the correct target file.

SHIMMED_TARGET="$(parse_shim "$SHIMMED_SHIM")"
assert_file_eq "$EMPTY_EXE" "$SHIMMED_TARGET"

ANOTHER_TARGET="$(parse_shim "$ANOTHER_SHIM")"
assert_file_eq "$EMPTY_EXE" "$ANOTHER_TARGET"
