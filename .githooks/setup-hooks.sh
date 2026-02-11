#!/usr/bin/env bash
set -euo pipefail

# Point this repo to use the versioned hooks directory.
git config --local core.hooksPath .githooks

# Ensure hooks are executable (safe even if already set).
if [[ -f ".githooks/pre-commit" ]]; then
  git update-index --chmod=+x .githooks/pre-commit || true
fi
if [[ -f ".githooks/commit-msg" ]]; then
  git update-index --chmod=+x .githooks/commit-msg || true
fi

echo "Git hooks configured:"
echo "  core.hooksPath = $(git config --get core.hooksPath)"
echo "Executable bits set for available hooks."
echo "Done."