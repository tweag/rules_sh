#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

is_windows() {
  local os_name
  os_name="$( uname )"
  # Examples: MINGW64_NT-10.0-17763
  [[ "${os_name}" =~ ^MING ]]
}

working_dir="${RBT_WORKING_DIR:-}"

if is_windows; then
  export BAZEL_SH='C:\msys64\usr\bin\bash.exe'
  bzl_pkgs='///...'
else
  bzl_pkgs='//...'
fi

if [[ -n "${working_dir:-}" ]]; then
  cd "${working_dir}"
fi

bazel test "${bzl_pkgs}"
