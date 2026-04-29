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
CLANG_BIN_DIR="${CLANG_DIR}/bin"
BASE_DEFCONFIG="vendor/kona-perf_defconfig"
CONFIG_FRAGMENTS=(
  "vendor/edo.config"
  "vendor/${DEVICE}.config"
)

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
export KCONFIG_CONFIG="${OUT_DIR}/.config"

clang --version
ld.lld --version

rm -rf "${OUT_DIR}" "${BUILD_DIR}"
mkdir -p "${OUT_DIR}" "${BUILD_DIR}"

CONFIG_PATHS=("${ROOT_DIR}/arch/arm64/configs/${BASE_DEFCONFIG}")
for fragment in "${CONFIG_FRAGMENTS[@]}"; do
  CONFIG_PATHS+=("${ROOT_DIR}/arch/arm64/configs/${fragment}")
done

COMMON_MAKE_ARGS=(
  -C "${ROOT_DIR}"
  O="${OUT_DIR}"
  ARCH=arm64
  LLVM=1
  LLVM_IAS=1
  CC=clang
  CLANG_TRIPLE=aarch64-linux-gnu-
  LD=ld.lld
  AR=llvm-ar
  NM=llvm-nm
  OBJCOPY=llvm-objcopy
  OBJDUMP=llvm-objdump
  READELF=llvm-readelf
  STRIP=llvm-strip
)

make "${COMMON_MAKE_ARGS[@]}" "${BASE_DEFCONFIG}"
"${ROOT_DIR}/scripts/kconfig/merge_config.sh" -m -O "${OUT_DIR}" "${CONFIG_PATHS[@]}"
make "${COMMON_MAKE_ARGS[@]}" olddefconfig

if ! grep -q "^CONFIG_MACH_SONY_${DEVICE^^}=y$" "${OUT_DIR}/.config"; then
  echo "Expected CONFIG_MACH_SONY_${DEVICE^^}=y in ${OUT_DIR}/.config" >&2
  exit 1
fi

make -j"${JOBS}" "${COMMON_MAKE_ARGS[@]}" Image.gz dtbs modules

cp "${OUT_DIR}/.config" "${BUILD_DIR}/"
cp "${OUT_DIR}/arch/arm64/boot/Image" "${BUILD_DIR}/Image"
cp "${OUT_DIR}/arch/arm64/boot/Image.gz" "${BUILD_DIR}/Image.gz"
cp "${OUT_DIR}/arch/arm64/boot/dts/vendor/somc/kona-edo-${DEVICE}_generic-overlay.dtbo" "${BUILD_DIR}/"
