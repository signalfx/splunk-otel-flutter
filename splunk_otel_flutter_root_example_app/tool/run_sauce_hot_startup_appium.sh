#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPIUM_DIR="$APP_DIR/appium-crash"

if [[ -z "${SAUCE_USERNAME:-}" ]]; then
  echo "SAUCE_USERNAME is required."
  exit 1
fi

if [[ -z "${SAUCE_ACCESS_KEY:-}" ]]; then
  echo "SAUCE_ACCESS_KEY is required."
  exit 1
fi

if [[ -z "${SAUCE_APP:-}" && -z "${SAUCE_APP_NAME:-}" ]]; then
  echo "SAUCE_APP_NAME or SAUCE_APP is required."
  echo "Example: SAUCE_APP_NAME=smart-cinema-hot-startup.apk $0"
  exit 1
fi

cd "$APPIUM_DIR"

if [[ ! -d node_modules ]]; then
  npm install
fi

npm run test:hot-startup
