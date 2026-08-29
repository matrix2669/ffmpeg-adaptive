#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$repo_dir"

scripts=(
    ffmpeg-smart.sh
    benchmark-accel.sh
    benchmark-live.sh
    scripts/validate.sh
    lib/*.sh
    tests/*.sh
)

for script in "${scripts[@]}"; do
    bash -n "$script"
done

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck --severity=error "${scripts[@]}"
fi

test_cases=(
    test-state-dir.sh
    test-additional-ffmpeg-options.sh
    test-map-all-codecs.sh
    test-benchmark-lock-owner.sh
    test-adaptive-probing.sh
    test-policy-matrix.sh
    test-hardware-command.sh
    test-pipe-replay.sh
    test-cli-contract.sh
)
for test_case in "${test_cases[@]}"; do
    "tests/$test_case"
done

project_version="$(awk 'NF { gsub(/[[:space:]]/, ""); print; exit }' VERSION)"
if ! printf '%s\n' "$project_version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-beta\.[1-9][0-9]*)?$'; then
    printf 'Invalid semantic version in VERSION: %s\n' "$project_version" >&2
    exit 1
fi

for versioned_script in ffmpeg-smart.sh benchmark-accel.sh; do
    script_version="$(awk -F'"' '$1 == "VERSION=" { print $2; exit }' "$versioned_script")"
    if test "$script_version" != "$project_version"; then
        printf 'VERSION mismatch: root=%s %s=%s\n' "$project_version" "$versioned_script" "$script_version" >&2
        exit 1
    fi
done

if ! grep -qF -- "## [$project_version]" CHANGELOG.md; then
    printf 'CHANGELOG.md has no section for %s\n' "$project_version" >&2
    exit 1
fi

printf 'Validated ffmpeg-adaptive %s\n' "$project_version"
