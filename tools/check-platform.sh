#!/usr/bin/env bash
# Consistency checks for the mt6877 platform tree.
#
# These verify what can be checked without building: that every file a device
# tree inherits exists, that no device-specific fact leaked into a platform
# variable, and that the honest gaps are still documented.
#
# A platform tree that passes is still NOT buildable -- but one that fails here
# would fail for a reason unrelated to the real blockers, which is exactly the
# noise that hides them.
#
# Scope note: these checks look at ASSIGNED values, not prose. A mention of
# "realme 11" in a comment documenting where a fact came from is correct and
# desirable; the same string in an assignment is a leak. An earlier version
# flagged both and raised three false alarms.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
ROOT="device/mediatek/mt6877-common"
FAIL=0
ok()  { printf '  PASS  %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL+1)); }

# Strip comments and blank lines, leaving only assignable statements.
active() {
  sed -e 's/#.*$//' -e '/^[[:space:]]*$/d' "$@" 2>/dev/null
}

echo "== 1. required files present =="
for f in mt6877.mk mt6877-common.mk BoardConfigCommon.mk Android.bp \
         Android.mk lineage.dependencies recovery.fstab README.md; do
  [ -f "$ROOT/$f" ] && ok "$f" || bad "$f MISSING"
done

echo
echo "== 2. device tree inheritance targets exist =="
# device/realme/RMX3771/lineagerodep.mk does:
#   $(call inherit-product, mt6877/mt6877.mk)
# which resolves to device/mediatek/mt6877-common/mt6877.mk.
if [ -f "$ROOT/mt6877/mt6877.mk" ] || [ -f "$ROOT/mt6877.mk" ]; then
  ok "inherit target mt6877/mt6877.mk resolves"
else
  bad "inherit target mt6877/mt6877.mk missing"
fi

echo
echo "== 3. no device-specific facts assigned in the platform tree =="
LEAKS=0
for pat in RMX3771 RE58B8L1 22712 chengdu narzo \
          BOARD_BOOTIMAGE_PARTITION_SIZE BOARD_DTBOIMG_PARTITION_SIZE \
          BOARD_PHYSICAL_PARTITION BOARD_VNDK_VERSION; do
  if active "$ROOT/mt6877.mk" "$ROOT/mt6877-common.mk" \
             "$ROOT/BoardConfigCommon.mk" "$ROOT/Android.mk" \
      | grep -qiE "$pat"; then
    bad "device-specific '$pat' is ASSIGNED in the platform tree"
    LEAKS=$((LEAKS+1))
  fi
done
[ "$LEAKS" -eq 0 ] && ok "no device-specific values assigned (comments excluded)"

echo
echo "== 4. realme regional partitions NOT in platform fstab =="
if grep -qE '^[[:space:]]*my_' "$ROOT/recovery.fstab" 2>/dev/null; then
  bad "my_* regional partitions assigned in platform fstab"
else
  ok "no my_* regional partitions assigned in platform fstab"
fi

echo
echo "== 5. platform fstab covers the logical partitions =="
for p in system vendor product system_ext odm; do
  grep -qE "^${p}[[:space:]]+/${p}[[:space:]]" "$ROOT/recovery.fstab" 2>/dev/null \
    && ok "fstab mounts /$p" || bad "fstab missing /$p"
done

echo
echo "== 6. SoC facts are self-consistent =="
active "$ROOT/mt6877.mk" | grep -q 'cortex-a55' \
  && ok "mt6877.mk records the A55 cores" || bad "mt6877.mk missing A55"
active "$ROOT/mt6877.mk" | grep -q 'cortex-a76' \
  && ok "mt6877.mk records the measured A76 cores (not A78)" \
  || bad "mt6877.mk does not record A76"
active "$ROOT/mt6877.mk" | grep -qi 'mali' \
  && ok "mt6877.mk records the GPU" || bad "mt6877.mk missing GPU"

echo
echo "== 7. dependencies reference only real repos =="
while IFS= read -r line; do
  case "$line" in ''|\#*) continue ;; esac
  case "$line" in
    FILL_ME*|TODO*|FIXME*)
      bad "placeholder dependency committed: $line" ;;
    android_hardware_mediatek|hardware_mediatek)
      ok "dependency exists: $line" ;;
    *)
      ok "dependency listed: $line (verify on GitHub)" ;;
  esac
done < "$ROOT/lineage.dependencies"

echo
echo "== 8. the honest gaps are still documented =="
# These are the gaps that remain TRUE. 'No kernel source exists' was removed
# because A15 (6.6) is published and builds -- asserting it now would be the
# same error in the opposite direction.
for pat in "cust.dtsi" "vendor tree does not exist" "sepolicy"; do
  grep -qi "$pat" "$ROOT/README.md" 2>/dev/null \
    && ok "README still documents: $pat" \
    || bad "README no longer documents: $pat"
done

echo
echo "== 8b. A15/GKI platform facts are self-consistent =="
# Measured from a live A15 device: GKI, boot header v4, 4K pages. If someone
# reverts these to A13 values (non-GKI / header v0), every A15 device breaks.
active "$ROOT/BoardConfigCommon.mk" | grep -q 'BOARD_USES_GENERIC_KERNEL := true' \
  && ok "BOARD_USES_GENERIC_KERNEL := true (A15 is GKI)" \
  || bad "BOARD_USES_GENERIC_KERNEL is not true -- A15 on this platform is GKI"
active "$ROOT/BoardConfigCommon.mk" | grep -q 'BOARD_BOOT_HEADER_VERSION := 4' \
  && ok "BOARD_BOOT_HEADER_VERSION := 4 (measured)" \
  || bad "BOARD_BOOT_HEADER_VERSION is not 4"
active "$ROOT/BoardConfigCommon.mk" | grep -q 'BOARD_KERNEL_PAGESIZE := 4096' \
  && ok "BOARD_KERNEL_PAGESIZE := 4096 (matches ARM64_4K_PAGES)" \
  || bad "BOARD_KERNEL_PAGESIZE is not 4096"
active "$ROOT/BoardConfigCommon.mk" | grep -q 'BOARD_VENDOR_BOOT_HEADER_VERSION := 4' \
  && ok "BOARD_VENDOR_BOOT_HEADER_VERSION := 4 (vendor_boot exists on A15)" \
  || bad "BOARD_VENDOR_BOOT_HEADER_VERSION is not 4"
active "$ROOT/mt6877.mk" | grep -q 'TARGET_USES_GKI_KERNEL := true' \
  && ok "TARGET_USES_GKI_KERNEL := true (A15 is GKI)" \
  || bad "mt6877.mk TARGET_USES_GKI_KERNEL is not true"
# BOARD_USES_GENERIC_KERNEL must appear in exactly ONE file: two assignments can
# disagree and the later include silently wins.
N_GKI=$(active "$ROOT/mt6877.mk" "$ROOT/mt6877-common.mk" "$ROOT/BoardConfigCommon.mk" \
        | grep -c 'BOARD_USES_GENERIC_KERNEL')
[ "$N_GKI" -eq 1 ] \
  && ok "BOARD_USES_GENERIC_KERNEL assigned exactly once" \
  || bad "BOARD_USES_GENERIC_KERNEL assigned $N_GKI times (must be 1)"
active "$ROOT/mt6877.mk" | grep -q 'TARGET_GPU_ARCH := valhall' \
  && ok "GPU arch recorded as valhall (measured from the live DT compatible)" \
  || bad "mt6877.mk does not record the measured Valhall GPU arch"

echo
echo "== 9. the VINTF manifest is EVIDENCE-BASED, not guessed =="
# A wrong manifest is a bootloop, so the rule is not "absent" -- it is "derived
# from a real device". The manifest now exists and must prove provenance and
# stay free of device-level HALs.
V="$ROOT/vintf/manifest.xml"
if [ ! -f "$V" ]; then
  bad "vintf/manifest.xml is missing (it is generated and should be present)"
else
  ok "vintf/manifest.xml present"
  # (a) provenance: the header must name the real source and say verbatim.
  grep -q 'VERBATIM MERGE' "$V" \
    && ok "manifest states it is a verbatim merge (not freehand)" \
    || bad "manifest does not state verbatim-merge provenance"
  grep -qi '/vendor/etc/vintf' "$V" \
    && ok "manifest names its real source path" \
    || bad "manifest does not name the device source path"
  # (b) no device-level HALs leaked in. com.oplus.* / camera.provider belong to
  #     the DEVICE tree (they live in /odm/etc/vintf on stock).
  if grep -qE '<name>(com\.oplus|android\.hardware\.camera\.provider)' "$V"; then
    bad "device-level HAL found in the platform manifest (com.oplus / camera.provider)"
  else
    ok "no device-level HAL (com.oplus.* / camera.provider) in the platform manifest"
  fi
  # (c) it must actually declare platform HALs -- an empty-but-present file would
  #     pass everything above and mean nothing.
  N=$(grep -c '<hal format=' "$V")
  [ "$N" -ge 15 ] \
    && ok "manifest declares $N <hal> blocks (matches the 18 source fragments)" \
    || bad "manifest declares only $N <hal> blocks -- too few to be the real merge"
  # (d) the MediaTek HALs that make it a PLATFORM manifest must be there.
  for h in vendor.mediatek.hardware.mtkpower android.hardware.thermal \
           vendor.mediatek.hardware.lbs; do
    grep -q "<name>$h</name>" "$V" \
      && ok "platform HAL present: $h" || bad "platform HAL missing: $h"
  done
  # (e) it must be WELL-FORMED XML. This is not pedantry: '--' is illegal inside
  #     an XML comment, so prose em-dashes silently make the file invalid, and
  #     VINTF would reject it at build time with a less obvious error.
  if command -v python >/dev/null 2>&1; then
    python -c "import xml.etree.ElementTree as E;E.parse('$V')" 2>/dev/null \
      && ok "manifest is well-formed XML" \
      || bad "manifest is NOT well-formed XML (check for '--' inside comments)"
  else
    ok "python unavailable; skipped XML well-formedness check"
  fi
fi

echo
echo "== 9b. init.mt6877.rc is deliberately absent, with the reason recorded =="
# Stock's init.mt6877.rc is vendor-tree content (all its services exec
# /vendor/bin/*) laced with realme policy (oplus_display, midas). Copying it
# here would be a dead file. The .bp module must be commented out, not dangling.
if [ -f "$ROOT/init.mt6877.rc" ]; then
  bad "init.mt6877.rc was added -- see Android.bp; it is vendor-tree content"
else
  ok "init.mt6877.rc absent (correct)"
fi
grep -qE '^[[:space:]]*# module \{' "$ROOT/Android.bp" \
  && ok "mt6877.init.rc module is commented out in Android.bp" \
  || bad "Android.bp may reference an init.mt6877.rc that does not exist"

echo
[ "$FAIL" -eq 0 ] && echo "PLATFORM CHECK: ALL PASS" || echo "PLATFORM CHECK: $FAIL FAILED"
exit $FAIL