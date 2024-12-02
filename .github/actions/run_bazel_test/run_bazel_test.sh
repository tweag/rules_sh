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

#USE_BAZEL_VERSION=7.2.1 bazelisk test  --build_tests_only "${bzl_pkgs}"

bazelisk --bisect=7.2.1..7.3.0 test  --build_tests_only "${bzl_pkgs}"
