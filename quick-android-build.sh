#!/bin/bash
# Simple Android build script - builds all architectures with minimal setup
# Usage: ./quick-android-build.sh [debug|release]

set -e

BUILD_TYPE=${1:-debug}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
RUST_DIR="$PROJECT_ROOT/rust"

echo "🚀 KMagick Quick Android Build"
echo "Build type: $BUILD_TYPE"

# Check if we're in the right directory structure
if [ ! -f "$RUST_DIR/Cargo.toml" ]; then
    echo "❌ This script must be run from the project root directory"
    echo "Expected to find: $RUST_DIR/Cargo.toml"
    exit 1
fi

# Check for Android NDK
if [ -z "$ANDROID_NDK_HOME" ] && [ -z "$NDK_HOME" ]; then
    echo "❌ Android NDK not found"
    echo "Please set ANDROID_NDK_HOME or NDK_HOME environment variable"
    exit 1
fi

NDK_PATH="${ANDROID_NDK_HOME:-$NDK_HOME}"
echo "Using NDK: $NDK_PATH"

# Check for ImageMagick (try to auto-detect)
if [ -z "$IMAGE_MAGICK_DIR" ]; then
    # Look for ImageMagick directory
    IM_DIRS=("$PROJECT_ROOT"/ImageMagick-* "$PROJECT_ROOT/../ImageMagick-*")
    for dir in "${IM_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            export IMAGE_MAGICK_DIR="$dir"
            echo "Found ImageMagick at: $IMAGE_MAGICK_DIR"
            break
        fi
    done
    
    if [ -z "$IMAGE_MAGICK_DIR" ]; then
        echo "❌ ImageMagick directory not found"
        echo "Please set IMAGE_MAGICK_DIR or ensure ImageMagick-* directory exists"
        exit 1
    fi
fi

# Setup other ImageMagick environment variables
if [ -z "$IMAGE_MAGICK_LIB_DIRS" ]; then
    # Look for jniLibs
    JNI_DIRS=("$PROJECT_ROOT/jniLibs" "$PROJECT_ROOT/../jniLibs")
    for dir in "${JNI_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            export IMAGE_MAGICK_LIB_DIRS="$dir"
            echo "Found jniLibs at: $IMAGE_MAGICK_LIB_DIRS"
            break
        fi
    done
fi

# Set default values if not found
export IMAGE_MAGICK_LIBS="${IMAGE_MAGICK_LIBS:-magickwand-7:magickcore-7}"
export IMAGE_MAGICK_INCLUDE_DIRS="${IMAGE_MAGICK_INCLUDE_DIRS:-$IMAGE_MAGICK_DIR}"
export IMAGE_MAGICK_STATIC="${IMAGE_MAGICK_STATIC:-0}"

echo "Environment configured:"
echo "  IMAGE_MAGICK_DIR: $IMAGE_MAGICK_DIR"
echo "  IMAGE_MAGICK_LIB_DIRS: $IMAGE_MAGICK_LIB_DIRS"
echo "  IMAGE_MAGICK_LIBS: $IMAGE_MAGICK_LIBS"

# Android targets
TARGETS=(
    "aarch64-linux-android"
    "armv7-linux-androideabi"
    "i686-linux-android"
    "x86_64-linux-android"
)

# Install targets
echo "📦 Installing Android Rust targets..."
for target in "${TARGETS[@]}"; do
    rustup target add "$target" || true
done

# Build for each target
cd "$RUST_DIR"
OUTPUT_DIR="$PROJECT_ROOT/android/libs"
mkdir -p "$OUTPUT_DIR"

echo "🔨 Building for Android..."

for target in "${TARGETS[@]}"; do
    echo ""
    echo "Building $target..."
    
    # Determine Android architecture name
    case $target in
        aarch64-linux-android)
            android_arch="arm64-v8a"
            ;;
        armv7-linux-androideabi)
            android_arch="armeabi-v7a"
            ;;
        i686-linux-android)
            android_arch="x86"
            ;;
        x86_64-linux-android)
            android_arch="x86_64"
            ;;
    esac
    
    # Build command
    if [ "$BUILD_TYPE" = "release" ]; then
        cargo build --target "$target" --release -p kmagick-rs
        LIB_PATH="target/$target/release/libkmagick.so"
    else
        cargo build --target "$target" -p kmagick-rs
        LIB_PATH="target/$target/debug/libkmagick.so"
    fi
    
    # Copy to output directory
    if [ -f "$LIB_PATH" ]; then
        ARCH_DIR="$OUTPUT_DIR/$android_arch"
        mkdir -p "$ARCH_DIR"
        cp "$LIB_PATH" "$ARCH_DIR/"
        
        # Get file size
        size=$(stat -c%s "$ARCH_DIR/libkmagick.so" 2>/dev/null || stat -f%z "$ARCH_DIR/libkmagick.so")
        size_kb=$((size / 1024))
        
        echo "✅ Built $android_arch (${size_kb}KB)"
    else
        echo "❌ Failed to build $target"
        exit 1
    fi
done

echo ""
echo "🎉 Android build completed successfully!"
echo "📁 Libraries available at: $OUTPUT_DIR"
echo ""
echo "Directory structure:"
find "$OUTPUT_DIR" -name "*.so" -type f | sort | while read -r file; do
    size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file")
    size_kb=$((size / 1024))
    echo "  $file (${size_kb}KB)"
done

echo ""
echo "🔧 Next steps:"
echo "1. Copy the libs directory to your Android project's src/main/jniLibs/"
echo "2. Ensure you have the ImageMagick shared libraries in the same directories"
echo "3. Add kmagick JAR and objenosis dependencies to your Android project"