workspace(name = "rules_sh")

load("//sh:repositories.bzl", "rules_sh_dependencies")

rules_sh_dependencies()

load("//sh:posix.bzl", "sh_posix_configure")

sh_posix_configure()

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

# documentation dependencies

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

maybe(
    http_archive,
    "io_bazel_stardoc",
    sha256 = "62bd2e60216b7a6fec3ac79341aa201e0956477e7c8f6ccc286f279ad1d96432",
    urls = [
        # NOTE: stardoc >= 0.7 is not compatible with Bazel 6
        "https://mirror.bazel.build/github.com/bazelbuild/stardoc/releases/download/0.6.2/stardoc-0.6.2.tar.gz",
        "https://github.com/bazelbuild/stardoc/releases/download/0.6.2/stardoc-0.6.2.tar.gz",
    ],
)
