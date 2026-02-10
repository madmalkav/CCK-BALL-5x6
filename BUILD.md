# CCK-BALL Local Build Guide

This guide covers building ZMK firmware locally on your Mac for the CCK-BALL keyboard.

## Prerequisites

### 1. Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install Build Tools

```bash
# Install CMake and other dependencies
brew install cmake ninja gperf python3 ccache qemu dtc wget libmagic

# Install west (ZMK's build tool)
pip3 install west
```

### 3. Install Zephyr SDK

```bash
# Download and install Zephyr SDK
cd ~
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5/zephyr-sdk-0.16.5_macos-x86_64.tar.xz
tar xf zephyr-sdk-0.16.5_macos-x86_64.tar.xz
cd zephyr-sdk-0.16.5
./setup.sh
```

## First-Time Setup

```bash
# 1. Navigate to your CCK-BALL directory
cd /Users/rgmclean/workspace/personal/CCK-BALL

# 2. Initialize the workspace
make -f Makefile.local setup

# This will:
# - Initialize west workspace
# - Download ZMK and dependencies
# - Export Zephyr environment
```

## Building Firmware

### Build Both Halves

```bash
make -f Makefile.local all
```

This creates:

- `zmk_cck_ball_left.uf2` - Left half firmware
- `zmk_cck_ball_right.uf2` - Right half firmware (with ZMK Studio)

### Build Individual Halves

```bash
# Left half only
make -f Makefile.local left

# Right half only (with ZMK Studio support)
make -f Makefile.local right

# Right half without ZMK Studio
make -f Makefile.local right-no-studio
```

## Flashing Firmware

1. Put keyboard into bootloader mode:
   - Double-tap the reset button on the nice!nano
   - The board should appear as a USB drive

2. Copy the `.uf2` file to the drive:

   ```bash
   # For left half
   cp zmk_cck_ball_left.uf2 /Volumes/NICENANO/

   # For right half
   cp zmk_cck_ball_right.uf2 /Volumes/NICENANO/
   ```

3. The board will automatically reboot with new firmware

## Cleaning Build

```bash
# Clean build directory only
make -f Makefile.local clean

# Clean everything (build + all downloaded modules)
make -f Makefile.local distclean
```

## Updating ZMK

```bash
# Update to latest ZMK version
make -f Makefile.local update

# Rebuild after update
make -f Makefile.local all
```

## Troubleshooting

### "west not found"

```bash
pip3 install --user west
# Add to PATH if needed
export PATH="$HOME/Library/Python/3.x/bin:$PATH"
```

### "CMake not found"

```bash
brew install cmake
```

### Build fails with missing dependencies

```bash
# Reinstall Zephyr SDK
cd ~/zephyr-sdk-0.16.5
./setup.sh
```

### Clear cache and rebuild

```bash
make -f Makefile.local distclean
make -f Makefile.local setup
make -f Makefile.local all
```

## Board Configuration

- **Board:** nice!nano v2
- **Left Shield:** cck_ball_left
- **Right Shield:** cck_ball_right
- **ZMK Studio:** Enabled on right half only

## Directory Structure

```
CCK-BALL/
├── Makefile          # Docker build (from main)
├── Makefile.local    # Local Mac build
├── BUILD.md          # This file
├── config/           # ZMK configuration
│   ├── cck_ball.keymap
│   ├── cck_ball.conf
│   └── boards/       # Board definitions
├── build/            # Build output (gitignored)
├── zmk/              # ZMK source (created by west)
└── modules/          # Dependencies (created by west)
```

## Quick Reference

```bash
# First time
make -f Makefile.local setup
make -f Makefile.local all

# Regular builds
make -f Makefile.local left   # or right, or all

# After config changes
make -f Makefile.local clean
make -f Makefile.local all

# Update ZMK
make -f Makefile.local update
make -f Makefile.local all
```
