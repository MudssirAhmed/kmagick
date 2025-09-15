#!/bin/bash

# Test script to validate Android build configuration
# This script tests that the NDK tools, config files, and build system are properly set up

set -e

echo "=========================================="
echo "Testing kmagick Android Build Configuration"
echo "=========================================="

# Test 1: Check NDK availability
echo "1. Testing NDK availability..."
NDK_ROOT=${ANDROID_NDK_ROOT:-"/usr/local/lib/android/sdk/ndk/27.3.13750724"}
if [ -d "$NDK_ROOT" ]; then
    echo "✓ NDK found at: $NDK_ROOT"
else
    echo "✗ NDK not found at: $NDK_ROOT"
    exit 1
fi

# Test 2: Check NDK toolchain
echo
echo "2. Testing NDK toolchain..."
CLANG_PATH="$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android23-clang++"
if [ -x "$CLANG_PATH" ]; then
    echo "✓ NDK compiler found and executable"
    echo "   Version: $($CLANG_PATH --version | head -n1)"
else
    echo "✗ NDK compiler not found at: $CLANG_PATH"
    exit 1
fi

# Test 3: Check magick-config.h
echo
echo "3. Testing magick-config.h..."
if [ -f "rust/kmagick/magick-config.h" ]; then
    echo "✓ magick-config.h exists"
    # Check if it defines the required macros
    if gcc -E -dM rust/kmagick/magick-config.h | grep -q "MAGICKCORE_QUANTUM_DEPTH.*16"; then
        echo "✓ MAGICKCORE_QUANTUM_DEPTH is set to 16"
    else
        echo "✗ MAGICKCORE_QUANTUM_DEPTH not properly defined"
        exit 1
    fi
    
    if gcc -E -dM rust/kmagick/magick-config.h | grep -q "MAGICKCORE_HDRI_ENABLE.*1"; then
        echo "✓ MAGICKCORE_HDRI_ENABLE is set to 1"
    else
        echo "✗ MAGICKCORE_HDRI_ENABLE not properly defined"
        exit 1
    fi
else
    echo "✗ magick-config.h not found"
    exit 1
fi

# Test 4: Check .cargo/config.toml
echo
echo "4. Testing .cargo/config.toml..."
if [ -f "rust/.cargo/config.toml" ]; then
    echo "✓ .cargo/config.toml exists"
    
    # Check if Android targets are configured
    for target in "aarch64-linux-android" "armv7-linux-androideabi" "i686-linux-android" "x86_64-linux-android"; do
        if grep -q "\[target\.$target\]" rust/.cargo/config.toml; then
            echo "✓ $target configuration found"
        else
            echo "✗ $target configuration missing"
            exit 1
        fi
    done
else
    echo "✗ .cargo/config.toml not found"
    exit 1
fi

# Test 5: Check Cargo.toml features
echo
echo "5. Testing Cargo.toml features..."
if [ -f "rust/kmagick/Cargo.toml" ]; then
    echo "✓ Cargo.toml exists"
    
    if grep -q "android_logger" rust/kmagick/Cargo.toml; then
        echo "✓ Android-specific dependencies found"
    else
        echo "✗ Android-specific dependencies missing"
        exit 1
    fi
    
    if grep -q "imagemagick-static" rust/kmagick/Cargo.toml; then
        echo "✓ ImageMagick static linking feature found"
    else
        echo "✗ ImageMagick static linking feature missing"
        exit 1
    fi
else
    echo "✗ Cargo.toml not found"
    exit 1
fi

# Test 6: Check Rust targets are installed
echo
echo "6. Testing Rust Android targets..."
cd rust  # Change to rust directory for rustup commands
for target in "aarch64-linux-android" "armv7-linux-androideabi" "i686-linux-android" "x86_64-linux-android"; do
    if rustup target list --installed | grep -q "$target"; then
        echo "✓ $target Rust target is installed"
    else
        echo "! $target Rust target not installed (this is optional for configuration testing)"
    fi
done
cd ..  # Return to root directory

# Test 7: Test build.rs compilation
echo
echo "7. Testing build.rs compilation..."
cd rust/kmagick
if rustc --edition=2021 build.rs --extern std -o /tmp/test-build-script 2>/dev/null; then
    echo "✓ build.rs compiles successfully"
    rm -f /tmp/test-build-script
else
    echo "✗ build.rs compilation failed"
    exit 1
fi
cd ../..

echo
echo "=========================================="
echo "✓ All Android build configuration tests passed!"
echo "=========================================="
echo
echo "Configuration Summary:"
echo "- NDK: $NDK_ROOT"
echo "- ImageMagick Quantum Depth: 16"
echo "- ImageMagick HDRI: Enabled"
echo "- Android Targets: aarch64, armv7, i686, x86_64"
echo "- Static Linking: Configured"
echo
echo "The Android build system is properly configured and ready for use."