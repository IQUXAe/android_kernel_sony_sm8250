ifneq ($(CONFIG_ARCH_SONY_EDO),y)
ifeq ($(CONFIG_BUILD_ARM64_DT_OVERLAY),y)
        dtbo-$(CONFIG_ARCH_KONA) += \
                kona-mtp-overlay.dtbo

kona-mtp-overlay.dtbo-base := kona.dtb kona-v2.dtb kona-v2.1.dtb
else
dtb-$(CONFIG_ARCH_KONA) += kona.dtb \
        kona-mtp.dtb \
        kona-v2.dtb \
        kona-v2-mtp.dtb \
        kona-v2.1.dtb \
        kona-v2.1-mtp.dtb

endif

endif

always		:= $(dtb-y)
subdir-y	:= $(dts-dirs)
clean-files    := *.dtb *.dtbo
