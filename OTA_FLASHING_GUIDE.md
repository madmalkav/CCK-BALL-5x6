# OTA Flashing Guide: CCK-BALL with Bus Pirate

This guide covers flashing MCUboot and OTA-enabled ZMK firmware onto a nice!nano v2 using a Bus Pirate as an SWD programmer.

> **⚠️ WARNING:** This process replaces the factory Adafruit bootloader. If something goes wrong, USB recovery will not work — you'll need the Bus Pirate again to re-flash.

## 🚨 Risks & Trade-offs (Read Before Flashing)

Switching to MCUboot fundamentally changes how you interact with your nice!nano:

1.  **No More USB Drive**: You will **lose the `NICENANO` USB drive**. You cannot drag-and-drop `.uf2` files anymore. All updates must be done via Bluetooth (OTA) or SWD (Bus Pirate).
2.  **Recovery Requires Hardware**: If you flash bad firmware that crashes the Bluetooth stack, you **cannot** recover via USB. You must re-connect the Bus Pirate to unbrick the board.
3.  **Incompatible Firmware**: You cannot flash standard nice!nano ZMK builds (from nice!nano docs or GitHub Actions) onto this board anymore. They expect the Adafruit bootloader/SoftDevice layout. You must ONLY use your custom `docker-ota` builds.
4.  **LED Status**: In bootloader mode, the blue LED on the nice!nano might not behave as expected (pulse/blink) because the generic nRF52840 build definition uses different LED pins. This is cosmetic and does not affect functionality.

---

## Prerequisites

- **Bus Pirate** (v3 or v4)
- **OpenOCD** installed (`brew install openocd`)
- **4 jumper wires** (female-to-female or female-to-pin)
- **Docker** (for building firmware)

## Step 1: Build Everything

```bash
# Build MCUboot + both OTA firmware halves
make docker-ota-all
```

This produces:
| File | Description |
|------|-------------|
| `mcuboot_nice_nano_v2.hex` | MCUboot bootloader |
| `build/left_ota/zephyr/zmk.hex` | Left half firmware |
| `build/right_ota/zephyr/zmk.hex` | Right half firmware |

## Step 2: Wire the Bus Pirate to nice!nano

Connect the Bus Pirate to the nice!nano's SWD pads (on the bottom of the PCB):

| Bus Pirate Pin | nice!nano Pad | Function                        |
| -------------- | ------------- | ------------------------------- |
| **GND**        | GND           | Ground                          |
| **+3.3V**      | VCC (3.3V)    | Power (only if not USB-powered) |
| **MOSI**       | SWDIO         | SWD Data                        |
| **CLK**        | SWCLK         | SWD Clock                       |

> **Note:** If the nice!nano is powered via USB, do NOT connect the 3.3V pin from Bus Pirate.

### nice!nano v2 SWD Pad Locations

The SWD pads are on the **bottom** of the nice!nano PCB, near the USB-C connector:

- Two small test pads labeled **SWD** (SWDIO) and **SWC** (SWCLK)
- If not labeled, consult the [nice!nano pinout diagram](https://nicekeyboards.com/docs/nice-nano/pinout-schematic)

## Step 3: Create OpenOCD Config

Save this as `buspirate-nrf52.cfg`:

```tcl
# Bus Pirate SWD interface for nRF52840
source [find interface/buspirate.cfg]

buspirate port /dev/tty.usbserial-XXXX
# ^ Replace with your actual Bus Pirate serial port
# Find it with: ls /dev/tty.usbserial-*

transport select swd

source [find target/nrf52.cfg]

# Slow speed for reliability
adapter speed 1000
```

## Step 4: Backup Existing Firmware/Bootloader (Highly Recommended)

Before you erase the chip, dump the current full 1MB flash content. This saves your existing Adafruit bootloader, SoftDevice, and ZMK firmware so you can restore it exactly as it was.

```bash
# Dump entire 1MB flash to a binary file (takes ~2-3 minutes)
openocd -f buspirate-nrf52.cfg -c "init; dump_image backup_full.bin 0x0 0x100000; exit"
```

**To Restore Backup:**

```bash
openocd -f buspirate-nrf52.cfg -c "init; halt; nrf5 mass_erase; program backup_full.bin 0x0 verify reset exit"
```

## Step 5: Flash MCUboot (First Time Only)

```bash
# 1. Full chip erase (removes Adafruit bootloader + SoftDevice)
openocd -f buspirate-nrf52.cfg -c "init; halt; nrf5 mass_erase; exit"

# 2. Flash MCUboot bootloader
openocd -f buspirate-nrf52.cfg -c "program mcuboot_nice_nano_v2.hex verify reset exit"

# 3. Flash ZMK firmware (right half example)
openocd -f buspirate-nrf52.cfg -c "program build/right_ota/zephyr/zmk.hex verify reset exit"
```

## Step 6: Verify It Works

After flashing, the keyboard should boot and be discoverable via Bluetooth as "CCK BALL OTA".

## Step 7: Future OTA Updates (No Wires!)

Once MCUboot + MCUmgr is running, update firmware over Bluetooth:

### Using nRF Connect App (iOS/Android)

1. Build new firmware: `make docker-ota`
2. Open nRF Connect app
3. Connect to "CCK BALL OTA"
4. Go to **DFU** tab
5. Select `build/right_ota/zephyr/zmk.bin`
6. Start upload

### Using mcumgr CLI (macOS)

```bash
# Install mcumgr
go install github.com/apache/mynewt-mcumgr-cli/mcumgr@latest

# List images
mcumgr --conntype ble --connstring ctlr_name=default,peer_name="CCK BALL OTA" image list

# Upload new firmware
mcumgr --conntype ble --connstring ctlr_name=default,peer_name="CCK BALL OTA" image upload build/right_ota/zephyr/zmk.bin

# Confirm and reset
mcumgr --conntype ble --connstring ctlr_name=default,peer_name="CCK BALL OTA" reset
```

## Recovery

If the board becomes unresponsive, re-flash using the Bus Pirate:

```bash
# Erase and re-flash
openocd -f buspirate-nrf52.cfg -c "init; halt; nrf5 mass_erase; exit"
openocd -f buspirate-nrf52.cfg -c "program mcuboot_nice_nano_v2.hex verify reset exit"
openocd -f buspirate-nrf52.cfg -c "program build/right_ota/zephyr/zmk.hex verify reset exit"
```

To go back to the **original Adafruit bootloader**, flash the [nice!nano bootloader hex](https://github.com/nicekeyboards/nice-nano-v2-bootloader/releases) using the same OpenOCD process.

## Flash Layout Reference

```
Address     Size    Content
─────────────────────────────────
0x00000     48 KB   MCUboot Bootloader
0x0C000    456 KB   Slot 0 (Active Firmware)
0x7E000    456 KB   Slot 1 (OTA Update Staging)
0xF0000     40 KB   Scratch (Swap Area)
0xFA000     24 KB   Storage (NVS/Settings)
─────────────────────────────────
Total:    1024 KB   (1 MB nRF52840 Flash)
```
