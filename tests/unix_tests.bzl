"""Unit tests for unix.bzl."""

load("@bazel_skylib//lib:new_sets.bzl", "sets")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//sh:unix.bzl", "unix")

_UnixInfo = provider()

def _get_unix_toolchain_impl(ctx):
    return [_UnixInfo(
        toolchain = ctx.toolchains[unix.TOOLCHAIN_TYPE],
        variables = ctx.var,
    )]

get_unix_toolchain = rule(
    implementation = _get_unix_toolchain_impl,
    toolchains = [unix.TOOLCHAIN_TYPE],
)

def _command_items_test(ctx):
    """The Unix toolchain should have an item for each command."""
    env = analysistest.begin(ctx)
    toolchain = analysistest.target_under_test(env)[_UnixInfo].toolchain

    expected = sets.make(unix.commands)
    actual = sets.make(toolchain.commands.keys())
    msg = "Mismatch between Unix toolchain items and known commands"
    asserts.new_set_equals(env, expected, actual, msg)

    return analysistest.end(env)

command_items_test = analysistest.make(_command_items_test)

def _make_variables_test(ctx):
    """The Unix toolchain should define a make variable for each found command."""
    env = analysistest.begin(ctx)
    toolchain = analysistest.target_under_test(env)[_UnixInfo].toolchain
    variables = analysistest.target_under_test(env)[_UnixInfo].variables

    for (cmd, cmd_path) in toolchain.commands.items():
        varname = "UNIX_%s" % cmd.upper()
        if cmd_path != None:
            asserts.equals(env, cmd_path, variables[varname])
        else:
            asserts.false(env, varname in variables)

    return analysistest.end(env)

make_variables_test = analysistest.make(_make_variables_test)

def _grep_genrule_test(ctx):
    env = analysistest.begin(ctx)
    actions = analysistest.target_actions(env)
    toolchain = ctx.attr.unix_toolchain[_UnixInfo].toolchain

    asserts.equals(env, 1, len(actions))
    genrule_command = " ".join(actions[0].argv)
    grep_path = toolchain.commands["grep"]
    msg = "genrule command should contain path to grep"
    asserts.true(env, genrule_command.find(grep_path) >= 0, msg)

    return analysistest.end(env)

grep_genrule_test = analysistest.make(
    _grep_genrule_test,
    attrs = {"unix_toolchain": attr.label()},
)

def unix_test_suite():
    """Creates the test targets and test suite for unix.bzl tests."""
    get_unix_toolchain(
        name = "unix_toolchain",
        toolchains = [unix.MAKE_VARIABLES],
    )
    command_items_test(
        name = "command_items_test",
        target_under_test = ":unix_toolchain",
    )
    make_variables_test(
        name = "make_variables_test",
        target_under_test = ":unix_toolchain",
    )
    native.genrule(
        name = "unix_grep_genrule",
        srcs = [":unix_tests.bzl"],
        outs = ["unix_grep_genrule.txt"],
        cmd = "$(UNIX_GREP) unix_grep_genrule $(execpath :unix_tests.bzl) > $(OUTS)",
        toolchains = [unix.MAKE_VARIABLES],
    )
    grep_genrule_test(
        name = "grep_genrule_test",
        target_under_test = ":unix_grep_genrule",
        unix_toolchain = ":unix_toolchain",
    )
