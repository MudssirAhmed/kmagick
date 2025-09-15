# Android build script for kmagick
# Run this in PowerShell 7 or later for cross-platform support
# Supports: arm64-v8a (aarch64), armeabi-v7a (armv7), x86, x86_64
# Usage: .\build-android.ps1 -arch aarch64 [-release] [-expand]
#   -arch: aarch64 (default), armv7, x86, x86_64  
#   -release: Build in release mode
#   -expand: Use cargo expand instead of build
param([String]$arch="aarch64", [switch]$release, [switch]$expand) 

Write-Host "Building kmagick for Android architecture: $arch" -ForegroundColor Green

$sep = if ($IsWindows) { ";" } else { ":" }
$exe_ext = if ($IsWindows) { ".exe" } else { "" }
$cmd_ext = if ($IsWindows) { ".cmd" } else { "" }

$root = Resolve-Path -Path "$PSScriptRoot/../.."

# Check if Application.mk exists for static build configuration
$applicationMkPath = Join-Path $root "Application.mk"
if (Test-Path $applicationMkPath) {
    $content = Get-Content -Path $applicationMkPath -Raw
    $staticMatch = [regex]::Match($content, "STATIC_BUILD\s*:=\s*([^\s\r\n]+)")
    if ($staticMatch.Success) {
        $static = $staticMatch.Groups[1].Value
        if ($static -eq "true") {
            $static = "1"
        } else {
            $static = "0"
        }
    } else {
        $static = "0"
    }
} else {
    Write-Warning "Application.mk not found. Assuming dynamic linking."
    $static = "0"
}

# Find ImageMagick directory
$imdir = Get-ChildItem -Path $root -Directory -Name "ImageMagick-*" | Select-Object -First 1
if ($imdir) {
    $imdir = Join-Path $root $imdir
} else {
    Write-Warning "ImageMagick directory not found. Using default path."
    $imdir = Join-Path $root "ImageMagick"
}

$jnidir = Join-Path $root "jniLibs"
$includedir = $imdir
$imlibs = "magick-7"
$libdirs = ""

# Build library directories path
if (Test-Path $jnidir) {
    $dirs = Get-ChildItem -Directory -Path $jnidir
    foreach ($d in $dirs) {
        if ($libdirs.Length -eq 0) {
            $libdirs += "$d"
        } else {
            $libdirs += "$sep$d"
        }
    }
}

# Set architecture-specific values
switch ($arch) {
    "aarch64" {
        $includearch = "arm64"
        $target = "aarch64-linux-android"
        $ar_tool = "aarch64-linux-android-ar$exe_ext"
        $linker_tool = "aarch64-linux-android23-clang++$cmd_ext"
    }
    "armv7" {
        $includearch = "arm"
        $target = "armv7-linux-androideabi"
        $ar_tool = "arm-linux-androideabi-ar$exe_ext"
        $linker_tool = "armv7a-linux-androideabi23-clang++$cmd_ext"
    }
    "x86" {
        $includearch = "x86"
        $target = "i686-linux-android"
        $ar_tool = "i686-linux-android-ar$exe_ext"
        $linker_tool = "i686-linux-android23-clang++$cmd_ext"
    }
    "x86_64" {
        $includearch = "x86_64"
        $target = "x86_64-linux-android"
        $ar_tool = "x86_64-linux-android-ar$exe_ext"
        $linker_tool = "x86_64-linux-android23-clang++$cmd_ext"
    }
    default {
        Write-Error "Unsupported architecture: $arch. Supported: aarch64, armv7, x86, x86_64"
        exit 1
    }
}

# Set up environment variables
$env:IMAGE_MAGICK_DIR = $imdir
$env:IMAGE_MAGICK_LIBS = "magickwand-7$sep" + "magickcore-7"
$env:IMAGE_MAGICK_LIB_DIRS = $libdirs
$env:IMAGE_MAGICK_INCLUDE_DIRS = "$imdir$sep$imdir/configs/$includearch"
$env:IMAGE_MAGICK_STATIC = $static

Write-Host "Environment configuration:" -ForegroundColor Yellow
Write-Host "  TARGET: $target" -ForegroundColor Cyan
Write-Host "  IMAGE_MAGICK_DIR: $($env:IMAGE_MAGICK_DIR)" -ForegroundColor Cyan
Write-Host "  IMAGE_MAGICK_LIBS: $($env:IMAGE_MAGICK_LIBS)" -ForegroundColor Cyan
Write-Host "  IMAGE_MAGICK_LIB_DIRS: $($env:IMAGE_MAGICK_LIB_DIRS)" -ForegroundColor Cyan
Write-Host "  IMAGE_MAGICK_INCLUDE_DIRS: $($env:IMAGE_MAGICK_INCLUDE_DIRS)" -ForegroundColor Cyan
Write-Host "  IMAGE_MAGICK_STATIC: $($env:IMAGE_MAGICK_STATIC)" -ForegroundColor Cyan

# Check if target is installed
$installedTargets = & rustup target list --installed
if ($installedTargets -notcontains $target) {
    Write-Host "Installing Rust target: $target" -ForegroundColor Yellow
    & rustup target add $target
}

# Build the project
$cargoCommand = if ($expand) { "expand" } else { "build" }
$cargoArgs = @("$cargoCommand", "--color=always", "--target=$target", "-p", "kmagick-rs")

if ($release) {
    $cargoArgs += "--release"
    $buildMode = "release"
} else {
    $buildMode = "debug"
}

Write-Host "Running: cargo $($cargoArgs -join ' ')" -ForegroundColor Yellow
& cargo @cargoArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build completed successfully!" -ForegroundColor Green
    if (-not $expand) {
        Write-Host "Output location: target/$target/$buildMode/libkmagick.so" -ForegroundColor Cyan
    }
} else {
    Write-Error "Build failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
