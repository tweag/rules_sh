"""Unix shell commands toolchain support.

Defines a hermetic version of the POSIX toolchain defined in
@rules_sh//sh:posix.bzl. Long-term this hermetic version will replace the old,
less hermetic version of the POSIX toolchain.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_tools//tools/cpp:lib_cc_configure.bzl", "get_cpu_value")
load("//sh/private:posix.bzl", _commands = "commands")
load("//sh:posix.bzl", "MAKE_VARIABLES", "TOOLCHAIN_TYPE")
load("//sh:sh.bzl", "ShBinariesInfo")

def _sh_posix_hermetic_toolchain_impl(ctx):
    if not ShBinariesInfo in ctx.attr.cmds:
        fail("The cmds attribute must be given a sh_binaries target.")

    sh_binaries_info = ctx.attr.cmds[ShBinariesInfo]

    unrecognizeds = [
        cmd
        for cmd in sh_binaries_info.executables.keys()
        if cmd not in _commands
    ]
    if unrecognizeds:
        fail("Unrecognized commands in keys of sh_posix_hermetic_toolchain's \"cmds\" attribute: {}. See posix_hermetic.commands in @rules_sh//sh:posix_hermetic.bzl for the list of recognized commands.".format(", ".join(unrecognizeds)))

    return [platform_common.ToolchainInfo(
        sh_binaries_info = sh_binaries_info,
        # exposed for use-cases requiring runfiles access.
        tool = ctx.attr.cmds,
        # exposed for backwards compatibility.
        commands = {
            cmd: sh_binaries_info.executables[cmd].path if cmd in sh_binaries_info.executables else None
            for cmd in _commands
        },
        paths = sh_binaries_info.paths.to_list(),
    )]

sh_posix_hermetic_toolchain = rule(
    attrs = {
        "cmds": attr.label(
            doc = "sh_binaries target that captures the tools to include in this toolchain.",
            mandatory = True,
        ),
    },
    # TODO[AH]: doc
    implementation = _sh_posix_hermetic_toolchain_impl,
)

posix_hermetic = struct(
    commands = _commands,
    TOOLCHAIN_TYPE = TOOLCHAIN_TYPE,
    MAKE_VARIABLES = MAKE_VARIABLES,
)
