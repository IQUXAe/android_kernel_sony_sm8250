#!/usr/bin/env bash

set -euo pipefail

DEVICE="${1:?usage: patch-kernelpatch.sh <pdx203|pdx206>}"

case "${DEVICE}" in
  pdx203|pdx206)
    ;;
  *)
    echo "Unsupported device: ${DEVICE}" >&2
    exit 1
    ;;
esac

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build/${DEVICE}"
CONFIG_PATH="${BUILD_DIR}/.config"
INPUT_IMAGE="${BUILD_DIR}/Image"
OUTPUT_IMAGE="${BUILD_DIR}/Image-kpatch"
KPTOOLS_BIN="${KPTOOLS_BIN:?KPTOOLS_BIN is not set}"
KPIMG_PATH="${KPIMG_PATH:?KPIMG_PATH is not set}"
KPATCH_SUPERKEY="${KPATCH_SUPERKEY:?KPATCH_SUPERKEY is not set}"

if [[ ! -f "${INPUT_IMAGE}" ]]; then
  echo "Missing built kernel Image in ${BUILD_DIR}" >&2
  exit 1
fi

if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "Missing build config in ${BUILD_DIR}" >&2
  exit 1
fi

if ! grep -q '^CONFIG_KALLSYMS=y$' "${CONFIG_PATH}"; then
  echo "KernelPatch requires CONFIG_KALLSYMS=y" >&2
  exit 1
fi

if [[ ! -x "${KPTOOLS_BIN}" ]]; then
  echo "kptools binary not executable: ${KPTOOLS_BIN}" >&2
  exit 1
fi

if [[ ! -f "${KPIMG_PATH}" ]]; then
  echo "kpimg image not found: ${KPIMG_PATH}" >&2
  exit 1
fi

rm -f "${OUTPUT_IMAGE}"
"${KPTOOLS_BIN}" --version
"${KPTOOLS_BIN}" -p --image "${INPUT_IMAGE}" --skey "${KPATCH_SUPERKEY}" --kpimg "${KPIMG_PATH}" --out "${OUTPUT_IMAGE}"

if [[ ! -f "${OUTPUT_IMAGE}" ]]; then
  echo "KernelPatch did not produce ${OUTPUT_IMAGE}" >&2
  exit 1
fi
