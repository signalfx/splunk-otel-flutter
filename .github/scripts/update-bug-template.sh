#!/usr/bin/env bash
#
# Sync the version dropdowns in .github/ISSUE_TEMPLATE/bug.yml with the
# stable release headings in the user-facing packages' CHANGELOGs.
#
# Stable-only filter: only `X.Y.Z` headings are included. Pre-releases
# (e.g. `X.Y.Z-dev.N`, `X.Y.Z-alpha.N`) fall through to the `Other` option.
#
set -euo pipefail

TEMPLATE=".github/ISSUE_TEMPLATE/bug.yml"
OTHER='Other (please specify in "Additional Context")'

# One entry per dropdown to keep in sync.
# Format: <changelog_path>|<dropdown_id>|<optional_first_option>
# The optional first option is prepended to the dropdown (e.g. a
# "Not using <package>" sentinel).
TARGETS=(
  "packages/splunk_otel_flutter/splunk_otel_flutter/CHANGELOG.md|main-sdk-version|"
  "packages/splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay/CHANGELOG.md|session-replay-version|Not using session replay"
)

if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: $TEMPLATE not found" >&2
  exit 1
fi

collect_versions() {
  local changelog=$1
  awk '/^##[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+[[:space:]]*$/ { print $2 }' "$changelog" \
    | awk '!seen[$0]++'
}

# Rewrite the `options:` block under the dropdown identified by $2 in the
# template file $1, replacing its contents with the multi-line string $3.
# The replacement is passed through the environment because BSD awk
# (default on macOS) rejects embedded newlines in `-v` assignments, while
# both BSD awk and gawk read `ENVIRON[...]` reliably.
update_dropdown() {
  local template=$1 dropdown_id=$2 replacement=$3

  local tmp="${template}.new"
  REPLACEMENT="$replacement" DROPDOWN_ID="$dropdown_id" awk '
    $0 ~ "^    id: " ENVIRON["DROPDOWN_ID"] "[[:space:]]*$" { in_dropdown = 1 }
    in_dropdown && /^      options:[[:space:]]*$/ {
      print
      printf "%s", ENVIRON["REPLACEMENT"]
      skipping = 1
      next
    }
    skipping {
      if (/^[[:space:]]{8}- / || /^[[:space:]]*$/) { next }
      skipping = 0
      in_dropdown = 0
    }
    { print }
  ' "$template" > "$tmp"

  # Hard guard: if the dropdown id is missing from the rewritten file, the
  # template structure changed unexpectedly. Fail loudly instead of
  # silently committing a broken template.
  if ! grep -qE "^    id: ${dropdown_id}[[:space:]]*$" "$tmp"; then
    echo "ERROR: dropdown id '${dropdown_id}' not found after rewrite; aborting" >&2
    rm -f "$tmp"
    exit 1
  fi

  mv "$tmp" "$template"
}

# Snapshot the template before any modifications so we can report a single
# "up to date" / "updated" message across all targets.
snapshot="${TEMPLATE}.orig"
cp "$TEMPLATE" "$snapshot"
trap 'rm -f "$snapshot" "${TEMPLATE}.new"' EXIT

for target in "${TARGETS[@]}"; do
  IFS='|' read -r changelog dropdown_id first_option <<< "$target"

  if [[ ! -f "$changelog" ]]; then
    echo "ERROR: $changelog not found" >&2
    exit 1
  fi

  # Collect stable-only versions from CHANGELOG headings, in file order
  # (newest first by convention), deduplicated, preserving order.
  # Portable alternative to `mapfile -t` (bash 4+; macOS ships bash 3.2).
  versions=()
  while IFS= read -r line; do
    versions+=("$line")
  done < <(collect_versions "$changelog")

  if [[ ${#versions[@]} -eq 0 ]]; then
    echo "ERROR: no stable versions found in $changelog" >&2
    exit 1
  fi

  # Build the replacement options block (8-space indent, matches template).
  replacement=""
  if [[ -n "$first_option" ]]; then
    replacement+="        - ${first_option}"$'\n'
  fi
  for v in "${versions[@]}"; do
    replacement+="        - ${v}"$'\n'
  done
  replacement+="        - ${OTHER}"$'\n'

  printf 'Target %-24s version(s): %s\n' "$dropdown_id" "${versions[*]}"

  update_dropdown "$TEMPLATE" "$dropdown_id" "$replacement"
done

if cmp -s "$snapshot" "$TEMPLATE"; then
  echo "$TEMPLATE already up to date"
else
  echo "Updated $TEMPLATE"
fi
