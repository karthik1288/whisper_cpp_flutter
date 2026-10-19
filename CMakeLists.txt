cmake_minimum_required(VERSION 3.22)
project(whisper_flutter LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 17)
set(BUILD_SHARED_LIBS OFF)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_METAL OFF CACHE BOOL "" FORCE)
if(ANDROID AND ANDROID_ABI STREQUAL "arm64-v8a")
  # One ggml-cpu library per ARM feature level (baseline, dotprod+fp16, +i8mm).
  # The bridge loads the best one the phone's CPU supports; a single library
  # would have to settle for the baseline NEON kernels, about half the speed.
  set(BUILD_SHARED_LIBS ON)
  set(GGML_BACKEND_DL ON CACHE BOOL "" FORCE)
  set(GGML_CPU_ALL_VARIANTS ON CACHE BOOL "" FORCE)
endif()
set(WHISPER_NATIVE_ROOT ios/whisper_cpp_flutter_plus/Sources)
add_subdirectory(${WHISPER_NATIVE_ROOT}/WhisperCppCore whisper-build)
add_library(whisper_flutter SHARED
  ${WHISPER_NATIVE_ROOT}/WhisperCppFlutterBridge/whisper_flutter.cpp)
target_include_directories(whisper_flutter PRIVATE
  ${WHISPER_NATIVE_ROOT}/WhisperCppFlutterBridge
  ${WHISPER_NATIVE_ROOT}/WhisperCppCore/include)
target_link_libraries(whisper_flutter PRIVATE whisper)
if(ANDROID)
  target_link_libraries(whisper_flutter PRIVATE log android)
endif()
