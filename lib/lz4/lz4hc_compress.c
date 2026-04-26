/*
 * LZ4HC 1.10.0 kernel wrapper
 *
 * Imports upstream freestanding HC core and preserves the kernel-facing API
 * which uses caller-provided work memory instead of dynamic allocation.
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/string.h>
#include <asm/unaligned.h>

#define LZ4_FREESTANDING 1
#define LZ4_MEMORY_USAGE 10
#define LZ4_memcpy(dst, src, size) __builtin_memcpy(dst, src, size)
#define LZ4_memmove(dst, src, size) __builtin_memmove(dst, src, size)
#define LZ4_memset(dst, value, size) memset(dst, value, size)
#define LZ4_HEAPMODE 0
#define LZ4HC_HEAPMODE 0
#define LZ4_STATIC_LINKING_ONLY
#define LZ4_HC_STATIC_LINKING_ONLY
#define LZ4_STATIC_LINKING_ONLY_DISABLE_MEMORY_ALLOCATION 1
#define LZ4_DISABLE_DEPRECATE_WARNINGS

#ifdef current
#undef current
#endif

#define LZ4_compress_HC lz4_upstream_compress_HC

#include "lz4hc.c"

#undef LZ4_compress_HC

int LZ4_compress_HC(const char *src, char *dst, int srcSize, int dstCapacity,
	int compressionLevel, void *wrkmem)
{
	return LZ4_compress_HC_extStateHC(wrkmem, src, dst, srcSize,
		dstCapacity, compressionLevel);
}
EXPORT_SYMBOL(LZ4_compress_HC);

EXPORT_SYMBOL(LZ4_loadDictHC);
EXPORT_SYMBOL(LZ4_compress_HC_continue);
EXPORT_SYMBOL(LZ4_saveDictHC);
