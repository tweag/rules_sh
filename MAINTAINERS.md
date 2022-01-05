# Maintenance instructions

## Cutting a new release

- Create a dedicated branch: `release-<version>` (e.g. `release-0.2.0`)
- Check the changes since the last release by
  [comparing the heads](https://github.com/tweag/rules_sh/compare/v0.2.0...HEAD),
  add anything relevant to `CHANGELOG.md`,
  and update the version heading and unreleased heading in `CHANGELOG.md`.
* Open a PR for the new release, like
  [#10](https://github.com/tweag/rules_sh/pull/14)
* When merged, create a tag of the form `v0.2.0` on the merge commit and push it:
  `git push origin v0.2.0`
* Create the release on GitHub, selecting the tag created above.
* Add the relevant changelog section to the release notes.
* Obtain the sha256 for the release archive, by downloading the blob,
  and calling `sha256sum` on it.
* Update the release notes with a workspace setup section for the new version,
  such as [this example](https://github.com/tweag/rules_sh/releases/tag/v0.2.0)
* Add the new version to the Bazel Central Registry as described below

## Add a new version to the Bazel Central Registry

* Follow the instructions given in the [README][bcr-add] to add a new version
  of this module. Use the following input file to `add_module.py` for
  reference - don't forget to update the version and dependencies:
  ```
  {
      "build_file": null,
      "build_targets": [],
      "compatibility_level": "0",
      "deps": [["bazel_skylib", "1.0.3"], ["platforms", "0.0.4"]],
      "module_dot_bazel": "path/to/rules_sh/MODULE.bazel",
      "name": "rules_sh",
      "patch_strip": 1,
      "patches": [],
      "presubmit_yml": "path/to/rules_sh/.bazelci/presubmit.yml",
      "strip_prefix": "rules_sh-0.2.0",
      "test_targets": [],
      "url": "https://github.com/tweag/rules_sh/archive/refs/tags/v0.2.0.tar.gz",
      "version": "0.2.0"
  }
  ```

[bcr-add]: https://github.com/bazelbuild/bazel-central-registry#module-contributor
