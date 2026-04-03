#!/usr/bin/env bash
set -euo pipefail

LIBDMDUTIL_SRC="${1:-${LIBDMDUTIL_SRC:-libdmdutil}}"
LIBDMDUTIL_BUILD="${2:-${LIBDMDUTIL_BUILD:-${LIBDMDUTIL_SRC}/build}}"
OUTPUT_DIR="${3:-${OUTPUT_DIR:-libdmdutil-python}}"

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
RUNTIME_DIR="${LIBDMDUTIL_SRC}/third-party/runtime-libs/${PLATFORM}/${ARCH}"

mkdir -p "${OUTPUT_DIR}"

cp libdmdutil_wrapper.py "${OUTPUT_DIR}/"
cp dmdutil_backend.py "${OUTPUT_DIR}/"
cp media.py "${OUTPUT_DIR}/"
cp test.py "${OUTPUT_DIR}/"

case "${PLATFORM}" in
  linux)
    cp libdmdutil_python_bridge.so "${OUTPUT_DIR}/"
    cp -a "${LIBDMDUTIL_BUILD}"/libdmdutil.so* "${OUTPUT_DIR}/" 2>/dev/null || true
    cp -a "${LIBDMDUTIL_BUILD}"/libzedmd.so* "${OUTPUT_DIR}/" 2>/dev/null || true
    cp -a "${LIBDMDUTIL_BUILD}"/libserialport.so* "${OUTPUT_DIR}/" 2>/dev/null || true
    cp -a "${LIBDMDUTIL_BUILD}"/libusb-1.0.so* "${OUTPUT_DIR}/" 2>/dev/null || true
    cp -a "${LIBDMDUTIL_BUILD}"/libsockpp.so* "${OUTPUT_DIR}/" 2>/dev/null || true
    cp -a "${LIBDMDUTIL_BUILD}"/libserum.so* "${OUTPUT_DIR}/" 2>/dev/null || true
    cp -a "${LIBDMDUTIL_BUILD}"/libpupdmd.so* "${OUTPUT_DIR}/" 2>/dev/null || true
    cp -a "${LIBDMDUTIL_BUILD}"/libvni.so* "${OUTPUT_DIR}/" 2>/dev/null || true
    cp -a "${LIBDMDUTIL_BUILD}"/libcargs.so* "${OUTPUT_DIR}/" 2>/dev/null || true
    cp -a "${RUNTIME_DIR}"/* "${OUTPUT_DIR}/" 2>/dev/null || true
    ;;
  macos)
    cp libdmdutil_python_bridge.dylib "${OUTPUT_DIR}/"
    cp -a "${LIBDMDUTIL_BUILD}"/libdmdutil*.dylib "${OUTPUT_DIR}/" 2>/dev/null || true
    cp -a "${LIBDMDUTIL_BUILD}"/libzedmd*.dylib "${OUTPUT_DIR}/" 2>/dev/null || true
    cp -a "${LIBDMDUTIL_BUILD}"/libserialport*.dylib "${OUTPUT_DIR}/" 2>/dev/null || true
    cp -a "${LIBDMDUTIL_BUILD}"/libusb-1.0*.dylib "${OUTPUT_DIR}/" 2>/dev/null || true
    cp -a "${LIBDMDUTIL_BUILD}"/libsockpp*.dylib "${OUTPUT_DIR}/" 2>/dev/null || true
    cp -a "${RUNTIME_DIR}"/* "${OUTPUT_DIR}/" 2>/dev/null || true
    ;;
  win)
    cp libdmdutil_python_bridge.dll "${OUTPUT_DIR}/"
    cp -a "${LIBDMDUTIL_BUILD}/Release/"*.dll "${OUTPUT_DIR}/" 2>/dev/null || true
    cp -a "${RUNTIME_DIR}"/*.dll "${OUTPUT_DIR}/" 2>/dev/null || true
    ;;
esac

echo "=== Runtime bundle staged at ${OUTPUT_DIR} ==="
