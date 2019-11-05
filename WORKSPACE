workspace(name = "rules_sh")

load("//sh:repositories.bzl", "rules_sh_dependencies")

rules_sh_dependencies()

load("//sh:posix.bzl", "sh_posix_configure")

sh_posix_configure()

load("@bazel_skylib//lib:unittest.bzl", "register_unittest_toolchains")

register_unittest_toolchains()
