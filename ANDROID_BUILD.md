# Android Build Configuration for KMagick

This document describes the Android build configuration and ImageMagick settings implemented for the KMagick project.

## Overview

The following components have been configured to support Android cross-compilation with proper ImageMagick integration:

## Files Modified/Created

### 1. `rust/kmagick/magick-config.h`
- **New file** containing ImageMagick configuration defines
- Sets `MAGICKCORE_QUANTUM_DEPTH=16` (configurable)
- Sets `MAGICKCORE_HDRI_ENABLE=1` (High Dynamic Range Imaging)
- Configures additional ImageMagick delegates (JPEG, PNG, TIFF, WEBP, ZLIB, BZLIB)
- Enables thread safety

### 2. `rust/kmagick/build.rs`
- **Enhanced** with proper error handling using `Result<(), Box<dyn std::error::Error>>`
- Added Android NDK path auto-detection and configuration
- Implements architecture-specific compiler flags for Android targets:
  - `aarch64-linux-android`: ARM64 with NEON optimizations
  - `armv7-linux-androideabi`: ARMv7 with NEON and soft-float
  - `i686-linux-android`: x86 with SSE optimizations
  - `x86_64-linux-android`: x86_64 with SSE4.2 and POPCNT
- Configures PATH for NDK toolchain access
- Includes magick-config.h in compiler include paths

### 3. `rust/.cargo/config.toml`
- **Updated** with proper NDK toolchain paths for all Android targets
- Configured linker and archiver tools using absolute paths
- Added architecture-specific `rustflags` for optimization
- Set up environment variables for NDK configuration
- Configured ImageMagick environment variables for Android builds

### 4. `rust/kmagick/Cargo.toml`
- **Enhanced** with Android-specific features and dependencies
- Added `imagemagick-static` and `imagemagick-dynamic` features
- Configured `android_logger` for Android-specific logging
- Maintained compatibility with existing dependencies

### 5. `rust/build-android.ps1`
- **Updated** to properly set `ANDROID_NDK_ROOT` environment variable
- Enhanced NDK path detection with fallback options
- Improved integration with new build configuration

## Android Build Configuration Details

### NDK Integration
- **Default NDK Path**: `/usr/local/lib/android/sdk/ndk/27.3.13750724`
- **Auto-detection**: Falls back to `ANDROID_NDK_HOME`, `NDK_HOME` environment variables
- **Toolchain**: Uses LLVM/Clang toolchain from NDK
- **API Level**: Targets Android API 23 (Android 6.0) by default

### ImageMagick Settings
- **Quantum Depth**: 16-bit (configurable via `MAGICKCORE_QUANTUM_DEPTH`)
- **HDRI**: Enabled (High Dynamic Range Imaging)
- **Static Linking**: Preferred for Android deployment
- **Thread Safety**: Enabled for multi-threaded operations

### Supported Android Architectures
1. **aarch64-linux-android** (ARM64)
   - Target: Modern 64-bit ARM devices
   - Optimizations: NEON SIMD instructions

2. **armv7-linux-androideabi** (ARM32)
   - Target: Older 32-bit ARM devices
   - Optimizations: NEON SIMD, soft-float ABI

3. **i686-linux-android** (x86)
   - Target: x86 Android devices/emulators
   - Optimizations: SSE3, Intel-specific tuning

4. **x86_64-linux-android** (x86_64)
   - Target: 64-bit x86 Android devices/emulators
   - Optimizations: SSE4.2, POPCNT

## Usage

### Prerequisites
1. Android NDK installed (version 27.3.13750724 or compatible)
2. Rust with Android targets installed:
   ```bash
   rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
   ```

### Building for Android

#### Using PowerShell Script (Recommended)
```powershell
# Build for ARM64 (default)
./rust/build-android.ps1

# Build for specific architecture
./rust/build-android.ps1 -arch aarch64  # ARM64
./rust/build-android.ps1 -arch arm      # ARM32
./rust/build-android.ps1 -arch x86      # x86
./rust/build-android.ps1 -arch x86_64   # x86_64

# Release build
./rust/build-android.ps1 -arch aarch64 -release
```

#### Using Cargo Directly
```bash
# Set NDK path
export ANDROID_NDK_ROOT=/path/to/ndk

# Build for specific target
cd rust
cargo build --target aarch64-linux-android --release -p kmagick-rs
```

## Validation

Run the configuration test script to verify setup:

```bash
./test-android-config.sh
```

This script validates:
- NDK availability and toolchain access
- magick-config.h correctness
- Cargo configuration validity
- Rust target installation
- Build script compilation

## Troubleshooting

### Common Issues

1. **NDK Not Found**
   - Ensure `ANDROID_NDK_ROOT` environment variable is set
   - Verify NDK installation path
   - Check NDK version compatibility

2. **Linker Errors**
   - Verify `.cargo/config.toml` paths are correct for your NDK version
   - Ensure target architecture is properly specified

3. **ImageMagick Configuration**
   - Check that ImageMagick libraries are available for the target platform
   - Verify `IMAGE_MAGICK_*` environment variables in build scripts

4. **Cross-compilation Issues**
   - Ensure proper NDK toolchain is in PATH
   - Verify architecture-specific compiler flags

## Environment Variables

The following environment variables affect the build:

- `ANDROID_NDK_ROOT`: Path to Android NDK
- `ANDROID_NDK_HOME`: Alternative NDK path variable
- `NDK_HOME`: Legacy NDK path variable
- `ANDROID_API`: Target Android API level (default: 23)
- `IMAGE_MAGICK_STATIC`: Force static linking (default: 1 for Android)
- `IMAGE_MAGICK_LIB_DIRS`: ImageMagick library directories
- `IMAGE_MAGICK_INCLUDE_DIRS`: ImageMagick include directories

## Features

- **Static Linking**: Optimized for Android deployment
- **Error Handling**: Comprehensive error reporting in build scripts
- **Multi-Architecture**: Support for all common Android architectures
- **Optimized Builds**: Architecture-specific compiler optimizations
- **Flexible Configuration**: Customizable ImageMagick settings