load("//sh:posix.bzl", "sh_posix_configure")


def _sh_configure_impl(ctx):
    sh_posix_configure(register = False)

sh_configure = module_extension(implementation = _sh_configure_impl)
