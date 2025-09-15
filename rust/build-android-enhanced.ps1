# Advanced Android build script for kmagick
# Supports multiple architectures and build types
# Usage: .\build-android-enhanced.ps1 [arch] [-release] [-all] [-clean]

param(
    [String]$arch = "aarch64",          # Target architecture
    [switch]$release,                   # Build in release mode
    [switch]$all,                       # Build all architectures
    [switch]$clean,                     # Clean build directory first
    [switch]$expand,                    # Use cargo expand for debugging
    [switch]$verbose                    # Verbose output
)

$ErrorActionPreference = "Stop"

# Path separator
$sep = if ($isWindows) { ";" } else { ":" }

# Get project root
$root = Resolve-Path -Path "$PSScriptRoot/../.."
$rustDir = "$PSScriptRoot"
$androidDir = "$root/android"

Write-Host "================================================" -ForegroundColor Green
Write-Host "KMagick Android Build Script" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Architecture mappings
$archMappings = @{
    "aarch64" = @{
        target = "aarch64-linux-android"
        ndk_arch = "arm64-v8a"
        include_arch = "arm64"
    }
    "arm" = @{
        target = "armv7-linux-androideabi"  
        ndk_arch = "armeabi-v7a"
        include_arch = "arm"
    }
    "x86" = @{
        target = "i686-linux-android"
        ndk_arch = "x86"
        include_arch = "x86"
    }
    "x86_64" = @{
        target = "x86_64-linux-android"
        ndk_arch = "x86_64"
        include_arch = "x86_64"
    }
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Yellow
    
    # Check for cargo
    if (!(Get-Command cargo -ErrorAction SilentlyContinue)) {
        throw "Cargo not found. Please install Rust."
    }
    
    # Check for Android NDK
    if (!$env:ANDROID_NDK_HOME -and !$env:NDK_HOME) {
        throw "Android NDK not configured. Please set ANDROID_NDK_HOME or NDK_HOME environment variable."
    }
    
    $ndkPath = if ($env:ANDROID_NDK_HOME) { $env:ANDROID_NDK_HOME } else { $env:NDK_HOME }
    if (!(Test-Path $ndkPath)) {
        throw "Android NDK path does not exist: $ndkPath"
    }
    
    # Check for ImageMagick
    $content = Get-Content -Path "$root/Application.mk" -ErrorAction SilentlyContinue
    if ($content) {
        $static = (Select-String -InputObject $content -Pattern "STATIC_BUILD\s+:=\s+([^\s]+)").Matches.Groups[1]
        $script:staticBuild = if ($static -eq "true") { "1" } else { "0" }
    } else {
        Write-Warning "Application.mk not found. Using dynamic linking."
        $script:staticBuild = "0"
    }
    
    $imDirPattern = "$root/ImageMagick-*"
    $imDirs = Get-ChildItem -Path $root -Directory -Name "ImageMagick-*" -ErrorAction SilentlyContinue
    if ($imDirs.Count -eq 0) {
        throw "ImageMagick directory not found. Expected pattern: $imDirPattern"
    }
    $script:imdir = Resolve-Path -Path "$root/$($imDirs[0])"
    
    Write-Host "✓ Prerequisites check passed" -ForegroundColor Green
    Write-Host "  NDK: $ndkPath" -ForegroundColor Gray
    Write-Host "  ImageMagick: $($script:imdir)" -ForegroundColor Gray
    Write-Host "  Static build: $($script:staticBuild)" -ForegroundColor Gray
}

# Function to setup environment for architecture
function Set-ArchEnvironment {
    param($archConfig)
    
    $target = $archConfig.target
    $includeArch = $archConfig.include_arch
    
    # Setup library directories
    $jnidir = "$root/jniLibs"
    $libdirs = ""
    
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
    
    # Set environment variables
    $env:IMAGE_MAGICK_DIR = $script:imdir
    $env:IMAGE_MAGICK_LIBS = "magickwand-7${sep}magickcore-7"
    $env:IMAGE_MAGICK_LIB_DIRS = $libdirs
    $env:IMAGE_MAGICK_INCLUDE_DIRS = "$($script:imdir)$sep$($script:imdir)/configs/$includeArch"
    $env:IMAGE_MAGICK_STATIC = $script:staticBuild
    
    if ($verbose) {
        Write-Host "Environment for $target:" -ForegroundColor Cyan
        Write-Host "  IMAGE_MAGICK_DIR: $env:IMAGE_MAGICK_DIR" -ForegroundColor Gray
        Write-Host "  IMAGE_MAGICK_LIBS: $env:IMAGE_MAGICK_LIBS" -ForegroundColor Gray
        Write-Host "  IMAGE_MAGICK_LIB_DIRS: $env:IMAGE_MAGICK_LIB_DIRS" -ForegroundColor Gray
        Write-Host "  IMAGE_MAGICK_INCLUDE_DIRS: $env:IMAGE_MAGICK_INCLUDE_DIRS" -ForegroundColor Gray
        Write-Host "  IMAGE_MAGICK_STATIC: $env:IMAGE_MAGICK_STATIC" -ForegroundColor Gray
    }
}

# Function to build for architecture
function Build-Architecture {
    param($archName, $archConfig)
    
    $target = $archConfig.target
    $ndkArch = $archConfig.ndk_arch
    
    Write-Host ""
    Write-Host "=================================" -ForegroundColor Blue
    Write-Host "Building for $archName ($target)" -ForegroundColor Blue
    Write-Host "NDK Architecture: $ndkArch" -ForegroundColor Blue
    Write-Host "=================================" -ForegroundColor Blue
    
    Set-ArchEnvironment $archConfig
    
    # Install target if not present
    Write-Host "Installing Rust target: $target" -ForegroundColor Yellow
    rustup target add $target
    
    # Build command
    $buildArgs = @(
        "build"
        "--color=always"
        "--target=$target"
        "-p"
        "kmagick-rs"
    )
    
    if ($release) {
        $buildArgs += "--release"
        $buildDir = "release"
    } else {
        $buildDir = "debug"
    }
    
    if ($verbose) {
        $buildArgs += "--verbose"
    }
    
    try {
        if ($expand) {
            Write-Host "Running cargo expand for target $target" -ForegroundColor Yellow
            $expandArgs = $buildArgs.Clone()
            $expandArgs[0] = "expand"
            & cargo @expandArgs
        } else {
            Write-Host "Building target $target..." -ForegroundColor Yellow
            & cargo @buildArgs
            
            if ($LASTEXITCODE -eq 0) {
                # Copy built library to android output directory
                $outputDir = "$androidDir/libs/$ndkArch"
                New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
                
                $srcPath = "$rustDir/target/$target/$buildDir/libkmagick.so"
                $dstPath = "$outputDir/libkmagick.so"
                
                if (Test-Path $srcPath) {
                    Copy-Item $srcPath $dstPath -Force
                    Write-Host "✓ Library copied to: $dstPath" -ForegroundColor Green
                    
                    # Show file size
                    $size = (Get-Item $dstPath).Length
                    $sizeKB = [math]::Round($size / 1KB, 2)
                    Write-Host "  Size: ${sizeKB} KB" -ForegroundColor Gray
                } else {
                    Write-Warning "Built library not found at: $srcPath"
                }
            }
        }
    } catch {
        Write-Error "Build failed for $archName ($target): $_"
        throw
    }
}

# Main execution
try {
    Test-Prerequisites
    
    if ($clean) {
        Write-Host "Cleaning build directories..." -ForegroundColor Yellow
        if (Test-Path "$rustDir/target") {
            Remove-Item -Recurse -Force "$rustDir/target"
        }
        if (Test-Path "$androidDir/libs") {
            Remove-Item -Recurse -Force "$androidDir/libs"  
        }
        Write-Host "✓ Build directories cleaned" -ForegroundColor Green
    }
    
    # Create android output directory
    New-Item -ItemType Directory -Force -Path "$androidDir/libs" | Out-Null
    
    if ($all) {
        Write-Host "Building for all Android architectures..." -ForegroundColor Magenta
        foreach ($archEntry in $archMappings.GetEnumerator()) {
            Build-Architecture $archEntry.Key $archEntry.Value
        }
    } else {
        if (!$archMappings.ContainsKey($arch)) {
            $validArchs = $archMappings.Keys -join ", "
            throw "Invalid architecture '$arch'. Valid options: $validArchs"
        }
        Build-Architecture $arch $archMappings[$arch]
    }
    
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    
    # List built libraries
    if (Test-Path "$androidDir/libs") {
        Write-Host ""
        Write-Host "Built libraries:" -ForegroundColor Cyan
        Get-ChildItem -Recurse -Path "$androidDir/libs" -Filter "*.so" | ForEach-Object {
            $sizeKB = [math]::Round($_.Length / 1KB, 2)
            Write-Host "  $($_.FullName) (${sizeKB} KB)" -ForegroundColor Gray
        }
    }
    
} catch {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Red
    Write-Host "Build failed: $_" -ForegroundColor Red
    Write-Host "================================================" -ForegroundColor Red
    exit 1
}