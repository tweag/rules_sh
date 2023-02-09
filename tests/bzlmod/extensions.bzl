load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
load("//import:import_test.bzl", "import_test_repositories")

def _test_repositories_impl(ctx):
    http_file(
        name = "rules_sh_shim_exe",
        sha256 = "cb440b8a08a2095a59666a859b35aa5a1524b140b909ecc760f38f3baccf80e6",
        urls = ["https://github.com/ScoopInstaller/Shim/releases/download/v1.0.1/shim.exe"],
        downloaded_file_path = "shim.exe",
        executable = True,
    )
    import_test_repositories()

test_repositories = module_extension(implementation = _test_repositories_impl)
