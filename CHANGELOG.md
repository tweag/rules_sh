# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

[Unreleased]: https://github.com/tweag/rules_sh/compare/v0.2.0...HEAD

## [0.2.0] - 2020-03-26

[0.2.0]: https://github.com/tweag/rules_sh/compare/v0.1.1...v0.2.0

### Added

- Define appropriate `bzl_library` rules, so that rules that
  depend `rules_sh` can generate `Stardoc` documentation.
  See PR [#11][#11] and [Skydoc's deprecation][skydoc_deprecation]
  for the motivation.

### Changed

- `sh_posix_toolchain` now has a single attribute `cmds`, which
  is a string to string `dict`; instead of having one attribute
  per member of `posix.commands`. It is a breaking change if you were
  calling `sh_posix_toolchain` directly.

  If you were calling this rule as follows:

  ```
  sh_posix_toolchain(cat = "/bin/cat", wc = "/usr/bin/wc")
  ```

  you should now do:

  ```
  sh_posix_toolchain(cmds = { "cat": "/bin/cat", "wc": "/usr/bin/wc" })
  ```

  See PR [#14][#14] and issue [#13][#13] for the motivation.

[#14]: https://github.com/tweag/rules_sh/pull/14
[#13]: https://github.com/tweag/rules_sh/issues/13
[#11]: https://github.com/tweag/rules_sh/pull/11
[skydoc_deprecation]: https://github.com/bazelbuild/stardoc/blob/master/docs/skydoc_deprecation.md#starlark-dependencies

## [0.1.1] - 2019-11-13

[0.1.1]: https://github.com/tweag/rules_sh/compare/v0.1.0...v0.1.1

### Changed

- Avoid finding non-POSIX compliant tools in `sh_posix_configure` on Windows.
  See [#7][#7].

[#7]: https://github.com/tweag/rules_sh/pull/7

## [0.1.0] - 2019-11-13

[0.1.0]: https://github.com/tweag/rules_sh/releases/tag/v0.1.0

### Added

- Initial release, see `README.md` for an overview.
  See [#1][#1] for the discussion on naming.

[#1]: https://github.com/tweag/rules_sh/issues/1
