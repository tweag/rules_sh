# Maintenance instructions

# Cutting a new release

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
