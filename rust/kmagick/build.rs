use std::env;
use winres;

fn main() {
    // Set ImageMagick configuration flags
    println!("cargo:rerun-if-changed=build.rs");
    
    // Get target information
    let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap_or_default();
    let target_arch = env::var("CARGO_CFG_TARGET_ARCH").unwrap_or_default();
    
    println!("cargo:warning=Building for target OS: {}, arch: {}", target_os, target_arch);

    // Set ImageMagick environment variables
    println!("cargo:rustc-env=MAGICKCORE_HDRI_ENABLE=1");
    println!("cargo:rustc-env=MAGICKCORE_QUANTUM_DEPTH=16");

    // Set C/C++ preprocessor definitions
    println!("cargo:warning=Setting ImageMagick compile definitions");
    println!("cargo:rerun-if-env-changed=CFLAGS");
    println!("cargo:rerun-if-env-changed=CXXFLAGS");
    
    // Android-specific configurations
    if target_os == "android" {
        println!("cargo:warning=Configuring for Android target");
        
        // Set Android-specific preprocessor definitions
        env::set_var("CFLAGS", "-DMAGICKCORE_HDRI_ENABLE=1 -DMAGICKCORE_QUANTUM_DEPTH=16 -DANDROID -D__ANDROID_API__=23");
        env::set_var("CXXFLAGS", "-DMAGICKCORE_HDRI_ENABLE=1 -DMAGICKCORE_QUANTUM_DEPTH=16 -DANDROID -D__ANDROID_API__=23");
        
        // Link against Android libraries
        println!("cargo:rustc-link-lib=android");
        println!("cargo:rustc-link-lib=log");
        
        // Set Android API level
        println!("cargo:rustc-env=ANDROID_API_LEVEL=23");
        
        return; // Skip Windows resource compilation for Android
    } else {
        env::set_var("CFLAGS", "-DMAGICKCORE_HDRI_ENABLE=1 -DMAGICKCORE_QUANTUM_DEPTH=16");
        env::set_var("CXXFLAGS", "-DMAGICKCORE_HDRI_ENABLE=1 -DMAGICKCORE_QUANTUM_DEPTH=16");
    }

    let is_windows = env::var("CARGO_CFG_WINDOWS").is_ok();
    // HOST must also be windows to run stamping tool
    if !is_windows || !cfg!(windows) {
        return
    }

    let res = winres::WindowsResource::new();
    res.compile().unwrap();
}
