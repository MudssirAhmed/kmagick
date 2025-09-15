use std::env;
use winres;

fn main() {
    // Set ImageMagick configuration flags
    println!("cargo:rerun-if-changed=build.rs");

    // Set environment variables for ImageMagick
    println!("cargo:rustc-env=MAGICKCORE_HDRI_ENABLE=1");
    println!("cargo:rustc-env=MAGICKCORE_QUANTUM_DEPTH=16");

    // Set C/C++ preprocessor definitions
    println!("cargo:warning=Setting ImageMagick compile definitions");
    println!("cargo:rerun-if-env-changed=CFLAGS");
    println!("cargo:rerun-if-env-changed=CXXFLAGS");

    env::set_var("CFLAGS", "-DMAGICKCORE_HDRI_ENABLE=1 -DMAGICKCORE_QUANTUM_DEPTH=16");
    env::set_var("CXXFLAGS", "-DMAGICKCORE_HDRI_ENABLE=1 -DMAGICKCORE_QUANTUM_DEPTH=16");

    let is_windows = env::var("CARGO_CFG_WINDOWS").is_ok();
    // HOST must also be windows to run stamping tool
    if !is_windows || !cfg!(windows) {
        return
    }

    let res = winres::WindowsResource::new();
    res.compile().unwrap();
}
