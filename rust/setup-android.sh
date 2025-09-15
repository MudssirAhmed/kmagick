#!/bin/bash
# Android NDK setup and validation script for kmagick
# This script helps validate and setup the Android build environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_status "Validating Android build environment for kmagick..."

# Check Rust installation
if ! command_exists rustc; then
    print_error "Rust is not installed. Please install from https://rustup.rs/"
    exit 1
fi
print_status "✓ Rust found: $(rustc --version)"

# Check cargo
if ! command_exists cargo; then
    print_error "Cargo is not found. Please ensure Rust is properly installed."
    exit 1
fi
print_status "✓ Cargo found: $(cargo --version)"

# Check rustup
if ! command_exists rustup; then
    print_error "rustup is not found. Please install from https://rustup.rs/"
    exit 1
fi

# Android targets to check/install
ANDROID_TARGETS=(
    "aarch64-linux-android"
    "armv7-linux-androideabi" 
    "i686-linux-android"
    "x86_64-linux-android"
)

print_status "Checking Android targets..."
MISSING_TARGETS=()

for target in "${ANDROID_TARGETS[@]}"; do
    if rustup target list --installed | grep -q "$target"; then
        print_status "✓ $target is installed"
    else
        print_warning "✗ $target is not installed"
        MISSING_TARGETS+=("$target")
    fi
done

# Install missing targets
if [ ${#MISSING_TARGETS[@]} -gt 0 ]; then
    print_status "Installing missing Android targets..."
    for target in "${MISSING_TARGETS[@]}"; do
        print_status "Installing $target..."
        rustup target add "$target"
    done
else
    print_status "✓ All Android targets are installed"
fi

# Check NDK environment
if [ -z "$ANDROID_NDK_HOME" ] && [ -z "$NDK_HOME" ]; then
    print_error "Android NDK not found. Please set ANDROID_NDK_HOME or NDK_HOME environment variable."
    print_error "Example: export ANDROID_NDK_HOME=/path/to/android-ndk"
    exit 1
fi

NDK_PATH=${ANDROID_NDK_HOME:-$NDK_HOME}
print_status "✓ Android NDK found at: $NDK_PATH"

# Check NDK tools
NDK_TOOLS_PATH="$NDK_PATH/toolchains/llvm/prebuilt"
if [ -d "$NDK_TOOLS_PATH" ]; then
    # Detect host architecture
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        HOST_TAG="linux-x86_64"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        HOST_TAG="darwin-x86_64"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        HOST_TAG="windows-x86_64"
    else
        print_warning "Unknown host OS, assuming linux-x86_64"
        HOST_TAG="linux-x86_64"
    fi
    
    NDK_BIN_PATH="$NDK_TOOLS_PATH/$HOST_TAG/bin"
    if [ -d "$NDK_BIN_PATH" ]; then
        print_status "✓ NDK tools found at: $NDK_BIN_PATH"
    else
        print_error "NDK tools not found at expected path: $NDK_BIN_PATH"
        exit 1
    fi
else
    print_error "NDK toolchain not found at: $NDK_TOOLS_PATH"
    exit 1
fi

# Check for ImageMagick setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

IMDIR=$(find "$ROOT_DIR" -maxdepth 1 -name "ImageMagick-*" -type d | head -n 1)
if [ -n "$IMDIR" ]; then
    print_status "✓ ImageMagick directory found: $IMDIR"
else
    print_warning "ImageMagick directory not found in parent directory"
    print_warning "Please ensure the Android-ImageMagick project is properly set up"
fi

JNIDIR="$ROOT_DIR/jniLibs"
if [ -d "$JNIDIR" ]; then
    print_status "✓ JNI libs directory found: $JNIDIR"
    
    # Check architecture directories
    ARCH_DIRS=("arm64-v8a" "armeabi-v7a" "x86" "x86_64")
    for arch in "${ARCH_DIRS[@]}"; do
        if [ -d "$JNIDIR/$arch" ]; then
            lib_count=$(find "$JNIDIR/$arch" -name "*.so" | wc -l)
            if [ "$lib_count" -gt 0 ]; then
                print_status "✓ $arch: $lib_count shared libraries found"
            else
                print_warning "✗ $arch: No shared libraries found"
            fi
        else
            print_warning "✗ $arch: Directory not found"
        fi
    done
else
    print_warning "JNI libs directory not found: $JNIDIR"
    print_warning "Please ensure Android-ImageMagick shared libraries are properly placed"
fi

# Check for cargo-ndk
if command_exists cargo-ndk; then
    print_status "✓ cargo-ndk found: $(cargo-ndk --version)"
else
    print_warning "cargo-ndk not found. Consider installing it for easier builds:"
    print_warning "  cargo install cargo-ndk"
fi

print_status "Environment validation complete!"
print_status ""
print_status "You can now build kmagick for Android using:"
print_status "  ./build-android.sh aarch64 --release"
print_status "  or"
print_status "  cargo ndk -t arm64-v8a -- build --package kmagick-rs --release"