#!/usr/bin/env bash
#
# Copyright 2026 Splunk Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

: "${SAUCE_USERNAME:?Set SAUCE_USERNAME before running this script.}"
: "${SAUCE_ACCESS_KEY:?Set SAUCE_ACCESS_KEY before running this script.}"
: "${SAUCE_APP:?Set SAUCE_APP to the Sauce storage app reference.}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is required to run the Appium crash-flow test."
  exit 1
fi

node "$script_dir/appium_crash_android.js"
