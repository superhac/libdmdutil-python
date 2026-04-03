#!/usr/bin/env bash
set -euo pipefail

LIBDMDUTIL_SRC="${1:-${LIBDMDUTIL_SRC:-libdmdutil}}"
LIBDMDUTIL_BUILD="${2:-${LIBDMDUTIL_BUILD:-${LIBDMDUTIL_SRC}/build}}"
OUTPUT_DIR="${3:-${OUTPUT_DIR:-.}}"

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

PLATFORM="${PLATFORM:-$(detect_platform)}"

mkdir -p "${OUTPUT_DIR}"

echo "=== Building libdmdutil-python bridge ==="
echo "  libdmdutil source : ${LIBDMDUTIL_SRC}"
echo "  libdmdutil build  : ${LIBDMDUTIL_BUILD}"
echo "  output dir        : ${OUTPUT_DIR}"
echo "  platform          : ${PLATFORM}"

if [[ ! -d "${LIBDMDUTIL_SRC}/include" ]]; then
  echo "ERROR: Cannot find libdmdutil include dir: ${LIBDMDUTIL_SRC}/include" >&2
  exit 1
fi

case "${PLATFORM}" in
  linux)
    "${CXX:-g++}" -shared -fPIC -std=c++20 \
      -o "${OUTPUT_DIR}/libdmdutil_python_bridge.so" \
      native/dmdutil_bridge.cpp \
      -I"${LIBDMDUTIL_SRC}/include" \
      -L"${LIBDMDUTIL_BUILD}" \
      -ldmdutil \
      -Wl,-rpath,'$ORIGIN'
    ;;
  macos)
    "${CXX:-clang++}" -shared -fPIC -std=c++20 \
      -o "${OUTPUT_DIR}/libdmdutil_python_bridge.dylib" \
      native/dmdutil_bridge.cpp \
      -I"${LIBDMDUTIL_SRC}/include" \
      -L"${LIBDMDUTIL_BUILD}" \
      -ldmdutil \
      -install_name "@rpath/libdmdutil_python_bridge.dylib" \
      -Wl,-rpath,@loader_path
    ;;
  win)
    cl.exe /LD /std:c++20 /EHsc /O2 \
      /Fe:"${OUTPUT_DIR}/libdmdutil_python_bridge.dll" \
      native\\dmdutil_bridge.cpp \
      /I "${LIBDMDUTIL_SRC}\\include" \
      "${LIBDMDUTIL_BUILD}\\Release\\dmdutil.lib"
    ;;
esac

echo "=== Bridge build complete ==="
