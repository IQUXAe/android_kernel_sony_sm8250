#ifndef __KSU_H_SUS_SU
#define __KSU_H_SUS_SU

#ifdef CONFIG_KSU_SUSFS_SUS_SU
int sus_su_fifo_init(int *maj_dev_num, char *drv_path);
int sus_su_fifo_exit(int *maj_dev_num, char *drv_path);

/* Called from susfs.c to enable/disable the sus_su driver */
void ksu_susfs_enable_sus_su(void);
void ksu_susfs_disable_sus_su(void);
#endif /* CONFIG_KSU_SUSFS_SUS_SU */

#endif /* __KSU_H_SUS_SU */
