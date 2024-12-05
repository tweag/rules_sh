load("@rules_sh//sh:sh.bzl", "ShBinariesInfo", "sh_binaries")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

# bundle single binary ###############################################

def _hello_world_binary():
    native.sh_binary(
        name = "hello_world",
        srcs = ["hello_world.sh"],
    )

def _bundle_single_binary_test_impl(ctx):
    env = analysistest.begin(ctx)

    bundle_under_test = analysistest.target_under_test(env)
    bundle_default_info = bundle_under_test[DefaultInfo]
    bundle_binaries_info = bundle_under_test[ShBinariesInfo]

    asserts.equals(
        env,
        1,
        len(bundle_default_info.files.to_list()),
        "Expected a singleton binary bundle",
    )

    asserts.true(
        env,
        ctx.executable.reference in bundle_default_info.files.to_list(),
        '"hello_world" should be in the DefaultInfo.files',
    )

    asserts.true(
        env,
        "hello_world" in bundle_binaries_info.executables,
        '"hello_world" should be in ShBinariesInfo.files',
    )

    asserts.equals(
        env,
        ctx.executable.reference,
        bundle_binaries_info.executables["hello_world"],
    )

    asserts.equals(
        env,
        1,
        len(bundle_binaries_info.paths.to_list()),
        "Expected a singleton PATH list.",
    )

    asserts.true(
        env,
        ctx.executable.reference.dirname in bundle_binaries_info.paths.to_list(),
        'Expected "hello_world" in bundle PATH list.',
    )

    return analysistest.end(env)

bundle_single_binary_test = analysistest.make(
    _bundle_single_binary_test_impl,
    attrs = {
        "reference": attr.label(
            executable = True,
            # TODO[AH] Both the target_under_test and the reference should be
            # provided in the exec configuration.
            # See https://github.com/bazelbuild/bazel-skylib/issues/377
            # cfg = "exec",
            cfg = "target",
            doc = "The single binary contained in the bundle. Used for reference.",
        ),
    },
)

def _test_single_binary():
    sh_binaries(
        name = "bundle_single_binary",
        srcs = [":hello_world"],
        tags = ["manual"],
    )
    bundle_single_binary_test(
        name = "bundle_single_binary_test",
        target_under_test = ":bundle_single_binary",
        reference = ":hello_world",
    )

# bundle binary with data ############################################

def _hello_data_binary():
    native.sh_binary(
        name = "hello_data",
        srcs = ["hello_data.sh"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        data = ["hello_data.txt"],
    )

def _bundle_binary_with_data_test_impl(ctx):
    env = analysistest.begin(ctx)

    bundle_under_test = analysistest.target_under_test(env)
    bundle_default_info = bundle_under_test[DefaultInfo]
    bundle_binaries_info = bundle_under_test[ShBinariesInfo]

    asserts.equals(
        env,
        # On Windows the runfiles will contain both hello_data and hello_data.exe.
        6 if ctx.attr.is_windows else 5,
        len(bundle_default_info.default_runfiles.files.to_list()),
        "Expected a runfiles set with five items",
    )

    for file in ctx.attr.reference[DefaultInfo].default_runfiles.files.to_list():
        asserts.true(
            env,
            file in bundle_default_info.default_runfiles.files.to_list(),
            "The file {} should be in the runfiles set.".format(file.basename),
        )

    # The dummy binary is a workaround for https://github.com/bazelbuild/bazel/issues/15486
    asserts.true(
        env,
        bundle_default_info.files_to_run.executable in bundle_default_info.default_runfiles.files.to_list(),
        "The bundle dummy binary should be in the runfiles set.",
    )

    return analysistest.end(env)

bundle_binary_with_data_test = analysistest.make(
    _bundle_binary_with_data_test_impl,
    attrs = {
        "reference": attr.label(
            executable = True,
            # TODO[AH] Both the target_under_test and the reference should be
            # provided in the exec configuration.
            # See https://github.com/bazelbuild/bazel-skylib/issues/377
            # cfg = "exec",
            cfg = "target",
            doc = "The binary with data contained in the bundle. Used for reference.",
        ),
        "is_windows": attr.bool(),
    },
)

def _test_binary_with_data():
    sh_binaries(
        name = "bundle_binary_with_data",
        srcs = [":hello_data"],
        tags = ["manual"],
    )
    bundle_binary_with_data_test(
        name = "bundle_binary_with_data_test",
        target_under_test = ":bundle_binary_with_data",
        reference = ":hello_data",
        is_windows = select({
            "@platforms//os:windows": True,
            "//conditions:default": False,
        }),
    )

# empty bundle with data #############################################

def _empty_bundle_with_data_test_impl(ctx):
    env = analysistest.begin(ctx)

    bundle_under_test = analysistest.target_under_test(env)
    bundle_default_info = bundle_under_test[DefaultInfo]
    bundle_binaries_info = bundle_under_test[ShBinariesInfo]

    asserts.equals(
        env,
        2,
        len(bundle_default_info.default_runfiles.files.to_list()),
        "Expected a runfiles set with two items.",
    )

    asserts.true(
        env,
        ctx.file.reference in bundle_default_info.default_runfiles.files.to_list(),
        '"hello_data.txt" should be in the runfiles set.',
    )

    # The dummy binary is a workaround for https://github.com/bazelbuild/bazel/issues/15486
    asserts.true(
        env,
        bundle_default_info.files_to_run.executable in bundle_default_info.default_runfiles.files.to_list(),
        "The bundle dummy binary should be in the runfiles set.",
    )

    return analysistest.end(env)

empty_bundle_with_data_test = analysistest.make(
    _empty_bundle_with_data_test_impl,
    attrs = {
        "reference": attr.label(
            allow_single_file = True,
            doc = "The data contained in the bundle. Used for reference.",
        ),
    },
)

def _test_empty_bundle_with_data():
    sh_binaries(
        name = "empty_bundle_with_data",
        srcs = [],
        data = ["hello_data.txt"],
        tags = ["manual"],
    )
    empty_bundle_with_data_test(
        name = "empty_bundle_with_data_test",
        target_under_test = ":empty_bundle_with_data",
        reference = "hello_data.txt",
    )

# bundle two binaries ################################################

def _bundle_two_binaries_test_impl(ctx):
    env = analysistest.begin(ctx)

    bundle_under_test = analysistest.target_under_test(env)
    bundle_default_info = bundle_under_test[DefaultInfo]
    bundle_binaries_info = bundle_under_test[ShBinariesInfo]

    asserts.equals(
        env,
        2,
        len(bundle_default_info.files.to_list()),
        "Expected two binaries in the bundle",
    )

    asserts.true(
        env,
        ctx.executable.reference_hello_world in bundle_default_info.files.to_list(),
        '"hello_world" should be in the DefaultInfo.files',
    )

    asserts.true(
        env,
        ctx.executable.reference_hello_data in bundle_default_info.files.to_list(),
        '"hello_data" should be in the DefaultInfo.files',
    )

    asserts.true(
        env,
        ctx.file.reference_data_file in bundle_default_info.default_runfiles.files.to_list(),
        "Expected the data file in the runfiles",
    )

    asserts.true(
        env,
        "hello_world" in bundle_binaries_info.executables,
        '"hello_world" should be in ShBinariesInfo.files',
    )

    asserts.equals(
        env,
        ctx.executable.reference_hello_world,
        bundle_binaries_info.executables["hello_world"],
    )

    asserts.true(
        env,
        "hello_data" in bundle_binaries_info.executables,
        '"hello_data" should be in ShBinariesInfo.files',
    )

    asserts.equals(
        env,
        ctx.executable.reference_hello_data,
        bundle_binaries_info.executables["hello_data"],
    )

    asserts.equals(
        env,
        1,
        len(bundle_binaries_info.paths.to_list()),
        "Expected a singleton PATH list.",
    )

    asserts.true(
        env,
        ctx.executable.reference_hello_world.dirname in bundle_binaries_info.paths.to_list(),
        'Expected "hello_world" in bundle PATH list.',
    )

    asserts.true(
        env,
        ctx.executable.reference_hello_data.dirname in bundle_binaries_info.paths.to_list(),
        'Expected "hello_data" in bundle PATH list.',
    )

    return analysistest.end(env)

bundle_two_binaries_test = analysistest.make(
    _bundle_two_binaries_test_impl,
    attrs = {
        "reference_hello_world": attr.label(
            executable = True,
            # TODO[AH] Both the target_under_test and the reference should be
            # provided in the exec configuration.
            # See https://github.com/bazelbuild/bazel-skylib/issues/377
            # cfg = "exec",
            cfg = "target",
            doc = "The first binary. Used for reference.",
        ),
        "reference_hello_data": attr.label(
            executable = True,
            # TODO[AH] Both the target_under_test and the reference should be
            # provided in the exec configuration.
            # See https://github.com/bazelbuild/bazel-skylib/issues/377
            # cfg = "exec",
            cfg = "target",
            doc = "The second binary. Used for reference.",
        ),
        "reference_data_file": attr.label(
            allow_single_file = True,
            doc = "The data file contained in the second dependency. Used for reference.",
        ),
    },
)

def _test_bundle_two_binaries():
    sh_binaries(
        name = "bundle_two_binaries",
        srcs = [
            ":hello_world",
            ":hello_data",
        ],
        tags = ["manual"],
    )
    bundle_two_binaries_test(
        name = "bundle_two_binaries_test",
        target_under_test = ":bundle_two_binaries",
        reference_hello_world = ":hello_world",
        reference_hello_data = ":hello_data",
        reference_data_file = "hello_data.txt",
    )

# merge bundles ######################################################

def _merge_bundles_test_impl(ctx):
    env = analysistest.begin(ctx)

    bundle_under_test = analysistest.target_under_test(env)
    bundle_default_info = bundle_under_test[DefaultInfo]
    bundle_binaries_info = bundle_under_test[ShBinariesInfo]

    asserts.equals(
        env,
        2,
        len(bundle_default_info.files.to_list()),
        "Expected two binaries in the bundle",
    )

    asserts.true(
        env,
        ctx.executable.reference_hello_world in bundle_default_info.files.to_list(),
        '"hello_world" should be in the DefaultInfo.files',
    )

    asserts.true(
        env,
        ctx.executable.reference_hello_data in bundle_default_info.files.to_list(),
        '"hello_data" should be in the DefaultInfo.files',
    )

    asserts.true(
        env,
        ctx.file.reference_data_file in bundle_default_info.default_runfiles.files.to_list(),
        "Expected the data file in the runfiles",
    )

    asserts.true(
        env,
        "hello_world" in bundle_binaries_info.executables,
        '"hello_world" should be in ShBinariesInfo.files',
    )

    asserts.equals(
        env,
        ctx.executable.reference_hello_world,
        bundle_binaries_info.executables["hello_world"],
    )

    asserts.true(
        env,
        "hello_data" in bundle_binaries_info.executables,
        '"hello_data" should be in ShBinariesInfo.files',
    )

    asserts.equals(
        env,
        ctx.executable.reference_hello_data,
        bundle_binaries_info.executables["hello_data"],
    )

    asserts.equals(
        env,
        1,
        len(bundle_binaries_info.paths.to_list()),
        "Expected a singleton PATH list.",
    )

    asserts.true(
        env,
        ctx.executable.reference_hello_world.dirname in bundle_binaries_info.paths.to_list(),
        'Expected "hello_world" in bundle PATH list.',
    )

    asserts.true(
        env,
        ctx.executable.reference_hello_data.dirname in bundle_binaries_info.paths.to_list(),
        'Expected "hello_data" in bundle PATH list.',
    )

    return analysistest.end(env)

merge_bundles_test = analysistest.make(
    _merge_bundles_test_impl,
    attrs = {
        "reference_hello_world": attr.label(
            executable = True,
            # TODO[AH] Both the target_under_test and the reference should be
            # provided in the exec configuration.
            # See https://github.com/bazelbuild/bazel-skylib/issues/377
            # cfg = "exec",
            cfg = "target",
            doc = "The binary contained in the first dependency. Used for reference.",
        ),
        "reference_hello_data": attr.label(
            executable = True,
            # TODO[AH] Both the target_under_test and the reference should be
            # provided in the exec configuration.
            # See https://github.com/bazelbuild/bazel-skylib/issues/377
            # cfg = "exec",
            cfg = "target",
            doc = "The binary contained in the second dependency. Used for reference.",
        ),
        "reference_data_file": attr.label(
            allow_single_file = True,
            doc = "The data file contained in the second dependency. Used for reference.",
        ),
    },
)

def _test_merge_bundles():
    sh_binaries(
        name = "merge_bundles_part_hello_world",
        srcs = [":hello_world"],
        tags = ["manual"],
    )
    sh_binaries(
        name = "merge_bundles_part_hello_data",
        srcs = [":hello_data"],
        tags = ["manual"],
    )
    sh_binaries(
        name = "merge_bundles",
        deps = [
            ":merge_bundles_part_hello_world",
            ":merge_bundles_part_hello_data",
        ],
        tags = ["manual"],
    )
    merge_bundles_test(
        name = "merge_bundles_test",
        target_under_test = ":merge_bundles",
        reference_hello_world = ":hello_world",
        reference_hello_data = ":hello_data",
        reference_data_file = "hello_data.txt",
    )

# bundle used in custom rule #########################################

def _custom_rule_impl(ctx):
    tools = ctx.attr.tools[ShBinariesInfo]
    (tools_inputs, tools_manifest) = ctx.resolve_tools(tools = [ctx.attr.tools])

    # Override the argv[0] relative runfiles tree or manifest by the bundle's.
    # This is a workaround for https://github.com/bazelbuild/bazel/issues/15486
    tools_env = {
        "RUNFILES_DIR": ctx.attr.tools[DefaultInfo].files_to_run.runfiles_manifest.dirname,
        "RUNFILES_MANIFEST_FILE": ctx.attr.tools[DefaultInfo].files_to_run.runfiles_manifest.path,
    }

    output_run = ctx.actions.declare_file("custom_rule_run_output")
    ctx.actions.run(
        outputs = [output_run],
        inputs = tools_inputs,
        executable = tools.executables["hello_data"],
        arguments = [output_run.path],
        mnemonic = "RunExecutableWithBundle",
        progress_message = "Running hello_data",
        env = tools_env,
        input_manifests = tools_manifest,
    )

    output_run_shell = ctx.actions.declare_file("custom_rule_run_shell_output")
    ctx.actions.run_shell(
        outputs = [output_run_shell],
        inputs = tools_inputs,
        tools = [
            tools.executables["hello_world"],
            tools.executables["hello_data"],
        ],
        arguments = [
            tools.executables["hello_world"].path,
            tools.executables["hello_data"].path,
            output_run_shell.path,
        ],
        mnemonic = "RunCommandWithBundle",
        command = "$1 > $3 && $2 >> $3",
        progress_message = "Running hello_world and hello_data",
        env = tools_env,
        input_manifests = tools_manifest,
    )

    default_info = DefaultInfo(
        files = depset(direct = [output_run, output_run_shell]),
        runfiles = ctx.runfiles(files = [output_run, output_run_shell]),
    )

    return [default_info]

custom_rule = rule(
    _custom_rule_impl,
    attrs = {
        "tools": attr.label(
            cfg = "exec",
            mandatory = True,
        ),
    },
)

def _test_custom_rule():
    sh_binaries(
        name = "custom_rule_bundle",
        srcs = [
            ":hello_world",
            ":hello_data",
        ],
        tags = ["manual"],
    )
    custom_rule(
        name = "custom_rule",
        tools = ":custom_rule_bundle",
        tags = ["manual"],
    )
    native.sh_test(
        name = "custom_rule_test",
        srcs = ["custom_rule_test.sh"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        data = [":custom_rule"],
    )

# bundle used in genrule #############################################

def _test_genrule():
    sh_binaries(
        name = "genrule_bundle",
        srcs = [
            ":hello_world",
            ":hello_data",
        ],
        tags = ["manual"],
    )
    native.genrule(
        name = "genrule",
        outs = [
            "genrule_output_world",
            "genrule_output_data",
            "genrule_output_by_path",
        ],
        cmd = """\
$(GENRULE_BUNDLE_HELLO_WORLD) >$(execpath genrule_output_world)
$(GENRULE_BUNDLE_HELLO_DATA) >$(execpath genrule_output_data)

PATH="$(_GENRULE_BUNDLE_PATH):$$PATH"
hello_world >$(execpath genrule_output_by_path)
hello_data >>$(execpath genrule_output_by_path)
""",
        toolchains = [":genrule_bundle"],
    )
    native.sh_test(
        name = "genrule_test",
        srcs = ["genrule_test.sh"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        data = [":genrule"],
    )

# non executable #####################################################

def _non_executable_impl(ctx):
    output = ctx.actions.declare_file(
        ctx.attr.path,
    )
    ctx.actions.write(
        output,
        content = "",
        is_executable = False,
    )
    return [DefaultInfo(
        files = depset(direct = [output]),
    )]

non_executable = rule(
    _non_executable_impl,
    attrs = {
        "path": attr.string(),
    },
)

def _non_executable_test_impl(ctx):
    env = analysistest.begin(ctx)

    workspace = str(ctx.label).split("//")[0]

    asserts.expect_failure(
        env,
        " ".join([
            "srcs must be executable,",
            "but '{}//sh_binaries:non_executable_target' is not.".format(workspace),
        ]),
    )

    return analysistest.end(env)

non_executable_test = analysistest.make(
    _non_executable_test_impl,
    expect_failure = True,
)

def _test_non_executable():
    non_executable(
        name = "non_executable_target",
        path = "non_executable_file",
        tags = ["manual"],
    )
    sh_binaries(
        name = "non_executable",
        srcs = [
            ":non_executable_target",
        ],
        tags = ["manual"],
    )
    non_executable_test(
        name = "non_executable_test",
        target_under_test = ":non_executable",
    )

# non bundle dependency ##############################################

def _non_bundle_dependency_test_impl(ctx):
    env = analysistest.begin(ctx)

    workspace = str(ctx.label).split("//")[0]

    asserts.expect_failure(
        env,
        " ".join([
            "deps must be sh_binaries targets,",
            "but '{}//sh_binaries:hello_world' is not.".format(workspace),
        ]),
    )

    return analysistest.end(env)

non_bundle_dependency_test = analysistest.make(
    _non_bundle_dependency_test_impl,
    expect_failure = True,
)

def _test_non_bundle_dependency():
    sh_binaries(
        name = "non_bundle_dependency",
        deps = [
            ":hello_world",
        ],
        tags = ["manual"],
    )
    non_bundle_dependency_test(
        name = "non_bundle_dependency_test",
        target_under_test = ":non_bundle_dependency",
    )

# name collision #####################################################

def _dummy_binary_impl(ctx):
    output = ctx.actions.declare_file(
        ctx.attr.path,
    )
    ctx.actions.write(
        output,
        content = "",
        is_executable = True,
    )
    return [DefaultInfo(
        executable = output,
    )]

dummy_binary = rule(
    _dummy_binary_impl,
    attrs = {
        "path": attr.string(),
    },
    executable = True,
)

def _name_collision_test_impl(ctx):
    env = analysistest.begin(ctx)

    workspace = str(ctx.label).split("//")[0]

    asserts.expect_failure(
        env,
        " ".join([
            "name collision on 'dummy' between",
            "'{}//sh_binaries:name_collision_1' and".format(workspace),
            "'{}//sh_binaries:name_collision_2' in srcs.".format(workspace),
        ]),
    )

    return analysistest.end(env)

name_collision_test = analysistest.make(
    _name_collision_test_impl,
    expect_failure = True,
)

def _test_name_collision():
    dummy_binary(
        name = "name_collision_1",
        path = "name_collision_1/dummy",
        tags = ["manual"],
    )
    dummy_binary(
        name = "name_collision_2",
        path = "name_collision_2/dummy",
        tags = ["manual"],
    )
    sh_binaries(
        name = "name_collision",
        srcs = [
            ":name_collision_1",
            ":name_collision_2",
        ],
        tags = ["manual"],
    )
    name_collision_test(
        name = "name_collision_test",
        target_under_test = ":name_collision",
    )

# override srcs ######################################################

def _override_srcs_test_impl(ctx):
    env = analysistest.begin(ctx)

    bundle_under_test = analysistest.target_under_test(env)
    bundle_binaries_info = bundle_under_test[ShBinariesInfo]

    asserts.equals(
        env,
        ctx.executable.reference,
        bundle_binaries_info.executables["dummy"],
    )

    asserts.equals(
        env,
        ctx.executable.reference.dirname,
        bundle_binaries_info.paths.to_list()[0],
    )

    return analysistest.end(env)

override_srcs_test = analysistest.make(
    _override_srcs_test_impl,
    attrs = {
        "reference": attr.label(
            executable = True,
            # TODO[AH] Both the target_under_test and the reference should be
            # provided in the exec configuration.
            # See https://github.com/bazelbuild/bazel-skylib/issues/377
            # cfg = "exec",
            cfg = "target",
            doc = "The binary that should take precedence. Used for reference.",
        ),
    },
)

def _test_override_srcs():
    dummy_binary(
        name = "override_srcs_bin_1",
        path = "override_srcs_bin_1/dummy",
        tags = ["manual"],
    )
    dummy_binary(
        name = "override_srcs_bin_2",
        path = "override_srcs_bin_2/dummy",
        tags = ["manual"],
    )
    sh_binaries(
        name = "override_srcs_1",
        srcs = [":override_srcs_bin_1"],
        tags = ["manual"],
    )
    sh_binaries(
        name = "override_srcs",
        srcs = [":override_srcs_bin_2"],
        deps = [":override_srcs_1"],
        tags = ["manual"],
    )
    override_srcs_test(
        name = "override_srcs_test",
        target_under_test = ":override_srcs",
        reference = ":override_srcs_bin_2",
    )

# override deps ######################################################

def _override_deps_test_impl(ctx):
    env = analysistest.begin(ctx)

    bundle_under_test = analysistest.target_under_test(env)
    bundle_binaries_info = bundle_under_test[ShBinariesInfo]

    asserts.equals(
        env,
        ctx.executable.reference,
        bundle_binaries_info.executables["dummy"],
    )

    asserts.equals(
        env,
        ctx.executable.reference.dirname,
        bundle_binaries_info.paths.to_list()[0],
    )

    return analysistest.end(env)

override_deps_test = analysistest.make(
    _override_deps_test_impl,
    attrs = {
        "reference": attr.label(
            executable = True,
            # TODO[AH] Both the target_under_test and the reference should be
            # provided in the exec configuration.
            # See https://github.com/bazelbuild/bazel-skylib/issues/377
            # cfg = "exec",
            cfg = "target",
            doc = "The binary that should take precedence. Used for reference.",
        ),
    },
)

def _test_override_deps():
    dummy_binary(
        name = "override_deps_bin_1",
        path = "override_deps_bin_1/dummy",
        tags = ["manual"],
    )
    dummy_binary(
        name = "override_deps_bin_2",
        path = "override_deps_bin_2/dummy",
        tags = ["manual"],
    )
    sh_binaries(
        name = "override_deps_1",
        srcs = [":override_deps_bin_1"],
        tags = ["manual"],
    )
    sh_binaries(
        name = "override_deps_2",
        srcs = [":override_deps_bin_2"],
        tags = ["manual"],
    )
    sh_binaries(
        name = "override_deps",
        deps = [
            ":override_deps_1",
            ":override_deps_2",
        ],
        tags = ["manual"],
    )
    override_deps_test(
        name = "override_deps_test",
        target_under_test = ":override_deps",
        reference = ":override_deps_bin_2",
    )

# Windows strip exe ##################################################

def _windows_strip_exe_test_impl(ctx):
    env = analysistest.begin(ctx)

    bundle_under_test = analysistest.target_under_test(env)
    bundle_binaries_info = bundle_under_test[ShBinariesInfo]

    asserts.true(
        env,
        "empty" in bundle_binaries_info.executables,
    )

    return analysistest.end(env)

windows_strip_exe_test = analysistest.make(
    _windows_strip_exe_test_impl,
    config_settings = {
        "//command_line_option:platforms": str(Label("//sh_binaries:windows")),
    },
    # TODO[AH] The target_under_test should be provided in the exec
    # configuration to be sure that the Windows platform check considers the
    # correct platform, i.e. the execute platform in tools use-cases.
    # See https://github.com/bazelbuild/bazel-skylib/issues/377
)

def _test_windows_strip_exe():
    native.platform(
        name = "windows",
        constraint_values = [
            "@platforms//os:windows",
        ],
    )
    sh_binaries(
        name = "windows_strip_exe",
        srcs = ["empty.exe"],
    )
    windows_strip_exe_test(
        name = "windows_strip_exe_test",
        target_under_test = ":windows_strip_exe",
    )

# Linux keep exe #####################################################

def _linux_keep_exe_test_impl(ctx):
    env = analysistest.begin(ctx)

    bundle_under_test = analysistest.target_under_test(env)
    bundle_binaries_info = bundle_under_test[ShBinariesInfo]

    asserts.true(
        env,
        "empty.exe" in bundle_binaries_info.executables,
    )

    return analysistest.end(env)

linux_keep_exe_test = analysistest.make(
    _linux_keep_exe_test_impl,
    config_settings = {
        "//command_line_option:platforms": str(Label("//sh_binaries:linux")),
    },
    # TODO[AH] The target_under_test should be provided in the exec
    # configuration to be sure that the Windows platform check considers the
    # correct platform, i.e. the execute platform in tools use-cases.
    # See https://github.com/bazelbuild/bazel-skylib/issues/377
)

def _test_linux_keep_exe():
    native.platform(
        name = "linux",
        constraint_values = [
            "@platforms//os:linux",
        ],
    )
    sh_binaries(
        name = "linux_keep_exe",
        srcs = ["empty.exe"],
    )
    linux_keep_exe_test(
        name = "linux_keep_exe_test",
        target_under_test = ":linux_keep_exe",
    )

# test suite #########################################################

def sh_binaries_test_suite(name):
    _hello_world_binary()
    _hello_data_binary()

    _test_single_binary()
    _test_binary_with_data()
    _test_empty_bundle_with_data()
    _test_bundle_two_binaries()
    _test_merge_bundles()
    _test_custom_rule()
    _test_genrule()
    _test_non_executable()
    _test_non_bundle_dependency()
    _test_name_collision()
    _test_override_srcs()
    _test_override_deps()
    _test_windows_strip_exe()
    _test_linux_keep_exe()

    native.test_suite(
        name = name,
        tests = [
            ":bundle_single_binary_test",
            ":bundle_binary_with_data_test",
            ":empty_bundle_with_data_test",
            ":bundle_two_binaries_test",
            ":merge_bundles_test",
            ":custom_rule_test",
            ":genrule_test",
            ":non_executable_test",
            ":non_bundle_dependency_test",
            ":name_collision_test",
            ":override_srcs_test",
            ":override_deps_test",
            ":windows_strip_exe_test",
            ":linux_keep_exe_test",
        ],
    )
