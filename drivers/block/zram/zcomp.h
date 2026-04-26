/*
 * Copyright (C) 2014 Sergey Senozhatsky.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version
 * 2 of the License, or (at your option) any later version.
 */

#ifndef _ZCOMP_H_
#define _ZCOMP_H_

#include <linux/compiler.h>
#include <linux/crypto.h>
#include <linux/percpu.h>

struct zcomp_strm {
	/* compression/decompression buffer */
	void *buffer;
	struct crypto_comp *tfm;
};

/* dynamic per-device compression frontend */
struct zcomp {
	struct zcomp_strm * __percpu *stream;
	const char *name;
	struct hlist_node node;
};

int zcomp_cpu_up_prepare(unsigned int cpu, struct hlist_node *node);
int zcomp_cpu_dead(unsigned int cpu, struct hlist_node *node);
ssize_t zcomp_available_show(const char *comp, char *buf);
bool zcomp_available_algorithm(const char *comp);

struct zcomp *zcomp_create(const char *comp);
void zcomp_destroy(struct zcomp *comp);

static __always_inline struct zcomp_strm *zcomp_stream_get(struct zcomp *comp)
{
	return *get_cpu_ptr(comp->stream);
}

static __always_inline void zcomp_stream_put(struct zcomp *comp)
{
	put_cpu_ptr(comp->stream);
}

static __always_inline int zcomp_compress(struct zcomp_strm *zstrm,
		const void *src, unsigned int *dst_len)
{
	/*
	 * Our dst memory (zstrm->buffer) is always `2 * PAGE_SIZE' sized
	 * because sometimes we can endup having a bigger compressed data
	 * due to various reasons: for example compression algorithms tend
	 * to add some padding to the compressed buffer. Speaking of padding,
	 * comp algorithm `842' pads the compressed length to multiple of 8
	 * and returns -ENOSP when the dst memory is not big enough, which
	 * is not something that ZRAM wants to see. We can handle the
	 * `compressed_size > PAGE_SIZE' case easily in ZRAM, but when we
	 * receive -ERRNO from the compressing backend we can't help it
	 * anymore. To make `842' happy we need to tell the exact size of
	 * the dst buffer, zram_drv will take care of the fact that
	 * compressed buffer is too big.
	 */
	*dst_len = PAGE_SIZE * 2;

	return crypto_comp_compress(zstrm->tfm,
			src, PAGE_SIZE,
			zstrm->buffer, dst_len);
}

static __always_inline int zcomp_decompress(struct zcomp_strm *zstrm,
		const void *src, unsigned int src_len, void *dst)
{
	unsigned int dst_len = PAGE_SIZE;

	return crypto_comp_decompress(zstrm->tfm,
			src, src_len,
			dst, &dst_len);
}

bool zcomp_set_max_streams(struct zcomp *comp, int num_strm);
#endif /* _ZCOMP_H_ */
