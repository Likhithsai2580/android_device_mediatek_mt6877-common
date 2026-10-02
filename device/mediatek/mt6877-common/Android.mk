// mt6877 platform — SoC-level proprietary module definitions.
//
// SCOPE: modules whose SOURCE is in this platform tree. Vendor HAL binaries and
// device-specific blobs belong to the device's own vendor tree.
//
// INTENTIONALLY EMPTY. Nothing here can be written without first confirming,
// against a real build, that a module actually needs defining. Declaring a
// module that does not exist breaks the build; declaring one that is not
// needed adds a confusing Android.mk to review.
//
// The mt6877 vendor tree that will need these is vendor/mediatek/mt6877-common
// — which does not exist yet (see README.md).

// TODO(porter): Android.mk for the mt6877-specific overlay/config files,
// once the set is known from an actual build attempt.