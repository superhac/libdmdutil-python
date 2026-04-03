#!/usr/bin/env bash
set -euo pipefail

LIBDMDUTIL_SRC="${1:-${LIBDMDUTIL_SRC:-libdmdutil}}"
LIBDMDUTIL_BUILD="${2:-${LIBDMDUTIL_BUILD:-${LIBDMDUTIL_SRC}/build}}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"

detect_platform() {
  case "$(uname -s)" in
    Linux) echo "linux" ;;
    Darwin) echo "macos" ;;
    MINGW*|MSYS*|CYGWIN*) echo "win" ;;
    *)
      echo "ERROR: Unsupported OS: $(uname -s)" >&2
      exit 1
      ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "x64" ;;
    aarch64|arm64)
      if [[ "$(detect_platform)" == "linux" ]]; then
        echo "aarch64"
      else
        echo "arm64"
      fi
      ;;
    *)
      echo "ERROR: Unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
}

PLATFORM="${PLATFORM:-$(detect_platform)}"
ARCH="${ARCH:-$(detect_arch)}"
EXTERNAL_SCRIPT="${LIBDMDUTIL_SRC}/platforms/${PLATFORM}/${ARCH}/external.sh"

if [[ ! -d "${LIBDMDUTIL_SRC}" ]]; then
  echo "ERROR: Cannot find libdmdutil source dir: ${LIBDMDUTIL_SRC}" >&2
  echo "Run ./fetch_libdmdutil.sh first or pass the source path as the first argument." >&2
  exit 1
fi

echo "=== Building libdmdutil ==="
echo "  source   : ${LIBDMDUTIL_SRC}"
echo "  build    : ${LIBDMDUTIL_BUILD}"
echo "  platform : ${PLATFORM}"
echo "  arch     : ${ARCH}"

if [[ -f "${EXTERNAL_SCRIPT}" ]]; then
  (
    cd "${LIBDMDUTIL_SRC}"
    bash "platforms/${PLATFORM}/${ARCH}/external.sh"
  )
fi

cmake_args=(
  -DPLATFORM="${PLATFORM}"
  -DARCH="${ARCH}"
  -DBUILD_SHARED=ON
  -DBUILD_STATIC=OFF
  -DENABLE_VNI=ON
  -DCMAKE_BUILD_TYPE=Release
  -B "${LIBDMDUTIL_BUILD}"
)

cmake "${cmake_args[@]}" "${LIBDMDUTIL_SRC}"

if [[ "${PLATFORM}" == "win" ]]; then
  cmake --build "${LIBDMDUTIL_BUILD}" --config Release
else
  cmake --build "${LIBDMDUTIL_BUILD}" --config Release -j "${JOBS}"
fi

echo "=== libdmdutil build complete ==="
