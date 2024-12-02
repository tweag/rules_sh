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

# good commits:
# - 000a83a77b417823e978f4b905a8039b2dd38ef3
# - 6d69b9c6003a963bf9e26b3d52b3a736e900cee0

# - 333027e234d03cd77624f6ee17b33705bba4cd2a
# - 610fe7bb25c8853fd9b55d85cb08d2bf4e3ee8b7

# failed (no binary): 282ac623df3523e2e31a2de9c002e5c50da19fec
bazelisk --bisect=ffe1df57c3ccbbff815df0068634b881da8c1501..7.3.0 test  --build_tests_only "${bzl_pkgs}"
