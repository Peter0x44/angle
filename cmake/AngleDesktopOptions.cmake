include_guard(GLOBAL)

if(CMAKE_SYSTEM_NAME STREQUAL "Android")
    message(FATAL_ERROR "The desktop CMake overlay does not support Android.")
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Fuchsia")
    message(FATAL_ERROR "The desktop CMake overlay does not support Fuchsia.")
endif()

set(_angle_is_desktop_apple FALSE)
if(APPLE AND NOT CMAKE_SYSTEM_NAME STREQUAL "iOS")
    set(_angle_is_desktop_apple TRUE)
endif()

set(_angle_is_mingw FALSE)
if(MINGW)
    set(_angle_is_mingw TRUE)
endif()

set(_angle_default_d3d9 OFF)
set(_angle_default_d3d11 OFF)
if(WIN32 AND MSVC)
    set(_angle_default_d3d9 ON)
    set(_angle_default_d3d11 ON)
endif()

set(_angle_default_gl ON)
if(WIN32 AND CMAKE_SYSTEM_PROCESSOR MATCHES "^(ARM64|arm64|AARCH64|aarch64)$")
    set(_angle_default_gl OFF)
endif()

set(_angle_default_vulkan OFF)
if(WIN32 OR UNIX OR _angle_is_desktop_apple)
    set(_angle_default_vulkan ON)
endif()

set(_angle_default_metal FALSE)
if(_angle_is_desktop_apple)
    set(_angle_default_metal TRUE)
endif()

set(_angle_default_wgpu FALSE)

set(_angle_default_x11 FALSE)
set(_angle_default_wayland FALSE)
set(_angle_default_gbm FALSE)
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(_angle_default_x11 TRUE)
endif()

option(ANGLE_ENABLE_SHARED "Enable shared-output targets in the desktop CMake overlay." ON)
option(ANGLE_ENABLE_STATIC "Enable static-output targets in the desktop CMake overlay." ON)

option(ANGLE_ENABLE_D3D9 "Enable the D3D9 backend on Windows." ${_angle_default_d3d9})
option(ANGLE_ENABLE_D3D11 "Enable the D3D11 backend on Windows." ${_angle_default_d3d11})
option(ANGLE_ENABLE_GL "Enable the desktop GL backend." ${_angle_default_gl})
option(ANGLE_ENABLE_VULKAN "Enable the Vulkan backend." ${_angle_default_vulkan})
option(ANGLE_ENABLE_METAL "Enable the Metal backend on macOS." ${_angle_default_metal})
option(ANGLE_ENABLE_WGPU "Enable the WGPU backend when its desktop prerequisites are met." ${_angle_default_wgpu})
option(ANGLE_ENABLE_NULL "Enable the null backend for desktop testing." ON)

option(ANGLE_USE_X11 "Enable X11 integration for desktop Linux builds." ${_angle_default_x11})
option(ANGLE_USE_WAYLAND "Enable Wayland integration for desktop Linux builds." ${_angle_default_wayland})
option(ANGLE_USE_GBM "Enable GBM integration for desktop Linux builds." ${_angle_default_gbm})

option(ANGLE_BUILD_TESTS "Enable desktop test targets in the overlay." OFF)
option(ANGLE_BUILD_SAMPLES "Enable desktop sample targets in the overlay." OFF)
option(ANGLE_ENABLE_VULKAN_SECONDARIES "Enable alternate Vulkan secondary-command-buffer targets." OFF)
option(ANGLE_ENABLE_MAINTAINER_CODEGEN "Enable maintainer-only code generation integration." OFF)

set(_angle_spirv_headers_header
    "${PROJECT_SOURCE_DIR}/third_party/spirv-headers/src/include/spirv/unified1/spirv.hpp")
set(_angle_spirv_tools_header
    "${PROJECT_SOURCE_DIR}/third_party/spirv-tools/src/include/spirv-tools/libspirv.hpp")
set(_angle_vulkan_headers_header
    "${PROJECT_SOURCE_DIR}/third_party/vulkan-headers/src/include/vulkan/vulkan.h")
set(_angle_vulkan_memory_allocator_header
    "${PROJECT_SOURCE_DIR}/third_party/vulkan_memory_allocator/include/vk_mem_alloc.h")
set(_angle_has_spirv_translator_deps FALSE)
if(EXISTS "${_angle_spirv_headers_header}" AND EXISTS "${_angle_spirv_tools_header}")
    set(_angle_has_spirv_translator_deps TRUE)
endif()

set(_angle_has_vulkan_runtime_deps FALSE)
if(EXISTS "${_angle_vulkan_headers_header}" AND EXISTS "${_angle_vulkan_memory_allocator_header}")
    set(_angle_has_vulkan_runtime_deps TRUE)
endif()

if(NOT ANGLE_ENABLE_SHARED AND NOT ANGLE_ENABLE_STATIC)
    message(FATAL_ERROR "At least one of ANGLE_ENABLE_SHARED or ANGLE_ENABLE_STATIC must be ON.")
endif()

if(NOT WIN32)
    if(ANGLE_ENABLE_D3D9 OR ANGLE_ENABLE_D3D11)
        message(FATAL_ERROR "D3D backends are only available on Windows.")
    endif()
endif()

if(NOT _angle_is_desktop_apple AND ANGLE_ENABLE_METAL)
    message(FATAL_ERROR "ANGLE_ENABLE_METAL is only valid for desktop Apple builds.")
endif()

if(ANGLE_ENABLE_VULKAN_SECONDARIES AND NOT ANGLE_ENABLE_VULKAN)
    message(FATAL_ERROR "ANGLE_ENABLE_VULKAN_SECONDARIES requires ANGLE_ENABLE_VULKAN.")
endif()

if(ANGLE_ENABLE_VULKAN AND NOT _angle_has_spirv_translator_deps)
    message(STATUS
        "Vulkan translator dependencies are not populated. Run `git submodule update --init -- "
        "third_party/spirv-headers/src third_party/spirv-tools/src` or `gclient sync` to "
        "populate them before wiring translator/SPIR-V targets.")
endif()

if(ANGLE_ENABLE_VULKAN AND NOT _angle_has_vulkan_runtime_deps)
    message(STATUS
        "Vulkan runtime dependencies are not populated. Run `git submodule update --init -- "
        "third_party/vulkan-headers/src third_party/vulkan_memory_allocator` or `gclient sync` "
        "to populate them before building the Vulkan backend.")
endif()

if(_angle_is_mingw AND (ANGLE_ENABLE_D3D9 OR ANGLE_ENABLE_D3D11))
    message(WARNING
        "MinGW D3D backend support is expected to lag behind MSVC. "
        "Keep GL/Vulkan/Null as the first validation targets.")
endif()

if(ANGLE_ENABLE_WGPU)
    message(STATUS
        "WGPU is enabled in the overlay option matrix, but Dawn dependency wiring is not "
        "implemented in this initial scaffold.")
endif()

if(ANGLE_ENABLE_MAINTAINER_CODEGEN)
    message(STATUS
        "Maintainer code generation mode is reserved for a later slice. "
        "The initial scaffold uses checked-in generated sources only.")
endif()

set(ANGLE_ENABLE_HLSL OFF)
if(ANGLE_ENABLE_D3D9 OR ANGLE_ENABLE_D3D11)
    set(ANGLE_ENABLE_HLSL ON)
endif()

set(ANGLE_ENABLE_ESSL OFF)
if(ANGLE_ENABLE_GL)
    set(ANGLE_ENABLE_ESSL ON)
endif()

set(ANGLE_ENABLE_GLSL OFF)
if(ANGLE_ENABLE_GL)
    set(ANGLE_ENABLE_GLSL ON)
endif()

set(ANGLE_ENABLE_MSL OFF)
if(ANGLE_ENABLE_METAL)
    set(ANGLE_ENABLE_MSL ON)
endif()

set(ANGLE_IS_MINGW ${_angle_is_mingw} CACHE INTERNAL "Whether the current toolchain is MinGW." FORCE)
set(ANGLE_IS_DESKTOP_APPLE ${_angle_is_desktop_apple} CACHE INTERNAL "Whether the current platform is desktop Apple." FORCE)
set(ANGLE_HAS_SPIRV_TRANSLATOR_DEPS ${_angle_has_spirv_translator_deps} CACHE INTERNAL "Whether SPIR-V translator third-party dependencies are present in the checkout." FORCE)
set(ANGLE_HAS_VULKAN_RUNTIME_DEPS ${_angle_has_vulkan_runtime_deps} CACHE INTERNAL "Whether Vulkan headers and VMA are present in the checkout." FORCE)
set(ANGLE_ENABLE_HLSL ${ANGLE_ENABLE_HLSL} CACHE INTERNAL "Derived translator HLSL support toggle." FORCE)
set(ANGLE_ENABLE_ESSL ${ANGLE_ENABLE_ESSL} CACHE INTERNAL "Derived translator ESSL support toggle." FORCE)
set(ANGLE_ENABLE_GLSL ${ANGLE_ENABLE_GLSL} CACHE INTERNAL "Derived translator GLSL support toggle." FORCE)
set(ANGLE_ENABLE_MSL ${ANGLE_ENABLE_MSL} CACHE INTERNAL "Derived translator MSL support toggle." FORCE)

function(angle_print_configuration_summary)
    message(STATUS "ANGLE desktop CMake overlay")
    message(STATUS "  System: ${CMAKE_SYSTEM_NAME}")
    message(STATUS "  C compiler: ${CMAKE_C_COMPILER_ID}")
    message(STATUS "  CXX compiler: ${CMAKE_CXX_COMPILER_ID}")
    message(STATUS "  Shared targets: ${ANGLE_ENABLE_SHARED}")
    message(STATUS "  Static targets: ${ANGLE_ENABLE_STATIC}")
    message(STATUS
        "  Backends: D3D9=${ANGLE_ENABLE_D3D9}, D3D11=${ANGLE_ENABLE_D3D11}, "
        "GL=${ANGLE_ENABLE_GL}, Vulkan=${ANGLE_ENABLE_VULKAN}, Metal=${ANGLE_ENABLE_METAL}, "
        "WGPU=${ANGLE_ENABLE_WGPU}, Null=${ANGLE_ENABLE_NULL}")
    message(STATUS
        "  Translators: HLSL=${ANGLE_ENABLE_HLSL}, ESSL=${ANGLE_ENABLE_ESSL}, "
        "GLSL=${ANGLE_ENABLE_GLSL}, MSL=${ANGLE_ENABLE_MSL}")
    message(STATUS "  SPIR-V translator deps: ${ANGLE_HAS_SPIRV_TRANSLATOR_DEPS}")
    message(STATUS "  Vulkan runtime deps: ${ANGLE_HAS_VULKAN_RUNTIME_DEPS}")
    message(STATUS
        "  Linux window systems: X11=${ANGLE_USE_X11}, Wayland=${ANGLE_USE_WAYLAND}, "
        "GBM=${ANGLE_USE_GBM}")
    message(STATUS
        "  Status: core static desktop libraries are wired through libANGLE/libEGL/"
        "libGLES; shared outputs, backend parity, and remaining support targets are still in progress.")
endfunction()
