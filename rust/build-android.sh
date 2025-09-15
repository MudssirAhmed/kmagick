#!/bin/bash

# Android build script for kmagick
# Supports: arm64-v8a (aarch64), armeabi-v7a (armv7), x86, x86_64
# Usage: ./build-android.sh [ARCH] [--release]
#   ARCH: aarch64 (default), armv7, x86, x86_64
#   --release: Build in release mode

set -e

# Default values
ARCH=${1:-aarch64}
BUILD_MODE="debug"
CARGO_FLAGS=""

# Parse arguments
for arg in "$@"; do
    case $arg in
        --release)
            BUILD_MODE="release"
            CARGO_FLAGS="--release"
            shift
            ;;
        aarch64|armv7|x86|x86_64)
            ARCH=$arg
            shift
            ;;
    esac
done

# Path separator (Unix)
SEP=":"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Building kmagick for Android architecture: $ARCH ($BUILD_MODE mode)"

# Check if Application.mk exists for static build configuration
if [[ -f "$ROOT_DIR/Application.mk" ]]; then
    STATIC_BUILD=$(grep -E "STATIC_BUILD\s*:=\s*([^\s]+)" "$ROOT_DIR/Application.mk" | sed -E 's/.*STATIC_BUILD\s*:=\s*([^\s]+).*/\1/')
    if [[ "$STATIC_BUILD" == "true" ]]; then
        STATIC="1"
    else
        STATIC="0"
    fi
else
    STATIC="0"
fi

# Find ImageMagick directory
IMDIR=$(find "$ROOT_DIR" -maxdepth 1 -name "ImageMagick-*" -type d | head -n 1)
if [[ -z "$IMDIR" ]]; then
    echo "Warning: ImageMagick directory not found. Make sure ImageMagick is properly set up."
    IMDIR="$ROOT_DIR/ImageMagick"
fi

JNIDIR="$ROOT_DIR/jniLibs"
IMLIBS="magick-7"
LIBDIRS=""

# Build library directories path
if [[ -d "$JNIDIR" ]]; then
    for dir in "$JNIDIR"/*; do
        if [[ -d "$dir" ]]; then
            if [[ -z "$LIBDIRS" ]]; then
                LIBDIRS="$dir"
            else
                LIBDIRS="$LIBDIRS$SEP$dir"
            fi
        fi
    done
fi

# Set architecture-specific values
case $ARCH in
    aarch64)
        INCLUDEARCH="arm64"
        TARGET="aarch64-linux-android"
        ;;
    armv7)
        INCLUDEARCH="arm"
        TARGET="armv7-linux-androideabi"
        ;;
    x86)
        INCLUDEARCH="x86"
        TARGET="i686-linux-android"
        ;;
    x86_64)
        INCLUDEARCH="x86_64"
        TARGET="x86_64-linux-android"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        echo "Supported architectures: aarch64, armv7, x86, x86_64"
        exit 1
        ;;
esac

# Set up environment variables for ImageMagick
export IMAGE_MAGICK_DIR="$IMDIR"
export IMAGE_MAGICK_LIBS="magickwand-7${SEP}magickcore-7"
export IMAGE_MAGICK_LIB_DIRS="$LIBDIRS"
export IMAGE_MAGICK_INCLUDE_DIRS="$IMDIR$SEP$IMDIR/configs/$INCLUDEARCH"
export IMAGE_MAGICK_STATIC="$STATIC"

echo "Environment configuration:"
echo "  TARGET: $TARGET"
echo "  IMAGE_MAGICK_DIR: $IMAGE_MAGICK_DIR"
echo "  IMAGE_MAGICK_LIBS: $IMAGE_MAGICK_LIBS"
echo "  IMAGE_MAGICK_LIB_DIRS: $IMAGE_MAGICK_LIB_DIRS"
echo "  IMAGE_MAGICK_INCLUDE_DIRS: $IMAGE_MAGICK_INCLUDE_DIRS"
echo "  IMAGE_MAGICK_STATIC: $IMAGE_MAGICK_STATIC"

# Check if target is installed
if ! rustup target list --installed | grep -q "$TARGET"; then
    echo "Installing Rust target: $TARGET"
    rustup target add "$TARGET"
fi

# Build the project
echo "Building kmagick for $TARGET..."
cargo build --color=always --target="$TARGET" -p kmagick-rs $CARGO_FLAGS

echo "Build completed successfully!"
echo "Output location: target/$TARGET/$BUILD_MODE/libkmagick.so"