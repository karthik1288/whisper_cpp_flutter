#!/bin/sh
# Precompiles ggml's Metal shaders for iOS devices so the plugin never compiles
# them on the phone, and merges the shader source into one file for the runtime
# fallback. Run it after changing ggml-metal.metal, ggml-common.h or
# ggml-metal-impl.h, then commit the two files it writes under ggml/Resources.
#
# Needs Xcode's Metal Toolchain (a separate download since Xcode 26):
#   xcodebuild -downloadComponent MetalToolchain
#
# The library is built without GGML_METAL_HAS_BF16 and GGML_METAL_HAS_TENSOR,
# which the runtime compile would set from the device, so one file loads on
# every iOS 16+ GPU (the flash-attention kernels need Metal 3, so iOS 14 and 15
# fall back to the source). ggml-metal-device.m turns those two features off
# when it loads this file. The fallback source still gets them.
set -eu

cd "$(dirname "$0")/whisper_cpp_flutter_plus/Sources/WhisperCppCore/ggml"
mkdir -p Resources

xcrun -sdk iphoneos metal -O3 -mios-version-min=16.0 -I src -I src/ggml-metal \
    -c src/ggml-metal/ggml-metal.metal -o - \
    | xcrun -sdk iphoneos metallib - -o Resources/default.metallib

# Same merge as ggml's CMake embed step: inline the two headers the shader
# includes, since the on-device compiler cannot resolve #include paths.
sed -e '/__embed_ggml-common.h__/d' \
    -e '/#include "ggml-common.h"/r src/ggml-common.h' \
    -e '/#include "ggml-common.h"/d' \
    src/ggml-metal/ggml-metal.metal \
    | sed -e '/#include "ggml-metal-impl.h"/r src/ggml-metal/ggml-metal-impl.h' \
          -e '/#include "ggml-metal-impl.h"/d' \
    > Resources/ggml-metal.txt

ls -l Resources/default.metallib Resources/ggml-metal.txt
