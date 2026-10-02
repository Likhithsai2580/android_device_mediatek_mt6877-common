# mt6877 SoC identity — MediaTek Dimensity 7050 / 7050V
#
# Every value here was read out of the stock device tree (a13-merged.dts),
# extracted from the realme 11 Pro 5G A13 firmware. Nothing is copied from a
# datasheet or a sibling SoC.

TARGET_BOARD_PLATFORM := mt6877
TARGET_BOOTLOADER_BOARD_NAME := mt6877
TARGET_NO_BOOTLOADER := true
TARGET_USES_64_BIT_BINDER := true
TARGET_2ND_ARCH_SUFFIX :=
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := mt6877

# ---- CPU ------------------------------------------------------------------
# MEASURED from the DTB, not assumed:
#   cpu@000..cpu@005  compatible = "arm,cortex-a55"   (6 little cores)
#   cpu@100, cpu@101  compatible = "arm,cortex-a76"   (2 big cores)
#
# That is 6xA55 + 2xA76. Worth flagging: it is NOT the 2xA78 configuration
# some Dimensity 7050 SKUs use. The big cores on this SoC are A76, and a board
# config that assumed A78 would pick the wrong scheduler topology.
TARGET_CPU_CORES_LITTLE := 6
TARGET_CPU_CORES_BIG := 2
TARGET_CPU_LITTLE_CORE := arm,cortex-a55
TARGET_CPU_BIG_CORE := arm,cortex-a76

# Two kernel variants (little / big), per the topology above.
TARGET_NUM_VARIANT_KERNELS := 2

# ---- GPU ------------------------------------------------------------------
# mali@13000000 in the DTB. Midgard/Pixel (Mali-G68 class).
TARGET_GPU := mali

# ---- Kernel ---------------------------------------------------------------
# Non-GKI. The device runs 4.19.191+ (built 2023-09-13), and realme published
# NO 4.19 DTS: their kernel-4.19 directory in the AndroidV source contains 4
# files and zero .dts. So this platform cannot build its own kernel from public
# source and MUST ship a prebuilt. See README.md.
TARGET_USES_GKI_KERNEL := false
BOARD_USES_GENERIC_KERNEL := false