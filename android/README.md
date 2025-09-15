# Android Build Guide for KMagick

This guide provides comprehensive instructions for building KMagick for Android using the Android NDK.

## Prerequisites

### 1. Install Required Tools

#### Rust
```bash
# Install Rust if not already installed
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Add Android targets
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add i686-linux-android
rustup target add x86_64-linux-android
```

#### Android NDK
1. Download Android NDK r22b from [Android Developer website](https://developer.android.com/ndk/downloads)
   - **Note**: NDK r22b is specifically recommended due to compatibility issues with newer versions
2. Extract to a directory (e.g., `/opt/android-ndk-r22b` on Linux/macOS, `C:\Android\ndk\r22b` on Windows)
3. Set environment variables:

**Linux/macOS:**
```bash
export ANDROID_NDK_HOME=/opt/android-ndk-r22b
export NDK_HOME=$ANDROID_NDK_HOME
export PATH=$PATH:$ANDROID_NDK_HOME
export CLANG_PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/clang
```

**Windows:**
```powershell
$ndkRoot = "C:\Android\ndk\r22b"
$env:ANDROID_NDK_HOME = $ndkRoot
$env:NDK_HOME = $ndkRoot
$env:PATH = "$env:PATH;$ndkRoot"
$env:CLANG_PATH = "$ndkRoot\toolchains\llvm\prebuilt\windows-x86_64\bin\clang.exe"
```

### 2. ImageMagick Setup

#### Download Android ImageMagick
1. Download the [Android-ImageMagick7](https://github.com/MolotovCherry/Android-ImageMagick7) repository
2. Place this kmagick repository inside the Android-ImageMagick7 directory
3. Download the latest Android ImageMagick shared libraries from the [releases page](https://github.com/MolotovCherry/Android-ImageMagick7/releases)
4. Create a `jniLibs` folder in the Android-ImageMagick7 root directory
5. Extract shared libraries to the jniLibs folder with the following structure:
```
Android-ImageMagick7/
├── jniLibs/
│   ├── arm64-v8a/
│   │   ├── libMagickCore-7.Q16HDRI.so
│   │   └── libMagickWand-7.Q16HDRI.so
│   ├── armeabi-v7a/
│   │   ├── libMagickCore-7.Q16HDRI.so
│   │   └── libMagickWand-7.Q16HDRI.so
│   ├── x86/
│   │   ├── libMagickCore-7.Q16HDRI.so
│   │   └── libMagickWand-7.Q16HDRI.so
│   └── x86_64/
│       ├── libMagickCore-7.Q16HDRI.so
│       └── libMagickWand-7.Q16HDRI.so
└── kmagick/  # This repository
```

## Building

### Method 1: Using the Enhanced PowerShell Script (Recommended)

The enhanced build script provides comprehensive build options:

```powershell
# Build for single architecture (debug)
.\rust\build-android-enhanced.ps1 -arch aarch64

# Build for single architecture (release)
.\rust\build-android-enhanced.ps1 -arch aarch64 -release

# Build for all architectures
.\rust\build-android-enhanced.ps1 -all -release

# Clean build
.\rust\build-android-enhanced.ps1 -all -release -clean

# Verbose output
.\rust\build-android-enhanced.ps1 -arch aarch64 -verbose
```

**Supported architectures:**
- `aarch64` → `aarch64-linux-android` (arm64-v8a)
- `arm` → `armv7-linux-androideabi` (armeabi-v7a)
- `x86` → `i686-linux-android` (x86)
- `x86_64` → `x86_64-linux-android` (x86_64)

### Method 2: Using the Bash Script (Linux/macOS)

```bash
# Make the script executable
chmod +x android/build-all-targets.sh

# Build debug version
./android/build-all-targets.sh debug

# Build release version
./android/build-all-targets.sh release
```

### Method 3: Using the Original PowerShell Script

```powershell
# Build for aarch64 (debug)
.\rust\build-android.ps1

# Build for aarch64 (release)
.\rust\build-android.ps1 -release

# Build for different architecture
.\rust\build-android.ps1 -arch arm -release
```

### Method 4: Manual Cargo Build

For direct control over the build process:

```bash
# Set environment variables (adjust paths as needed)
export ANDROID_NDK_HOME=/path/to/android-ndk-r22b
export IMAGE_MAGICK_DIR=/path/to/ImageMagick-7.x.x
export IMAGE_MAGICK_LIBS="magickwand-7:magickcore-7"
export IMAGE_MAGICK_LIB_DIRS="/path/to/jniLibs/arm64-v8a"
export IMAGE_MAGICK_INCLUDE_DIRS="/path/to/ImageMagick-7.x.x:/path/to/ImageMagick-7.x.x/configs/arm64"
export IMAGE_MAGICK_STATIC=0

# Build for specific target
cd rust
cargo build --target aarch64-linux-android --release -p kmagick-rs
```

## Output

After a successful build, you'll find the compiled libraries in:
- **Enhanced script**: `android/libs/`
- **Bash script**: `android/libs/`
- **Manual build**: `rust/target/{target}/release/`

The directory structure will be:
```
android/libs/
├── arm64-v8a/
│   └── libkmagick.so
├── armeabi-v7a/
│   └── libkmagick.so
├── x86/
│   └── libkmagick.so
└── x86_64/
    └── libkmagick.so
```

## Integration with Android Projects

### 1. Copy Libraries
Copy the generated libraries to your Android project's `src/main/jniLibs/` directory:

```bash
cp -r android/libs/* your-android-project/app/src/main/jniLibs/
```

### 2. Add Gradle Dependencies
In your Android app's `build.gradle`:

```gradle
android {
    compileSdk 34
    
    defaultConfig {
        minSdk 23
        targetSdk 34
        
        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64'
        }
    }
    
    packagingOptions {
        jniLibs {
            keepDebugSymbols += ['**/*.so']
        }
    }
}

dependencies {
    implementation 'org.objenesis:objenesis:3.2'  // Required for kmagick
    // Add kmagick JAR dependency
}
```

### 3. CMake Integration (Optional)
If using CMake in your Android project, you can use the provided `android/CMakeLists.txt`:

```cmake
# In your app's CMakeLists.txt
add_subdirectory(path/to/kmagick/android)
target_link_libraries(your-app kmagick-android)
```

## Troubleshooting

### Common Issues

1. **NDK not found**
   - Ensure `ANDROID_NDK_HOME` is set correctly
   - Verify NDK version is r22b (newer versions may have issues)

2. **ImageMagick libraries not found**
   - Check that jniLibs directory exists and contains the correct architecture libraries
   - Verify `IMAGE_MAGICK_DIR` points to the correct ImageMagick directory

3. **Linker errors**
   - Ensure all ImageMagick dependencies are present in jniLibs
   - Check that target architecture matches between Rust target and NDK arch

4. **Build fails with "Package MagickWand was not found"**
   - This is expected in a clean environment without ImageMagick installed system-wide
   - The build script should handle this by setting the appropriate environment variables

### Build Verification

To verify your build:
```bash
# Check library architecture
file android/libs/arm64-v8a/libkmagick.so

# Check library dependencies
readelf -d android/libs/arm64-v8a/libkmagick.so

# Check exported symbols
nm -D android/libs/arm64-v8a/libkmagick.so | grep Java_
```

### Performance Optimization

For production builds:
1. Use release mode (`-release` flag)
2. Consider using `opt-level = "s"` for smaller library size
3. Strip debug symbols (automatically done in release builds)

### Size Optimization

To reduce library size:
1. Use release builds
2. Consider removing unused ImageMagick features
3. Use `strip` command to remove additional debug information if needed

## Testing

Test your built library with the provided Android example:
1. Copy built libraries to `example/android-setup/app/src/main/jniLibs/`
2. Copy kmagick JAR to `example/android-setup/app/libs/`
3. Open the project in Android Studio
4. Build and run on device/emulator