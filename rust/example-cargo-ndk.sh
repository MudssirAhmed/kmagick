#!/bin/bash
# Example build script using cargo-ndk for kmagick
# This demonstrates the recommended modern approach for Android builds

set -e

print_info() {
    echo "==> $1"
}

print_info "kmagick Android Build Example using cargo-ndk"
print_info "=============================================="

# Check if cargo-ndk is installed
if ! command -v cargo-ndk >/dev/null 2>&1; then
    print_info "Installing cargo-ndk..."
    cargo install cargo-ndk
fi

print_info "Building kmagick for all Android architectures..."

# Note: This would normally require proper ImageMagick setup
# The environment variables would need to be set properly

print_info "Example 1: Build for all architectures (release mode)"
echo "cargo ndk -t armeabi-v7a -t arm64-v8a -t x86 -t x86_64 -- build --package kmagick-rs --release"

print_info "Example 2: Build for ARM64 only (debug mode)"  
echo "cargo ndk -t arm64-v8a -- build --package kmagick-rs"

print_info "Example 3: Build with custom features"
echo "cargo ndk -t arm64-v8a -- build --package kmagick-rs --features android --release"

print_info "Example 4: Build and install directly to device (if connected)"
echo "cargo ndk -t arm64-v8a -- install --package kmagick-rs --release"

print_info ""
print_info "Target Architecture Mapping:"
print_info "  armeabi-v7a  -> ARM 32-bit (older Android devices)"
print_info "  arm64-v8a    -> ARM 64-bit (modern Android devices)"  
print_info "  x86          -> x86 32-bit (emulators)"
print_info "  x86_64       -> x86 64-bit (modern emulators)"

print_info ""
print_info "Prerequisites:"
print_info "1. Android NDK installed and ANDROID_NDK_HOME set"
print_info "2. ImageMagick for Android libraries properly configured"
print_info "3. Rust Android targets installed (setup-android.sh handles this)"

print_info ""
print_info "For a complete setup, run: ./setup-android.sh"