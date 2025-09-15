#!/bin/bash
set -e

# Android NDK build script for all architectures
# This script builds the kmagick library for all supported Android architectures

# Check if Android NDK is properly configured
if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "Error: ANDROID_NDK_HOME environment variable is not set"
    echo "Please set it to your Android NDK installation path"
    exit 1
fi

if [ -z "$IMAGE_MAGICK_DIR" ]; then
    echo "Error: IMAGE_MAGICK_DIR environment variable is not set"
    echo "Please set it to your ImageMagick installation path"
    exit 1
fi

# Build configuration
BUILD_TYPE=${1:-debug}  # debug or release
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
RUST_DIR="$SCRIPT_DIR/../rust"

echo "Building kmagick for Android with BUILD_TYPE=$BUILD_TYPE"
echo "Using NDK: $ANDROID_NDK_HOME"
echo "Using ImageMagick: $IMAGE_MAGICK_DIR"

# Android architectures and their corresponding Rust targets
declare -a ANDROID_ARCHS=(
    "arm64-v8a:aarch64-linux-android"
    "armeabi-v7a:armv7-linux-androideabi"
    "x86:i686-linux-android"
    "x86_64:x86_64-linux-android"
)

# Create output directory
OUTPUT_DIR="$SCRIPT_DIR/libs"
mkdir -p "$OUTPUT_DIR"

# Install Android targets if not already installed
echo "Installing Android Rust targets..."
for arch_mapping in "${ANDROID_ARCHS[@]}"; do
    IFS=':' read -ra ARCH_PARTS <<< "$arch_mapping"
    RUST_TARGET="${ARCH_PARTS[1]}"
    rustup target add "$RUST_TARGET" || true
done

# Build for each architecture
for arch_mapping in "${ANDROID_ARCHS[@]}"; do
    IFS=':' read -ra ARCH_PARTS <<< "$arch_mapping"
    ANDROID_ARCH="${ARCH_PARTS[0]}"
    RUST_TARGET="${ARCH_PARTS[1]}"
    
    echo ""
    echo "================================="
    echo "Building for $ANDROID_ARCH ($RUST_TARGET)"
    echo "================================="
    
    # Create output directory for this architecture
    ARCH_OUTPUT_DIR="$OUTPUT_DIR/$ANDROID_ARCH"
    mkdir -p "$ARCH_OUTPUT_DIR"
    
    # Build the library
    cd "$RUST_DIR"
    
    if [ "$BUILD_TYPE" = "release" ]; then
        cargo build --target="$RUST_TARGET" --release -p kmagick-rs
        
        # Copy the built library
        cp "target/$RUST_TARGET/release/libkmagick.so" "$ARCH_OUTPUT_DIR/"
        
        # Strip debug symbols for release builds
        if command -v "${RUST_TARGET}-strip" &> /dev/null; then
            "${RUST_TARGET}-strip" "$ARCH_OUTPUT_DIR/libkmagick.so"
        fi
    else
        cargo build --target="$RUST_TARGET" -p kmagick-rs
        
        # Copy the built library
        cp "target/$RUST_TARGET/debug/libkmagick.so" "$ARCH_OUTPUT_DIR/"
    fi
    
    echo "Built library for $ANDROID_ARCH at $ARCH_OUTPUT_DIR/libkmagick.so"
done

echo ""
echo "================================="
echo "Android build completed successfully!"
echo "Libraries are available in: $OUTPUT_DIR"
echo "================================="

# List all built libraries
find "$OUTPUT_DIR" -name "*.so" -type f | sort