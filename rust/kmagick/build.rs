use std::env;
use winres;

fn main() {
    // Set ImageMagick configuration flags
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rustc-env=MAGICKCORE_HDRI_ENABLE=1");
    println!("cargo:rustc-env=MAGICKCORE_QUANTUM_DEPTH=16");

    // Add C/C++ compiler flags
    println!("cargo:rustc-flags=-DMAGICKCORE_HDRI_ENABLE=1");
    println!("cargo:rustc-flags=-DMAGICKCORE_QUANTUM_DEPTH=16");

    let is_windows = env::var("CARGO_CFG_WINDOWS").is_ok();
    // HOST must also be windows to run stamping tool
    if !is_windows || !cfg!(windows) {
        return
    }

    let res = winres::WindowsResource::new();
    res.compile().unwrap();
}
