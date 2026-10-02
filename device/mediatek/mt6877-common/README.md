# android_device_mediatek_mt6877-common

LineageOS platform tree for **mt6877** (MediaTek Dimensity 7050 / 7050V).

Every mt6877 phone inherits this. It holds what is true of the *chipset* — not
of any one device. Panel, board revision, RAM/flash variants and project
numbers belong in each device's own tree.

## Status: scaffolded, NOT buildable

This tree is the shared foundation every mt6877 port was missing. It is real
work, but it is **not finished**, and the remaining parts are not things that
can be written by inspection. Two are hard blockers.

| piece | state |
|---|---|
| `mt6877.mk` | done — CPU/GPU/ABI facts measured from the DTB |
| `BoardConfigCommon.mk` | done — AVB/A-B/kernel facts measured from the device |
| `recovery.fstab` | done — reconstructed from the device's real fstab |
| `mt6877-common.mk` | done — SoC-level framework packages, HAL set cross-checked |
| `Android.bp` | scaffolded, **manifest deliberately empty** (see below) |
| `Android.mk` | **empty on purpose** |
| `lineage.dependencies` | lists only real repos; names the missing ones |

## The two walls

### 1. No kernel source exists

```
device kernel        4.19.191+   (built 2023-09-13, adb shell uname -r)
realme AndroidV src  kernel-6.6  → compiles; we built it
                    kernel-4.19 → 4 files, ZERO .dts/.dtsi
```

**realme published no 4.19 device tree.** The kernel the phone runs cannot be
rebuilt from public source. This platform therefore ships a **prebuilt kernel**
(`TARGET_PREBUILT_KERNEL`). This is realme's omission, not a research gap, and
no amount of effort substitutes for the missing artifact.

If the device is ever updated to **A15**, this changes: the 6.6 tree is
published and compiles, so a source-built kernel becomes possible.

### 2. The vendor tree does not exist

`vendor_mediatek_mt6877-common` has to be created — the blob set, the mk files,
and (usually the real work) **sepolicy**. Sepolicy is the part that cannot be
guessed: wrong policy rules produce a bootloop, not a build error, and the
denial you then debug may be unrelated-looking.

## Why `Android.bp` has no VINTF manifest

It looks like an oversight and is not. A VINTF manifest that declares a HAL the
device does not ship causes a boot-time HAL crash; one that omits a HAL it does
ship causes immediate service-not-found. Both surface as unexplained boot
failures.

The content is derivable — `ls /vendor/lib64/hw` and
`/vendor/etc/vintf/manifest.xml` on a stock device give the exact list — but it
is **per device**, because which HALs are enabled is a vendor decision, not an
SoC fact. Writing a plausible-looking manifest now would be a guess with a
bootloop attached. `Android.bp` carries the module definitions and a TODO
saying how to fill them.

## Facts this tree is built on

From the realme 11 Pro 5G (RMX3771 / RE58B8L1 / project 22712) stock A13
firmware:

```
CPU        6x arm,cortex-a55 (cpu@000..005) + 2x arm,cortex-a76 (cpu@100,101)
GPU        mali@13000000
Buses      i2c0..i2c11, spi0..spi7, uart, mmc0-2, usbc, dsi, dsi_te, ufs
Power      scp@10500000 (82 refs), cpufreq, dvfs nodes, full thermal bank
Crypto     pwrap/mt6359-pmic, spmi, mt6315
Storage    logical partitions in `super`, classic A/B, EROFS stock images
```

The 6×A55 + 2×A76 configuration is worth flagging: it is *not* the 2×A78
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

1. **Boot a GSI on the device.** Cheapest high-information test available:
   stock kernel + the device tree we already validated. If it boots, the
   remaining work is userspace. If not, the kernel/DT path is the problem and
   everything here is solving the wrong thing.
2. **Build `vendor_mediatek_mt6877-common`.** Start with the fstab and the
   mk files; sepolicy last, and only what the build actually asks for.
3. **Generate the VINTF manifest** from a stock device, not by hand.
4. **Attempt a build and let it drive.** The missing pieces are discoverable
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

This device is non-GKI and cannot build its kernel from public source, so
`TARGET_PREBUILT_KERNEL` is a **portability necessity, not a choice**. It is
fine for an unofficial port and is a blocker for official LineageOS support.
Worth knowing before investing heavily: if official support is the goal, the
device would have to move to a kernel realme published source for (i.e. A15 /
6.6), because that is the only configuration where the charter requirement can
be met.

Per AOSP, `TARGET_PREBUILT_KERNEL` works for `make bootimage` on any device,
and for devices without `init_boot` you need a ramdisk — this device **has**
`init_boot_a`/`init_boot_b`, so that particular workaround does not apply.

## Licence

Original work. The facts are read off a realme device's stock device tree and
firmware; the files themselves are not copied from realme.