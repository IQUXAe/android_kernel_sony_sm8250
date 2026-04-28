#!/usr/bin/env bash

set -euo pipefail

DEVICE="${1:?usage: package-anykernel.sh <pdx203|pdx206>}"

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
ARTIFACT_DIR="${ROOT_DIR}/artifacts"
PACKAGE_DIR="${ROOT_DIR}/out/anykernel-${DEVICE}"
ANYKERNEL_REPO="${ANYKERNEL_REPO:-https://github.com/osm0sis/AnyKernel3}"
ANYKERNEL_BRANCH="${ANYKERNEL_BRANCH:-master}"
ZIP_NAME="AnyKernel3-${DEVICE}-$(git -C "${ROOT_DIR}" rev-parse --short HEAD).zip"

if [[ ! -f "${BUILD_DIR}/Image" ]]; then
  echo "Missing built kernel Image in ${BUILD_DIR}" >&2
  exit 1
fi

rm -rf "${PACKAGE_DIR}" "${ARTIFACT_DIR}"
mkdir -p "${ARTIFACT_DIR}"

git clone --depth 1 --branch "${ANYKERNEL_BRANCH}" "${ANYKERNEL_REPO}" "${PACKAGE_DIR}"
rm -rf "${PACKAGE_DIR}/.git" "${PACKAGE_DIR}/.github" "${PACKAGE_DIR}/patch" "${PACKAGE_DIR}/ramdisk" "${PACKAGE_DIR}/modules"
rm -f "${PACKAGE_DIR}/README.md"

cp "${BUILD_DIR}/Image" "${PACKAGE_DIR}/Image"

cat > "${PACKAGE_DIR}/anykernel.sh" <<EOF
## AnyKernel3 Ramdisk Mod Script
## IQUXAe PDX kernel package

properties() { '
kernel.string=IQUXAe ${DEVICE} kernel
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=${DEVICE}
device.name2=${DEVICE}-generic
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; }

BLOCK=boot;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

. tools/ak3-core.sh;

split_boot;
flash_boot;
EOF

(
  cd "${PACKAGE_DIR}"
  zip -r9 "${ARTIFACT_DIR}/${ZIP_NAME}" ./* -x '*.git*' '*placeholder'
)

sha256sum "${ARTIFACT_DIR}/${ZIP_NAME}" > "${ARTIFACT_DIR}/${ZIP_NAME}.sha256"
