def _copy_file(repository_ctx, *, source, destination, executable):
    """Create a file copy of the source at the destination.

    Args:
      repository_ctx: The repository rule context.
      source: string; Label; or path, The file to copy.
      destination: string; Label; or path, The copy to create, relative to the repository directory.
      executable: bool, Whether the copy should be executable.
    """

    # Note, Bazel provides no "copy file" primitive in repository rules. This
    # reads the source file and writes a new file as a workaround.
    # See https://github.com/bazelbuild/bazel/issues/11858
    repository_ctx.file(
        destination,
        repository_ctx.read(source),
        executable = executable,
        legacy_utf8 = False,
    )

def create_shim(repository_ctx, *, name, target, shim_exe = Label("@rules_sh_shim_exe//file:shim.exe")):
    """Create a binary shim for the given target.

    Creates a copy of the [shim binary][shim-binary] named `<name>.exe` with a
    neighboring `<name>.shim` file that points to the given target.

    [shim-binary]: https://github.com/ScoopInstaller/Shim

    #### Example

    This can be used inside a repository rule run on Windows to generate a shim
    of an external executable and import it into an `sh_binaries` target.

    ```bzl
    powershell = repository_ctx.which("powershell")
    if powershell != None:
        create_shim(
            repository_ctx,
            name = "powershell",
            target = powershell,
        )

    repository_ctx.file(
        "BUILD.bazel",
        "\\n".join([
            "sh_binaries(",
            "    name = 'tools',",
            "    srcs = ['powershell.exe'],",
            "    data = ['powershell.shim'],",
            ")",
        ]),
    )
    ```

    Args:
      name: string or path, The name of the newly created shim, without the .exe suffix, relative to the repository directory.
      target: string or path, Absolute path to the target executable.
      shim_exe: string; Label; or path, The original shim binary.
    """
    _copy_file(
        repository_ctx,
        source = shim_exe,
        destination = "{}.exe".format(name),
        executable = True,
    )
    repository_ctx.file(
        "{}.shim".format(name),
        "path = {}".format(repository_ctx.path(target)),
        executable = False,
    )
