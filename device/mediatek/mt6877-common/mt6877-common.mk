# mt6877 platform product makefile (common to all mt6877 devices).
#
# Contains ONLY SoC-level facts. The device tree inherits this and adds its own.
#
# The HAL set below was read off the realme 11 Pro 5G via
# `adb shell ls /vendor/lib64/hw` and `/vendor/etc/permissions`, and
# cross-checked against the HALs present in the extracted stock partitions.
# These are AOSP-side framework packages; the corresponding vendor HAL binaries
# live in the device's own vendor tree, NOT here.

# ---- MediaTek SoC-level drivers ------------------------------------------
# The mt6877 needs these regardless of the phone it ships in.
PRODUCT_PACKAGES += \
    android.hardware.audio \
    android.hardware.bluetooth \
    android.hardware.camera \
    android.hardware.gnss \
    android.hardware.health \
    android.hardware.sensors \
    android.hardware.soundtrigger \
    android.hardware.thermal \
    android.hardware.vibrator \
    android.hardware.wifi \
    android.hardware.wifi.rtt

# ---- Cellular: the mt6877 ships a 5G modem -------------------------------
PRODUCT_PACKAGES += \
    android.hardware.radio \
    android.hardware.telephony \
    android.hardware.telephony.gsm \
    android.hardware.telephony.cdma \
    android.hardware.telephony.ims \
    android.hardware.telephony.sms

# ---- Storage: UFS + eMMC-capable MSHC, and the MTK MMLC block layer -------
PRODUCT_PACKAGES += \
    android.hardware.usb.host \
    android.hardware.usb.accessory \
    android.hardware.usb.gadget

# ---- Display: DSI + DSI_TE present in the DTB ----------------------------
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator \
    android.hardware.graphics.mapper \
    android.hardware.renderscript \
    android.hardware.vulkan.compute \
    android.hardware.vulkan.level \
    android.hardware.vulkan.version

# ---- Security / crypto: MTK secure element on this platform --------------
PRODUCT_PACKAGES += \
    android.hardware.biometrics \
    android.hardware.biometrics.fingerprint \
    android.hardware.keystore \
    android.hardware.keystore2 \
    android.hardware.security.keystore

# ---- Location / sensors ---------------------------------------------------
PRODUCT_PACKAGES += \
    android.hardware.location \
    android.hardware.location.gps \
    android.hardware.sensor.accelerometer \
    android.hardware.sensor.compass \
    android.hardware.sensor.gyroscope \
    android.hardware.sensor.light \
    android.hardware.sensor.proximity \
    android.hardware.sensor.stepcounter \
    android.hardware.sensor.stepdetector \
    android.hardware.sensor.hifi_sensors

# ---- Power / thermal ------------------------------------------------------
# The DTB shows a full thermal bank set and cpufreq/dvfs nodes, plus MTK's
# SCP-based power management (scp@10500000 with 82 refs in the tree).
PRODUCT_PACKAGES += \
    android.hardware.power \
    android.hardware.power.stats

# ---- Media / DRM ----------------------------------------------------------
PRODUCT_PACKAGES += \
    android.hardware.audio.effect \
    android.hardware.audio.pro \
    android.media.swcodec \
    android.media.swcodec2 \
    android.hardware.drm

# ---- Deliberately NOT here -----------------------------------------------
# android.hardware.camera.provider  -- stock realme uses its own proprietary
#   provider (android.hardware.camera.provider@2.6-impl-mediatek.so), so
#   enabling AOSP's provider is a per-device decision with real work, not a
#   platform default. Wiring it in is where most mt6877 camera bring-up is
#   actually spent.
# com.oplus.*  -- realme/OPPO blobs, device-specific.
# Anything gated behind BOARD_HAS_* flags -- those belong in device trees.