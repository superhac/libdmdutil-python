#!/usr/bin/env bash
set -euo pipefail

DEST="${1:-${LIBDMDUTIL_SRC:-libdmdutil}}"
API_URL="${LIBDMDUTIL_RELEASE_API:-https://api.github.com/repos/vpinball/libdmdutil/releases/latest}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: Missing required command: $1" >&2
    exit 1
  }
}

require_cmd curl
require_cmd tar
require_cmd mktemp

echo "=== Fetching latest libdmdutil release ==="
echo "  destination: ${DEST}"

json="$(curl -fsSL -H 'Accept: application/vnd.github+json' -H 'User-Agent: libdmdutil-python-fetch' "${API_URL}")"
tag="$(printf '%s' "${json}" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"

if [[ -z "${tag}" ]]; then
  echo "ERROR: Could not determine latest libdmdutil tag from GitHub API." >&2
  exit 1
fi

tarball_url="https://github.com/vpinball/libdmdutil/archive/refs/tags/${tag}.tar.gz"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

echo "  release tag : ${tag}"
echo "  tarball     : ${tarball_url}"

curl -fsSL -o "${tmpdir}/libdmdutil.tar.gz" "${tarball_url}"
tar -xzf "${tmpdir}/libdmdutil.tar.gz" -C "${tmpdir}"

srcdir="$(find "${tmpdir}" -mindepth 1 -maxdepth 1 -type d | head -n1)"
if [[ -z "${srcdir}" ]]; then
  echo "ERROR: Could not locate extracted libdmdutil source directory." >&2
  exit 1
fi

rm -rf "${DEST}"
mkdir -p "$(dirname "${DEST}")"
mv "${srcdir}" "${DEST}"

echo "=== libdmdutil ready at ${DEST} ==="
