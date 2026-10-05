# mt6877 SoC identity — MediaTek Dimensity 7050 / 7050V
#
# Every value here was read out of the stock device tree, extracted from realme
# 11 Pro 5G firmware. Nothing is copied from a datasheet or a sibling SoC.
#
# CPU/GPU/bus facts below were first measured on A13 (a13-merged.dts) and
# re-confirmed on the live A15 device tree; they did not change between the two
# releases. Kernel/GKI facts DID change and are marked as such.

TARGET_BOARD_PLATFORM := mt6877
TARGET_BOOTLOADER_BOARD_NAME := mt6877
TARGET_NO_BOOTLOADER := true
TARGET_USES_64_BIT_BINDER := true
TARGET_2ND_ARCH_SUFFIX :=
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := mt6877

# ---- CPU ------------------------------------------------------------------
# MEASURED from the device tree, re-confirmed on the live A15 unit:
#   cpu@000..cpu@005  compatible = "arm,cortex-a55"   (6 little cores)
#   cpu@100, cpu@101  compatible = "arm,cortex-a76"   (2 big cores)
#
# That is 6xA55 + 2xA76 as far as the DEVICE TREE is concerned, and the DTB is
# what the kernel uses to select scheduler topology and errata workarounds.
#
# HONEST DISCREPANCY: MediaTek's own Dimensity 7050 page and the usual spec
# aggregators describe the big cluster as Cortex-A78, not A76. Both readings are
# recorded here because neither is verified against silicon; what matters for a
# build is that the DTB says A76, so a board config assuming A78 would not match
# what the kernel sees. Do not "correct" this to A78 without a DTB that says so.
TARGET_CPU_CORES_LITTLE := 6
TARGET_CPU_CORES_BIG := 2
TARGET_CPU_LITTLE_CORE := arm,cortex-a55
TARGET_CPU_BIG_CORE := arm,cortex-a76

# Two kernel variants (little / big), per the topology above.
TARGET_NUM_VARIANT_KERNELS := 2

# ---- GPU ------------------------------------------------------------------
# MEASURED on the live device -- the compatible string itself names the family:
#   /proc/device-tree/mali@13000000/compatible
#     -> "mediatek,mali", "arm,mali-valhall"
# So this is a VALHALL GPU (Mali-G68 class), not Midgard/Bifrost. An earlier
# revision of this file said "Midgard/Pixel", which is simply wrong.
TARGET_GPU := mali
TARGET_GPU_ARCH := valhall

# ---- Kernel ---------------------------------------------------------------
# A15 is GKI: Linux 6.6, and realme PUBLISHED that tree -- it builds (see the
# device tree's docs/KERNEL_BUILD_SUCCESS.md). This is what makes A15 the port
# target rather than a preference: the LineageOS charter forbids a prebuilt
# kernel on non-GKI devices, and only the A15 configuration can satisfy that
# from public source.
TARGET_USES_GKI_KERNEL := true

# A13 note (true only FOR AN A13 PORT): that build was non-GKI, kernel
# 4.19.191+, and realme published no 4.19 device tree (their kernel-4.19 dir
# holds 4 files and zero .dts), so an A13 port MUST ship a prebuilt. Do not
# flip TARGET_USES_GKI_KERNEL here to accommodate it -- override per device.

# NOTE: BOARD_USES_GENERIC_KERNEL is set in BoardConfigCommon.mk only. Setting
# it here too would create two assignments that can disagree, and the later
# include silently wins.