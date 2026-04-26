ccflags-y += -O3

ifneq ($(filter y,$(CONFIG_LZ4_COMPRESS) $(CONFIG_LZ4_DECOMPRESS)),)
obj-y += lz4_compress.o
else ifneq ($(filter m,$(CONFIG_LZ4_COMPRESS) $(CONFIG_LZ4_DECOMPRESS)),)
obj-m += lz4_compress.o
endif

obj-$(CONFIG_LZ4HC_COMPRESS) += lz4hc_compress.o
