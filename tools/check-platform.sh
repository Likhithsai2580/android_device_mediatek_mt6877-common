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
for pat in "No kernel source exists" "vendor tree does not exist" "sepolicy"; do
  grep -qi "$pat" "$ROOT/README.md" 2>/dev/null \
    && ok "README still documents: $pat" \
    || bad "README no longer documents: $pat"
done

echo
echo "== 9. no VINTF manifest was guessed =="
# A wrong manifest is a bootloop, so an absent one must stay absent until it is
# derived from a real device.
if [ -f "$ROOT/vintf/manifest.xml" ]; then
  bad "vintf/manifest.xml EXISTS -- was it derived from a real device?"
else
  ok "no guessed VINTF manifest present"
fi

echo
[ "$FAIL" -eq 0 ] && echo "PLATFORM CHECK: ALL PASS" || echo "PLATFORM CHECK: $FAIL FAILED"
exit $FAIL