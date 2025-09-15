use std::env;

fn main() {
    let target = env::var("TARGET").unwrap_or_default();
    
    // Handle Android-specific build configurations
    if target.contains("android") {
        println!("cargo:rustc-cfg=target_os=\"android\"");
        
        // Set Android-specific linker flags for ImageMagick
        if let Ok(imagemagick_lib_dirs) = env::var("IMAGE_MAGICK_LIB_DIRS") {
            for lib_dir in imagemagick_lib_dirs.split(&get_path_separator()) {
                println!("cargo:rustc-link-search=native={}", lib_dir);
            }
        }
        
        if let Ok(imagemagick_libs) = env::var("IMAGE_MAGICK_LIBS") {
            for lib in imagemagick_libs.split(&get_path_separator()) {
                println!("cargo:rustc-link-lib={}", lib);
            }
        }
        
        // Android-specific configuration
        configure_android_build();
    } else {
        // Non-Android platform configuration
        configure_native_build();
    }
}

fn configure_android_build() {
    // Android-specific ImageMagick configuration
    println!("cargo:rustc-cfg=feature=\"android\"");
    
    // Set up Android logging
    println!("cargo:rustc-cfg=feature=\"android_logger\"");
}

fn configure_native_build() {
    let is_windows = env::var("CARGO_CFG_WINDOWS").is_ok();
    
    // Windows resource compilation
    if is_windows && cfg!(windows) {
        #[cfg(feature = "winres")]
        {
            let res = winres::WindowsResource::new();
            res.compile().unwrap();
        }
    }
}

fn get_path_separator() -> String {
    if cfg!(windows) {
        ";".to_string()
    } else {
        ":".to_string()
    }
}
