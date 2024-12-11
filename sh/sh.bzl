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
        "paths": "depset of string, The directories under which the binaries can be found.",
    },
)

_WINDOWS_EXE_EXTENSIONS = [".exe", ".cmd", ".bat", ".ps1"]

_POSIX_WRAPPER_TEMPLATE = """\
#!/bin/sh
if [[ -z ${{RUNFILES_MANIFEST_FILE+x}} && -z ${{RUNFILES_DIR+x}} ]]; then
    if [[ -f "{main_executable}.runfiles_manifest" ]]; then
    export RUNFILES_MANIFEST_FILE="{main_executable}.runfiles_manifest"
    elif [[ -d "{main_executable}.runfiles" ]]; then
    export RUNFILES_DIR="{main_executable}.runfiles"
    else
    echo "ERROR: Runfiles not found for bundle {main_executable}" >&2
    exit 1
    fi
fi
exec "{original_executable}" "$@"
"""

_WINDOWS_WRAPPER_TEMPLATE = """\
@echo off
if not defined RUNFILES_MANIFEST_FILE if not defined RUNFILES_DIR (
    if exist "{main_executable}.runfiles_manifest" (
        set RUNFILES_MANIFEST_FILE="{main_executable}.runfiles_manifest"
    ) else if exist "{main_executable}.runfiles" (
        set RUNFILES_DIR="{main_executable}.runfiles"
    ) else (
        echo ERROR: Runfiles not found for bundle {main_executable} >&2
        exit /b 1
    )
)
"{original_executable}" %*
"""

def _sh_binaries_from_srcs(ctx, srcs, is_windows, main_executable):
    executable_files = []
    runfiles = ctx.runfiles()
    executables_dict = dict()
    executable_paths = []

    for src in srcs:
        if src[DefaultInfo].files_to_run == None or src[DefaultInfo].files_to_run.executable == None:
            fail("srcs must be executable, but '{}' is not.".format(src.label))

        original_executable = src[DefaultInfo].files_to_run.executable
        name = original_executable.basename
        if is_windows:
            (noext, ext) = paths.split_extension(original_executable.basename)
            if ext in _WINDOWS_EXE_EXTENSIONS:
                name = noext

        if name in executables_dict:
            fail("name collision on '{}' between '{}' and '{}' in srcs.".format(
                name,
                executables_dict[name].owner,
                src.label,
            ))

        if src[DefaultInfo].default_runfiles:
            executable = ctx.actions.declare_file(ctx.label.name + ".path/" + (name + ".bat" if is_windows else name))
            ctx.actions.write(
                executable,
                (_WINDOWS_WRAPPER_TEMPLATE if is_windows else _POSIX_WRAPPER_TEMPLATE).format(
                    main_executable = main_executable.path,
                    original_executable = original_executable.path,
                ),
                is_executable = True,
            )
            executable_files.append(original_executable)
            runfiles = runfiles.merge(src[DefaultInfo].default_runfiles)
        else:
            executable = original_executable
        executable_files.append(executable)
        executables_dict[name] = executable
        executable_paths.append(executable.dirname)

    return struct(
        executable_files = executable_files,
        runfiles = runfiles,
        executables_dict = executables_dict,
        executable_paths = executable_paths,
    )

def _sh_binaries_from_deps(ctx, deps):
    executable_files = []
    runfiles = ctx.runfiles()
    executables_dict = dict()
    executable_paths = []

    for dep in deps:
        if not ShBinariesInfo in dep:
            fail("deps must be sh_binaries targets, but '{}' is not.".format(dep.label))

        executable_files.append(dep[DefaultInfo].files)
        # TODO: Handle tools with runfiles in deps correctly. They need to be wrapped in a new
        # wrapper script as in _sh_binaries_from_srcs since the dummy executable they reference
        # is no longer the sibling of the runfiles tree.
        runfiles = runfiles.merge(dep[DefaultInfo].default_runfiles)
        executables_dict.update(dep[ShBinariesInfo].executables)
        executable_paths.append(dep[ShBinariesInfo].paths)

    return struct(
        executable_files = executable_files,
        runfiles = runfiles,
        executables_dict = executables_dict,
        executable_paths = executable_paths,
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
        paths = depset(
            direct = direct.executable_paths,
            # Reverse the order so that later deps take precedence.
            transitive = transitive.executable_paths[::-1],
            order = "preorder",
        ),
    )

def _sh_binaries_impl(ctx):
    is_windows = ctx.attr._is_windows[ConstantInfo].value
    executable = ctx.actions.declare_file(ctx.label.name)
    direct = _sh_binaries_from_srcs(ctx, ctx.attr.srcs, is_windows, executable)
    transitive = _sh_binaries_from_deps(ctx, ctx.attr.deps)
    data_runfiles = _runfiles_from_data(ctx, ctx.attr.data)

    sh_binaries_info = _mk_sh_binaries_info(direct, transitive)
    template_variable_info = mk_template_variable_info(ctx.label.name, sh_binaries_info)
    default_info = mk_default_info_with_files_to_run(
        ctx,
        executable,
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
    (tools_inputs, tools_manifest) = ctx.resolve_tools(tools = [ctx.attr.tools])

    # Use binary-a in a `run` action.
    ctx.actions.run(
        executable = tools.executables["binary-a"], # Invoke binary-a
        inputs = tools_inputs,
        input_manifests = tools_manifest,
        ...
    )

    # Use binary-a and binary-b in a `run_shell` action.
    ctx.actions.run_shell(
        command = "{binary_a}; {binary_b}".format(
            binary_a = tools.executables["binary-a"].path, # Path to binary-a
            binary_b = tools.executables["binary-b"].path, # Path to binary-b
        ]),
        tools = [
            tools.executables["binary-a"],
            tools.executables["binary-b"],
        ],
        inputs = tools_inputs,
        input_manifests = tools_manifest,
        ...
    )

    # Use binary-a and binary-b in a `run_shell` action with `PATH`.
    ctx.actions.run_shell(
        command = "PATH={path}:$PATH; binary-a; binary-b".format(
            path = ":".join(tools.paths.to_list()),
        ),
        tools = [
            tools.executables["binary-a"],
            tools.executables["binary-b"],
        ],
        inputs = tools_inputs,
        input_manifests = tools_manifest,
        ...
    )
```
""",
)
