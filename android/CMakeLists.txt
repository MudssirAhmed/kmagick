cmake_minimum_required(VERSION 3.22.1)
project(kmagick)

# Set C++ standard
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(PkgConfig)

# Android specific configurations
if(ANDROID)
    message(STATUS "Configuring for Android platform")
    message(STATUS "Android ABI: ${ANDROID_ABI}")
    message(STATUS "Android API Level: ${ANDROID_PLATFORM}")
    
    # Set Android specific definitions
    add_definitions(-DANDROID -D__ANDROID_API__=${ANDROID_PLATFORM})
    
    # Find Android log library
    find_library(log-lib log)
    
    # ImageMagick configuration for Android
    if(DEFINED ENV{IMAGE_MAGICK_DIR})
        set(IMAGEMAGICK_ROOT $ENV{IMAGE_MAGICK_DIR})
        message(STATUS "Using ImageMagick from: ${IMAGEMAGICK_ROOT}")
        
        # Include directories
        include_directories(${IMAGEMAGICK_ROOT})
        include_directories(${IMAGEMAGICK_ROOT}/configs/${ANDROID_ABI})
        
        # Library directories
        if(EXISTS ${IMAGEMAGICK_ROOT}/../jniLibs/${ANDROID_ABI})
            link_directories(${IMAGEMAGICK_ROOT}/../jniLibs/${ANDROID_ABI})
        endif()
        
        # Link ImageMagick libraries
        find_library(MAGICKWAND_LIB MagickWand-7.Q16HDRI 
                    PATHS ${IMAGEMAGICK_ROOT}/../jniLibs/${ANDROID_ABI}
                    NO_DEFAULT_PATH)
        find_library(MAGICKCORE_LIB MagickCore-7.Q16HDRI 
                    PATHS ${IMAGEMAGICK_ROOT}/../jniLibs/${ANDROID_ABI}
                    NO_DEFAULT_PATH)
        
        if(MAGICKWAND_LIB AND MAGICKCORE_LIB)
            message(STATUS "Found ImageMagick libraries:")
            message(STATUS "  MagickWand: ${MAGICKWAND_LIB}")
            message(STATUS "  MagickCore: ${MAGICKCORE_LIB}")
        else()
            message(WARNING "ImageMagick libraries not found in jniLibs/${ANDROID_ABI}")
        endif()
    else()
        message(WARNING "IMAGE_MAGICK_DIR environment variable not set")
    endif()
    
    # Find the pre-built Rust library
    find_library(KMAGICK_RUST_LIB kmagick
                PATHS ${CMAKE_SOURCE_DIR}/libs/${ANDROID_ABI}
                NO_DEFAULT_PATH)
    
    if(KMAGICK_RUST_LIB)
        message(STATUS "Found kmagick Rust library: ${KMAGICK_RUST_LIB}")
        
        # Create imported target for the Rust library
        add_library(kmagick-rust SHARED IMPORTED)
        set_target_properties(kmagick-rust PROPERTIES
                             IMPORTED_LOCATION ${KMAGICK_RUST_LIB})
        
        # Create a target that depends on the Rust library
        # This is mainly for packaging purposes
        add_library(kmagick-android SHARED IMPORTED)
        set_target_properties(kmagick-android PROPERTIES
                             IMPORTED_LOCATION ${KMAGICK_RUST_LIB})
        
        # Link dependencies
        if(MAGICKWAND_LIB AND MAGICKCORE_LIB)
            target_link_libraries(kmagick-android 
                                 ${MAGICKWAND_LIB}
                                 ${MAGICKCORE_LIB}
                                 ${log-lib})
        endif()
    else()
        message(WARNING "kmagick Rust library not found. Run the Rust build first.")
        
        # Create a dummy target
        add_library(kmagick-android SHARED dummy.cpp)
        target_link_libraries(kmagick-android ${log-lib})
    endif()
    
else()
    message(STATUS "Configuring for non-Android platform")
endif()

# Install targets
if(ANDROID AND KMAGICK_RUST_LIB)
    install(FILES ${KMAGICK_RUST_LIB}
            DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/${ANDROID_ABI})
endif()