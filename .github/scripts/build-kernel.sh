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
ARTIFACT_DIR="${ROOT_DIR}/artifacts/${DEVICE}"
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

rm -rf "${OUT_DIR}" "${ARTIFACT_DIR}"
mkdir -p "${OUT_DIR}" "${ARTIFACT_DIR}"

make O="${OUT_DIR}" KBUILD_DIFFCONFIG="${DIFFCONFIG}" vendor/kona-perf_defconfig

if ! grep -q "^CONFIG_MACH_SONY_${DEVICE^^}=y$" "${OUT_DIR}/.config"; then
  echo "Expected CONFIG_MACH_SONY_${DEVICE^^}=y in ${OUT_DIR}/.config" >&2
  exit 1
fi

make -j"${JOBS}" O="${OUT_DIR}" Image modules dtbs

cp "${OUT_DIR}/.config" "${ARTIFACT_DIR}/"
cp "${OUT_DIR}/arch/arm64/boot/Image" "${ARTIFACT_DIR}/Image"

for base_dtb in kona.dtb kona-v2.dtb kona-v2.1.dtb; do
  cp "${OUT_DIR}/arch/arm64/boot/dts/vendor/qcom/${base_dtb}" "${ARTIFACT_DIR}/"
done

cp "${OUT_DIR}/arch/arm64/boot/dts/vendor/somc/kona-edo-${DEVICE}_generic-overlay.dtbo" "${ARTIFACT_DIR}/"

if compgen -G "${OUT_DIR}/lib/modules/*/modules.order" > /dev/null; then
  MODULES_STAGING="${OUT_DIR}/modules-staging"
  rm -rf "${MODULES_STAGING}"
  make O="${OUT_DIR}" INSTALL_MOD_PATH="${MODULES_STAGING}" modules_install
  tar -C "${MODULES_STAGING}" -caf "${ARTIFACT_DIR}/modules.tar.zst" .
fi

(cd "${ARTIFACT_DIR}" && sha256sum ./* > sha256sums.txt)
