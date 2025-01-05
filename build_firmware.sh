#!/bin/bash

# Build firmware for Glove80 keyboard
# Usage: ./build_firmware.sh [branch]
# Arguments:
#   branch - Git branch to use (defaults to 'main')

set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DIST_DIR="${SCRIPT_DIR}/dist"
readonly FIRMWARE_DIR="${SCRIPT_DIR}/firmware"
readonly CONFIG_DIR="${FIRMWARE_DIR}/config"
readonly DOCKER_IMAGE="glove80-zmk-config-docker"
readonly OUTPUT_KEYMAP="${CONFIG_DIR}/glove80.keymap"
readonly OUTPUT_FIRMWARE="glove80.uf2"

# Helper functions
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
error() { log "ERROR: $*" >&2; }
die() { error "$*"; exit 1; }

check_prerequisites() {
    local -r missing=()
    for cmd in rake docker; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Missing required commands: ${missing[*]}"
    fi
}

create_keymap() {
    log "Generating keymap file..."
    
    sed -e '/\/\* Custom Device-tree \*\//,/\/\* Glove80 system behavior & macros \*\// {
        /\/\* Custom Device-tree \*\// {
            p
            r '"${SCRIPT_DIR}"'/device.dtsi
        }
        /\/\* Glove80 system behavior & macros \*\//p
        d
    }' -e '/\/\* Custom Defined Behaviors \*\//,/\/\* Automatically generated macro definitions \*\// {
        /\/\* Custom Defined Behaviors \*\// {
            p
            a\
/ {
            r '"${SCRIPT_DIR}"'/keymap.dtsi
            a\
};
        }
        /\/\* Automatically generated macro definitions \*\//p
        d
    }' "${SCRIPT_DIR}/keymap.zmk" > "$OUTPUT_KEYMAP" || die "Failed to generate keymap"
    
    log "Keymap created at: $OUTPUT_KEYMAP"
}

build_docker_image() {
    log "Building Docker image..."
    docker build -f "${FIRMWARE_DIR}/Dockerfile" -t "$DOCKER_IMAGE" "$SCRIPT_DIR" \
        || die "Docker build failed"
}

build_firmware() {
    local branch="$1"
    
    log "Building firmware using branch: $branch"
    
    # Create output directories
    mkdir -p "$DIST_DIR" "$CONFIG_DIR"
    
    # Run initial build
    log "Running rake build..."
    "${SCRIPT_DIR}/rake" -B || die "Rake build failed"
    
    # Create keymap file
    create_keymap
    
    # Copy configuration
    cp -f "${SCRIPT_DIR}/keymap.json" "$CONFIG_DIR/" || die "Failed to copy keymap.json"
    
    # Build and run Docker
    build_docker_image
    
    log "Running Docker build..."
    docker run --rm \
        -v "${SCRIPT_DIR}:/firmware" \
        -e UID="$(id -u)" \
        -e GID="$(id -g)" \
        -e BRANCH="$branch" \
        "$DOCKER_IMAGE" || die "Docker run failed"
    
    # Move firmware to dist directory
    if [[ -f "${SCRIPT_DIR}/${OUTPUT_FIRMWARE}" ]]; then
        mv -f "${SCRIPT_DIR}/${OUTPUT_FIRMWARE}" "$DIST_DIR/" || die "Failed to move firmware file"
        log "Firmware built successfully: ${DIST_DIR}/${OUTPUT_FIRMWARE}"
    else
        die "Firmware file not found after build"
    fi
}

main() {
    # Check prerequisites
    check_prerequisites
    
    # Parse arguments
    local branch="${1:-main}"
    
    # Build firmware
    build_firmware "$branch"
}

# Run main if script is not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
