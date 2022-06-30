load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

def rules_sh_dependencies():
    """Load repositories required by rules_sh."""
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "e5d90f0ec952883d56747b7604e2a15ee36e288bb556c3d0ed33e818a4d971f2",
        strip_prefix = "bazel-skylib-1.0.2",
        urls = ["https://github.com/bazelbuild/bazel-skylib/archive/1.0.2.tar.gz"],
    )
    maybe(
        http_archive,
        "platforms",
        sha256 = "23566db029006fe23d8140d14514ada8c742d82b51973b4d331ee423c75a0bfa",
        strip_prefix = "platforms-46993efdd33b73649796c5fc5c9efb193ae19d51",
        urls = ["https://github.com/bazelbuild/platforms/archive/46993efdd33b73649796c5fc5c9efb193ae19d51.tar.gz"],
    )
    maybe(
        http_file,
        name = "rules_sh_shim_exe",
        sha256 = "cb440b8a08a2095a59666a859b35aa5a1524b140b909ecc760f38f3baccf80e6",
        urls = ["https://github.com/ScoopInstaller/Shim/releases/download/v1.0.1/shim.exe"],
        downloaded_file_path = "shim.exe",
        executable = True,
    )
