# android_device_mediatek_mt6877-common

LineageOS platform tree for **mt6877** (MediaTek Dimensity 7050 / 7050V).

Every mt6877 phone inherits this. It holds what is true of the *chipset* — not
of any one device. Panel, board revision, RAM/flash variants and project
numbers belong in each device's own tree.

## Status: scaffolded, NOT buildable

This tree is the shared foundation every mt6877 port was missing. It ships
measured SoC facts (CPU/GPU/ABI/kernel/AVB/fstab) and a **real VINTF manifest**
generated from stock. It is **not finished**, and the remaining parts are not
things that can be written by inspection. Two are hard blockers.

|| piece | state ||
||---|---||
| piece | state |
|---|---|
| `mt6877.mk` | done — CPU/GPU/ABI facts measured from the DTB |
| `BoardConfigCommon.mk` | done — AVB/A-B/kernel facts measured from the device |
| `recovery.fstab` | done — reconstructed from the device's real fstab |
| `mt6877-common.mk` | done — SoC-level framework packages, HAL set cross-checked |
| `Android.mk` | **empty on purpose** |
| `lineage.dependencies` | lists only real repos; names the missing ones |
| `vintf/manifest.xml` | **done** — 18 fragments merged verbatim from stock A15 |
| `Android.bp` | `mt6877.vintf` bound to the real manifest; `init.mt6877.rc` module commented out on purpose |
| `init.mt6877.rc` | **deliberately absent** — stock's file is vendor-tree content; see below |

## The two walls

### 1. Kernel source — RESOLVED on A15, and this device runs A15

```
A15 device kernel     6.6.30-android15-8-o-gbf7a50923577-4k   (adb shell uname -r)
realme AndroidV src   kernel-6.6  -> published AND builds; Image produced
A13 device kernel     4.19.191+   -> realme published NO 4.19 device tree
```

**The phone has been updated to A15, so the old wall is gone.** The 6.6 tree is
published, compiles with a stock aarch64 cross-toolchain, and a generic GKI
`Image` has been built and verified (36,870,656 B, `ARMd` magic, banner
`Linux version 6.6.30-4k`). See the device tree's
`docs/KERNEL_BUILD_SUCCESS.md`.

This matters for more than convenience: the LineageOS charter says *non-GKI
devices MUST NOT ship a prebuilt kernel*. The A13 configuration could not meet
that requirement from public source. **A15 can** — which is why A15 is the port
target.

The A13 route remains what it was: `TARGET_PREBUILT_KERNEL`, a portability
necessity rather than a choice. Do not describe it as the platform's situation
any more; it is one device's situation if that device is left on A13.

### 1b. The remaining device-tree gap: `cust.dtsi` is referenced but not published

Not a kernel wall, but the same shape. realme's `oplus6877_22712.dts` includes
`<oplus6877_22712/cust.dtsi>`, a file **absent from the published tree**, and
`k6877v1_64.dts` ends with its `cust.dtsi` / touch / camera includes commented
out. Consequence: the published source reproduces **95.3%** of the live A15
device tree, and the residual 16 nodes (camera, NFC, LCD bias, charge pump,
`oplus,mm_config`) come from that one omission. The stock binary DTBO is the
authoritative artifact for those nodes. Full analysis in the device tree's
`docs/A15_SOURCE_VS_LIVE_DTB.md`.

### 2. The vendor tree does not exist

`vendor_mediatek_mt6877-common` has to be created — the blob set, the mk files,
and (usually the real work) **sepolicy**. Sepolicy is the part that cannot be
guessed: wrong policy rules produce a bootloop, not a build error, and the
denial you then debug may be unrelated-looking.

## VINTF manifest — now present, generated from stock

`Android.bp` was deliberately left with an empty manifest at scaffold time, with
this reasoning: a VINTF manifest that declares a HAL the device does not ship
causes a boot-time HAL crash, and one that omits a HAL it does ship causes an
immediate service-not-found. Both surface as unexplained boot failures.

That reasoning was right. The remedy was to **derive the manifest from a stock
device rather than write it by hand** — which is now done.
`vintf/manifest.xml` is a verbatim merge of the 18 vendor-side fragments pulled
from `/vendor/etc/vintf/manifest/*.xml` on a realme 11 Pro 5G A15 stock device.
Every `<hal>` block is copied as-is from its source file (name / version /
fqname / interface / format). Nothing was invented, nothing was dropped.

The split it embodies is the platform-vs-device one the warning was really about:
  - **This file** carries only the SoC-level HALs — MediaTek-named ones and the
    standard AOSP HALs the mt6877 provides (gnss, light, graphics, audio.core,
    thermal, memtrack, power, LBS, APU, engineermode).
  - **Excluded on purpose**: `com.oplus.*` and realme HALs, and
    `android.hardware.camera.provider` (stock uses its own proprietary provider).
    Those live in `/odm/etc/vintf/manifest` — they are DEVICE-level, so a device
    tree supplies them, never this common manifest.

`Android.bp` now binds `mt6877.vintf` to that manifest.

## `init.mt6877.rc` — deliberately absent, and that is the correct state

The stock tree ships `/vendor/etc/init/hw/init.mt6877.rc` (1,168 lines) and it was
examined before deciding. It does **not** belong here:

1. It declares only **7 services, all of which exec a `/vendor/bin` binary**
   (`swap_enable_init`, `readahead_init` → `/vendor/bin/swap_enable.sh`; plus
   `bugreport`, `meta_tst`, `factory_no_image`, `osi`, `fuelgauged(_nvram)`). A
   `device/` tree cannot ship `/vendor/bin/*` — those come from the vendor tree.
   Copying the file here would mount a set of dangling execs.
2. **56 of its lines are realme/OPPO device policy, not SoC policy** — a ~50-line
   `/sys/kernel/oplus_display/*` chown/chmod block, MIDAS `/dev/midas_dev`, and
   `sys.oplus.bootupgrade` cpufreq limiting. Putting those in a *common* tree
   forces them on every mt6877 phone, which is the exact mistake this tree exists
   to prevent.
3. It **imports two files that do not exist on the device** (`init.volte.rc`,
   `init.mal.rc`), so it is already partly stale in stock and depends on the
   vendor tree's layout.

The genuinely platform-level content is thin — `boot_dramboost`, cpuset cgroup
writes, and the `sysctl` rmem/wmem bumps — and is cheap to re-add once a build
asks for it. The `mt6877.init.rc` module in `Android.bp` is therefore commented
out rather than left referencing a non-existent source.

## Facts this tree is built on

From the realme 11 Pro 5G (RMX3771 / RE58B8L1 / project 22712). The empirical
facts below were first measured on the live **A15** device (running
`RMX3771_15.0.0.600(EX01)`, kernel `6.6.30-android15-8-o-gbf7a50923577-4k`),
cross-checked against the recovered A13 config and the published 6.6 source:

```
CPU        6x arm,cortex-a55 (cpu@000..005) + 2x arm,cortex-a76 (cpu@100,101)
GPU        mali@13000000  (arm,mali-valhall -> Valhall arch, NOT Midgard)
Buses      i2c0..i2c11 (12), spi0..spi7 (8), uart, mmc0-2, usbc, dsi, dsi_te, ufs
Power      scp@10500000 (82 refs), cpufreq, dvfs nodes, full thermal bank
Crypto     pwrap/mt6359-pmic, spmi, mt6315
Storage    logical partitions inside `super`, classic A/B (not virtual-A/B),
           EROFS on the stock system; ext4 on the GSI boot test
Kernel     GKI, Linux 6.6.30, boot header v4, ramdisk in vendor_boot
```

The 6x A55 + 2x A76 configuration is worth flagging: it is *not* the 2x A78
variant some Dimensity 7050 SKUs use. That was read out of the DTB rather than
assumed from a spec sheet.

## What is deliberately excluded

**realme's `my_*` regional logical partitions.** The stock ODM fstab mounts
`my_company`, `my_product`, `my_region`, `my_heytap`, `my_carrier`, `my_stock`,
`my_bigball`, `my_engineering`, `my_manifest`, `my_custom`, `my_preload` out
of `super`. That is an OPPO/realme regional split, **not a chipset trait**.
Putting it here would force every mt6877 device — including a hypothetical
Xiaomi or Samsung one — to inherit a regional layout that has nothing to do
with it. A port that wants them declares them in its own device tree.

Same reasoning for `/mnt/vendor/protect1`, `protect2`, `nvdata`, `nvcfg`:
realme security storage, device-specific.

## Suggested next steps, in order

1. **(DONE)** Boot a GSI on the device — stock kernel + the device tree we
   validated. **Result: passed.** TrebleDroid A15 booted on the stock kernel +
   stock DT, with display, touch, both SIMs, LTE, audio, Bluetooth, Wi-Fi **and
   camera** all working. See `docs/GSI_BOOT_TEST.md`. Conclusion: the
   kernel/DT path is sound; the remaining work is userspace.
2. **Generate the VINTF manifest** from a stock device — **done** (this tree's
   `vintf/manifest.xml`). What remains is the per-device odm fragments, which
   the RMX3771 device tree supplies.
3. **(RESOLVED — no file needed)** `init.mt6877.rc` is deliberately absent; the
   stock file is vendor-tree content with realme pollution. See the section
   above. Rationale recorded in `Android.bp`; re-add only when the vendor tree
   exists.
4. **Build `vendor_mediatek_mt6877-common`.** Start with the fstab and the mk
   files; sepolicy last, and only what the build actually asks for.
5. **Port the device tree (RMX3771).** With the platform tree solid, this is the
   device-specific bits: partition sizes, the `my_*` regional layout, odm VINTF
   fragments (camera provider, sensors), and the `cust.dtsi` nodes shipped as a
   prebuilt DTBO from the stock firmware.
6. **Attempt a build and let it drive.** The missing pieces are discoverable
   from build output; guessing them is how a tree ends up subtly wrong.

## Research notes (checked against upstream, worth knowing before starting)

**sepolicy is less scary than it looks.** LineageOS already ships
`LineageOS/android_device_mediatek_sepolicy_vndr`, which is the MediaTek vendor
policy — it is MTK-generic, not per-SoC, and it already merges basic + BSP +
modem policy. That covers most of what mt6877 needs and is a `lineage.dependencies`
entry away. What is genuinely per-device is the realme/OPPO domain rules
(`oplus_*`, `vendor.oplus.*` — and the stock ODM carries
`precompiled_sepolicy*` checksum files, which is the thing to work from).

So the sepolicy estimate above is pessimistic. Realistically: inherit the MTK
policy, then add what the build denies.

**The prebuilt-kernel route has a documented caveat.** The LineageOS charter
says:

> Non-GKI devices MUST NOT ship a prebuilt kernel.

An **A13** port cannot satisfy that from public source (no 4.19 device tree was
published), so `TARGET_PREBUILT_KERNEL` there is a **portability necessity, not a
choice** — fine for an unofficial port, a blocker for official support.

**On A15 the requirement is satisfiable**: the 6.6 tree is published, it builds,
and the platform is GKI. That is the concrete reason A15 is the port target
rather than a preference. If official LineageOS support is the goal, A15 is the
only configuration that can meet the charter.

Per AOSP, `TARGET_PREBUILT_KERNEL` works for `make bootimage` on any device,
and for devices without `init_boot` you need a ramdisk — this device **has**
`init_boot_a`/`init_boot_b`, so that particular workaround does not apply.

## Licence

Original work. The facts are read off a realme device's stock device tree and
firmware; the files themselves are not copied from realme.