load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load(
    "//sh:sh.bzl",
    "ShBinariesInfo",
    "sh_binaries",
)
load(
    "//sh/experimental:posix_hermetic.bzl",
    "posix_hermetic",
    "sh_posix_hermetic_toolchain",
)

# empty toolchain ####################################################

def _empty_toolchain():
    sh_binaries(
        name = "binaries-empty",
        srcs = [],
    )
    sh_posix_hermetic_toolchain(
        name = "posix-toolchain-empty",
        cmds = ":binaries-empty",
    )

def _empty_toolchain_test_impl(ctx):
    env = analysistest.begin(ctx)

    toolchain = analysistest.target_under_test(env)[platform_common.ToolchainInfo]

    # --------------------------------------------
    # sh_binaries attribute

    asserts.true(
        env,
        hasattr(toolchain, "sh_binaries_info"),
        "Expected 'sh_binaries_info' attribute",
    )
    asserts.equals(
        env,
        toolchain.sh_binaries_info.executables,
        {},
    )
    asserts.equals(
        env,
        toolchain.sh_binaries_info.paths.to_list(),
        [],
    )

    # --------------------------------------------
    # Backwards compatible attributes

    asserts.true(
        env,
        hasattr(toolchain, "commands"),
        "Expected 'commands' attribute for backwards compatibility",
    )
    asserts.equals(
        env,
        {cmd: None for cmd in posix_hermetic.commands},
        getattr(toolchain, "commands", None),
        "Malformed backwards-compatible 'commands' attribute",
    )
    asserts.true(
        env,
        hasattr(toolchain, "paths"),
        "Expected 'paths' attribute for backwards compatibility",
    )
    asserts.equals(
        env,
        getattr(toolchain, "paths", None),
        [],
        "Malformed backwards-compatible 'paths' attribute",
    )

    return analysistest.end(env)

empty_toolchain_test = analysistest.make(
    _empty_toolchain_test_impl,
)

def _test_empty_toolchain():
    _empty_toolchain()
    empty_toolchain_test(
        name = "empty_toolchain_test",
        target_under_test = ":posix-toolchain-empty",
    )

# unrecognized tool ##################################################

def _unrecognized_tool_toolchain():
    native.sh_binary(
        name = "unrecognized",
        srcs = ["unrecognized.sh"],
    )
    sh_binaries(
        name = "binaries-unrecognized",
        srcs = [":unrecognized"],
    )
    sh_posix_hermetic_toolchain(
        name = "posix-toolchain-unrecognized",
        cmds = ":binaries-unrecognized",
        tags = ["manual"],
    )

def _unrecognized_tool_toolchain_test_impl(ctx):
    env = analysistest.begin(ctx)

    asserts.expect_failure(
        env,
        """Unrecognized commands in keys of sh_posix_hermetic_toolchain's "cmds" attribute: unrecognized""",
    )

    return analysistest.end(env)

unrecognized_tool_toolchain_test = analysistest.make(
    _unrecognized_tool_toolchain_test_impl,
    expect_failure = True,
)

def _test_unrecognized_tool_toolchain():
    _unrecognized_tool_toolchain()
    unrecognized_tool_toolchain_test(
        name = "unrecognized_tool_toolchain_test",
        target_under_test = ":posix-toolchain-unrecognized",
    )

# shell scripts toolchain ############################################

# A toolchain that depends on local files, but has no further runtime
# dependencies, like runfiles resolution.

def _shell_scripts_toolchain():
    native.sh_binary(
        name = "false",
        srcs = ["false.sh"],
    )
    native.sh_binary(
        name = "true",
        srcs = ["true.sh"],
    )
    sh_binaries(
        name = "binaries-shell-scripts",
        srcs = [
            "false",
            "true",
        ],
    )
    sh_posix_hermetic_toolchain(
        name = "posix-toolchain-shell-scripts",
        cmds = ":binaries-shell-scripts",
    )
    native.toolchain(
        name = "toolchain-shell-scripts",
        toolchain = ":posix-toolchain-shell-scripts",
        toolchain_type = "//sh/posix:toolchain_type",
    )

def _shell_scripts_toolchain_transition_impl(settings, attr):
    return {
        "//command_line_option:extra_toolchains": "//tests/posix_hermetic:toolchain-shell-scripts",
    }

_shell_scripts_toolchain_transition = transition(
    implementation = _shell_scripts_toolchain_transition_impl,
    inputs = [],
    outputs = ["//command_line_option:extra_toolchains"],
)

def _use_shell_scripts_toolchain_impl(ctx):
    src = ctx.attr.src[DefaultInfo]
    return [
        DefaultInfo(
            files = src.files,
            runfiles = ctx
                .runfiles(files = src.files.to_list())
                .merge(src.default_runfiles),
        ),
    ]

_use_shell_scripts_toolchain = rule(
    _use_shell_scripts_toolchain_impl,
    cfg = _shell_scripts_toolchain_transition,
    attrs = {
        "src": attr.label(),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def _shell_scripts_toolchain_test_impl(ctx):
    env = analysistest.begin(ctx)

    toolchain = analysistest.target_under_test(env)[platform_common.ToolchainInfo]

    # --------------------------------------------
    # sh_binaries attribute

    asserts.true(
        env,
        hasattr(toolchain, "sh_binaries_info"),
        "Expected 'sh_binaries_info' attribute",
    )
    asserts.equals(
        env,
        len(toolchain.sh_binaries_info.executables),
        2,
    )
    asserts.true(
        env,
        "false" in toolchain.sh_binaries_info.executables,
        "Expected 'false' to be a member of the executables dict",
    )
    asserts.true(
        env,
        ctx.executable.false_binary in toolchain.sh_binaries_info.executables.values(),
        "Expected 'false' binary to be a member of the executables",
    )
    asserts.true(
        env,
        "true" in toolchain.sh_binaries_info.executables,
        "Expected 'true' to be a member of the executables dict",
    )
    asserts.true(
        env,
        ctx.executable.true_binary in toolchain.sh_binaries_info.executables.values(),
        "Expected 'true' binary to be a member of the executables",
    )
    asserts.equals(
        env,
        len(toolchain.sh_binaries_info.paths.to_list()),
        1,
    )
    asserts.equals(
        env,
        toolchain.sh_binaries_info.paths.to_list()[0],
        ctx.executable.false_binary.dirname,
    )

    # --------------------------------------------
    # Backwards compatible attributes

    asserts.true(
        env,
        hasattr(toolchain, "commands"),
        "Expected 'commands' attribute for backwards compatibility",
    )
    asserts.equals(
        env,
        len(getattr(toolchain, "commands", None)),
        len(posix_hermetic.commands),
        "Malformed backwards-compatible 'commands' attribute",
    )
    asserts.equals(
        env,
        toolchain.commands["false"],
        ctx.executable.false_binary.path,
    )
    asserts.equals(
        env,
        toolchain.commands["true"],
        ctx.executable.true_binary.path,
    )
    asserts.true(
        env,
        all([
            toolchain.commands[cmd] == None
            for cmd in posix_hermetic.commands
            if not cmd in ["false", "true"]
        ]),
    )
    asserts.true(
        env,
        hasattr(toolchain, "paths"),
        "Expected 'paths' attribute for backwards compatibility",
    )
    asserts.equals(
        env,
        len(getattr(toolchain, "paths", None)),
        1,
        "Malformed backwards-compatible 'paths' attribute",
    )
    asserts.equals(
        env,
        toolchain.paths[0],
        ctx.executable.false_binary.dirname,
    )

    return analysistest.end(env)

shell_scripts_toolchain_test = analysistest.make(
    _shell_scripts_toolchain_test_impl,
    attrs = {
        "false_binary": attr.label(
            executable = True,
            # TODO[AH] Both the target_under_test and the reference should be
            # provided in the exec configuration.
            # See https://github.com/bazelbuild/bazel-skylib/issues/377
            # cfg = "exec",
            cfg = "target",
        ),
        "true_binary": attr.label(
            executable = True,
            # TODO[AH] Both the target_under_test and the reference should be
            # provided in the exec configuration.
            # See https://github.com/bazelbuild/bazel-skylib/issues/377
            # cfg = "exec",
            cfg = "target",
        ),
    },
)

def _test_shell_scripts_toolchain():
    _shell_scripts_toolchain()
    shell_scripts_toolchain_test(
        name = "shell_scripts_toolchain_test",
        target_under_test = ":posix-toolchain-shell-scripts",
        false_binary = ":false",
        true_binary = ":true",
    )

# custom rule usage ##################################################

CustomRuleInfo = provider()

def _custom_rule_impl(ctx):
    toolchain = ctx.toolchains["//sh/posix:toolchain_type"]

    explicit_output = ctx.actions.declare_file("{}_explicit.txt".format(ctx.label.name))
    ctx.actions.run_shell(
        outputs = [explicit_output],
        tools = [
            toolchain.sh_binaries_info.executables["false"],
            toolchain.sh_binaries_info.executables["true"],
        ],
        arguments = [
            toolchain.sh_binaries_info.executables["false"].path,
            toolchain.sh_binaries_info.executables["true"].path,
            explicit_output.path,
        ],
        command = """\
FALSE="$1"
TRUE="$2"
OUT="$3"
{ $FALSE && echo 1 || echo 0; } >>$OUT
{ $TRUE && echo 1 || echo 0; } >>$OUT
""",
    )

    path_output = ctx.actions.declare_file("{}_path.txt".format(ctx.label.name))
    ctx.actions.run_shell(
        outputs = [path_output],
        tools = [
            toolchain.sh_binaries_info.executables["false"],
            toolchain.sh_binaries_info.executables["true"],
        ],
        arguments = [
            ":".join(toolchain.sh_binaries_info.paths.to_list()),
            path_output.path,
        ],
        command = """\
# Disable the shell builtins and standard PATH to ensure
# that we use the commands provided by the toolchain.
enable -n false true
export PATH="$1"
OUT="$2"
{ false && echo 1 || echo 0; } >>$OUT
{ true && echo 1 || echo 0; } >>$OUT
""",
    )

    return [
        DefaultInfo(
            files = depset(direct = [explicit_output, path_output]),
            runfiles = ctx.runfiles(files = [explicit_output, path_output]),
        ),
        CustomRuleInfo(
            false_binary = toolchain.sh_binaries_info.executables["false"],
        ),
    ]

_custom_rule = rule(
    _custom_rule_impl,
    cfg = _shell_scripts_toolchain_transition,
    toolchains = ["//sh/posix:toolchain_type"],
    attrs = {
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def _custom_rule_test_impl(ctx):
    env = analysistest.begin(ctx)

    rule_info = analysistest.target_under_test(env)[CustomRuleInfo]

    asserts.equals(
        env,
        rule_info.false_binary,
        ctx.executable.false_binary,
    )

    return analysistest.end(env)

custom_rule_test = analysistest.make(
    _custom_rule_test_impl,
    attrs = {
        "false_binary": attr.label(
            executable = True,
            # The _shell_scripts_toolchain_transition places the toolchain
            # provided binary under a different configuration than the
            # reference binary would be under the regular `host` configuration.
            # We apply the same transition to the reference to align the
            # configurations.
            cfg = _shell_scripts_toolchain_transition,
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def _test_custom_rule():
    _custom_rule(
        name = "custom_rule",
        tags = ["manual"],
    )
    custom_rule_test(
        name = "custom_rule_analysis_test",
        target_under_test = ":custom_rule",
        false_binary = ":false",
    )
    native.sh_test(
        name = "custom_rule_output_test",
        srcs = ["custom_rule_output_test.sh"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        data = [":custom_rule"],
    )
    native.test_suite(
        name = "custom_rule_test",
        tests = [
            ":custom_rule_analysis_test",
            ":custom_rule_output_test",
        ],
    )

# genrule usage ######################################################

def _test_genrule():
    native.genrule(
        name = "genrule_explicit",
        tags = ["manual"],
        outs = ["genrule_explicit.txt"],
        cmd = """\
{ $(POSIX_FALSE) && echo 1 || echo 0; } >> $(OUTS)
{ $(POSIX_TRUE) && echo 1 || echo 0; } >> $(OUTS)
""",
        toolchains = [posix_hermetic.MAKE_VARIABLES],
    )
    native.genrule(
        name = "genrule_path",
        tags = ["manual"],
        outs = ["genrule_path.txt"],
        cmd = """\
# Disable the shell builtins and standard PATH to ensure
# that we use the commands provided by the toolchain.
enable -n false true
export PATH="$(_POSIX_PATH)"
{ false && echo 1 || echo 0; } >> $(OUTS)
{ true && echo 1 || echo 0; } >> $(OUTS)
""",
        toolchains = [posix_hermetic.MAKE_VARIABLES],
    )
    _use_shell_scripts_toolchain(
        name = "genrule_explicit_transitioned",
        src = ":genrule_explicit",
    )
    _use_shell_scripts_toolchain(
        name = "genrule_path_transitioned",
        src = ":genrule_path",
    )
    native.sh_test(
        name = "genrule_explicit_output_test",
        srcs = ["genrule_explicit_output_test.sh"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        data = [":genrule_explicit_transitioned"],
    )
    native.sh_test(
        name = "genrule_path_output_test",
        srcs = ["genrule_path_output_test.sh"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        data = [":genrule_path_transitioned"],
    )
    native.test_suite(
        name = "genrule_test",
        tests = [
            ":genrule_explicit_output_test",
            ":genrule_path_output_test",
        ],
    )

# runfiles toolchain #################################################

# A toolchain that depends on runfiles resolution.

def _runfiles_toolchain():
    native.sh_binary(
        name = "echo",
        srcs = ["echo.sh"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        data = [":echo_data.txt"],
    )
    sh_binaries(
        name = "binaries-runfiles",
        srcs = [":echo"],
    )
    sh_posix_hermetic_toolchain(
        name = "posix-toolchain-runfiles",
        cmds = ":binaries-runfiles",
    )
    native.toolchain(
        name = "toolchain-runfiles",
        toolchain = ":posix-toolchain-runfiles",
        toolchain_type = "//sh/posix:toolchain_type",
    )

def _runfiles_toolchain_transition_impl(settings, attr):
    return {
        "//command_line_option:extra_toolchains": "//tests/posix_hermetic:toolchain-runfiles",
    }

_runfiles_toolchain_transition = transition(
    implementation = _runfiles_toolchain_transition_impl,
    inputs = [],
    outputs = ["//command_line_option:extra_toolchains"],
)

def _use_runfiles_toolchain_impl(ctx):
    src = ctx.attr.src[DefaultInfo]
    return [
        DefaultInfo(
            files = src.files,
            runfiles = ctx
                .runfiles(files = src.files.to_list())
                .merge(src.default_runfiles),
        ),
    ]

_use_runfiles_toolchain = rule(
    _use_runfiles_toolchain_impl,
    cfg = _runfiles_toolchain_transition,
    attrs = {
        "src": attr.label(),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def _runfiles_toolchain_test_impl(ctx):
    env = analysistest.begin(ctx)

    toolchain = analysistest.target_under_test(env)[platform_common.ToolchainInfo]

    # --------------------------------------------
    # runfiles forwarding

    toolchain_runfiles = toolchain.tool[DefaultInfo].default_runfiles.files.to_list()
    echo_runfiles = ctx.attr.echo_binary[DefaultInfo].default_runfiles.files.to_list()
    asserts.true(
        env,
        all([
            runfile in toolchain_runfiles
            for runfile in echo_runfiles
        ]),
        "Expected that all of echo's runfiles are forwared in the toolchain runfiles.",
    )

    return analysistest.end(env)

runfiles_toolchain_test = analysistest.make(
    _runfiles_toolchain_test_impl,
    attrs = {
        "echo_binary": attr.label(
            executable = True,
            # TODO[AH] Both the target_under_test and the reference should be
            # provided in the exec configuration.
            # See https://github.com/bazelbuild/bazel-skylib/issues/377
            # cfg = "exec",
            cfg = "target",
        ),
        "echo_data": attr.label(allow_single_file = True),
    },
)

def _test_runfiles_toolchain():
    _runfiles_toolchain()
    runfiles_toolchain_test(
        name = "runfiles_toolchain_test",
        target_under_test = ":posix-toolchain-runfiles",
        echo_binary = ":echo",
        echo_data = ":echo_data.txt",
    )

# runfiles in custom rule ############################################

def _runfiles_custom_rule_impl(ctx):
    toolchain = ctx.toolchains["//sh/posix:toolchain_type"]

    (tools_inputs, tools_manifest) = ctx.resolve_tools(tools = [toolchain.tool])

    # Override the argv[0] relative runfiles tree or manifest by the bundle's.
    # This is a workaround for https://github.com/bazelbuild/bazel/issues/15486
    tools_env = {
        "RUNFILES_DIR": toolchain.tool[DefaultInfo].files_to_run.runfiles_manifest.dirname,
        "RUNFILES_MANIFEST_FILE": toolchain.tool[DefaultInfo].files_to_run.runfiles_manifest.path,
    }

    output = ctx.actions.declare_file("{}.txt".format(ctx.label.name))
    ctx.actions.run_shell(
        outputs = [output],
        inputs = tools_inputs,
        input_manifests = tools_manifest,
        env = tools_env,
        tools = [
            toolchain.sh_binaries_info.executables["echo"],
        ],
        arguments = [
            toolchain.sh_binaries_info.executables["echo"].path,
            output.path,
        ],
        command = """\
ECHO="$1"
OUT="$2"
$ECHO message >>$OUT
""",
    )

    return [
        DefaultInfo(
            files = depset(direct = [output]),
            runfiles = ctx.runfiles(files = [output]),
        ),
    ]

_runfiles_custom_rule = rule(
    _runfiles_custom_rule_impl,
    cfg = _runfiles_toolchain_transition,
    toolchains = ["//sh/posix:toolchain_type"],
    attrs = {
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def _test_runfiles_custom_rule():
    _runfiles_custom_rule(
        name = "runfiles_custom_rule",
        tags = ["manual"],
    )
    native.sh_test(
        name = "runfiles_custom_rule_test",
        srcs = ["runfiles_custom_rule_test.sh"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        data = ["runfiles_custom_rule"],
    )

# runfiles in genrule ################################################

def _test_runfiles_genrule():
    native.genrule(
        name = "runfiles_genrule",
        tags = ["manual"],
        outs = ["runfiles_genrule.txt"],
        cmd = """\
IS_WINDOWS=
case "$$OSTYPE" in
  cygwin|msys|win32) IS_WINDOWS=1;;
esac

with_runfiles() {
  # The explicit RUNFILES_DIR|RUNFILES_MANIFEST_FILE is a workaround for
  # https://github.com/bazelbuild/bazel/issues/15486
  if [[ -n $$IS_WINDOWS ]]; then
    RUNFILES_MANIFEST_FILE=$(execpath @rules_sh//sh/posix:make_variables).runfiles_manifest \\
      eval "$$@"
  else
    RUNFILES_DIR=$(execpath @rules_sh//sh/posix:make_variables).runfiles \\
      eval "$$@"
  fi
}

with_runfiles $(POSIX_ECHO) message >>$(OUTS)
""",
        toolchains = [posix_hermetic.MAKE_VARIABLES],
    )
    _use_runfiles_toolchain(
        name = "runfiles_genrule_transitioned",
        src = ":runfiles_genrule",
    )
    native.sh_test(
        name = "runfiles_genrule_test",
        srcs = ["runfiles_genrule_test.sh"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        data = [":runfiles_genrule_transitioned"],
    )

# test suite #########################################################

def posix_hermetic_test_suite(name):
    _test_empty_toolchain()
    _test_unrecognized_tool_toolchain()
    _test_shell_scripts_toolchain()
    _test_custom_rule()
    _test_genrule()
    _test_runfiles_toolchain()
    _test_runfiles_custom_rule()
    _test_runfiles_genrule()

    native.test_suite(
        name = name,
        tests = [
            ":empty_toolchain_test",
            ":unrecognized_tool_toolchain_test",
            ":shell_scripts_toolchain_test",
            ":custom_rule_test",
            ":genrule_test",
            ":runfiles_toolchain_test",
            ":runfiles_custom_rule_test",
            ":runfiles_genrule_test",
        ],
    )
