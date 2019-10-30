workspace(name = "rules_sh")

load("//sh:repositories.bzl", "rules_sh_dependencies")

rules_sh_dependencies()

load("//sh:unix.bzl", "unix_configure")

unix_configure()

load("@bazel_skylib//lib:unittest.bzl", "register_unittest_toolchains")

register_unittest_toolchains()
