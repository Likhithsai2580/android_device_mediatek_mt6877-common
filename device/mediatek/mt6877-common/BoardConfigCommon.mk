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
# Non-GKI, kernel 4.19.191+ (2023-09-13). No public 4.19 DTS exists from
# realme, so the kernel is a PREBUILT. Override TARGET_PREBUILT_KERNEL in the
# device tree to point at your own prebuilts dir.
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_USES_GENERIC_KERNEL := false

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
# TARGET_BOOTIMAGE_PARTITION_SIZE / BOARD_DTBOIMG_PARTITION_SIZE: these differ
#   per device. The measured realme values (40 MiB / 1.61 MiB) are NOT SoC
#   facts and must not be inherited by an unrelated mt6877 phone.
# BOARD_KERNEL_CMDLINE device-specific flags (panel, touch, camera): same.
# BOARD_PHYSICAL_PARTITION: varies by device storage layout.
# BOARD_VNDK_VERSION: tied to the target Android version, not the SoC.