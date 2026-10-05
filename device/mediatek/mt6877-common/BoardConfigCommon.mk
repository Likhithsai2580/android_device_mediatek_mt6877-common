# BoardConfig for the mt6877 platform (common to all mt6877 devices).
#
# SCOPE: only what is true of the SoC itself. Anything specific to one phone
# (panel, board revision, RAM/flash variants, project number) belongs in that
# device's own BoardConfig, NOT here.
#
# Sourced from the realme 11 Pro 5G A13 stock device tree. Where a value is
# device-specific it is called out and must be overridden by the device tree.

DEVICE_PATH := device/mediatek/mt6877-common

# ---- Kernel ---------------------------------------------------------------
# A15 (Android 15) on this platform is GKI: Linux 6.6, boot header v4, and the
# kernel image is built from PUBLISHED source.
#
# Measured on a realme 11 Pro 5G running RMX3771_15.0.0.600(EX01):
#   boot_a        header_version=4  kernel_size=14,678,442  ramdisk_size=0
#                 (ramdisk_size 0 is the GKI signature -- the ramdisk lives in
#                  vendor_boot, not boot)
#   vendor_boot_a header_version=4  page_size=4096  vendor_ramdisk_size=40,272,743
#   uname -r      6.6.30-android15-8-o-gbf7a50923577-4k
#
# The published 6.6 source builds standalone (see the device tree's
# docs/KERNEL_BUILD_SUCCESS.md), but its correct home is a Lineage tree with MTK
# kleaf, not a standalone flash.
BOARD_USES_GENERIC_KERNEL := true
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_KERNEL_PAGESIZE := 4096
BOARD_BOOT_HEADER_VERSION := 4
BOARD_VENDOR_BOOT_HEADER_VERSION := 4
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true

# A13 note (still accurate FOR AN A13 PORT): that build was NON-GKI, Linux
# 4.19.191+, and realme published no 4.19 device tree, so an A13 port ships a
# PREBUILT kernel via TARGET_PREBUILT_KERNEL. Do not set
# BOARD_USES_GENERIC_KERNEL := false here to accommodate it -- override per
# device, because GKI is the platform default on A15 and flipping it in common
# would misconfigure every A15 device.

# ---- Kernel command line --------------------------------------------------
# SoC-level only. The device tree adds its own hardware-specific flags.
BOARD_KERNEL_CMDLINE += androidboot.hardware=mt6877
BOARD_KERNEL_CMDLINE += androidboot.hardware.platform=mt6877
BOARD_KERNEL_CMDLINE += androidboot.memcg=1

# NOTE: androidboot.dtb_idx is intentionally NOT set here. On this platform the
# DTB is appended to the kernel inside boot.img rather than selected from a dtb
# partition, and the measured boot.img header (v0) carries no dtb_size field.
# Setting dtb_idx=0 on a device that does not use a dtb partition can prevent
# boot. It belongs in the device tree only if that device actually has one.

# ---- Buses visible in the stock DTB (reference, not a config knob) --------
# i2c0..i2c11 (12 controllers), spi0..spi7 (8), uart0..uart3, 3x usbc, dsi,
# dsi_te, mmc0-2, ufs. These are facts about the SoC and are recorded here so a
# porter does not have to re-derive them; they are not build variables.

# ---- AVB / partitions -----------------------------------------------------
# Measured on the device: logical partitions inside `super`, classic A/B with
# explicit _a/_b suffixes and slotselect in the fstab. NOT virtual-A/B.
BOARD_AVB_DEVICE_PATH := odm
BOARD_AVB_DEVICE_PARTITIONS := vendor,odm,product,system_ext
BOARD_SUPER_PARTITION_GROUPS := boot_default
BOARD_SUPER_PARTITION_METADATA_DEVICE := metadata
BOARD_SUPER_PARTITION_METADATA_GROUP := slot_a
BOARD_SUPER_PARTITION_SLOT_METADATA_GROUP := slot_a

# NOTE: realme splits `super` further into `my_*` logical partitions
# (my_company, my_product, my_region, my_heytap, my_carrier, my_stock,
# my_bigball, my_engineering, my_manifest, my_custom, my_preload) per
# odm/etc/oplus.fstab. Those are realme/OPPO regional splits, NOT part of the
# SoC, so they are NOT declared here. A port that wants them overrides
# BOARD_SUPER_PARTITION_GROUPS in its own device tree. Do not copy them into
# this file: doing so would force every mt6877 device to inherit a regional
# layout that has nothing to do with the chipset.

# ---- Encryption -----------------------------------------------------------
BOARD_USES_FBE_HASH := true
BOARD_USES_FBE_ENCRYPTION := true
BOARD_USES_AVB := true
BOARD_AVB_ENABLE := true
BOARD_AVB_ENABLE_VERIFICATION := true
BOARD_AVB_VERITY_ENABLE := true
BOARD_AVB_HASHTREE_DISABLE := false
BOARD_USES_METADATA_PARTITION := true

# ---- Not set here (deliberately) ------------------------------------------
# Partition SIZES: these differ per device. Measured realme values are NOT SoC
#   facts and must not be inherited by an unrelated mt6877 phone. From the live
#   A15 device (blockdev --getsize64):
#     boot        41,943,040  (40 MiB)
#     init_boot    8,388,608  ( 8 MiB)
#     vendor_boot 67,108,864  (64 MiB)
#     dtbo         8,388,608  ( 8 MiB)
#   A device tree sets BOARD_BOOTIMAGE_PARTITION_SIZE and friends itself.
# BOARD_KERNEL_CMDLINE device-specific flags (panel, touch, camera): same.
# BOARD_PHYSICAL_PARTITION: varies by device storage layout.
# BOARD_VNDK_VERSION: tied to the target Android version, not the SoC.