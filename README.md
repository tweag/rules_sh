# Shell rules for Bazel

This project extends Bazel with a toolchain for common shell commands.

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
