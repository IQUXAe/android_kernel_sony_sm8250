#!/usr/bin/env bash

set -euo pipefail

DEVICE="${1:?usage: package-anykernel.sh <pdx203|pdx206> [kernel-image] [variant]}"

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
KERNEL_IMAGE_PATH="${2:-${BUILD_DIR}/Image.gz}"
VARIANT="${3:-stock}"
VARIANT_SUFFIX=""
KERNEL_LABEL=""
DEVICE_NAMES=""
PACKAGE_KERNEL_NAME="Image.gz"

if [[ "${VARIANT}" != "stock" ]]; then
  VARIANT_SUFFIX="-${VARIANT}"
  KERNEL_LABEL=" (${VARIANT})"
fi

case "${DEVICE}" in
  pdx203)
    DEVICE_NAMES=$(cat <<'EOF'
device.name1=pdx203
device.name2=Pdx203
device.name3=XQ-AT72
device.name4=XQ-AT52
device.name5=XQ-AT51
device.name6=XQ-AT42
device.name7=xq-at72
device.name8=xq-at52
device.name9=xq-at51
device.name10=xq-at42
EOF
)
    ;;
  pdx206)
    DEVICE_NAMES=$(cat <<'EOF'
device.name1=pdx206
device.name2=Pdx206
device.name3=XQ-AS72
device.name4=XQ-AS62
device.name5=XQ-AS52
device.name6=XQ-AS42
device.name7=xq-as72
device.name8=xq-as62
device.name9=xq-as52
device.name10=xq-as42
EOF
)
    ;;
esac

ZIP_NAME="AnyKernel3-${DEVICE}${VARIANT_SUFFIX}-$(git -C "${ROOT_DIR}" rev-parse --short HEAD).zip"

if [[ ! -f "${KERNEL_IMAGE_PATH}" ]]; then
  echo "Missing kernel Image at ${KERNEL_IMAGE_PATH}" >&2
  exit 1
fi

rm -rf "${PACKAGE_DIR}"
mkdir -p "${ARTIFACT_DIR}"

git clone --depth 1 --branch "${ANYKERNEL_BRANCH}" "${ANYKERNEL_REPO}" "${PACKAGE_DIR}"
rm -rf "${PACKAGE_DIR}/.git" "${PACKAGE_DIR}/.github" "${PACKAGE_DIR}/patch" "${PACKAGE_DIR}/ramdisk" "${PACKAGE_DIR}/modules"
rm -f "${PACKAGE_DIR}/README.md"

if [[ "${KERNEL_IMAGE_PATH##*/}" == "${PACKAGE_KERNEL_NAME}" ]]; then
  cp "${KERNEL_IMAGE_PATH}" "${PACKAGE_DIR}/${PACKAGE_KERNEL_NAME}"
else
  if ! command -v gzip >/dev/null 2>&1; then
    echo "gzip is required to package ${PACKAGE_KERNEL_NAME}" >&2
    exit 1
  fi
  gzip -c "${KERNEL_IMAGE_PATH}" > "${PACKAGE_DIR}/${PACKAGE_KERNEL_NAME}"
fi

mkdir -p "${PACKAGE_DIR}/META-INF/com/google/android"

if [[ ! -f "${PACKAGE_DIR}/META-INF/com/google/android/update-binary" ]]; then
  cat > "${PACKAGE_DIR}/META-INF/com/google/android/update-binary" <<'EOF'
#!/sbin/sh
set -eu

OUTFD="${2:-}"
ZIPFILE="${3:-}"
TMPDIR="/tmp/anykernel"

if [ -z "${OUTFD}" ] || [ -z "${ZIPFILE}" ]; then
  echo "update-binary: missing recovery arguments" >&2
  exit 1
fi

rm -rf "${TMPDIR}"
mkdir -p "${TMPDIR}"
unzip -o "${ZIPFILE}" -d "${TMPDIR}" >/dev/null

export OUTFD="/proc/self/fd/${OUTFD}"
export ZIPFILE

cd "${TMPDIR}"
chmod 755 anykernel.sh
exec /sbin/sh ./anykernel.sh "$@"
EOF
  chmod 755 "${PACKAGE_DIR}/META-INF/com/google/android/update-binary"
fi

if [[ ! -f "${PACKAGE_DIR}/META-INF/com/google/android/updater-script" ]]; then
  cat > "${PACKAGE_DIR}/META-INF/com/google/android/updater-script" <<'EOF'
ui_print("AnyKernel3 installer");
EOF
fi

cat > "${PACKAGE_DIR}/anykernel.sh" <<EOF
## AnyKernel3 Ramdisk Mod Script
## IQUXAe PDX kernel package

properties() { '
kernel.string=IQUXAe ${DEVICE} kernel${KERNEL_LABEL}
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
${DEVICE_NAMES}
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
