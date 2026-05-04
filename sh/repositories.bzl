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
        sha256 = "1de5b47721fce0af0dd453b3071228fdfc44bd18199826b3f0b03b423aae9f65",
        strip_prefix = "rules_cc-0.2.18",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_cc/releases/download/0.2.18/rules_cc-0.2.18.tar.gz",
            "https://github.com/bazelbuild/rules_cc/releases/download/0.2.18/rules_cc-0.2.18.tar.gz",
        ],
    )
    maybe(
        http_archive,
        name = "bazel_features",
        sha256 = "5f7f87f50584df12bbfe5e461d358b16a8e15d245a7e596011bf39aaee5f58a9",
        strip_prefix = "bazel_features-1.47.0",
        urls = [
            "https://github.com/bazel-contrib/bazel_features/releases/download/v1.47.0/bazel_features-v1.47.0.tar.gz",
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
        sha256 = "f4f709b1e354b0089038001854400938962d60d749cd910e12d5883a084510d3",
        strip_prefix = "rules_python-2.0.0",
        urls = [
            "https://github.com/bazelbuild/rules_python/releases/download/2.0.0/rules_python-2.0.0.tar.gz",
        ],
    )
    maybe(
        http_archive,
        name = "rules_java",
        sha256 = "9de4e178c2c4f98d32aafe5194c3f2b717ae10405caa11bdcb460ac2a6f61516",
        urls = [
            "https://github.com/bazelbuild/rules_java/releases/download/9.6.1/rules_java-9.6.1.tar.gz",
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
        sha256 = "dbad4a23abcca6171e47b79edc53bd6a41067a3b75f9e8b104656b459ff25046",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/platforms/releases/download/1.1.0/platforms-1.1.0.tar.gz",
            "https://github.com/bazelbuild/platforms/releases/download/1.1.0/platforms-1.1.0.tar.gz",
        ],
    )
    maybe(
        http_archive,
        name = "rules_sh_shim_exe",
        sha256 = "c8452b3c4b8c219edef150cc423b0c844cb2d46381266011f6f076301e7e65d9",
        urls = ["https://github.com/ScoopInstaller/Shim/releases/download/v1.1.0/shim-1.1.0.zip"],
        build_file_content = """exports_files(["shim.exe"])""",
    )
