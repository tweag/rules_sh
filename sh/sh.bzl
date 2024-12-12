load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")
load(
    "@rules_sh//sh/private:defs.bzl",
    "ConstantInfo",
    "mk_default_info_with_files_to_run",
    "mk_template_variable_info",
)

ShBinariesInfo = provider(
    doc = "The description of a sh_binaries target.",
    fields = {
        "executables": "dict of File, The executables included in the bundle by name.",
        "files_to_run": "dict of FilesToRunProvider, to be passed to ctx.action.run / ctx.action.run_shell.",
        "paths": "depset of string, The directories under which the binaries can be found.",
    },
)

_WINDOWS_EXE_EXTENSIONS = [".exe", ".cmd", ".bat", ".ps1"]

def _sh_binaries_from_srcs(ctx, srcs, is_windows):
    executable_files = []
    runfiles = ctx.runfiles()
    executables_dict = dict()
    files_to_run_dict = dict()
    executable_paths = []

    for src in srcs:
        if src[DefaultInfo].files_to_run == None or src[DefaultInfo].files_to_run.executable == None:
            fail("srcs must be executable, but '{}' is not.".format(src.label))

        files_to_run = src[DefaultInfo].files_to_run
        executable = files_to_run.executable
        name = executable.basename
        if is_windows:
            (noext, ext) = paths.split_extension(executable.basename)
            if ext in _WINDOWS_EXE_EXTENSIONS:
                name = noext

        if name in executables_dict:
            fail("name collision on '{}' between '{}' and '{}' in srcs.".format(
                name,
                executables_dict[name].owner,
                src.label,
            ))

        executable_files.append(executable)
        runfiles = runfiles.merge(src[DefaultInfo].default_runfiles)
        executables_dict[name] = executable
        files_to_run_dict[name] = files_to_run
        executable_paths.append(executable.dirname)

    return struct(
        executable_files = executable_files,
        runfiles = runfiles,
        executables_dict = executables_dict,
        executable_paths = executable_paths,
        files_to_run_dict = files_to_run_dict,
    )

def _sh_binaries_from_deps(ctx, deps):
    executable_files = []
    runfiles = ctx.runfiles()
    files_to_run_dict = dict()
    executables_dict = dict()
    executable_paths = []

    for dep in deps:
        if not ShBinariesInfo in dep:
            fail("deps must be sh_binaries targets, but '{}' is not.".format(dep.label))

        executable_files.append(dep[DefaultInfo].files)
        runfiles = runfiles.merge(dep[DefaultInfo].default_runfiles)
        executables_dict.update(dep[ShBinariesInfo].executables)
        files_to_run_dict.update(dep[ShBinariesInfo].files_to_run)
        executable_paths.append(dep[ShBinariesInfo].paths)

    return struct(
        executable_files = executable_files,
        runfiles = runfiles,
        executables_dict = executables_dict,
        executable_paths = executable_paths,
        files_to_run_dict = files_to_run_dict,
    )

def _runfiles_from_data(ctx, data):
    runfiles = ctx.runfiles()

    for data in data:
        runfiles = runfiles.merge(ctx.runfiles(transitive_files = data[DefaultInfo].files))
        runfiles = runfiles.merge(data[DefaultInfo].default_runfiles)

    return runfiles

def _mk_sh_binaries_info(direct, transitive):
    return ShBinariesInfo(
        executables = dicts.add(
            # The order is important so that srcs take precedence over deps on collision.
            transitive.executables_dict,
            direct.executables_dict,
        ),
        files_to_run = dicts.add(
            # The order is important so that srcs take precedence over deps on collision.
            transitive.files_to_run_dict,
            direct.files_to_run_dict,
        ),
        paths = depset(
            direct = direct.executable_paths,
            # Reverse the order so that later deps take precedence.
            transitive = transitive.executable_paths[::-1],
            order = "preorder",
        ),
    )

def _sh_binaries_impl(ctx):
    is_windows = ctx.attr._is_windows[ConstantInfo].value
    direct = _sh_binaries_from_srcs(ctx, ctx.attr.srcs, is_windows)
    transitive = _sh_binaries_from_deps(ctx, ctx.attr.deps)
    data_runfiles = _runfiles_from_data(ctx, ctx.attr.data)

    sh_binaries_info = _mk_sh_binaries_info(direct, transitive)
    template_variable_info = mk_template_variable_info(ctx.label.name, sh_binaries_info)
    default_info = mk_default_info_with_files_to_run(
        ctx,
        ctx.label.name,
        depset(direct = direct.executable_files, transitive = transitive.executable_files),
        direct.runfiles.merge(transitive.runfiles).merge(data_runfiles),
    )

    return [sh_binaries_info, template_variable_info, default_info]

sh_binaries = rule(
    _sh_binaries_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            doc = "The executables to include in the bundle.",
        ),
        "deps": attr.label_list(
            doc = "Existing binary bundles to merge into this bundle. In case of collision, later deps take precedence over earlier ones, and srcs take precedence over deps.",
        ),
        "data": attr.label_list(
            allow_files = True,
            doc = "Additional runtime dependencies needed by any of the bundled binaries.",
        ),
        "_is_windows": attr.label(
            default = "@rules_sh//sh/private:is_windows",
        ),
    },
    executable = True,
    doc = """\
Defines a bundle of binaries usable as build tools in a genrule or a custom rule.

Exposes the bundled tools as make variables of the form
`$(BUNDLE_NAME_BINARY_NAME)`, and exposes a make variable of the form
`$(_BUNDLE_NAME_PATH)` to extend `PATH` with all bundled binaries.

Also exposes the bundled tools and a list of `PATH` items through the Starlark
provider `ShBinariesInfo`.

#### Example

*Defining a Bundle*

Create a binary bundle target as follows:

```bzl
sh_binaries(
    name = "a-bundle",
    srcs = [
        "binary-a",
        "binary-b",
    ],
)
```

*Using a Bundle in a Genrule*

Use the binaries in the bundle in a `genrule` by adding it to the `toolchains`
attribute and use the generated make variables to access the bundled binaries
as follows:

```bzl
genrule(
    name = "a-genrule",
    toolchains = [":a-bundle"],
    cmd = "\\n".join([
        "$(A_BUNDLE_BINARY_A) -foo bar",  # Invoke binary-a
        "$(A_BUNDLE_BINARY_B) -baz qux",  # Invoke binary-b
        "PATH=$(_A_BUNDLE_PATH):$$PATH",  # Extend PATH to include both binaries
        "binary-a; binary-b",             # Invoke binary-a and binary-b
    ]),
    outs = [...],
)
```

*Merging Bundles*

Merge existing bundles into other bundles using the `deps` attribute as follows:

```bzl
sh_binaries(
    name = "another-bundle",
    srcs = ["binary-c"],
    deps = [":a-bundle"],
)
```

The make variable prefix will be determined by the `sh_binaries` target that
you depend on. E.g. with the above `another-bundle` target the make variable
prefix will be `ANOTHER_BUNDLE_`:

```bzl
genrule(
    name = "another-genrule",
    toolchains = [":another-bundle"],
    cmd = "\\n".join([
        "$(ANOTHER_BUNDLE_BINARY_A) -foo bar", # Invoke binary-a
        "$(ANOTHER_BUNDLE_BINARY_C) -baz qux", # Invoke binary-c
        "PATH=$(_ANOTHER_BUNDLE_PATH):$$PATH", # Extend PATH to include both binaries
        "binary-a; binary-c",                  # Invoke binary-a and binary-c
    ]),
    outs = [...],
)
```

*Using a Bundle in a Custom Rule*

Use the binaries in a bundle in a custom rule by adding an attribute to depend
on the bundle as follows, note that it should use the `cfg = "exec"` parameter,
because these tools will be used as build tools:

```bzl
# defs.bzl
custom_rule = rule(
    _custom_rule_impl,
    attrs = {
        "tools": attr.label(
             cfg = "exec",
        ),
    },
)

# BUILD.bazel
custom_rule(
    name = "custom",
    tools = ":a-bundle",
)
```

Use the `ShBinariesInfo` provider to use the tools in build actions. The
individual tools are exposed in the `executables` field, and the `PATH` list is
exposed in `paths` as follows:

```bzl
load("@rules_sh//sh:sh.bzl", "ShBinariesInfo")

def _custom_rule_impl(ctx):
    tools = ctx.attr.tools[ShBinariesInfo]

    # Use binary-a in a `run` action.
    ctx.actions.run(
        executable = tools.files_to_run["binary-a"], # Invoke binary-a
        ...
    )

    # Use binary-a and binary-b in a `run_shell` action.
    ctx.actions.run_shell(
        command = "{binary_a}; {binary_b}".format(
            binary_a = tools.executables["binary-a"].path, # Path to binary-a
            binary_b = tools.executables["binary-b"].path, # Path to binary-b
        ]),
        tools = [
            tools.files_to_run["binary-a"],
            tools.files_to_run["binary-b"],
        ],
        ...
    )

    # Use binary-a and binary-b in a `run_shell` action with `PATH`.
    ctx.actions.run_shell(
        command = "PATH={path}:$PATH; binary-a; binary-b".format(
            path = ":".join(tools.paths.to_list()),
        ),
        tools = [
            tools.files_to_run["binary-a"],
            tools.files_to_run["binary-b"],
        ],
        ...
    )
```

*Caveat: Using Binaries that require Runfiles*

Note, support for binaries that require runfiles is limited due to limitations
imposed by Bazel's Starlark API, see [#15486][issue-15486]. In order for these
to work you will need to define the `RUNFILES_DIR` or `RUNFILES_MANIFEST_FILE`
environment variables for the action using tools from the bundle.

(Use `RUNFILES_MANIFEST_FILE` if your operating system and configuration does
not support a runfiles tree and instead only provides a runfiles manifest file,
as is commonly the case on Windows.)

You can achieve this in a `genrule` as follows:

```bzl
genrule(
    name = "runfiles-genrule",
    toolchains = [":a-bundle"],
    cmd = "\\n".join([
        # The explicit RUNFILES_DIR/RUNFILES_MANIFEST_FILE is a workaround for
        # https://github.com/bazelbuild/bazel/issues/15486
        "RUNFILES_DIR=$(execpath :a-bundle).runfiles",
        "RUNFILES_MANIFEST_FILE=$(execpath :a-bundle).runfiles_manifest",
        "$(A_BUNDLE_BINARY_A)",
        "$(A_BUNDLE_BINARY_B)",
    ]),
    outs = [...],
)
```

And in a custom rule as follows:

```bzl
def _custom_rule_impl(ctx):
    tools = ctx.attr.tools[ShBinariesInfo]
    # The explicit RUNFILES_DIR/RUNFILES_MANIFEST_FILE is a workaround for
    # https://github.com/bazelbuild/bazel/issues/15486
    tools_env = {
        "RUNFILES_DIR": ctx.attr.tools[DefaultInfo].files_to_run.runfiles_manifest.dirname,
        "RUNFILES_MANIFEST_FILE": ctx.attr.tools[DefaultInfo].files_to_run.runfiles_manifest.path,
    }

    ctx.actions.run(
        executable = tools.files_to_run["binary-a"],
        env = tools_env, # Pass the environment into the action.
        ...
    )
```

[issue-15486]: https://github.com/bazelbuild/bazel/issues/15486
""",
)
