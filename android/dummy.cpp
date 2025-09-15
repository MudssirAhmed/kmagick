// Dummy C++ file for CMake when Rust library is not available
// This file provides a minimal implementation that can be used as a fallback

#include <jni.h>
#include <android/log.h>

#define LOG_TAG "kmagick-dummy"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

extern "C" {

JNIEXPORT jstring JNICALL
Java_com_kmagick_KMagick_getDummyVersion(JNIEnv *env, jobject /* this */) {
    LOGW("Using dummy kmagick implementation. Please build the Rust library first.");
    return env->NewStringUTF("dummy-0.0.0");
}

// Additional dummy functions can be added here as needed
JNIEXPORT jboolean JNICALL
Java_com_kmagick_KMagick_isDummyImplementation(JNIEnv *env, jobject /* this */) {
    return JNI_TRUE;
}

} // extern "C"