#!/usr/bin/env bash
# Picks the version of a release, from the tag so 0.2.0 becomes 0.2.0 with the Android version code 2000, or on a run by hand from the version asked for, else from the project settings.
set -euo pipefail

if [[ "${GITHUB_REF:-}" == refs/tags/* ]]; then
  version="${GITHUB_REF_NAME#v}"
elif [[ -n "${RELEASE_VERSION:-}" ]]; then
  version="${RELEASE_VERSION#v}"
else
  version=$(grep '^app.version=' gradle.properties | cut -d= -f2 | tr -d '\r')
fi
IFS=. read -r major minor patch <<< "${version%%-*}"
code=$(( ${major:-0} * 1000000 + ${minor:-0} * 1000 + ${patch:-0} ))
echo "Version $version, version code $code"
echo "name=$version" >> "$GITHUB_OUTPUT"
echo "args=-Papp.version=$version -Papp.versionCode=$code" >> "$GITHUB_OUTPUT"
