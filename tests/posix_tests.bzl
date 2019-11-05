"""Unit tests for posix.bzl."""

load("@bazel_skylib//lib:new_sets.bzl", "sets")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//sh:posix.bzl", "posix")

_PosixInfo = provider()

def _get_posix_toolchain_impl(ctx):
    return [_PosixInfo(
        toolchain = ctx.toolchains[posix.TOOLCHAIN_TYPE],
        variables = ctx.var,
    )]

get_posix_toolchain = rule(
    implementation = _get_posix_toolchain_impl,
    toolchains = [posix.TOOLCHAIN_TYPE],
)

def _command_items_test(ctx):
    """The POSIX toolchain should have an item for each command."""
    env = analysistest.begin(ctx)
    toolchain = analysistest.target_under_test(env)[_PosixInfo].toolchain

    expected = sets.make(posix.commands)
    actual = sets.make(toolchain.commands.keys())
    msg = "Mismatch between POSIX toolchain items and known commands"
    asserts.new_set_equals(env, expected, actual, msg)

    return analysistest.end(env)

command_items_test = analysistest.make(_command_items_test)

def _make_variables_test(ctx):
    """The POSIX toolchain should define a make variable for each found command."""
    env = analysistest.begin(ctx)
    toolchain = analysistest.target_under_test(env)[_PosixInfo].toolchain
    variables = analysistest.target_under_test(env)[_PosixInfo].variables

    for (cmd, cmd_path) in toolchain.commands.items():
        varname = "POSIX_%s" % cmd.upper()
        if cmd_path != None:
            asserts.equals(env, cmd_path, variables[varname])
        else:
            asserts.false(env, varname in variables)

    return analysistest.end(env)

make_variables_test = analysistest.make(_make_variables_test)

def _grep_genrule_test(ctx):
    env = analysistest.begin(ctx)
    actions = analysistest.target_actions(env)
    toolchain = ctx.attr.posix_toolchain[_PosixInfo].toolchain

    asserts.equals(env, 1, len(actions))
    genrule_command = " ".join(actions[0].argv)
    grep_path = toolchain.commands["grep"]
    msg = "genrule command should contain path to grep"
    asserts.true(env, genrule_command.find(grep_path) >= 0, msg)

    return analysistest.end(env)

grep_genrule_test = analysistest.make(
    _grep_genrule_test,
    attrs = {"posix_toolchain": attr.label()},
)

def posix_test_suite():
    """Creates the test targets and test suite for posix.bzl tests."""
    get_posix_toolchain(
        name = "posix_toolchain",
        toolchains = [posix.MAKE_VARIABLES],
    )
    command_items_test(
        name = "command_items_test",
        target_under_test = ":posix_toolchain",
    )
    make_variables_test(
        name = "make_variables_test",
        target_under_test = ":posix_toolchain",
    )
    native.genrule(
        name = "posix_grep_genrule",
        srcs = [":posix_tests.bzl"],
        outs = ["posix_grep_genrule.txt"],
        cmd = "$(POSIX_GREP) posix_grep_genrule $(execpath :posix_tests.bzl) > $(OUTS)",
        toolchains = [posix.MAKE_VARIABLES],
    )
    grep_genrule_test(
        name = "grep_genrule_test",
        target_under_test = ":posix_grep_genrule",
        posix_toolchain = ":posix_toolchain",
    )
