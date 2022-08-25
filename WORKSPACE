workspace(name = "rules_sh")

load("//sh:repositories.bzl", "rules_sh_dependencies")

rules_sh_dependencies()

load("//sh:posix.bzl", "sh_posix_configure")

sh_posix_configure()

load("@bazel_skylib//lib:unittest.bzl", "register_unittest_toolchains")

register_unittest_toolchains()

load("//tests/import:import_test.bzl", "import_test_repositories")

import_test_repositories()


# documentation dependencies

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

maybe(
    http_archive,
    "io_bazel_stardoc",
    sha256 = "aa814dae0ac400bbab2e8881f9915c6f47c49664bf087c409a15f90438d2c23e",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/stardoc/releases/download/0.5.1/stardoc-0.5.1.tar.gz",
        "https://github.com/bazelbuild/stardoc/releases/download/0.5.1/stardoc-0.5.1.tar.gz",
    ],
)
