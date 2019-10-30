# Shell rules for Bazel

This project extends Bazel with a toolchain for common Unix shell commands.

## Setup

Add the following to your `WORKSPACE` file to install `rules_sh`:

``` python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_sh",
    # Replace git revision and sha256.
    sha256 = "0000000000000000000000000000000000000000000000000000000000000000",
    strip_prefix = "rules_sh-0000000000000000000000000000000000000000",
    urls = ["https://github.com/tweag/rules_sh/archive/0000000000000000000000000000000000000000.tar.gz"],
)
load("@rules_sh//sh:repositories.bzl", "rules_sh_dependencies")
rules_sh_dependencies()
```

## Usage

### Configure the toolchain

Add the following to your `WORKSPACE` file to configure a local Unix toolchain.

``` python
load("@rules_sh//sh:unix.bzl", "unix_configure")
unix_configure()
```

Bazel will query `PATH` for common Unix shell commands. You can override the
path to individual commands with environment variables of the form
`UNIX_<COMMAND_NAME>`. E.g. `UNIX_MAKE=/usr/bin/gmake`.

Note, this introduces an inhermeticity to the build as the contents of `PATH`
may be specific to your machine's setup.

Refer to [`rules_nixpkgs`'s][rules_nixpkgs] `nixpkgs_unix_configure` for a
hermetic alternative.

[rules_nixpkgs]: https://github.com/tweag/rules_nixpkgs.git

### Use Unix tools in `genrule`s

The Unix toolchain exposes custom make variables of the form
`UNIX_<COMMAND_NAME>` for discovered commands. Use these as follows:

``` python
genrule(
    name = "example",
    srcs = [":some-input-file"],
    outs = ["some-output-file"],
    cmd = "$(UNIX_GREP) some-pattern $(execpath :some-input-file.bzl) > $(OUTS)",
    toolchains = ["@rules_sh//sh/unix:make_variables"],
)
```

See `unix.commands` defined in `@rules_sh//sh/unix.bzl` for the list of known
Unix commands.

### Use Unix tools in custom rules

The Unix toolchain provides two attributes:
- `commands`: A `dict` mapping names of commands to their paths.
- `paths`: A deduplicated list of bindir paths suitable for generating `$PATH`.

``` python
def _my_rule_impl(ctx):
    unix_info = ctx.toolchains["@rules_sh//sh/unix:toolchain_type"]
    ctx.actions.run(
        executable = unix_info.commands["grep"],
        ...
    )
    ctx.actions.run_shell(
        command = "grep ...",
        env = {"PATH": ":".join(unix_info.paths)},
        ...
    )

my_rule = rule(
    _my_rule_impl,
    toolchains = ["@rules_sh//sh/unix:toolchain_type"],
    ...
)
```
