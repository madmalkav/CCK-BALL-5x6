# CCK-BALL ZMK Firmware Build Makefile

# Configuration
BOARD := nice_nano
ZMK_CONFIG := /work/config
BUILD_DIR := build
OUTPUT_DIR := /work

# Snippet for ZMK Studio support (right side only)
STUDIO_SNIPPET := studio-rpc-usb-uart

# Docker configuration
DOCKER_IMAGE := zmkfirmware/zmk-build-arm:stable
DOCKER_CMD := docker run --rm -w /work -v $(CURDIR):/work $(DOCKER_IMAGE)

.PHONY: all setup init update left right clean help settings-reset
.PHONY: docker-all docker-setup docker-left docker-right docker-clean docker-settings-reset

# Default target: build both halves
all: left right

# Full setup (init + update + export)
setup: init update export

# Initialize west workspace
init:
	west init -l config

# Update west modules
update:
	west update

# Export Zephyr
export:
	west zephyr-export

# Install development dependencies (requires root)
deps:
	apt update && apt install -y vim

# Build left half (peripheral)
left:
	west zephyr-export
	west build -p always -s zmk/app -b $(BOARD) -- \
		-DZMK_CONFIG=$(ZMK_CONFIG) \
		-DSHIELD=cck_ball_left
	cp $(BUILD_DIR)/zephyr/zmk.uf2 $(OUTPUT_DIR)/zmk_cck_ball_left.uf2
	@echo "✓ Left half built: $(OUTPUT_DIR)/zmk_cck_ball_left.uf2"

# Build right half (central - with ZMK Studio support)
right:
	west zephyr-export
	west build -p always -s zmk/app -b $(BOARD) -S $(STUDIO_SNIPPET) -- \
		-DZMK_CONFIG=$(ZMK_CONFIG) \
		-DSHIELD=cck_ball_right \
		-DCONFIG_ZMK_STUDIO=y
	cp $(BUILD_DIR)/zephyr/zmk.uf2 $(OUTPUT_DIR)/zmk_cck_ball_right.uf2
	@echo "✓ Right half built: $(OUTPUT_DIR)/zmk_cck_ball_right.uf2"

# Clean build directory
clean:
	rm -rf $(BUILD_DIR)
	@echo "✓ Build directory cleaned"

# Build settings reset firmware (both halves)
settings-reset:
	west zephyr-export
	west build -p always -s zmk/app -b $(BOARD) -- \
		-DZMK_CONFIG=$(ZMK_CONFIG) \
		-DSHIELD="settings_reset"
	cp $(BUILD_DIR)/zephyr/zmk.uf2 $(OUTPUT_DIR)/settings_reset.uf2
	@echo "✓ Settings reset built: $(OUTPUT_DIR)/settings_reset.uf2"

# ============================================
# Docker Build Targets
# ============================================

# Docker: Build both halves
docker-all:
	$(DOCKER_CMD) make all

# Docker: Setup workspace
docker-setup:
	$(DOCKER_CMD) make setup

# Docker: Build left half
docker-left:
	$(DOCKER_CMD) make left

# Docker: Build right half
docker-right:
	$(DOCKER_CMD) make right

# Docker: Clean build
docker-clean:
	$(DOCKER_CMD) make clean

# Docker: Build settings reset
docker-settings-reset:
	$(DOCKER_CMD) make settings-reset

# Docker: Build OTA variant
docker-ota:
	$(DOCKER_CMD) make ota

ota: left-ota right-ota

left-ota:
	west zephyr-export
	west build -d build/left_ota -s zmk/app -b nice_nano_v2 -- -DSHIELD=cck_ball_ota_left -DZMK_CONFIG="$(CURDIR)/config"

right-ota:
	west zephyr-export
	west build -d build/right_ota -s zmk/app -b nice_nano_v2 -- -DSHIELD=cck_ball_ota_right -DZMK_CONFIG="$(CURDIR)/config"

# Docker: Build MCUboot bootloader
docker-mcuboot:
	$(DOCKER_CMD) bash scripts/build_mcuboot.sh

# Docker: Build everything for OTA (MCUboot + both halves)
docker-ota-all: docker-mcuboot docker-ota

# Help
help:
	@echo "CCK-BALL ZMK Firmware Build"
	@echo ""
	@echo "=== Docker Builds (Recommended) ==="
	@echo "Usage: make docker-[target]"
	@echo ""
	@echo "  docker-all            - Build both halves using Docker"
	@echo "  docker-setup          - Initialize workspace using Docker"
	@echo "  docker-left           - Build left half using Docker"
	@echo "  docker-right          - Build right half using Docker (with ZMK Studio)"
	@echo "  docker-settings-reset - Build settings reset using Docker"
	@echo "  docker-clean          - Clean build directory using Docker"
	@echo ""
	@echo "=== Native Builds (requires west installed) ==="
	@echo "Usage: make [target]"
	@echo ""
	@echo "  all     - Build both left and right halves (default)"
	@echo "  setup   - Initialize workspace (init + update + export)"
	@echo "  init    - Initialize west workspace"
	@echo "  update  - Update west modules"
	@echo "  export  - Export Zephyr"
	@echo "  deps    - Install development dependencies"
	@echo "  left            - Build left half only"
	@echo "  right           - Build right half only (with ZMK Studio)"
	@echo "  settings-reset  - Build settings reset firmware"
	@echo "  clean           - Clean build directory"
	@echo "  help            - Show this help message"

