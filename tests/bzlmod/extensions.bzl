load("//import:import_test.bzl", "import_test_repositories")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

def _tests_configure_impl(ctx):
    import_test_repositories()

tests_configure = module_extension(implementation = _tests_configure_impl)
