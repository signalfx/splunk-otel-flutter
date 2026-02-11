# Contributing Guidelines

Thank you for your interest in contributing to our repository! Whether it's a bug
report, new feature, question, or additional documentation, we greatly value
feedback and contributions from our community. Read through this document
before submitting any issues or pull requests to ensure we have all the
necessary information to effectively respond to your bug report or
contribution.

In addition to this document, please review our [Code of
Conduct](CODE_OF_CONDUCT.md). For any code of conduct questions or comments
please email oss@splunk.com.


## Getting started

## Opentelemetry

TBD during development

## Reporting Security Issues

See [SECURITY.md](SECURITY.md#reporting-security-issues) for detailed instructions.

## Licensing

See the [LICENSE](LICENSE) file for our repository's licensing. We will ask you to
confirm the licensing of your contribution.

All contributors must execute the [Splunk Contributor License Agreement
(CLA) form](https://www.splunk.com/en_us/form/contributions.html).


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


