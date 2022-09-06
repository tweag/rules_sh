load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

def rules_sh_dependencies():
    """## Setup

    See the **WORKSPACE setup** section of the [current release][releases].

    [releases]: https://github.com/tweag/rules_sh/releases

    Or use the following template in your `WORKSPACE` file to install a development
    version of `rules_sh`:

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
    """
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "74d544d96f4a5bb630d465ca8bbcfe231e3594e5aae57e1edbf17a6eb3ca2506",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
        ],
    )
    maybe(
        http_archive,
        name = "platforms",
        sha256 = "5308fc1d8865406a49427ba24a9ab53087f17f5266a7aabbfc28823f3916e1ca",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/platforms/releases/download/0.0.6/platforms-0.0.6.tar.gz",
            "https://github.com/bazelbuild/platforms/releases/download/0.0.6/platforms-0.0.6.tar.gz",
        ],
    )
    maybe(
        http_file,
        name = "rules_sh_shim_exe",
        sha256 = "cb440b8a08a2095a59666a859b35aa5a1524b140b909ecc760f38f3baccf80e6",
        urls = ["https://github.com/ScoopInstaller/Shim/releases/download/v1.0.1/shim.exe"],
        downloaded_file_path = "shim.exe",
        executable = True,
    )
