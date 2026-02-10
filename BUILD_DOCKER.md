# CCK-BALL - Docker Build Guide

Quick guide for building ZMK firmware using Docker (recommended method).

## Prerequisites

- Docker Desktop for Mac installed
- That's it! No local ZMK installation needed.

## Build Commands

The Docker image has ZMK pre-installed, so you can build directly:

```bash
# Build both halves (left + right)
make docker-all

# Build left half only
make docker-left

# Build right half only (with ZMK Studio)
make docker-right

# Clean build artifacts
make docker-clean
```

## Output Files

After building, you'll find in your repository root:

- `zmk_cck_ball_left.uf2` - Left half firmware
- `zmk_cck_ball_right.uf2` - Right half firmware (with ZMK Studio)

## Flashing

1. Put keyboard in bootloader mode (double-tap reset button)
2. Drag `.uf2` file to the USB drive that appears
3. Done!

## Notes

- **No setup required** - Docker image has everything built-in
- **No local pollution** - Only `build/` directory and `.uf2` files are created locally
- Build artifacts can be cleaned with `make docker-clean`
- For ZMK v0.3 (this branch), uses stable Docker image
