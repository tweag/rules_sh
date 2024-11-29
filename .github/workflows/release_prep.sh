#!/usr/bin/env bash
set -euo pipefail

TAG="$1"

REPO="${GITHUB_REPOSITORY#*/}"

# The prefix is chosen to match what GitHub generates for source archives
PREFIX="${REPO}${TAG:1}"
ARCHIVE="${REPO}${TAG:1}.tar.gz"

git archive --format=tar.gz --prefix="${PREFIX}/" -o $ARCHIVE HEAD

SHA=$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')

cat << EOF
## Using Bzlmod with Bazel 6+

1. Enable with \`common --enable_bzlmod\` in \`.bazelrc\`.
2. Add to your \`MODULE.bazel\` file:

### For the core module

\`\`\`starlark
bazel_dep(name = "rules_sh", version = "${TAG:1}")
\`\`\`

## Using WORKSPACE

Paste this snippet into your \`WORKSPACE.bazel\` file:

\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_sh",
    sha256 = "${SHA}",
    strip_prefix = "$PREFIX",
    urls = ["https://github.com/tweag/rules_sh/releases/download/$TAG/$ARCHIVE"],
)

load("@rules_sh//sh:repositories.bzl", "rules_sh_dependencies")

rules_sh_dependencies()
\`\`\`
EOF

echo "archive=$ARCHIVE" >> "$GITHUB_OUTPUT"
