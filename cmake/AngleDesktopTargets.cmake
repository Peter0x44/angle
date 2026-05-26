include_guard(GLOBAL)

function(angle_add_interface_target target_name)
    if(TARGET ${target_name})
        return()
    endif()

    add_library(${target_name} INTERFACE)
    target_compile_features(${target_name} INTERFACE cxx_std_20)
endfunction()

function(angle_append_compile_definitions target_name)
    foreach(definition IN LISTS ARGN)
        if(definition)
            target_compile_definitions(${target_name} INTERFACE ${definition})
        endif()
    endforeach()
endfunction()

function(angle_collect_text_sources out_var)
    set(collected_sources)

    foreach(search_root IN LISTS ARGN)
        if(EXISTS "${search_root}")
            file(GLOB_RECURSE _angle_globbed_sources CONFIGURE_DEPENDS
                "${search_root}/*.h"
                "${search_root}/*.hh"
                "${search_root}/*.hpp"
                "${search_root}/*.c"
                "${search_root}/*.cc"
                "${search_root}/*.cpp"
                "${search_root}/*.inc"
                "${search_root}/*.inl"
                "${search_root}/*.m"
                "${search_root}/*.mm")
            list(APPEND collected_sources ${_angle_globbed_sources})
        endif()
    endforeach()

    if(collected_sources)
        list(REMOVE_DUPLICATES collected_sources)
        list(SORT collected_sources)
    endif()

    set(${out_var} "${collected_sources}" PARENT_SCOPE)
endfunction()

set(_angle_is_linux FALSE)
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(_angle_is_linux TRUE)
endif()

set(_angle_has_libdrm FALSE)
if(_angle_is_linux)
    find_path(ANGLE_LIBDRM_INCLUDE_DIR
        NAMES drm.h
        PATH_SUFFIXES libdrm)
    find_library(ANGLE_LIBDRM_LIBRARY NAMES drm)

    if(ANGLE_LIBDRM_INCLUDE_DIR AND ANGLE_LIBDRM_LIBRARY)
        set(_angle_has_libdrm TRUE)
    endif()
endif()

set(_angle_enable_cgl FALSE)
if(APPLE AND ANGLE_ENABLE_GL)
    set(_angle_enable_cgl TRUE)
endif()

set(_angle_use_vulkan_display FALSE)
if(_angle_is_linux AND ANGLE_ENABLE_VULKAN)
    set(_angle_use_vulkan_display TRUE)
endif()

set(_angle_egl_no_x11 FALSE)
if(_angle_use_vulkan_display AND NOT ANGLE_USE_X11)
    set(_angle_egl_no_x11 TRUE)
endif()

if(APPLE)
    find_library(ANGLE_APPLE_COCOA_FRAMEWORK Cocoa REQUIRED)
    find_library(ANGLE_APPLE_CORESERVICES_FRAMEWORK CoreServices REQUIRED)
    find_library(ANGLE_APPLE_FOUNDATION_FRAMEWORK Foundation REQUIRED)
    find_library(ANGLE_APPLE_IOKIT_FRAMEWORK IOKit REQUIRED)
    find_library(ANGLE_APPLE_IOSURFACE_FRAMEWORK IOSurface REQUIRED)
    find_library(ANGLE_APPLE_METAL_FRAMEWORK Metal REQUIRED)
    find_library(ANGLE_APPLE_OPENGL_FRAMEWORK OpenGL REQUIRED)
    find_library(ANGLE_APPLE_QUARTZCORE_FRAMEWORK QuartzCore REQUIRED)
endif()

angle_add_interface_target(angle_headers)
add_library(ANGLE::headers ALIAS angle_headers)
target_include_directories(angle_headers
    INTERFACE
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src>
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src/common/base>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)

angle_add_interface_target(angle_backend_config)
add_library(ANGLE::backend_config ALIAS angle_backend_config)
target_link_libraries(angle_backend_config INTERFACE angle_headers)
angle_append_compile_definitions(angle_backend_config
    $<$<BOOL:${ANGLE_ENABLE_D3D9}>:ANGLE_ENABLE_D3D9>
    $<$<BOOL:${ANGLE_ENABLE_D3D11}>:ANGLE_ENABLE_D3D11>
    $<$<BOOL:${ANGLE_ENABLE_GL}>:ANGLE_ENABLE_OPENGL>
    $<$<BOOL:${ANGLE_ENABLE_VULKAN}>:ANGLE_ENABLE_VULKAN>
    $<$<BOOL:${ANGLE_ENABLE_METAL}>:ANGLE_ENABLE_METAL>
    $<$<BOOL:${ANGLE_ENABLE_WGPU}>:ANGLE_ENABLE_WGPU>
    $<$<BOOL:${ANGLE_ENABLE_NULL}>:ANGLE_ENABLE_NULL>
    $<$<BOOL:${WIN32}>:NOMINMAX>
    $<$<BOOL:${WIN32}>:WIN32_LEAN_AND_MEAN=1>
    $<$<BOOL:${ANGLE_USE_X11}>:ANGLE_USE_X11>
    $<$<BOOL:${ANGLE_USE_WAYLAND}>:ANGLE_USE_WAYLAND>
    $<$<BOOL:${ANGLE_USE_GBM}>:ANGLE_USE_GBM>
    $<$<BOOL:${_angle_enable_cgl}>:ANGLE_ENABLE_CGL=1>
    $<$<BOOL:${_angle_use_vulkan_display}>:ANGLE_USE_VULKAN_DISPLAY>
    $<$<BOOL:${_angle_use_vulkan_display}>:ANGLE_VULKAN_DISPLAY_MODE_SIMPLE>
    $<$<BOOL:${_angle_egl_no_x11}>:EGL_NO_X11>
    ANGLE_CAPTURE_ENABLED=0)

angle_add_interface_target(angle_library_name_config)
add_library(ANGLE::library_name_config ALIAS angle_library_name_config)
target_link_libraries(angle_library_name_config INTERFACE angle_headers)
angle_append_compile_definitions(angle_library_name_config
    ANGLE_EGL_LIBRARY_NAME=\"libEGL\"
    ANGLE_GLESV2_LIBRARY_NAME=\"libGLESv2\"
    ANGLE_MESA_EGL_LIBRARY_NAME=\"mesa/src/egl/libEGL\"
    ANGLE_MESA_GLESV2_LIBRARY_NAME=\"mesa/src/mapi/es2api/libGLESv2\"
    ANGLE_VULKAN_SECONDARIES_EGL_LIBRARY_NAME=\"libEGL_vulkan_secondaries\"
    ANGLE_VULKAN_SECONDARIES_GLESV2_LIBRARY_NAME=\"libGLESv2_vulkan_secondaries\")

add_library(angle_xxhash STATIC
    ${PROJECT_SOURCE_DIR}/src/common/third_party/xxhash/xxhash.c
    ${PROJECT_SOURCE_DIR}/src/common/third_party/xxhash/xxhash.h)
add_library(ANGLE::xxhash ALIAS angle_xxhash)
target_include_directories(angle_xxhash PUBLIC ${PROJECT_SOURCE_DIR}/src/common/third_party/xxhash)

set(angle_common_sources
    ${PROJECT_SOURCE_DIR}/src/common/BinaryStream.h
    ${PROJECT_SOURCE_DIR}/src/common/CircularBuffer.h
    ${PROJECT_SOURCE_DIR}/src/common/Color.h
    ${PROJECT_SOURCE_DIR}/src/common/Color.inc
    ${PROJECT_SOURCE_DIR}/src/common/FastVector.h
    ${PROJECT_SOURCE_DIR}/src/common/FixedQueue.h
    ${PROJECT_SOURCE_DIR}/src/common/FixedVector.h
    ${PROJECT_SOURCE_DIR}/src/common/MemoryBuffer.h
    ${PROJECT_SOURCE_DIR}/src/common/Optional.h
    ${PROJECT_SOURCE_DIR}/src/common/PackedEGLEnums_autogen.h
    ${PROJECT_SOURCE_DIR}/src/common/PackedEnums.h
    ${PROJECT_SOURCE_DIR}/src/common/PackedGLEnums_autogen.h
    ${PROJECT_SOURCE_DIR}/src/common/PoolAlloc.h
    ${PROJECT_SOURCE_DIR}/src/common/SimpleMutex.h
    ${PROJECT_SOURCE_DIR}/src/common/SynchronizedValue.h
    ${PROJECT_SOURCE_DIR}/src/common/WorkerThread.h
    ${PROJECT_SOURCE_DIR}/src/common/aligned_memory.h
    ${PROJECT_SOURCE_DIR}/src/common/android_util.h
    ${PROJECT_SOURCE_DIR}/src/common/angleutils.h
    ${PROJECT_SOURCE_DIR}/src/common/apple_platform_utils.h
    ${PROJECT_SOURCE_DIR}/src/common/backtrace_utils.h
    ${PROJECT_SOURCE_DIR}/src/common/bitset_utils.h
    ${PROJECT_SOURCE_DIR}/src/common/debug.h
    ${PROJECT_SOURCE_DIR}/src/common/entry_points_enum_autogen.h
    ${PROJECT_SOURCE_DIR}/src/common/event_tracer.h
    ${PROJECT_SOURCE_DIR}/src/common/hash_containers.h
    ${PROJECT_SOURCE_DIR}/src/common/hash_utils.h
    ${PROJECT_SOURCE_DIR}/src/common/log_utils.h
    ${PROJECT_SOURCE_DIR}/src/common/mathutil.h
    ${PROJECT_SOURCE_DIR}/src/common/matrix_utils.h
    ${PROJECT_SOURCE_DIR}/src/common/platform.h
    ${PROJECT_SOURCE_DIR}/src/common/platform_helpers.h
    ${PROJECT_SOURCE_DIR}/src/common/span.h
    ${PROJECT_SOURCE_DIR}/src/common/span_util.h
    ${PROJECT_SOURCE_DIR}/src/common/string_utils.h
    ${PROJECT_SOURCE_DIR}/src/common/system_utils.h
    ${PROJECT_SOURCE_DIR}/src/common/tls.h
    ${PROJECT_SOURCE_DIR}/src/common/uniform_type_info_autogen.h
    ${PROJECT_SOURCE_DIR}/src/common/unsafe_buffers.h
    ${PROJECT_SOURCE_DIR}/src/common/utilities.h
    ${PROJECT_SOURCE_DIR}/src/common/vector_utils.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/base_export.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/containers/mru_cache.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/logging.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/macros.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/no_destructor.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/numerics/checked_math.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/numerics/checked_math_impl.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/numerics/clamped_math.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/numerics/clamped_math_impl.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/numerics/math_constants.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/numerics/ranges.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/numerics/safe_conversions.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/numerics/safe_conversions_arm_impl.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/numerics/safe_conversions_impl.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/numerics/safe_math.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/numerics/safe_math_arm_impl.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/numerics/safe_math_clang_gcc_impl.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/numerics/safe_math_shared_impl.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/sha1.h
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/sys_byteorder.h
    ${PROJECT_SOURCE_DIR}/src/common/Float16ToFloat32.cpp
    ${PROJECT_SOURCE_DIR}/src/common/MemoryBuffer.cpp
    ${PROJECT_SOURCE_DIR}/src/common/PackedEGLEnums_autogen.cpp
    ${PROJECT_SOURCE_DIR}/src/common/PackedEnums.cpp
    ${PROJECT_SOURCE_DIR}/src/common/PackedGLEnums_autogen.cpp
    ${PROJECT_SOURCE_DIR}/src/common/PoolAlloc.cpp
    ${PROJECT_SOURCE_DIR}/src/common/SimpleMutex.cpp
    ${PROJECT_SOURCE_DIR}/src/common/WorkerThread.cpp
    ${PROJECT_SOURCE_DIR}/src/common/aligned_memory.cpp
    ${PROJECT_SOURCE_DIR}/src/common/android_util.cpp
    ${PROJECT_SOURCE_DIR}/src/common/angleutils.cpp
    ${PROJECT_SOURCE_DIR}/src/common/base/anglebase/sha1.cc
    ${PROJECT_SOURCE_DIR}/src/common/debug.cpp
    ${PROJECT_SOURCE_DIR}/src/common/entry_points_enum_autogen.cpp
    ${PROJECT_SOURCE_DIR}/src/common/event_tracer.cpp
    ${PROJECT_SOURCE_DIR}/src/common/mathutil.cpp
    ${PROJECT_SOURCE_DIR}/src/common/matrix_utils.cpp
    ${PROJECT_SOURCE_DIR}/src/common/platform_helpers.cpp
    ${PROJECT_SOURCE_DIR}/src/common/string_utils.cpp
    ${PROJECT_SOURCE_DIR}/src/common/system_utils.cpp
    ${PROJECT_SOURCE_DIR}/src/common/tls.cpp
    ${PROJECT_SOURCE_DIR}/src/common/uniform_type_info_autogen.cpp
    ${PROJECT_SOURCE_DIR}/src/common/utilities.cpp
    ${PROJECT_SOURCE_DIR}/src/common/backtrace_utils_noop.cpp)

if(_angle_is_linux)
    list(APPEND angle_common_sources
        ${PROJECT_SOURCE_DIR}/src/common/system_utils_linux.cpp
        ${PROJECT_SOURCE_DIR}/src/common/system_utils_posix.cpp)
endif()

if(APPLE)
    list(APPEND angle_common_sources
        ${PROJECT_SOURCE_DIR}/src/common/apple/ObjCPtr.h
        ${PROJECT_SOURCE_DIR}/src/common/apple/SoftLinking.h
        ${PROJECT_SOURCE_DIR}/src/common/apple/apple_platform.h
        ${PROJECT_SOURCE_DIR}/src/common/apple_platform_utils.mm
        ${PROJECT_SOURCE_DIR}/src/common/system_utils_apple.cpp
        ${PROJECT_SOURCE_DIR}/src/common/system_utils_mac.cpp
        ${PROJECT_SOURCE_DIR}/src/common/system_utils_posix.cpp)

    if(_angle_enable_cgl)
        list(APPEND angle_common_sources
            ${PROJECT_SOURCE_DIR}/src/common/gl/cgl/FunctionsCGL.cpp
            ${PROJECT_SOURCE_DIR}/src/common/gl/cgl/FunctionsCGL.h)
    endif()
endif()

if(WIN32)
    list(APPEND angle_common_sources
        ${PROJECT_SOURCE_DIR}/src/common/system_utils_win.cpp
        ${PROJECT_SOURCE_DIR}/src/common/system_utils_win32.cpp)
endif()

add_library(angle_common STATIC ${angle_common_sources})
add_library(ANGLE::common ALIAS angle_common)
target_compile_features(angle_common PUBLIC cxx_std_20)
target_link_libraries(angle_common
    PUBLIC
        angle_backend_config
        angle_headers
    PRIVATE
        angle_xxhash)
target_include_directories(angle_common
    PUBLIC
        ${PROJECT_SOURCE_DIR}/src/common/base
        ${PROJECT_SOURCE_DIR}/src/common/third_party/xxhash)
target_compile_definitions(angle_common
    PRIVATE
        ANGLE_ENABLE_SHARE_CONTEXT_LOCK=1
        ANGLE_ENABLE_CONTEXT_MUTEX=1
        ANGLE_OUTSIDE_WEBKIT)

if(WIN32)
    target_compile_definitions(angle_common PRIVATE ANGLE_IS_WIN)
elseif(_angle_is_linux)
    target_compile_definitions(angle_common PRIVATE ANGLE_IS_LINUX)
    target_link_libraries(angle_common PUBLIC dl)
elseif(APPLE)
    target_link_libraries(angle_common
        PUBLIC
            ${ANGLE_APPLE_CORESERVICES_FRAMEWORK}
            ${ANGLE_APPLE_FOUNDATION_FRAMEWORK}
            ${ANGLE_APPLE_METAL_FRAMEWORK})
endif()

add_library(libEGL_egl_loader STATIC
    ${PROJECT_SOURCE_DIR}/src/libEGL/egl_loader_autogen.cpp
    ${PROJECT_SOURCE_DIR}/src/libEGL/egl_loader_autogen.h)
add_library(ANGLE::libEGL_egl_loader ALIAS libEGL_egl_loader)
target_compile_features(libEGL_egl_loader PUBLIC cxx_std_20)
target_link_libraries(libEGL_egl_loader PUBLIC angle_headers)
target_compile_definitions(libEGL_egl_loader PUBLIC ANGLE_USE_EGL_LOADER)

add_library(angle_gl_enum_utils STATIC
    ${PROJECT_SOURCE_DIR}/src/common/gl_enum_utils.cpp
    ${PROJECT_SOURCE_DIR}/src/common/gl_enum_utils.h
    ${PROJECT_SOURCE_DIR}/src/common/gl_enum_utils_autogen.cpp
    ${PROJECT_SOURCE_DIR}/src/common/gl_enum_utils_autogen.h)
add_library(ANGLE::gl_enum_utils ALIAS angle_gl_enum_utils)
target_compile_features(angle_gl_enum_utils PUBLIC cxx_std_20)
target_link_libraries(angle_gl_enum_utils PUBLIC angle_headers)

add_library(angle_common_shader_state STATIC
    ${PROJECT_SOURCE_DIR}/src/common/CompiledShaderState.cpp
    ${PROJECT_SOURCE_DIR}/src/common/CompiledShaderState.h)
add_library(ANGLE::common_shader_state ALIAS angle_common_shader_state)
target_compile_features(angle_common_shader_state PUBLIC cxx_std_20)
target_link_libraries(angle_common_shader_state PUBLIC angle_common angle_headers)

add_library(angle_image_util STATIC
    ${PROJECT_SOURCE_DIR}/src/image_util/AstcDecompressor.h
    ${PROJECT_SOURCE_DIR}/src/image_util/AstcDecompressorNoOp.cpp
    ${PROJECT_SOURCE_DIR}/src/image_util/copyimage.cpp
    ${PROJECT_SOURCE_DIR}/src/image_util/copyimage.h
    ${PROJECT_SOURCE_DIR}/src/image_util/copyimage.inc
    ${PROJECT_SOURCE_DIR}/src/image_util/generatemip.h
    ${PROJECT_SOURCE_DIR}/src/image_util/generatemip.inc
    ${PROJECT_SOURCE_DIR}/src/image_util/imageformats.cpp
    ${PROJECT_SOURCE_DIR}/src/image_util/imageformats.h
    ${PROJECT_SOURCE_DIR}/src/image_util/loadimage.cpp
    ${PROJECT_SOURCE_DIR}/src/image_util/loadimage.h
    ${PROJECT_SOURCE_DIR}/src/image_util/loadimage.inc
    ${PROJECT_SOURCE_DIR}/src/image_util/loadimage_astc.cpp
    ${PROJECT_SOURCE_DIR}/src/image_util/loadimage_etc.cpp
    ${PROJECT_SOURCE_DIR}/src/image_util/loadimage_paletted.cpp
    ${PROJECT_SOURCE_DIR}/src/image_util/storeimage.h
    ${PROJECT_SOURCE_DIR}/src/image_util/storeimage_paletted.cpp)
add_library(ANGLE::image_util ALIAS angle_image_util)
target_compile_features(angle_image_util PUBLIC cxx_std_20)
target_link_libraries(angle_image_util PUBLIC angle_common angle_headers)
target_include_directories(angle_image_util PUBLIC ${PROJECT_SOURCE_DIR}/src)

set(angle_gpu_info_util_sources
    ${PROJECT_SOURCE_DIR}/src/gpu_info_util/SystemInfo.cpp
    ${PROJECT_SOURCE_DIR}/src/gpu_info_util/SystemInfo.h
    ${PROJECT_SOURCE_DIR}/src/gpu_info_util/SystemInfo_internal.h)

if(_angle_is_linux)
    list(APPEND angle_gpu_info_util_sources
        ${PROJECT_SOURCE_DIR}/src/gpu_info_util/SystemInfo_linux.cpp)

    if(ANGLE_USE_X11)
        list(APPEND angle_gpu_info_util_sources
            ${PROJECT_SOURCE_DIR}/src/gpu_info_util/SystemInfo_x11.cpp)
    endif()
endif()

if(APPLE)
    list(APPEND angle_gpu_info_util_sources
        ${PROJECT_SOURCE_DIR}/src/gpu_info_util/SystemInfo_apple.mm
        ${PROJECT_SOURCE_DIR}/src/gpu_info_util/SystemInfo_macos.mm)
endif()

if(WIN32)
    list(APPEND angle_gpu_info_util_sources ${PROJECT_SOURCE_DIR}/src/gpu_info_util/SystemInfo_win.cpp)
endif()

if(_angle_is_linux AND ANGLE_USE_X11)
    add_library(angle_libxnvctrl STATIC
        ${PROJECT_SOURCE_DIR}/src/third_party/libXNVCtrl/NVCtrl.c
        ${PROJECT_SOURCE_DIR}/src/third_party/libXNVCtrl/NVCtrl.h
        ${PROJECT_SOURCE_DIR}/src/third_party/libXNVCtrl/NVCtrlLib.h
        ${PROJECT_SOURCE_DIR}/src/third_party/libXNVCtrl/nv_control.h)
    add_library(ANGLE::libxnvctrl ALIAS angle_libxnvctrl)
    target_compile_options(angle_libxnvctrl
        PRIVATE
            -Wno-incompatible-pointer-types-discards-qualifiers
            -Wno-deprecated-non-prototype)
    target_link_libraries(angle_libxnvctrl PUBLIC xcb)
endif()

add_library(angle_gpu_info_util STATIC ${angle_gpu_info_util_sources})
add_library(ANGLE::gpu_info_util ALIAS angle_gpu_info_util)
target_compile_features(angle_gpu_info_util PUBLIC cxx_std_20)
target_link_libraries(angle_gpu_info_util PUBLIC angle_common angle_headers)
target_include_directories(angle_gpu_info_util PUBLIC ${PROJECT_SOURCE_DIR}/src)

if(WIN32)
    target_link_libraries(angle_gpu_info_util PRIVATE dxgi)
elseif(_angle_is_linux)
    if(ANGLE_USE_X11)
        target_compile_definitions(angle_gpu_info_util PRIVATE GPU_INFO_USE_X11)
        target_link_libraries(angle_gpu_info_util
            PUBLIC
                angle_libxnvctrl
                X11
                Xi
                Xext)
    endif()
elseif(APPLE)
    target_link_libraries(angle_gpu_info_util
        PUBLIC
            ${ANGLE_APPLE_COCOA_FRAMEWORK}
            ${ANGLE_APPLE_IOKIT_FRAMEWORK}
            ${ANGLE_APPLE_METAL_FRAMEWORK})

    if(_angle_enable_cgl)
        target_link_libraries(angle_gpu_info_util PUBLIC ${ANGLE_APPLE_OPENGL_FRAMEWORK})
    endif()
endif()

angle_add_interface_target(angle_translator_headers)
add_library(ANGLE::translator_headers ALIAS angle_translator_headers)
target_link_libraries(angle_translator_headers INTERFACE angle_headers)

add_library(preprocessor STATIC
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/DiagnosticsBase.cpp
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/DiagnosticsBase.h
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/DirectiveHandlerBase.cpp
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/DirectiveHandlerBase.h
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/DirectiveParser.cpp
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/DirectiveParser.h
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/ExpressionParser.h
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/Input.cpp
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/Input.h
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/Lexer.cpp
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/Lexer.h
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/Macro.cpp
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/Macro.h
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/MacroExpander.cpp
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/MacroExpander.h
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/Preprocessor.cpp
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/Preprocessor.h
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/SourceLocation.h
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/Token.cpp
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/Token.h
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/Tokenizer.h
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/numeric_lex.h
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/preprocessor_lex_autogen.cpp
    ${PROJECT_SOURCE_DIR}/src/compiler/preprocessor/preprocessor_tab_autogen.cpp)
add_library(ANGLE::preprocessor ALIAS preprocessor)
target_compile_features(preprocessor PUBLIC cxx_std_20)
target_link_libraries(preprocessor PUBLIC angle_common angle_translator_headers)
target_include_directories(preprocessor PUBLIC ${PROJECT_SOURCE_DIR}/src)

angle_add_interface_target(angle_spirv_headers)
add_library(ANGLE::spirv_headers ALIAS angle_spirv_headers)
target_link_libraries(angle_spirv_headers INTERFACE angle_common angle_headers)
target_include_directories(angle_spirv_headers INTERFACE
    ${PROJECT_SOURCE_DIR}/src
    ${PROJECT_SOURCE_DIR}/third_party/spirv-headers/src/include
    ${PROJECT_SOURCE_DIR}/third_party/spirv-tools/src/include)

add_library(angle_spirv_base STATIC
    ${PROJECT_SOURCE_DIR}/src/common/spirv/angle_spirv_utils.cpp)
add_library(ANGLE::spirv_base ALIAS angle_spirv_base)
target_compile_features(angle_spirv_base PUBLIC cxx_std_20)
target_link_libraries(angle_spirv_base PUBLIC angle_common angle_spirv_headers)
target_include_directories(angle_spirv_base PUBLIC ${PROJECT_SOURCE_DIR}/src)

add_library(angle_spirv_builder STATIC
    ${PROJECT_SOURCE_DIR}/src/common/spirv/spirv_instruction_builder_autogen.cpp
    ${PROJECT_SOURCE_DIR}/src/common/spirv/spirv_instruction_builder_autogen.h)
add_library(ANGLE::spirv_builder ALIAS angle_spirv_builder)
target_compile_features(angle_spirv_builder PUBLIC cxx_std_20)
target_link_libraries(angle_spirv_builder PUBLIC angle_common angle_spirv_base angle_spirv_headers)
target_include_directories(angle_spirv_builder PUBLIC ${PROJECT_SOURCE_DIR}/src)

add_library(angle_spirv_parser STATIC
    ${PROJECT_SOURCE_DIR}/src/common/spirv/spirv_instruction_parser_autogen.cpp
    ${PROJECT_SOURCE_DIR}/src/common/spirv/spirv_instruction_parser_autogen.h)
add_library(ANGLE::spirv_parser ALIAS angle_spirv_parser)
target_compile_features(angle_spirv_parser PUBLIC cxx_std_20)
target_link_libraries(angle_spirv_parser PUBLIC angle_common angle_spirv_base angle_spirv_headers)
target_include_directories(angle_spirv_parser PUBLIC ${PROJECT_SOURCE_DIR}/src)

set(angle_generated_dir "${PROJECT_BINARY_DIR}/angle")
file(MAKE_DIRECTORY "${angle_generated_dir}")

angle_collect_text_sources(angle_program_version_inputs
    "${PROJECT_SOURCE_DIR}/include"
    "${PROJECT_SOURCE_DIR}/src")

list(FILTER angle_program_version_inputs EXCLUDE REGEX "/(tests|test_utils|fuzz|perf_tests)/")
list(FILTER angle_program_version_inputs EXCLUDE REGEX "/libANGLE/renderer/cl/")

if(NOT ANGLE_ENABLE_D3D9 AND NOT ANGLE_ENABLE_D3D11)
    list(FILTER angle_program_version_inputs EXCLUDE REGEX "/libANGLE/renderer/d3d/")
endif()

if(NOT ANGLE_ENABLE_GL)
    list(FILTER angle_program_version_inputs EXCLUDE REGEX "/libANGLE/renderer/gl/")
endif()

if(NOT ANGLE_ENABLE_METAL)
    list(FILTER angle_program_version_inputs EXCLUDE REGEX "/libANGLE/renderer/metal/")
endif()

if(NOT ANGLE_ENABLE_NULL)
    list(FILTER angle_program_version_inputs EXCLUDE REGEX "/libANGLE/renderer/null/")
endif()

if(NOT ANGLE_ENABLE_VULKAN)
    list(FILTER angle_program_version_inputs EXCLUDE REGEX "/libANGLE/renderer/vulkan/")
endif()

if(NOT ANGLE_ENABLE_WGPU)
    list(FILTER angle_program_version_inputs EXCLUDE REGEX "/libANGLE/renderer/wgpu/")
endif()

string(REPLACE ";" "\n" angle_program_version_response_contents "${angle_program_version_inputs}")
set(angle_program_version_response "${angle_generated_dir}/angle_program_version_inputs.rsp")
file(WRITE "${angle_program_version_response}" "${angle_program_version_response_contents}\n")

set(angle_commit_header "${angle_generated_dir}/angle_commit.h")
set(angle_shader_program_version_header "${angle_generated_dir}/ANGLEShaderProgramVersion.h")

add_custom_target(angle_version_headers_gen
    COMMAND
        "${CMAKE_COMMAND}"
        -DOUTPUT_FILE=${angle_commit_header}
        -DSOURCE_DIR=${PROJECT_SOURCE_DIR}
        -P
        "${PROJECT_SOURCE_DIR}/cmake/AngleGenerateCommitHeader.cmake"
    COMMAND
        "${CMAKE_COMMAND}"
        -DOUTPUT_FILE=${angle_shader_program_version_header}
        -DRESPONSE_FILE=${angle_program_version_response}
        -P
        "${PROJECT_SOURCE_DIR}/cmake/AngleGenerateProgramVersionHeader.cmake"
    DEPENDS
        "${PROJECT_SOURCE_DIR}/cmake/AngleGenerateCommitHeader.cmake"
        "${PROJECT_SOURCE_DIR}/cmake/AngleGenerateProgramVersionHeader.cmake"
        "${angle_program_version_response}"
        ${angle_program_version_inputs}
    BYPRODUCTS
        "${angle_commit_header}"
        "${angle_shader_program_version_header}"
    VERBATIM)

add_library(angle_version_info STATIC
    ${PROJECT_SOURCE_DIR}/src/common/angle_version_info.cpp
    ${PROJECT_SOURCE_DIR}/src/common/angle_version_info.h)
add_library(ANGLE::version_info ALIAS angle_version_info)
add_dependencies(angle_version_info angle_version_headers_gen)
target_compile_features(angle_version_info PUBLIC cxx_std_20)
target_link_libraries(angle_version_info PUBLIC angle_translator_headers)
target_include_directories(angle_version_info
    PUBLIC
        ${PROJECT_SOURCE_DIR}/src
        ${angle_generated_dir})

angle_collect_text_sources(angle_translator_sources
    "${PROJECT_SOURCE_DIR}/src/compiler/translator")

list(FILTER angle_translator_sources EXCLUDE REGEX "/translator/ir/")

if(NOT ANGLE_ENABLE_HLSL)
    list(FILTER angle_translator_sources EXCLUDE REGEX "/translator/hlsl/")
    list(FILTER angle_translator_sources EXCLUDE REGEX "/tree_ops/hlsl/")
endif()

if(NOT ANGLE_ENABLE_GLSL)
    list(FILTER angle_translator_sources EXCLUDE REGEX "/translator/glsl/")
    list(FILTER angle_translator_sources EXCLUDE REGEX "/tree_ops/glsl/")
endif()

if(NOT ANGLE_ENABLE_MSL)
    list(FILTER angle_translator_sources EXCLUDE REGEX "/translator/msl/")
    list(FILTER angle_translator_sources EXCLUDE REGEX "/tree_ops/msl/")
endif()

if(NOT ANGLE_ENABLE_VULKAN)
    list(FILTER angle_translator_sources EXCLUDE REGEX "/translator/spirv/")
    list(FILTER angle_translator_sources EXCLUDE REGEX "/tree_ops/spirv/")
endif()

if(NOT ANGLE_ENABLE_WGPU)
    list(FILTER angle_translator_sources EXCLUDE REGEX "/translator/wgsl/")
    list(FILTER angle_translator_sources EXCLUDE REGEX "/tree_ops/wgsl/")
endif()

if(NOT APPLE)
    list(FILTER angle_translator_sources EXCLUDE REGEX "/tree_ops/glsl/apple/")
endif()

add_library(translator STATIC ${angle_translator_sources})
add_library(ANGLE::translator ALIAS translator)
target_compile_features(translator PUBLIC cxx_std_20)
target_link_libraries(translator
    PUBLIC
        angle_common
        angle_common_shader_state
        angle_translator_headers
        angle_version_info
        preprocessor)
target_include_directories(translator PUBLIC ${PROJECT_SOURCE_DIR}/src)

if(ANGLE_ENABLE_VULKAN)
    target_link_libraries(translator
        PUBLIC
            angle_spirv_headers
            angle_spirv_base
            angle_spirv_builder)
endif()

target_compile_definitions(translator
    PUBLIC
        $<$<BOOL:${ANGLE_ENABLE_HLSL}>:ANGLE_ENABLE_HLSL>
        $<$<BOOL:${ANGLE_ENABLE_ESSL}>:ANGLE_ENABLE_ESSL>
        $<$<BOOL:${ANGLE_ENABLE_GLSL}>:ANGLE_ENABLE_GLSL>
        $<$<BOOL:${ANGLE_ENABLE_MSL}>:ANGLE_ENABLE_MSL>)

if(ANGLE_ENABLE_VULKAN)
    angle_add_interface_target(angle_vulkan_headers)
    add_library(ANGLE::vulkan_headers ALIAS angle_vulkan_headers)
    target_link_libraries(angle_vulkan_headers INTERFACE angle_headers)
    target_include_directories(angle_vulkan_headers INTERFACE
        ${PROJECT_SOURCE_DIR}/src
        ${PROJECT_SOURCE_DIR}/src/third_party/volk
        ${PROJECT_SOURCE_DIR}/third_party/vulkan-headers/src/include)
    angle_append_compile_definitions(angle_vulkan_headers
        ANGLE_SHARED_LIBVULKAN=1
        $<$<BOOL:${WIN32}>:VK_USE_PLATFORM_WIN32_KHR>
        $<$<BOOL:${ANGLE_USE_X11}>:VK_USE_PLATFORM_XCB_KHR>
        $<$<BOOL:${ANGLE_USE_X11}>:VK_USE_PLATFORM_XLIB_KHR>
        $<$<BOOL:${ANGLE_USE_WAYLAND}>:VK_USE_PLATFORM_WAYLAND_KHR>
        $<$<BOOL:${APPLE}>:VK_USE_PLATFORM_METAL_EXT>
        $<$<BOOL:${APPLE}>:VK_USE_PLATFORM_MACOS_MVK>)

    add_library(angle_volk STATIC
        ${PROJECT_SOURCE_DIR}/src/third_party/volk/volk.c
        ${PROJECT_SOURCE_DIR}/src/third_party/volk/volk.h)
    add_library(ANGLE::volk ALIAS angle_volk)
    target_link_libraries(angle_volk PUBLIC angle_vulkan_headers)
    target_include_directories(angle_volk PUBLIC ${PROJECT_SOURCE_DIR}/src/third_party/volk)

    add_library(angle_libvulkan_loader STATIC
        ${PROJECT_SOURCE_DIR}/src/common/vulkan/libvulkan_loader.cpp
        ${PROJECT_SOURCE_DIR}/src/common/vulkan/libvulkan_loader.h)
    add_library(ANGLE::libvulkan_loader ALIAS angle_libvulkan_loader)
    target_compile_features(angle_libvulkan_loader PUBLIC cxx_std_20)
    target_link_libraries(angle_libvulkan_loader PUBLIC angle_common angle_vulkan_headers)
    target_include_directories(angle_libvulkan_loader PUBLIC ${PROJECT_SOURCE_DIR}/src)
    target_compile_definitions(angle_libvulkan_loader PUBLIC ANGLE_USE_CUSTOM_LIBVULKAN)

    add_library(angle_vulkan_icd STATIC
        ${PROJECT_SOURCE_DIR}/src/common/vulkan/vulkan_icd.cpp
        ${PROJECT_SOURCE_DIR}/src/common/vulkan/vulkan_icd.h)
    add_library(ANGLE::vulkan_icd ALIAS angle_vulkan_icd)
    target_compile_features(angle_vulkan_icd PUBLIC cxx_std_20)
    target_link_libraries(angle_vulkan_icd PUBLIC angle_common angle_vulkan_headers)
    target_include_directories(angle_vulkan_icd PUBLIC ${PROJECT_SOURCE_DIR}/src)
    target_compile_definitions(angle_vulkan_icd
        PUBLIC
            ANGLE_VK_MOCK_ICD_JSON="angledata/VkICD_mock_icd.json"
            ANGLE_VK_LAYERS_DIR="angledata")

    angle_add_interface_target(angle_vulkan_entry_points)
    add_library(ANGLE::vulkan_entry_points ALIAS angle_vulkan_entry_points)
    target_link_libraries(angle_vulkan_entry_points INTERFACE angle_vulkan_headers angle_volk)

    add_library(angle_compression STATIC
        ${PROJECT_SOURCE_DIR}/third_party/zlib/google/compression_utils_portable.cc
        ${PROJECT_SOURCE_DIR}/third_party/zlib/google/compression_utils_portable.h)
    add_library(ANGLE::compression ALIAS angle_compression)
    target_compile_features(angle_compression PUBLIC cxx_std_20)
    target_include_directories(angle_compression
        PUBLIC
            ${PROJECT_SOURCE_DIR}/third_party/zlib
            ${PROJECT_SOURCE_DIR}/third_party/zlib/google)

    add_library(angle_vk_mem_alloc_wrapper STATIC
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/vulkan/vk_mem_alloc_wrapper.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/vulkan/vk_mem_alloc_wrapper.h)
    add_library(ANGLE::vk_mem_alloc_wrapper ALIAS angle_vk_mem_alloc_wrapper)
    target_compile_features(angle_vk_mem_alloc_wrapper PUBLIC cxx_std_20)
    target_link_libraries(angle_vk_mem_alloc_wrapper PUBLIC angle_common angle_vulkan_headers)
    target_include_directories(angle_vk_mem_alloc_wrapper
        PUBLIC
            ${PROJECT_SOURCE_DIR}/src
            ${PROJECT_SOURCE_DIR}/third_party/vulkan_memory_allocator/include)

    target_sources(angle_gpu_info_util PRIVATE
        ${PROJECT_SOURCE_DIR}/src/gpu_info_util/SystemInfo_vulkan.cpp
        ${PROJECT_SOURCE_DIR}/src/gpu_info_util/SystemInfo_vulkan.h)
    target_link_libraries(angle_gpu_info_util
        PUBLIC
            angle_libvulkan_loader
            angle_vulkan_headers
            angle_vulkan_icd)

    if(_angle_is_linux)
        target_compile_definitions(angle_gpu_info_util PRIVATE ANGLE_USE_VULKAN_SYSTEM_INFO)
    endif()
endif()

if(_angle_is_linux AND (ANGLE_ENABLE_GL OR ANGLE_ENABLE_VULKAN))
    add_library(angle_dma_buf STATIC
        ${PROJECT_SOURCE_DIR}/src/common/linux/dma_buf_utils.cpp
        ${PROJECT_SOURCE_DIR}/src/common/linux/dma_buf_utils.h)
    add_library(ANGLE::dma_buf ALIAS angle_dma_buf)
    target_compile_features(angle_dma_buf PUBLIC cxx_std_20)
    target_link_libraries(angle_dma_buf PUBLIC angle_common angle_headers)

    if(ANGLE_ENABLE_VULKAN)
        target_link_libraries(angle_dma_buf PUBLIC angle_vulkan_headers)
    endif()

    target_include_directories(angle_dma_buf PUBLIC ${PROJECT_SOURCE_DIR}/src)
endif()

if(ANGLE_ENABLE_NULL)
    add_library(angle_null_backend STATIC
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/BufferNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/BufferNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/CompilerNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/CompilerNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/ContextNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/ContextNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/DeviceNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/DeviceNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/DisplayNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/DisplayNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/FenceNVNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/FenceNVNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/FramebufferNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/FramebufferNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/ImageNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/ImageNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/ProgramExecutableNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/ProgramExecutableNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/ProgramNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/ProgramNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/ProgramPipelineNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/ProgramPipelineNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/QueryNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/QueryNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/RenderbufferNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/RenderbufferNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/SamplerNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/SamplerNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/ShaderNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/ShaderNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/SurfaceNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/SurfaceNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/SyncNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/SyncNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/TextureNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/TextureNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/TransformFeedbackNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/TransformFeedbackNULL.h
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/VertexArrayNULL.cpp
        ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/null/VertexArrayNULL.h)
    add_library(ANGLE::null_backend ALIAS angle_null_backend)
    target_compile_features(angle_null_backend PUBLIC cxx_std_20)
    target_link_libraries(angle_null_backend PUBLIC angle_common angle_translator_headers)
    target_include_directories(angle_null_backend PUBLIC ${PROJECT_SOURCE_DIR}/src)
    target_compile_definitions(angle_null_backend PUBLIC LIBANGLE_IMPLEMENTATION ANGLE_ENABLE_NULL)
endif()

if(WIN32 AND (ANGLE_ENABLE_GL OR ANGLE_ENABLE_D3D9 OR ANGLE_ENABLE_D3D11))
    set(angle_d3d_format_table_sources)

    if(ANGLE_ENABLE_GL OR ANGLE_ENABLE_D3D11)
        list(APPEND angle_d3d_format_table_sources
            ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/dxgi_format_map.h
            ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/dxgi_format_map_autogen.cpp
            ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/dxgi_support_table.h
            ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/dxgi_support_table_autogen.cpp)
    endif()

    if(ANGLE_ENABLE_GL OR ANGLE_ENABLE_D3D9)
        list(APPEND angle_d3d_format_table_sources
            ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/d3d_format.cpp
            ${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/d3d_format.h)
    endif()

    add_library(angle_d3d_format_tables STATIC ${angle_d3d_format_table_sources})
    add_library(ANGLE::d3d_format_tables ALIAS angle_d3d_format_tables)
    target_compile_features(angle_d3d_format_tables PUBLIC cxx_std_20)
    target_link_libraries(angle_d3d_format_tables PUBLIC angle_common angle_translator_headers)
    target_include_directories(angle_d3d_format_tables PUBLIC ${PROJECT_SOURCE_DIR}/src)
    target_compile_definitions(angle_d3d_format_tables PUBLIC LIBANGLE_IMPLEMENTATION)

    if(ANGLE_ENABLE_D3D9 OR ANGLE_ENABLE_D3D11)
        angle_collect_text_sources(angle_d3d_shared_sources
            "${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/d3d")
        list(FILTER angle_d3d_shared_sources EXCLUDE REGEX "/d3d9/")
        list(FILTER angle_d3d_shared_sources EXCLUDE REGEX "/d3d11/")

        add_library(angle_d3d_shared STATIC ${angle_d3d_shared_sources})
        add_library(ANGLE::d3d_shared ALIAS angle_d3d_shared)
        target_compile_features(angle_d3d_shared PUBLIC cxx_std_20)
        target_link_libraries(angle_d3d_shared
            PUBLIC
                angle_common
                angle_d3d_format_tables
                angle_gpu_info_util
                angle_image_util
                angle_translator_headers
                translator)
        target_include_directories(angle_d3d_shared PUBLIC ${PROJECT_SOURCE_DIR}/src)
        target_compile_definitions(angle_d3d_shared
            PUBLIC
                LIBANGLE_IMPLEMENTATION
                ANGLE_PRELOADED_D3DCOMPILER_MODULE_NAMES={\"d3dcompiler_47.dll\",\"d3dcompiler_46.dll\",\"d3dcompiler_43.dll\"})

        if(ANGLE_ENABLE_D3D9)
            angle_collect_text_sources(angle_d3d9_backend_sources
                "${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/d3d/d3d9")

            add_library(angle_d3d9_backend STATIC ${angle_d3d9_backend_sources})
            add_library(ANGLE::d3d9_backend ALIAS angle_d3d9_backend)
            target_compile_features(angle_d3d9_backend PUBLIC cxx_std_20)
            target_link_libraries(angle_d3d9_backend PUBLIC angle_d3d_shared)
            target_include_directories(angle_d3d9_backend PUBLIC ${PROJECT_SOURCE_DIR}/src)
            target_compile_definitions(angle_d3d9_backend PUBLIC LIBANGLE_IMPLEMENTATION ANGLE_ENABLE_D3D9)
        endif()

        if(ANGLE_ENABLE_D3D11)
            angle_collect_text_sources(angle_d3d11_backend_sources
                "${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/d3d/d3d11")
            list(FILTER angle_d3d11_backend_sources EXCLUDE REGEX "/winrt/")
            list(FILTER angle_d3d11_backend_sources EXCLUDE REGEX "/converged/")

            add_library(angle_d3d11_backend STATIC ${angle_d3d11_backend_sources})
            add_library(ANGLE::d3d11_backend ALIAS angle_d3d11_backend)
            target_compile_features(angle_d3d11_backend PUBLIC cxx_std_20)
            target_link_libraries(angle_d3d11_backend PUBLIC angle_d3d_shared)
            target_include_directories(angle_d3d11_backend PUBLIC ${PROJECT_SOURCE_DIR}/src)
            target_compile_definitions(angle_d3d11_backend PUBLIC LIBANGLE_IMPLEMENTATION ANGLE_ENABLE_D3D11)
        endif()
    endif()

endif()

if(ANGLE_ENABLE_GL)
    angle_collect_text_sources(angle_gl_backend_sources
        "${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/gl")
    list(FILTER angle_gl_backend_sources EXCLUDE REGEX "_unittest\\.(cpp|mm)$")
    list(FILTER angle_gl_backend_sources EXCLUDE REGEX "/egl/android/")

    if(NOT WIN32)
        list(FILTER angle_gl_backend_sources EXCLUDE REGEX "/wgl/")
    endif()

    if(NOT _angle_is_linux)
        list(FILTER angle_gl_backend_sources EXCLUDE REGEX "/egl/")
        list(FILTER angle_gl_backend_sources EXCLUDE REGEX "/glx/")
    elseif(NOT ANGLE_USE_X11)
        list(FILTER angle_gl_backend_sources EXCLUDE REGEX "/glx/")
    endif()

    if(NOT _angle_enable_cgl)
        list(FILTER angle_gl_backend_sources EXCLUDE REGEX "/cgl/")
    endif()

    if(WIN32)
        list(APPEND angle_gl_backend_sources
            ${PROJECT_SOURCE_DIR}/src/third_party/khronos/GL/wglext.h)
    endif()

    add_library(angle_gl_backend STATIC ${angle_gl_backend_sources})
    add_library(ANGLE::gl_backend ALIAS angle_gl_backend)
    target_compile_features(angle_gl_backend PUBLIC cxx_std_20)
    target_link_libraries(angle_gl_backend
        PUBLIC
            angle_common
            angle_gpu_info_util
            angle_image_util
            angle_translator_headers)
    target_include_directories(angle_gl_backend
        PUBLIC
            ${PROJECT_SOURCE_DIR}/src
            ${PROJECT_SOURCE_DIR}/src/third_party/khronos)
    target_compile_definitions(angle_gl_backend
        PUBLIC
            LIBANGLE_IMPLEMENTATION
            ANGLE_ENABLE_GL_DESKTOP_BACKEND)

    if(TARGET angle_d3d_format_tables)
        target_link_libraries(angle_gl_backend PUBLIC angle_d3d_format_tables)
    endif()

    if(TARGET angle_dma_buf)
        target_link_libraries(angle_gl_backend PUBLIC angle_dma_buf)
    endif()

    if(_angle_is_linux)
        if(_angle_has_libdrm)
            target_compile_definitions(angle_gl_backend PUBLIC ANGLE_HAS_LIBDRM)
            target_include_directories(angle_gl_backend PUBLIC ${ANGLE_LIBDRM_INCLUDE_DIR})
            target_link_libraries(angle_gl_backend PUBLIC ${ANGLE_LIBDRM_LIBRARY})
        endif()

        if(ANGLE_USE_X11)
            target_link_libraries(angle_gl_backend
                PUBLIC
                    X11
                    Xi
                    Xext)
        endif()
    elseif(APPLE)
        target_link_libraries(angle_gl_backend
            PUBLIC
                ${ANGLE_APPLE_COCOA_FRAMEWORK}
                ${ANGLE_APPLE_IOSURFACE_FRAMEWORK}
                ${ANGLE_APPLE_QUARTZCORE_FRAMEWORK})

        if(_angle_enable_cgl)
            target_link_libraries(angle_gl_backend PUBLIC ${ANGLE_APPLE_OPENGL_FRAMEWORK})
        endif()
    endif()
endif()

if(APPLE AND ANGLE_ENABLE_METAL)
    angle_collect_text_sources(angle_metal_backend_sources
        "${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/metal")
    list(FILTER angle_metal_backend_sources EXCLUDE REGEX "_unittest\\.(cpp|mm)$")

    add_library(angle_metal_backend STATIC ${angle_metal_backend_sources})
    add_library(ANGLE::metal_backend ALIAS angle_metal_backend)
    target_compile_features(angle_metal_backend PUBLIC cxx_std_20)
    target_link_libraries(angle_metal_backend
        PUBLIC
            angle_common
            angle_gpu_info_util
            angle_image_util
            angle_translator_headers
            translator)
    target_include_directories(angle_metal_backend PUBLIC ${PROJECT_SOURCE_DIR}/src)
    target_compile_definitions(angle_metal_backend PUBLIC LIBANGLE_IMPLEMENTATION)
    target_compile_options(angle_metal_backend
        PRIVATE
            $<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:-Wno-nullability-completeness>
            $<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:-Wno-unguarded-availability>
            $<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:-fno-objc-arc>)
    target_link_libraries(angle_metal_backend
        PUBLIC
            ${ANGLE_APPLE_COCOA_FRAMEWORK}
            ${ANGLE_APPLE_IOSURFACE_FRAMEWORK}
            ${ANGLE_APPLE_METAL_FRAMEWORK}
            ${ANGLE_APPLE_QUARTZCORE_FRAMEWORK})
endif()

if(ANGLE_ENABLE_VULKAN)
    angle_collect_text_sources(angle_vulkan_backend_sources
        "${PROJECT_SOURCE_DIR}/src/libANGLE/renderer/vulkan")
    list(FILTER angle_vulkan_backend_sources EXCLUDE REGEX "_unittest\\.(cpp|mm)$")

    list(FILTER angle_vulkan_backend_sources EXCLUDE REGEX "/android/")
    list(FILTER angle_vulkan_backend_sources EXCLUDE REGEX "/fuchsia/")
    list(FILTER angle_vulkan_backend_sources EXCLUDE REGEX "/null/")
    list(FILTER angle_vulkan_backend_sources EXCLUDE REGEX "/CL[A-Za-z0-9_]*\\.(cpp|h)$")
    list(FILTER angle_vulkan_backend_sources EXCLUDE REGEX "/cl_types\\.h$")
    list(FILTER angle_vulkan_backend_sources EXCLUDE REGEX "/clspv_utils\\.(cpp|h)$")
    list(FILTER angle_vulkan_backend_sources EXCLUDE REGEX "/vk_cl_utils\\.(cpp|h)$")

    if(NOT WIN32)
        list(FILTER angle_vulkan_backend_sources EXCLUDE REGEX "/win32/")
    endif()

    if(NOT _angle_is_linux)
        list(FILTER angle_vulkan_backend_sources EXCLUDE REGEX "/linux/")
    else()
        if(NOT ANGLE_USE_X11)
            list(FILTER angle_vulkan_backend_sources EXCLUDE REGEX "/linux/xcb/")
        endif()
        if(NOT ANGLE_USE_WAYLAND)
            list(FILTER angle_vulkan_backend_sources EXCLUDE REGEX "/linux/wayland/")
        endif()
        if(NOT ANGLE_USE_GBM)
            list(FILTER angle_vulkan_backend_sources EXCLUDE REGEX "/linux/gbm/")
        endif()
    endif()

    if(NOT APPLE)
        list(FILTER angle_vulkan_backend_sources EXCLUDE REGEX "/mac/")
    endif()

    add_library(angle_vulkan_backend STATIC ${angle_vulkan_backend_sources})
    add_library(ANGLE::vulkan_backend ALIAS angle_vulkan_backend)
    target_compile_features(angle_vulkan_backend PUBLIC cxx_std_20)
    target_link_libraries(angle_vulkan_backend
        PUBLIC
            angle_common
            angle_compression
            angle_gpu_info_util
            angle_image_util
            angle_libvulkan_loader
            angle_spirv_base
            angle_spirv_builder
            angle_spirv_headers
            angle_spirv_parser
            angle_translator_headers
            angle_vk_mem_alloc_wrapper
            angle_vulkan_entry_points
            angle_vulkan_headers
            angle_vulkan_icd)
    target_include_directories(angle_vulkan_backend
        PUBLIC
            ${PROJECT_SOURCE_DIR}/src
            ${PROJECT_SOURCE_DIR}/third_party/vulkan_memory_allocator/include
            ${PROJECT_SOURCE_DIR}/third_party/zlib
            ${PROJECT_SOURCE_DIR}/third_party/zlib/google)
    target_compile_definitions(angle_vulkan_backend
        PUBLIC
            LIBANGLE_IMPLEMENTATION
            ANGLE_ENABLE_CRC_FOR_PIPELINE_CACHE
            ANGLE_USE_CUSTOM_VULKAN_OUTSIDE_RENDER_PASS_CMD_BUFFERS=1
            ANGLE_USE_CUSTOM_VULKAN_RENDER_PASS_CMD_BUFFERS=1)

    if(TARGET angle_dma_buf)
        target_link_libraries(angle_vulkan_backend PUBLIC angle_dma_buf)
    endif()

    if(_angle_is_linux)
        if(ANGLE_USE_X11)
            target_link_libraries(angle_vulkan_backend PUBLIC xcb)
        endif()
        if(ANGLE_USE_WAYLAND)
            target_link_libraries(angle_vulkan_backend PUBLIC wayland-client wayland-egl)
        endif()
        if(ANGLE_USE_GBM)
            target_link_libraries(angle_vulkan_backend PUBLIC gbm)
        endif()
    elseif(APPLE)
        target_link_libraries(angle_vulkan_backend
            PUBLIC
                ${ANGLE_APPLE_COCOA_FRAMEWORK}
                ${ANGLE_APPLE_IOSURFACE_FRAMEWORK}
                ${ANGLE_APPLE_METAL_FRAMEWORK}
                ${ANGLE_APPLE_QUARTZCORE_FRAMEWORK})
    endif()
endif()

angle_collect_text_sources(angle_libangle_sources
    "${PROJECT_SOURCE_DIR}/src/libANGLE")

list(FILTER angle_libangle_sources EXCLUDE REGEX "_unittest\\.cpp$")
list(FILTER angle_libangle_sources EXCLUDE REGEX "/capture/")
list(FILTER angle_libangle_sources EXCLUDE REGEX "/renderer/cl/")
list(FILTER angle_libangle_sources EXCLUDE REGEX "/renderer/d3d/")
list(FILTER angle_libangle_sources EXCLUDE REGEX "/renderer/gl/")
list(FILTER angle_libangle_sources EXCLUDE REGEX "/renderer/metal/")
list(FILTER angle_libangle_sources EXCLUDE REGEX "/renderer/null/")
list(FILTER angle_libangle_sources EXCLUDE REGEX "/renderer/vulkan/")
list(FILTER angle_libangle_sources EXCLUDE REGEX "/renderer/wgpu/")
list(FILTER angle_libangle_sources EXCLUDE REGEX "/renderer/d3d_format")
list(FILTER angle_libangle_sources EXCLUDE REGEX "/renderer/dxgi_")
list(FILTER angle_libangle_sources EXCLUDE REGEX "/libANGLE/CL")
list(FILTER angle_libangle_sources EXCLUDE REGEX "/renderer/CL")
list(FILTER angle_libangle_sources EXCLUDE REGEX "/cl_")
list(FILTER angle_libangle_sources EXCLUDE REGEX "/validationCL")

if(NOT APPLE)
    list(FILTER angle_libangle_sources EXCLUDE REGEX "\\.mm$")
endif()

add_library(libANGLE STATIC ${angle_libangle_sources})
add_library(ANGLE::libANGLE ALIAS libANGLE)
set_target_properties(libANGLE PROPERTIES OUTPUT_NAME ANGLE)
target_compile_features(libANGLE PUBLIC cxx_std_20)
target_link_libraries(libANGLE
    PUBLIC
        angle_common
        angle_common_shader_state
        angle_gpu_info_util
        angle_image_util
        angle_version_info
        translator)

if(ANGLE_ENABLE_NULL)
    target_link_libraries(libANGLE PUBLIC angle_null_backend)
endif()

if(TARGET angle_gl_backend)
    target_link_libraries(libANGLE PUBLIC angle_gl_backend)
endif()

if(TARGET angle_metal_backend)
    target_link_libraries(libANGLE PUBLIC angle_metal_backend)
endif()

if(TARGET angle_vulkan_backend)
    target_link_libraries(libANGLE PUBLIC angle_vulkan_backend)
endif()

if(TARGET angle_d3d9_backend)
    target_link_libraries(libANGLE PUBLIC angle_d3d9_backend)
endif()

if(TARGET angle_d3d11_backend)
    target_link_libraries(libANGLE PUBLIC angle_d3d11_backend)
endif()

target_include_directories(libANGLE
    PUBLIC
        ${PROJECT_SOURCE_DIR}/src
        ${PROJECT_SOURCE_DIR}/third_party/zlib/google
        ${PROJECT_SOURCE_DIR}/third_party/zlib)
target_compile_definitions(libANGLE
    PUBLIC
        LIBANGLE_IMPLEMENTATION
        $<$<NOT:$<BOOL:${ANDROID}>>:ANGLE_PLATFORM_EXPORT=>
        $<$<BOOL:${ANGLE_USE_X11}>:ANGLE_USE_X11>
        $<$<BOOL:${ANGLE_USE_WAYLAND}>:ANGLE_USE_WAYLAND>
        $<$<BOOL:${ANGLE_USE_GBM}>:ANGLE_USE_GBM>)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_definitions(libANGLE PRIVATE ANGLE_GENERATE_SHADER_DEBUG_INFO)
endif()

if(WIN32)
    target_link_libraries(libANGLE PUBLIC gdi32 user32)
endif()

angle_collect_text_sources(angle_libglesv2_sources
    "${PROJECT_SOURCE_DIR}/src/libGLESv2")

list(FILTER angle_libglesv2_sources EXCLUDE REGEX "/cl_")
list(FILTER angle_libglesv2_sources EXCLUDE REGEX "/entry_points_cl")
list(FILTER angle_libglesv2_sources EXCLUDE REGEX "/proc_table_cl")

add_library(libGLESv2 STATIC ${angle_libglesv2_sources})
add_library(ANGLE::libGLESv2 ALIAS libGLESv2)
set_target_properties(libGLESv2 PROPERTIES OUTPUT_NAME GLESv2)
target_compile_features(libGLESv2 PUBLIC cxx_std_20)
target_link_libraries(libGLESv2
    PUBLIC
        angle_library_name_config
        libANGLE)
target_include_directories(libGLESv2 PUBLIC ${PROJECT_SOURCE_DIR}/src)
target_compile_definitions(libGLESv2
    PUBLIC
        LIBGLESV2_IMPLEMENTATION
        ANGLE_EXPORT=
        ANGLE_STATIC=1
        ANGLE_UTIL_EXPORT=
        EGLAPI=
        GL_APICALL=
        GL_API=)

add_library(libEGL STATIC
    ${PROJECT_SOURCE_DIR}/src/libEGL/libEGL_autogen.cpp
    ${PROJECT_SOURCE_DIR}/src/libEGL/resource.h)
add_library(ANGLE::libEGL ALIAS libEGL)
set_target_properties(libEGL PROPERTIES OUTPUT_NAME EGL)
target_compile_features(libEGL PUBLIC cxx_std_20)
target_link_libraries(libEGL
    PUBLIC
        angle_common
        angle_library_name_config
        libEGL_egl_loader
        libGLESv2)
target_include_directories(libEGL PUBLIC ${PROJECT_SOURCE_DIR}/src)
target_compile_definitions(libEGL
    PUBLIC
        LIBEGL_IMPLEMENTATION
        ANGLE_DISPATCH_LIBRARY="libGLESv2"
        EGLAPI=)

add_library(libGLESv1_CM STATIC
    ${PROJECT_SOURCE_DIR}/src/libGLESv1_CM/libGLESv1_CM.cpp
    ${PROJECT_SOURCE_DIR}/src/libGLESv1_CM/resource.h)
add_library(ANGLE::libGLESv1_CM ALIAS libGLESv1_CM)
set_target_properties(libGLESv1_CM PROPERTIES OUTPUT_NAME GLESv1_CM)
target_compile_features(libGLESv1_CM PUBLIC cxx_std_20)
target_link_libraries(libGLESv1_CM PUBLIC libGLESv2)
target_include_directories(libGLESv1_CM PUBLIC ${PROJECT_SOURCE_DIR}/src)
target_compile_definitions(libGLESv1_CM
    PUBLIC
        ANGLE_EXPORT=
        ANGLE_STATIC=1
        ANGLE_UTIL_EXPORT=
        EGLAPI=
        GL_APICALL=
        GL_API=)

angle_add_interface_target(libfeature_support)
add_library(ANGLE::libfeature_support ALIAS libfeature_support)
target_link_libraries(libfeature_support INTERFACE angle_common)

if(ANGLE_ENABLE_VULKAN_SECONDARIES)
    angle_add_interface_target(libANGLE_vulkan_secondaries)
    add_library(ANGLE::libANGLE_vulkan_secondaries ALIAS libANGLE_vulkan_secondaries)
    target_link_libraries(libANGLE_vulkan_secondaries INTERFACE angle_common translator)

    angle_add_interface_target(libGLESv2_vulkan_secondaries)
    add_library(ANGLE::libGLESv2_vulkan_secondaries ALIAS libGLESv2_vulkan_secondaries)
    target_link_libraries(libGLESv2_vulkan_secondaries
        INTERFACE
            angle_library_name_config
            libANGLE_vulkan_secondaries)

    angle_add_interface_target(libEGL_vulkan_secondaries)
    add_library(ANGLE::libEGL_vulkan_secondaries ALIAS libEGL_vulkan_secondaries)
    target_link_libraries(libEGL_vulkan_secondaries
        INTERFACE
            angle_common
            angle_library_name_config
            libGLESv2_vulkan_secondaries)
endif()
