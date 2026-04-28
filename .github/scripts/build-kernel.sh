#!/usr/bin/env bash

set -euo pipefail

DEVICE="${1:?usage: build-kernel.sh <pdx203|pdx206>}"

case "${DEVICE}" in
  pdx203|pdx206)
    ;;
  *)
    echo "Unsupported device: ${DEVICE}" >&2
    exit 1
    ;;
esac

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/out/${DEVICE}"
BUILD_DIR="${ROOT_DIR}/build/${DEVICE}"
CLANG_DIR="${CLANG_DIR:?CLANG_DIR is not set}"
JOBS="${JOBS:-$(nproc)}"
DIFFCONFIG="${DEVICE}_diffconfig"
CLANG_BIN_DIR="${CLANG_DIR}/bin"

if [[ ! -x "${CLANG_BIN_DIR}/clang" ]]; then
  echo "clang not found in ${CLANG_BIN_DIR}" >&2
  exit 1
fi

if [[ ! -x "${CLANG_BIN_DIR}/ld.lld" ]]; then
  echo "ld.lld not found in ${CLANG_BIN_DIR}" >&2
  exit 1
fi

export PATH="${CLANG_BIN_DIR}:${PATH}"
export ARCH=arm64
export SUBARCH=arm64
export LLVM=1
export LLVM_IAS=1
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export LD=ld.lld
export AR=llvm-ar
export NM=llvm-nm
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export READELF=llvm-readelf
export STRIP=llvm-strip

clang --version
ld.lld --version

rm -rf "${OUT_DIR}" "${BUILD_DIR}"
mkdir -p "${OUT_DIR}" "${BUILD_DIR}"

make O="${OUT_DIR}" KBUILD_DIFFCONFIG="${DIFFCONFIG}" vendor/kona-perf_defconfig

if ! grep -q "^CONFIG_MACH_SONY_${DEVICE^^}=y$" "${OUT_DIR}/.config"; then
  echo "Expected CONFIG_MACH_SONY_${DEVICE^^}=y in ${OUT_DIR}/.config" >&2
  exit 1
fi

make -j"${JOBS}" O="${OUT_DIR}" Image dtbs

cp "${OUT_DIR}/.config" "${BUILD_DIR}/"
cp "${OUT_DIR}/arch/arm64/boot/Image" "${BUILD_DIR}/Image"
cp "${OUT_DIR}/arch/arm64/boot/dts/vendor/somc/kona-edo-${DEVICE}_generic-overlay.dtbo" "${BUILD_DIR}/"
