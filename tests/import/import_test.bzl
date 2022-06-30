load("@bazel_tools//tools/cpp:lib_cc_configure.bzl", "get_cpu_value")
load("@rules_sh//sh:import.bzl", "create_shim")

# create shim ########################################################

def _create_shim_test():
    native.sh_test(
        name = "create_shim_test",
        srcs = ["create_shim_test.sh"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        data = [
            "@rules_sh_shim_exe//file:shim.exe",
            "@rules_sh_import_test_create_shim_test_source//:empty.exe",
            "@rules_sh_import_test_create_shim_test_shim//:shimmed.exe",
            "@rules_sh_import_test_create_shim_test_shim//:shimmed.shim",
            "@rules_sh_import_test_create_shim_test_shim//prefix:another.exe",
            "@rules_sh_import_test_create_shim_test_shim//prefix:another.shim",
        ],
        args = [
            "rules_sh/$(rootpath @rules_sh_shim_exe//file:shim.exe)",
            "rules_sh/$(rootpath @rules_sh_import_test_create_shim_test_source//:empty.exe)",
            "rules_sh/$(rootpath @rules_sh_import_test_create_shim_test_shim//:shimmed.exe)",
            "rules_sh/$(rootpath @rules_sh_import_test_create_shim_test_shim//:shimmed.shim)",
            "rules_sh/$(rootpath @rules_sh_import_test_create_shim_test_shim//prefix:another.exe)",
            "rules_sh/$(rootpath @rules_sh_import_test_create_shim_test_shim//prefix:another.shim)",
        ],
    )

def _create_shim_test_source_repository_impl(repository_ctx):
    repository_ctx.file(
        "empty.exe",
        "",
        executable = True,
    )
    repository_ctx.file(
        "BUILD.bazel",
        'exports_files(["empty.exe"])',
        executable = False,
    )

_create_shim_test_source_repository = repository_rule(
    _create_shim_test_source_repository_impl,
)

def _create_shim_test_shim_repository_impl(repository_ctx):
    create_shim(
        repository_ctx,
        name = "shimmed",
        target = repository_ctx.attr.empty_exe,
    )
    create_shim(
        repository_ctx,
        name = "prefix/another",
        target = repository_ctx.attr.empty_exe,
    )
    repository_ctx.file(
        "BUILD.bazel",
        'exports_files(["shimmed.exe", "shimmed.shim"])',
        executable = False,
    )
    repository_ctx.file(
        "prefix/BUILD.bazel",
        'exports_files(["another.exe", "another.shim"])',
        executable = False,
    )

_create_shim_test_shim_repository = repository_rule(
    _create_shim_test_shim_repository_impl,
    attrs = {
        "empty_exe": attr.label(mandatory = True),
    },
)

def _create_shim_repositories():
    _create_shim_test_source_repository(
        name = "rules_sh_import_test_create_shim_test_source",
    )
    _create_shim_test_shim_repository(
        name = "rules_sh_import_test_create_shim_test_shim",
        empty_exe = "@rules_sh_import_test_create_shim_test_source//:empty.exe",
    )

# invoke shim ########################################################

def _invoke_shim_test():
    native.genrule(
        name = "invoke_shim",
        outs = ["invoke_shim.out"],
        cmd = """\
PATH="$(_TOOLS_PATH):$$PATH"
cmd /c echo Hello World >$(OUTS)
""",
        toolchains = ["@rules_sh_import_test_invoke_shim_test_cmd//:tools"],
        tags = ["manual"],
        target_compatible_with = ["@platforms//os:windows"],
    )
    native.sh_test(
        name = "invoke_shim_test",
        srcs = ["invoke_shim_test.sh"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        data = [":invoke_shim"],
    )

def _invoke_shim_test_cmd_impl(repository_ctx):
    cpu_value = get_cpu_value(repository_ctx)
    if cpu_value.find("windows") != -1:
        cmd = repository_ctx.which("cmd")
        if cmd == None:
            fail("Could not find cmd")
        create_shim(
            repository_ctx,
            name = "cmd",
            target = cmd,
        )
    repository_ctx.file(
        "BUILD.bazel",
        """\
load("@rules_sh//sh:sh.bzl", "sh_binaries")
sh_binaries(
    name = "tools",
    srcs = select({
        "@platforms//os:windows": ["cmd.exe"],
        "//conditions:default": [],
    }),
    data = select({
        "@platforms//os:windows": ["cmd.shim"],
        "//conditions:default": [],
    }),
    visibility = ["//visibility:public"],
)
""",
        executable = True,
    )

_invoke_shim_test_cmd = repository_rule(
    _invoke_shim_test_cmd_impl,
)

def _invoke_shim_repositories():
    _invoke_shim_test_cmd(
        name = "rules_sh_import_test_invoke_shim_test_cmd",
    )

# test suite #########################################################

def import_test_suite(name):
    _create_shim_test()
    _invoke_shim_test()

    native.test_suite(
        name = name,
        tests = [
            ":create_shim_test",
            ":invoke_shim_test",
        ],
    )

# external workspaces ################################################

def import_test_repositories():
    _create_shim_repositories()
    _invoke_shim_repositories()
