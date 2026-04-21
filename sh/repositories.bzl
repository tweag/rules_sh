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
        name = "rules_shell",
        sha256 = "20721f63908879c083f94869e618ea8d4ff5edb91ff9a72a2ebee357fdbc352d",
        strip_prefix = "rules_shell-0.8.0",
        url = "https://github.com/bazelbuild/rules_shell/releases/download/v0.8.0/rules_shell-v0.8.0.tar.gz",
    )
    maybe(
        http_archive,
        name = "rules_cc",
        sha256 = "283fa1cdaaf172337898749cf4b9b1ef5ea269da59540954e51fba0e7b8f277a",
        strip_prefix = "rules_cc-0.2.17",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_cc/releases/download/0.2.17/rules_cc-0.2.17.tar.gz",
            "https://github.com/bazelbuild/rules_cc/releases/download/0.2.17/rules_cc-0.2.17.tar.gz",
        ],
    )
    maybe(
        http_archive,
        name = "bazel_features",
        sha256 = "adfdb3cffab3a99a63363d844d559a81965d2b61a6062dd51a3d2478d416768f",
        strip_prefix = "bazel_features-1.45.0",
        urls = [
            "https://github.com/bazel-contrib/bazel_features/releases/download/v1.45.0/bazel_features-v1.45.0.tar.gz",
        ],
    )
    maybe(
        http_archive,
        name = "com_google_protobuf",
        sha256 = "877bf9f880631aa31daf2c09896276985696728137fcd43cc534a28c5566d9ba",
        strip_prefix = "protobuf-29.6",
        urls = [
            "https://github.com/protocolbuffers/protobuf/releases/download/v29.6/protobuf-29.6.tar.gz",
        ],
    )
    maybe(
        http_archive,
        name = "rules_python",
        sha256 = "098ba13578e796c00c853a2161f382647f32eb9a77099e1c88bc5299333d0d6e",
        strip_prefix = "rules_python-1.9.0",
        urls = [
            "https://github.com/bazelbuild/rules_python/releases/download/1.9.0/rules_python-1.9.0.tar.gz",
        ],
    )
    maybe(
        http_archive,
        name = "rules_java",
        sha256 = "6d8c6d5cd86fed031ee48424f238fa35f33abc9921fd97dd4ae1119a29fc807f",
        urls = [
            "https://github.com/bazelbuild/rules_java/releases/download/8.6.3/rules_java-8.6.3.tar.gz",
        ],
    )
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "3b5b49006181f5f8ff626ef8ddceaa95e9bb8ad294f7b5d7b11ea9f7ddaf8c59",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.9.0/bazel-skylib-1.9.0.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.9.0/bazel-skylib-1.9.0.tar.gz",
        ],
    )
    maybe(
        http_archive,
        name = "platforms",
        sha256 = "3384eb1c30762704fbe38e440204e114154086c8fc8a8c2e3e28441028c019a8",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/platforms/releases/download/1.0.0/platforms-1.0.0.tar.gz",
            "https://github.com/bazelbuild/platforms/releases/download/1.0.0/platforms-1.0.0.tar.gz",
        ],
    )
    maybe(
        http_archive,
        name = "rules_sh_shim_exe",
        sha256 = "c8452b3c4b8c219edef150cc423b0c844cb2d46381266011f6f076301e7e65d9",
        urls = ["https://github.com/ScoopInstaller/Shim/releases/download/v1.1.0/shim-1.1.0.zip"],
        build_file_content = """exports_files(["shim.exe"])""",
    )
