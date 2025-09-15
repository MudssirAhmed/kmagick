use std::env;
use std::path::PathBuf;

#[cfg(windows)]
use winres;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Set ImageMagick configuration flags
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed=magick-config.h");

    // Set environment variables for ImageMagick
    println!("cargo:rustc-env=MAGICKCORE_HDRI_ENABLE=1");
    println!("cargo:rustc-env=MAGICKCORE_QUANTUM_DEPTH=16");

    // Set C/C++ preprocessor definitions
    println!("cargo:warning=Setting ImageMagick compile definitions");
    println!("cargo:rerun-if-env-changed=CFLAGS");
    println!("cargo:rerun-if-env-changed=CXXFLAGS");

    // Configure ImageMagick for the target platform
    configure_imagemagick()?;

    // Windows resource compilation
    let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap_or_default();
    if target_os == "windows" && cfg!(windows) {
        compile_windows_resources()?;
    }

    Ok(())
}

fn configure_imagemagick() -> Result<(), Box<dyn std::error::Error>> {
    let target = env::var("TARGET").unwrap_or_default();
    let mut cflags = String::from("-DMAGICKCORE_HDRI_ENABLE=1 -DMAGICKCORE_QUANTUM_DEPTH=16");
    let mut cxxflags = cflags.clone();

    // Add magick-config.h include path
    let config_dir = env::current_dir()?.join("magick-config.h").parent().unwrap().to_path_buf();
    cflags.push_str(&format!(" -I{}", config_dir.display()));
    cxxflags.push_str(&format!(" -I{}", config_dir.display()));

    if target.contains("android") {
        configure_android_build(&mut cflags, &mut cxxflags)?;
    }

    // Set the flags
    env::set_var("CFLAGS", &cflags);
    env::set_var("CXXFLAGS", &cxxflags);

    Ok(())
}

fn configure_android_build(cflags: &mut String, cxxflags: &mut String) -> Result<(), Box<dyn std::error::Error>> {
    let ndk_root = env::var("ANDROID_NDK_ROOT")
        .or_else(|_| env::var("ANDROID_NDK_HOME"))
        .or_else(|_| env::var("NDK_HOME"))
        .unwrap_or_else(|_| "/usr/local/lib/android/sdk/ndk/27.3.13750724".to_string());

    println!("cargo:warning=Using Android NDK at: {}", ndk_root);

    // Configure Android-specific settings
    let target = env::var("TARGET").unwrap_or_default();
    let android_api = env::var("ANDROID_API").unwrap_or_else(|_| "23".to_string());

    // Set NDK paths and Android-specific flags
    let ndk_path = PathBuf::from(&ndk_root);
    let toolchain_path = ndk_path.join("toolchains/llvm/prebuilt");
    
    // Determine host triple for toolchain
    let host_triple = if cfg!(target_os = "linux") {
        "linux-x86_64"
    } else if cfg!(target_os = "windows") {
        "windows-x86_64"
    } else if cfg!(target_os = "macos") {
        "darwin-x86_64"
    } else {
        return Err("Unsupported host OS for Android builds".into());
    };

    let toolchain_bin = toolchain_path.join(host_triple).join("bin");
    
    // Add Android-specific compiler flags
    cflags.push_str(&format!(" -DANDROID -D__ANDROID_API__={}", android_api));
    cxxflags.push_str(&format!(" -DANDROID -D__ANDROID_API__={}", android_api));

    // Configure target-specific settings
    if target.contains("aarch64") {
        cflags.push_str(" -march=armv8-a");
        cxxflags.push_str(" -march=armv8-a");
    } else if target.contains("armv7") {
        cflags.push_str(" -march=armv7-a -mfloat-abi=softfp -mfpu=neon");
        cxxflags.push_str(" -march=armv7-a -mfloat-abi=softfp -mfpu=neon");
    } else if target.contains("i686") {
        cflags.push_str(" -march=i686 -mtune=intel -mssse3 -mfpmath=sse");
        cxxflags.push_str(" -march=i686 -mtune=intel -mssse3 -mfpmath=sse");
    } else if target.contains("x86_64") {
        cflags.push_str(" -march=x86-64 -msse4.2 -mpopcnt");
        cxxflags.push_str(" -march=x86-64 -msse4.2 -mpopcnt");
    }

    // Set PATH for NDK toolchain
    if let Ok(current_path) = env::var("PATH") {
        let new_path = format!("{}:{}", toolchain_bin.display(), current_path);
        env::set_var("PATH", new_path);
    }

    Ok(())
}

#[cfg(windows)]
fn compile_windows_resources() -> Result<(), Box<dyn std::error::Error>> {
    let res = winres::WindowsResource::new();
    res.compile()?;
    Ok(())
}

#[cfg(not(windows))]
fn compile_windows_resources() -> Result<(), Box<dyn std::error::Error>> {
    Ok(())
}
