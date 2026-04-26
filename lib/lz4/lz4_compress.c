/*
 * LZ4 1.10.0 kernel wrapper
 *
 * Imports upstream freestanding core and preserves the kernel-facing API
 * which uses caller-provided work memory instead of dynamic allocation.
 */

#include <linux/bitops.h>
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
#define LZ4_STATIC_LINKING_ONLY
#define LZ4_STATIC_LINKING_ONLY_DISABLE_MEMORY_ALLOCATION 1
#define LZ4_DISABLE_DEPRECATE_WARNINGS

#ifdef current
#undef current
#endif

/*
 * Keep the upstream ABI internal to this translation unit, then expose the
 * historical kernel wrappers with wrkmem arguments below.
 */
#define LZ4_compress_default lz4_upstream_compress_default
#define LZ4_compress_fast lz4_upstream_compress_fast
#define LZ4_compress_destSize lz4_upstream_compress_destSize

#include "lz4.c"

#undef LZ4_compress_default
#undef LZ4_compress_fast
#undef LZ4_compress_destSize

int LZ4_compress_fast(const char *source, char *dest, int inputSize,
	int maxOutputSize, int acceleration, void *wrkmem)
{
	return LZ4_compress_fast_extState(wrkmem, source, dest, inputSize,
		maxOutputSize, acceleration);
}
EXPORT_SYMBOL(LZ4_compress_fast);

int LZ4_compress_default(const char *source, char *dest, int inputSize,
	int maxOutputSize, void *wrkmem)
{
	return LZ4_compress_fast(source, dest, inputSize, maxOutputSize,
		LZ4_ACCELERATION_DEFAULT, wrkmem);
}
EXPORT_SYMBOL(LZ4_compress_default);

int LZ4_compress_destSize(const char *source, char *dest, int *sourceSizePtr,
	int targetDestSize, void *wrkmem)
{
	return LZ4_compress_destSize_extState(wrkmem, source, dest,
		sourceSizePtr, targetDestSize, LZ4_ACCELERATION_DEFAULT);
}
EXPORT_SYMBOL(LZ4_compress_destSize);

EXPORT_SYMBOL(LZ4_loadDict);
EXPORT_SYMBOL(LZ4_saveDict);
EXPORT_SYMBOL(LZ4_compress_fast_continue);
EXPORT_SYMBOL(LZ4_decompress_safe);
EXPORT_SYMBOL(LZ4_decompress_safe_partial);
EXPORT_SYMBOL(LZ4_decompress_fast);
EXPORT_SYMBOL(LZ4_setStreamDecode);
EXPORT_SYMBOL(LZ4_decompress_safe_continue);
EXPORT_SYMBOL(LZ4_decompress_fast_continue);
EXPORT_SYMBOL(LZ4_decompress_safe_usingDict);
EXPORT_SYMBOL(LZ4_decompress_fast_usingDict);
