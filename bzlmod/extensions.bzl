load("//sh:posix.bzl", "sh_posix_configure")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

def _sh_configure_impl(ctx):
    sh_posix_configure(register = False)
    http_file(
        name = "rules_sh_shim_exe",
        sha256 = "cb440b8a08a2095a59666a859b35aa5a1524b140b909ecc760f38f3baccf80e6",
        urls = ["https://github.com/ScoopInstaller/Shim/releases/download/v1.0.1/shim.exe"],
        downloaded_file_path = "shim.exe",
        executable = True,
    )

sh_configure = module_extension(implementation = _sh_configure_impl)
