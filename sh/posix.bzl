"""Unix shell commands toolchain support.

Defines a toolchain capturing common Unix shell commands as defined by IEEE
1003.1-2008 (POSIX), see `sh_posix_toolchain`, and `sh_posix_configure` to scan
the local environment for shell commands. The list of known commands is
available in `posix.commands`.

"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//sh/private:get_cpu_value.bzl", "get_cpu_value")
load(
    "//sh/private:defs.bzl",
    "mk_default_info_with_files_to_run",
    "mk_template_variable_info",
)
load("//sh/private:posix.bzl", _commands = "commands")

TOOLCHAIN_TYPE = "@rules_sh//sh/posix:toolchain_type"
MAKE_VARIABLES = "@rules_sh//sh/posix:make_variables"

def _sh_posix_toolchain_impl(ctx):
    commands = {}
    cmds = ctx.attr.cmds
    for cmd in _commands:
        cmd_path = cmds.get(cmd, None)
        if not cmd_path:
            cmd_path = None
        commands[cmd] = cmd_path
    unrecognizeds = [cmd for cmd in cmds.keys() if cmd not in _commands]
    if unrecognizeds:
        fail("Unrecognized commands in keys of sh_posix_toolchain's \"cmds\" attributes: {}. See posix.commands in @rules_sh//sh:posix.bzl for the list of recognized commands.".format(", ".join(unrecognizeds)))
    cmd_paths = {
        paths.dirname(cmd_path): None
        for cmd_path in commands.values()
        if cmd_path
    }.keys()
    return [platform_common.ToolchainInfo(
        commands = commands,
        paths = cmd_paths,
    )]

sh_posix_toolchain = rule(
    attrs = {
        "cmds": attr.string_dict(
            doc = "dict where keys are command names and values are paths",
            mandatory = True,
        ),
    },
    doc = """
A toolchain capturing standard Unix shell commands.

Provides:
  commands: Dict of String, an item per command holding the path to the executable or None.
  paths: List of String, deduplicated bindir paths. Suitable for generating `$PATH`.

Use `sh_posix_configure` to create an instance of this toolchain.
See `sh_posix_make_variables` on how to use this toolchain in genrules.
""",
    implementation = _sh_posix_toolchain_impl,
)

def _sh_posix_make_variables_impl(ctx):
    toolchain = ctx.toolchains[TOOLCHAIN_TYPE]

    if not hasattr(toolchain, "sh_binaries_info"):
        cmd_vars = {
            "POSIX_%s" % cmd.upper(): cmd_path
            for cmd in _commands
            for cmd_path in [toolchain.commands[cmd]]
            if cmd_path
        }
        return [platform_common.TemplateVariableInfo(cmd_vars)]

    template_variable_info = mk_template_variable_info(
        "posix",
        toolchain.sh_binaries_info,
    )

    default_info = mk_default_info_with_files_to_run(
        ctx,
        ctx.label.name,
        toolchain.tool[DefaultInfo].files,
        toolchain.tool[DefaultInfo].default_runfiles,
    )

    return [template_variable_info, default_info]

sh_posix_make_variables = rule(
    doc = """
Provides POSIX toolchain commands as custom make variables.

Make variables:
  Provides a make variable of the form `POSIX_<COMMAND>` for each available
  command, where `<COMMAND>` is the name of the command in upper case.

Use `posix.MAKE_VARIABLES` instead of instantiating this rule yourself.

Example:
  >>> genrule(
          name = "use-grep",
          srcs = [":some-file"],
          outs = ["grep-out"],
          cmd = "$(POSIX_GREP) search $(execpath :some-file) > $(OUTS)",
          toolchains = [posix.MAKE_VARIABLES],
      )
""",
    implementation = _sh_posix_make_variables_impl,
    toolchains = [TOOLCHAIN_TYPE],
)

def _windows_detect_sh_dir(repository_ctx):
    # Taken and adapted from @bazel_tools//tools/sh/sh_configure.bzl.
    sh_path = repository_ctx.os.environ.get("BAZEL_SH")
    if not sh_path:
        sh_path = repository_ctx.which("bash.exe")
        if sh_path:
            # repository_ctx.which returns a path object, convert that to
            # string so we can call string.startswith on it.
            sh_path = str(sh_path)

            # When the Windows Subsystem for Linux is installed there's a
            # bash.exe under %WINDIR%\system32\bash.exe that launches Ubuntu
            # Bash which cannot run native Windows programs so it's not what
            # we want.
            windir = repository_ctx.os.environ.get("WINDIR")
            if windir and sh_path.startswith(windir):
                sh_path = None

    if sh_path != None:
        sh_dir = str(repository_ctx.path(sh_path).dirname)

    return sh_dir

def _sh_posix_config_impl(repository_ctx):
    cpu = get_cpu_value(repository_ctx)
    env = repository_ctx.os.environ

    windows_sh_dir = None
    if cpu == "x64_windows":
        windows_sh_dir = _windows_detect_sh_dir(repository_ctx)

    commands = {}
    for cmd in _commands:
        cmd_path = env.get("POSIX_%s" % cmd.upper(), None)
        if cmd_path == None and cpu != "x64_windows":
            cmd_path = repository_ctx.which(cmd)
        elif cmd_path == None and cpu == "x64_windows":
            # Autodetection using `repository_ctx.which` is not safe on
            # Windows, as it may turn up false friends. E.g. Windows has a
            # `find.exe` which is unrelated to POSIX `find`. Instead we use
            # tools next to `bash.exe`.
            cmd_path = repository_ctx.path(windows_sh_dir + "/" + cmd + ".exe")
            if not cmd_path.exists:
                cmd_path = None
        commands[cmd] = cmd_path
    repository_ctx.file("BUILD.bazel", executable = False, content = """
load("@rules_sh//sh:posix.bzl", "sh_posix_toolchain")
sh_posix_toolchain(
    name = "local_posix",
    visibility = ["//visibility:public"],
    cmds = {{
        {commands}
    }}
)
toolchain(
    name = "local_posix_toolchain",
    toolchain = ":local_posix",
    toolchain_type = "{toolchain_type}",
    exec_compatible_with = [
        "@platforms//cpu:{arch}",
        "@platforms//os:{os}",
    ],
)
""".format(
        commands = ",\n        ".join([
            '"{cmd}": "{path}"'.format(cmd = cmd, path = cmd_path)
            for (cmd, cmd_path) in commands.items()
            if cmd_path
        ]),
        arch = {
            "aarch64": "arm64",
            "arm64_windows": "arm64",
            "darwin_arm64": "arm64",
        }.get(cpu, "x86_64"),
        os = {
            "arm64_windows": "windows",
            "darwin": "osx",
            "darwin_arm64": "osx",
            "darwin_x86_64": "osx",
            "x64_windows": "windows",
        }.get(cpu, "linux"),
        toolchain_type = TOOLCHAIN_TYPE,
    ))

_sh_posix_config = repository_rule(
    configure = True,
    environ = ["PATH"] + [
        "POSIX_%s" % cmd.upper()
        for cmd in _commands
    ],
    local = True,
    implementation = _sh_posix_config_impl,
)

def sh_posix_configure(name = "local_posix_config", register = True):
    """## Usage

    ### Configure the toolchain

    Add the following to your `WORKSPACE` file to configure a local POSIX toolchain.

    ``` python
    load("@rules_sh//sh:posix.bzl", "sh_posix_configure")
    sh_posix_configure()
    ```

    Bazel will query `PATH` for common Unix shell commands. You can override the
    path to individual commands with environment variables of the form
    `POSIX_<COMMAND_NAME>`. E.g. `POSIX_MAKE=/usr/bin/gmake`.

    Note, this introduces an inhermeticity to the build as the contents of `PATH`
    may be specific to your machine's setup.

    Refer to [`rules_nixpkgs`'s][rules_nixpkgs] `nixpkgs_posix_configure` for a
    hermetic alternative.

    [rules_nixpkgs]: https://github.com/tweag/rules_nixpkgs.git

    ### Use Unix tools in `genrule`s

    The POSIX toolchain exposes custom make variables of the form
    `POSIX_<COMMAND_NAME>` for discovered commands. Use these as follows:

    ``` python
    genrule(
        name = "example",
        srcs = [":some-input-file"],
        outs = ["some-output-file"],
        cmd = "$(POSIX_GREP) some-pattern $(execpath :some-input-file.bzl) > $(OUTS)",
        toolchains = ["@rules_sh//sh/posix:make_variables"],
    )
    ```

    See `posix.commands` defined in `@rules_sh//sh/posix.bzl` for the list of known
    POSIX commands.

    ### Use Unix tools in custom rules

    The POSIX toolchain provides two attributes:
    - `commands`: A `dict` mapping names of commands to their paths.
    - `paths`: A deduplicated list of bindir paths suitable for generating `$PATH`.

    ``` python
    def _my_rule_impl(ctx):
        posix_info = ctx.toolchains["@rules_sh//sh/posix:toolchain_type"]
        ctx.actions.run(
            executable = posix_info.commands["grep"],
            ...
        )
        ctx.actions.run_shell(
            command = "grep ...",
            env = {"PATH": ":".join(posix_info.paths)},
            ...
        )

    my_rule = rule(
        _my_rule_impl,
        toolchains = ["@rules_sh//sh/posix:toolchain_type"],
        ...
    )
    ```
    """
    _sh_posix_config(name = name)
    if register:
        native.register_toolchains("@{}//:local_posix_toolchain".format(name))

posix = struct(
    commands = _commands,
    TOOLCHAIN_TYPE = TOOLCHAIN_TYPE,
    MAKE_VARIABLES = MAKE_VARIABLES,
)
