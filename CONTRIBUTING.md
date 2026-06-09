# Contributing Guidelines

Thank you for your interest in contributing to our repository! Whether it's a bug
report, new feature, question, or additional documentation, we greatly value
feedback and contributions from our community. Read through this document before
submitting any issues or pull requests to ensure we have all the necessary
information to effectively respond to your bug report or contribution.

In addition to this document, review our [Code of Conduct](CODE_OF_CONDUCT.md).
For any code of conduct questions or comments, send an email to <oss@splunk.com>.

## Reporting Bugs/Feature Requests

We welcome you to use the GitHub issue tracker to report bugs or suggest
features. When filing an issue, check existing open, or recently closed,
issues to make sure somebody else hasn't already reported the issue. Try
to include as much information as you can. Details like these can be useful:

- A reproducible test case or series of steps
- The version of our code being used
- Any modifications you've made relevant to the bug
- Anything unusual about your environment or deployment
- Any known workarounds

When filing an issue, do *NOT* include:

- Internal identifiers such as Jira tickets
- Any sensitive information related to your environment, users, etc.

## Reporting Security Issues

See [SECURITY.md](SECURITY.md#reporting-security-issues) for instructions.

## Setting Up Your Environment

See [SETUP.md](SETUP.md) for the full local setup: installing the Flutter
toolchain and Melos, bootstrapping the workspace (`melos bootstrap`), and
enabling the Git hooks that mirror our CI checks.

## Contributing via Pull Requests

Contributions via Pull Requests (PRs) are much appreciated. Before sending us a
pull request, make sure that:

1. You are working against the latest source on the `main` (or `develop`) branch.
2. You check existing open, and recently merged, pull requests to make sure
   someone else hasn't addressed the problem already.
3. You open an issue to discuss any significant work - we would hate for your
   time to be wasted.
4. You submit PRs that are easy to review and ideally less than 500 lines of code.
   Multiple PRs can be submitted for larger contributions.

To send us a pull request:

1. Fork the repository.
2. Modify the source; a single change per PR is recommended.
3. Ensure local tests pass and add new tests related to the contribution.
4. Commit to your fork using clear, [conventional commit](#commit-message-guidelines) messages.
5. Title your PR `DEMRUM-1234: Description` (use the `NO-TICKET:` prefix if it is not associated with an internal ticket).
6. Complete the **Generative AI usage** section of the PR template by checking exactly one box.
7. Send us a pull request, answering any default questions in the pull request
   interface.
8. Pay attention to any automated CI failures reported in the pull request, and
   stay involved in the conversation.

GitHub provides additional documentation on [forking a
repository](https://help.github.com/articles/fork-a-repo/) and [creating a pull
request](https://help.github.com/articles/creating-a-pull-request/).

### Pull Request Checks

Every PR runs the checks below (see [.github/workflows](.github/workflows)). All
must pass before a PR can be merged:

| Check | What it verifies | Run locally |
| --- | --- | --- |
| `commitlint` | Conventional commit format (see below) | commit-msg hook |
| `flutter-analyze` | Static analysis, no warnings | `melos analyze` |
| `flutter-test` | All package tests pass | `melos test` |
| `rum-sdk-version-sync` | `rumSdkFlutterVersion` matches `pubspec.yaml` version | n/a |
| `validate_pr_title` | PR title is `DEMRUM-1234: ...` or `NO-TICKET: ...` | n/a |
| `validate_gai_usage_disclosure` | PR body discloses Generative AI usage (exactly one box checked) | n/a |
| `CLA Assistant` | Signed Splunk CLA (see [Licensing](#licensing)) | n/a |

Run this before pushing to catch issues early:

```bash
melos bootstrap
melos format
melos analyze
melos test
```

The pre-commit hook (see [SETUP.md](SETUP.md)) mirrors formatting and analysis
locally.

## Commit Message Guidelines

We enforce a conventional commit message format to ensure consistency, enable automated changelog generation, and facilitate better understanding of our project history. Please adhere to the following rules when crafting your commit messages:

### Format

Commit messages must follow the format: `<type>(<scope>)?: <subject>`

*   **`type`**: This is a required field and must be one of the following:
    *   `build`: Changes that affect the build system or external dependencies (e.g., gulp, broccoli, npm).
    *   `chore`: Routine tasks that don't modify source code or tests (e.g., updating dependencies, cleaning up files).
    *   `ci`: Changes to our CI configuration files and scripts (e.g., Travis, Circle, BrowserStack, SauceLabs).
    *   `docs`: Documentation only changes.
    *   `feat`: A new feature.
    *   `fix`: A bug fix.
    *   `perf`: A code change that improves performance.
    *   `refactor`: A code change that neither fixes a bug nor adds a feature.
    *   `revert`: Reverts a previous commit.
    *   `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc.).
    *   `test`: Adding missing tests or correcting existing tests.

*   **`scope`** (optional): A parenthesized word or phrase providing additional context to the commit. For example, `feat(parser): add ability to parse arrays`.

*   **`!`** (optional): An exclamation mark immediately before the colon indicates a breaking change. For example, `feat(api)!: remove old endpoint`.

*   **`subject`**: A concise description of the change.
    *   It must start with a letter or number (can be uppercase or lowercase).
    *   Do not end the subject line with a period.

### Length Limits

*   **Header (first line)**: Must not exceed 72 characters.
*   **Body/Footer lines**: Must not exceed 100 characters.

### Body

*   If a commit body is present, there **must** be a blank line between the header and the body.
*   The body should provide more detailed contextual information about the code changes.

## Documentation

The Splunk Observability documentation is hosted on the [Splunk Observability
Cloud docs site](https://help.splunk.com/en/splunk-observability-cloud), which
contains all the prescriptive guidance for Splunk Observability products.
Prescriptive guidance consists of step-by-step instructions, conceptual material,
and decision support for customers. Reference documentation and development
documentation is still hosted on this repository.

## Finding contributions to work on

Looking at the existing issues is a great way to find something to contribute
on. As our repositories, by default, use the default GitHub issue labels
(enhancement/bug/duplicate/help wanted/invalid/question/wontfix), looking at
any 'help wanted' issues is a great place to start.

## Licensing

See the [LICENSE](LICENSE) file for our repository's licensing. We will ask you to
confirm the licensing of your contribution.

### Contributor License Agreement

Before contributing, you must sign the [Splunk Contributor License Agreement (CLA)](https://www.splunk.com/en_us/form/contributions.html).
