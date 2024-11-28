"""Unix shell commands toolchain support.

Defines a hermetic version of the POSIX toolchain defined in
@rules_sh//sh:posix.bzl. Long-term this hermetic version will replace the old,
less hermetic version of the POSIX toolchain.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
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
        fail("Unrecognized commands in keys of sh_posix_hermetic_toolchain's \"cmds\" attribute: {}. See posix_hermetic.commands in @rules_sh//sh/experimental:posix_hermetic.bzl for the list of recognized commands.".format(", ".join(unrecognizeds)))

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
    implementation = _sh_posix_hermetic_toolchain_impl,
    # TODO[AH] Add a reference to repository rules that generate this toolchain.
    doc = """\
Defines a POSIX toolchain based on an sh_binaries bundle.

Provides:
  sh_binaries_info: ShBinariesInfo, for use in custom rules, see `sh_binaries`.
  tool: Target, the sh_binaries target for use in custom rules that requires runfiles, see `sh_binaries`.
  commands: Dict of String, an item per command holding the path to the executable or None. Provided for backwards compatibility with `sh_posix_toolchain`.
  paths: List of String, deduplicated bindir paths. Suitable for generating `$PATH`. Provided for backwards compatibility with `sh_posix_toolchain`.

#### Example

*Using the toolchain in a genrule*

You need to add a dependency on the `@rules_sh//sh/posix:make_variables` target
to the `toolchains` attribute to import the toolchain into a `genrule`. You can
then use specific tools through make-variables of the form `POSIX_<TOOL>`, or
by extending the `PATH` variable with `$(_POSIX_PATH)`. For example:

```bzl
genrule(
    name = "a-genrule",
    toolchains = ["@rules_sh//sh/posix:make_variables"],
    cmd = "\\n".join([
        "FILE=$(execpath :some-input-file.bzl)",
        "$(POSIX_GREP) some-pattern $$FILE > $(OUTS)",
        "PATH=$(_POSIX_PATH)",
        "grep some-pattern $$FILE >> $(OUTS)",
    ]),
    srcs = [":some-input-file"],
    outs = ["some-output-file"],
)
```

*Using the toolchain in a custom rule*

You need to add a dependency on the `@rules_sh//sh/posix:toolchain_type` to
your custom rule. For example:

```bzl
custom_rule = rule(
    _custom_rule_impl,
    toolchains = ["//sh/posix:toolchain_type"],
    ...
)
```

You can then access the `ShBinariesInfo` provider through the
`sh_binaries_info` attribute of the toolchain object. See `sh_binaries` for
details on the use of that provider. The example below illustrates how to
access the `grep` tool directly, or how to expose it through the `PATH`
environment variable.

```bzl
load("@rules_sh//sh:sh.bzl", "ShBinariesInfo")

def _custom_rule_impl(ctx):
    toolchain = ctx.toolchains["//sh/posix:toolchain_type"]
    sh_binaries_info = toolchain.sh_binaries_info

    ctx.actions.run(
        executable = sh_binaries_info.executables["grep"],
        ...
    )

    ctx.actions.run_shell(
        command = "grep ...",
        tools = [tools.executables["grep"]],
        env = {"PATH": ":".join(sh_binaries_info.paths.to_list())},
        ...
    )
```

Note that the `grep` tool still needs to be declared as an explicit dependency
of the action in the `PATH` use-case using the `tools` parameter.

The toolchain also exposes the attributes `commands` and `paths` exposed by the
non-hermetic POSIX toolchain for backwards compatibility. Note, however, that
actions still need to explicitly declare the relevant tool files as inputs
explicitly.

*Caveat: Using Binaries that require Runfiles*

If the tools bundled by the hermetic POSIX toolchains require Bazel runfiles
access then the same caveats as for `sh_binaries` apply.

For example, use in a `genrule` looks like this:

```bzl
genrule(
    name = "runfiles-genrule",
    toolchains = ["@rules_sh//sh/posix:make_variables"],
    cmd = "\\n".join([
        # The explicit RUNFILES_DIR/RUNFILES_MANIFEST_FILE is a workaround for
        # https://github.com/bazelbuild/bazel/issues/15486
        "RUNFILES_DIR=$(execpath @rules_sh//sh/posix:make_variables).runfiles",
        "RUNFILES_MANIFEST_FILE=$(execpath @rules_sh//sh/posix:make_variables).runfiles_manifest",
        "FILE=$(execpath :some-input-file.bzl)",
        "$(POSIX_GREP) some-pattern $$FILE > $(OUTS)",
        "PATH=$(_POSIX_PATH)",
        "grep some-pattern $$FILE >> $(OUTS)",
    ]),
    srcs = [":some-input-file"],
    outs = ["some-output-file"],
)
```

And use in a custom rule looks like this:

```bzl
def _custom_rule_impl(ctx):
    toolchain = ctx.toolchains["//sh/posix:toolchain_type"]
    sh_binaries_info = toolchain.sh_binaries_info

    # The explicit RUNFILES_DIR/RUNFILES_MANIFEST_FILE is a workaround for
    # https://github.com/bazelbuild/bazel/issues/15486
    tools_env = {
        "RUNFILES_DIR": toolchain.tool[DefaultInfo].files_to_run.runfiles_manifest.dirname,
        "RUNFILES_MANIFEST_FILE": toolchain.tool[DefaultInfo].files_to_run.runfiles_manifest.path,
    }
    (tools_inputs, tools_manifest) = ctx.resolve_tools(tools = [toolchain.tool])

    ctx.actions.run(
        executable = sh_binaries_info.executables["grep"],
        env = tools_env, # Pass the environment into the action.
        inputs = tools_inputs,
        input_manifests = tools_manifest,
        ...
    )
```

*Defining a toolchain*

A hermetic POSIX toolchain can be defined by capturing an `sh_binaries` bundle
that provides the required tools. For example:

```bzl
sh_binaries(
    name = "commands",
    srcs = [
        ...
    ],
)

sh_posix_hermetic_toolchain(
    name = "posix",
    cmds = ":commands",
)

toolchain(
    name = "posix_toolchain",
    toolchain = ":posix",
    toolchain_type = "@rules_sh//sh/posix:toolchain_type",
    exec_compatible_with = [
        ...
    ],
    target_compatible_with = [
        ...
    ],
)
```
""",
)

posix_hermetic = struct(
    commands = _commands,
    TOOLCHAIN_TYPE = TOOLCHAIN_TYPE,
    MAKE_VARIABLES = MAKE_VARIABLES,
)
