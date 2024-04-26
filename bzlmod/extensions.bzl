load("//sh:posix.bzl", "sh_posix_configure")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

def _get_local_posix_config_enabled(module_ctx):
    # Check that every `local_posix_config` tag on this extension agrees about
    # whether we should create the local posix toolchain:
    #
    # (if no tags are set, default to true)
    enable_attrs = [
        tag.enable
        for mod in module_ctx.modules
        for tag in mod.tags.local_posix_config
    ] or [True]

    if all(enable_attrs) or not any(enable_attrs):
        return enable_attrs[0]
    else:
        # if the tags are not in agreement:
        msg = "Mismatched values for `sh_configure.local_posix_config.enable`:"

        for mod in module_ctx.modules:
            msg += "\n  - module `{}` (version: {}) specifies:".format(
                mod.name, mod.version,
            )
            for tag in mod.tags.local_posix_config:
                msg += "\n    * {}".format(tag.enable)
        msg += "\n"

        # fallback to using the first occurrence:
        (fallback, mod_name, mod_version) = [
            (tag.enable, mod.name, mod.version)
            for mod in module_ctx.modules
            for tag in mod.tags.local_posix_config
        ][0]

        msg += "\nUsing `{}` from module `{}` (version: {}) ".format(
            fallback, mod_name, mod_version,
        )
        msg += "— this is the first occurrence of this tag reached via BFS from "
        msg += "the root module."

        print(msg)
        return fallback

# Note: inlining this makes Bazel crash with:
# ```
# net.starlark.java.eval.Starlark$UncheckedEvalException:
#   IllegalStateException thrown during Starlark evaluation
# ```
_stub = repository_rule(
    implementation = lambda rctx: rctx.file("BUILD.bazel"),
)

def _sh_configure_impl(module_ctx):
    enable_local_posix_toolchain = _get_local_posix_config_enabled(module_ctx)

    if enable_local_posix_toolchain:
        sh_posix_configure(register = False)
    else:
        # stub repository so `use_repo(..., "local_posix_config")` and
        # `register_toolchains("@local_posix_config//...")` do not raise errors
        _stub(name = "local_posix_config")

    http_file(
        name = "rules_sh_shim_exe",
        sha256 = "cb440b8a08a2095a59666a859b35aa5a1524b140b909ecc760f38f3baccf80e6",
        urls = ["https://github.com/ScoopInstaller/Shim/releases/download/v1.1.0/shim.exe"],
        downloaded_file_path = "shim.exe",
        executable = True,
    )

sh_configure = module_extension(
    implementation = _sh_configure_impl,
    tag_classes = {
        "local_posix_config": tag_class(
            attrs = {
                "enable": attr.bool(
                    default = True,
                    doc = """
Whether to create and register the `@local_posix_config//:local_posix_toolchain`
toolchain.

In the event that there are multiple instances of this tag that contradict, the
first tag's value (where modules are ordered by BFS from the root module) will
be used.
""",
                ),
            },
            doc = """
Tag class with options for the `@local_posix_config` repo that this extension
creates.
""",
        ),
    },
    doc = """
Module extension that sets up `rules_sh` toolchains.

This is essentially a wrapper over `@rules_sh//sh:posix.bzl#sh_posix_configure`
for use with bzlmod.
""",
)
