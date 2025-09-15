#!/bin/bash
# cargo-ndk wrapper script for kmagick Android builds
# This script simplifies building kmagick for Android using cargo-ndk

set -e

# Default values
BUILD_TYPE="debug"
ANDROID_API="23"
ARCHS="arm64-v8a,armeabi-v7a,x86,x86_64"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --release)
            BUILD_TYPE="release"
            shift
            ;;
        --api)
            ANDROID_API="$2"
            shift 2
            ;;
        --archs)
            ARCHS="$2"
            shift 2
            ;;
        --help)
            echo "cargo-ndk wrapper for kmagick Android builds"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --release           Build in release mode (default: debug)"
            echo "  --api <version>     Android API level (default: 23)"
            echo "  --archs <list>      Comma-separated list of architectures"
            echo "                      (default: arm64-v8a,armeabi-v7a,x86,x86_64)"
            echo "  --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --release"
            echo "  $0 --api 28 --archs arm64-v8a,armeabi-v7a"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "Building kmagick for Android with cargo-ndk"
echo "Build type: $BUILD_TYPE"
echo "Android API: $ANDROID_API"
echo "Architectures: $ARCHS"

# Check if cargo-ndk is installed
if ! command -v cargo-ndk &> /dev/null; then
    echo "cargo-ndk not found. Installing..."
    cargo install cargo-ndk
fi

# Check NDK environment
if [ -z "$ANDROID_NDK_HOME" ] && [ -z "$NDK_HOME" ]; then
    echo "Error: Neither ANDROID_NDK_HOME nor NDK_HOME is set"
    echo "Please set one of these environment variables to your Android NDK path"
    exit 1
fi

# Set NDK path
NDK_PATH="${ANDROID_NDK_HOME:-$NDK_HOME}"
echo "Using NDK: $NDK_PATH"

# Check if ImageMagick environment is set
if [ -z "$IMAGE_MAGICK_DIR" ]; then
    echo "Warning: IMAGE_MAGICK_DIR not set. Please ensure ImageMagick is configured."
fi

# Build command
CARGO_NDK_CMD="cargo ndk"
CARGO_NDK_CMD="$CARGO_NDK_CMD --platform $ANDROID_API"
CARGO_NDK_CMD="$CARGO_NDK_CMD --target $ARCHS"

if [ "$BUILD_TYPE" = "release" ]; then
    CARGO_NDK_CMD="$CARGO_NDK_CMD -- build --release -p kmagick-rs"
else
    CARGO_NDK_CMD="$CARGO_NDK_CMD -- build -p kmagick-rs"
fi

echo "Running: $CARGO_NDK_CMD"

# Execute build
eval $CARGO_NDK_CMD

# Check build results
echo ""
echo "Build completed! Checking results..."

# Create output directory
OUTPUT_DIR="../android/libs"
mkdir -p "$OUTPUT_DIR"

# Copy built libraries
IFS=',' read -ra ARCH_ARRAY <<< "$ARCHS"
for arch in "${ARCH_ARRAY[@]}"; do
    # Map Android arch to Rust target
    case $arch in
        arm64-v8a)
            rust_target="aarch64-linux-android"
            ;;
        armeabi-v7a)
            rust_target="armv7-linux-androideabi"
            ;;
        x86)
            rust_target="i686-linux-android"
            ;;
        x86_64)
            rust_target="x86_64-linux-android"
            ;;
        *)
            echo "Warning: Unknown architecture $arch"
            continue
            ;;
    esac
    
    src_path="target/$rust_target/$BUILD_TYPE/libkmagick.so"
    dst_dir="$OUTPUT_DIR/$arch"
    dst_path="$dst_dir/libkmagick.so"
    
    if [ -f "$src_path" ]; then
        mkdir -p "$dst_dir"
        cp "$src_path" "$dst_path"
        echo "✓ Copied $arch library to $dst_path"
        
        # Show file size
        size=$(stat -c%s "$dst_path" 2>/dev/null || stat -f%z "$dst_path")
        size_kb=$((size / 1024))
        echo "  Size: ${size_kb}KB"
    else
        echo "❌ Library not found for $arch at $src_path"
    fi
done

echo ""
echo "Android build completed successfully!"
echo "Libraries available in: $OUTPUT_DIR"