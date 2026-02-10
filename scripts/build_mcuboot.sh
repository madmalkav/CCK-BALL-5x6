#!/bin/bash
# Build MCUboot bootloader for nice!nano v2 (nRF52840)
# This script runs INSIDE the Docker container
set -e

MCUBOOT_DIR="/work/bootloader/mcuboot"
BUILD_DIR="/work/build/mcuboot"
OUTPUT_DIR="/work"

echo "=== Building MCUboot for nice!nano v2 ==="

# Pull MCUboot if not present
if [ ! -d "$MCUBOOT_DIR" ]; then
    echo "MCUboot not found. Running west update..."
    west update mcuboot
fi

# bootstrap pip if missing
if ! python3 -m pip --version > /dev/null 2>&1; then
    echo "Pip not found. attempting to install..."
    apt-get update && apt-get install -y python3-pip || python3 -m ensurepip
fi

# Install web requirements
python3 -m pip install -r "$MCUBOOT_DIR/scripts/requirements.txt" --break-system-packages

# Export Zephyr
west zephyr-export

# Create MCUboot overlay for our partition layout
cat > /tmp/mcuboot_overlay.dts << 'EOF'
/* MCUboot overlay for CCK-BALL nice!nano v2 */

/* Delete specific partitions if they exist (failure if not)
 * Instead, we delete the partitions node from flash0.
 */ 

&flash0 {
    /delete-node/ partitions;
};

&flash0 {
    partitions {
        compatible = "fixed-partitions";
        #address-cells = <1>;
        #size-cells = <1>;

        boot_partition: partition@0 {
            label = "mcuboot";
            reg = <0x00000000 0x0000c000>;
        };
        slot0_partition: partition@c000 {
            label = "image-0";
            reg = <0x0000c000 0x00072000>;
        };
        slot1_partition: partition@7e000 {
            label = "image-1";
            reg = <0x0007e000 0x00072000>;
        };
        scratch_partition: partition@f0000 {
            label = "image-scratch";
            reg = <0x000f0000 0x0000a000>;
        };
        storage_partition: partition@fa000 {
            label = "storage";
            reg = <0x000fa000 0x00006000>;
        };
    };
};

/ {
    chosen {
        zephyr,code-partition = &boot_partition;
    };
};
EOF

echo "Building MCUboot..."
west build -p always -d "$BUILD_DIR" -b nrf52840dk_nrf52840 -s "$MCUBOOT_DIR/boot/zephyr" -- \
    -DDTC_OVERLAY_FILE=/tmp/mcuboot_overlay.dts \
    -DCONFIG_BOOT_SIGNATURE_TYPE_RSA=y \
    -DCONFIG_BOOT_SIGNATURE_KEY_FILE=\"root-rsa-2048.pem\"

# Copy outputs
cp "$BUILD_DIR/zephyr/zephyr.hex" "$OUTPUT_DIR/mcuboot_nice_nano_v2.hex"
cp "$BUILD_DIR/zephyr/zephyr.bin" "$OUTPUT_DIR/mcuboot_nice_nano_v2.bin"

echo ""
echo "✓ MCUboot built successfully!"
echo "  HEX: $OUTPUT_DIR/mcuboot_nice_nano_v2.hex"
echo "  BIN: $OUTPUT_DIR/mcuboot_nice_nano_v2.bin"
