# Release Tags and GitHub Releases

## Tag convention

Each SDK version has one repository tag covering all four packages:

- Stable: `vX.Y.Z`, for example `v1.3.0`.
- Preview: `vX.Y.Z-alpha.N` or `vX.Y.Z-dev.N`.

Use an annotated tag whose version matches the package manifests, changelogs,
and `rumSdkFlutterVersion` constant at the tagged commit.

## Choosing the commit

Create the tag after the release changes have been merged into `develop` and
the corresponding versions of all four packages are available on pub.dev.
Normally, the tag points to the release pull request's merge commit on `develop`.
Confirm that its package contents match the published versions.

Use the specific release commit even if `develop` has advanced. A later merge
into `main` does not require another tag or a change to the existing tag.

For historical releases, identify the source commit from release history and
compare it with the published package archives before creating a missing tag.
Do not select a commit solely because its manifest has the right version.
Only packages that existed at the time need to be checked.

## Creating and pushing a tag

Fetch the current branch and tags, then inspect the release commit:

```bash
git fetch origin develop --tags
git log origin/develop --first-parent --oneline
```

Set the version and full commit SHA explicitly. Replace the SHA placeholder
below with the verified release commit:

```bash
release_version=1.3.0
release_commit=REPLACE_WITH_VERIFIED_FULL_COMMIT_SHA
```

Confirm that the commit belongs to `develop`, then create and push only that tag:

```bash
git merge-base --is-ancestor "$release_commit" origin/develop &&
  git tag -a "v${release_version}" "$release_commit" -m "Release ${release_version}" &&
  git push origin "refs/tags/v${release_version}"
```

If the tag already exists, verify its target and reuse it. Published version tags
must not be moved, replaced, or force-pushed. Avoid `git push --tags`, which can
publish unrelated local tags.

## Adding a GitHub Release

Create one GitHub Release per version, using the existing tag:

1. Open the repository's **Releases** page and select **Draft a new release**.
2. Select the existing `vX.Y.Z` tag and use `vX.Y.Z` as the release title.
3. Summarize that version's entries from all four package changelogs at the tag.
   Include links to the published package versions. If generating notes from
   pull requests, choose the previous version tag explicitly and review the result.
4. Mark preview versions as **pre-release**. Set the newest stable version as
   **latest**.
5. Review the draft and publish it.

For missing historical Releases, reuse the existing tags and create entries
from oldest to newest. Include the original pub.dev publication date in each
description, and select the newest stable version as latest after backfilling.
Creating these records does not require another package publication or a CI job.

See GitHub's documentation for
[managing releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
and
[generating release notes](https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes).
