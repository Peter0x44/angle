# ANGLE Desktop CMake Overlay

This repository now contains an initial desktop-only CMake overlay.

Current scope:

- Desktop platforms only: Windows, Linux, and macOS.
- Android, Fuchsia, and OpenCL are intentionally out of scope.
- The configure step models the desktop backend option matrix and now builds a small set of real internal libraries.

Current limitations:

- Only a subset of GN-owned targets are wired as concrete CMake libraries so far.
- The public desktop libraries are currently wired as static libraries only; shared-library parity is still incomplete.
- Code generation is still expected to come from the checked-in generated sources.
- Version-header generation in the overlay is handled by CMake helper scripts rather than requiring Python.
- WGPU is represented in the option matrix, but Dawn dependency wiring is not implemented yet.
- The overlay expects a C++20 toolchain, matching ANGLE's current GN configuration.
- The Linux and macOS backend graph is now wired for host-native configure/build work, but runtime smoke coverage on those hosts is still pending.
- Advancing the Vulkan translator stack additionally requires populated `third_party/spirv-headers/src` and `third_party/spirv-tools/src` contents in the checkout. In a plain git clone, run `git submodule update --init -- third_party/spirv-headers/src third_party/spirv-tools/src`; in a depot_tools checkout, `gclient sync` also populates them.
- Building the Vulkan backend also requires populated `third_party/vulkan-headers/src` and `third_party/vulkan_memory_allocator` contents in the checkout. In a plain git clone, run `git submodule update --init -- third_party/vulkan-headers/src third_party/vulkan_memory_allocator`; in a depot_tools checkout, `gclient sync` also populates them.

Currently wired real libraries:

- `angle_xxhash`
- `angle_common`
- `angle_common_shader_state`
- `angle_image_util`
- `angle_gpu_info_util`
- `angle_libxnvctrl` on Linux when `ANGLE_USE_X11=ON`
- `angle_dma_buf` on Linux when GL or Vulkan support is enabled
- `angle_compression`
- `preprocessor`
- `angle_spirv_base`
- `angle_spirv_builder`
- `angle_spirv_parser`
- `angle_version_info`
- `translator`
- `angle_d3d_format_tables`
- `angle_d3d_shared`
- `angle_d3d9_backend` when `ANGLE_ENABLE_D3D9=ON`
- `angle_d3d11_backend` when `ANGLE_ENABLE_D3D11=ON`
- `angle_null_backend` when `ANGLE_ENABLE_NULL=ON`
- `angle_gl_backend` on desktop hosts when `ANGLE_ENABLE_GL=ON`
- `angle_metal_backend` on macOS when `ANGLE_ENABLE_METAL=ON`
- `angle_vulkan_headers`
- `angle_volk`
- `angle_libvulkan_loader`
- `angle_vulkan_icd`
- `angle_vk_mem_alloc_wrapper`
- `angle_vulkan_backend` on desktop hosts when `ANGLE_ENABLE_VULKAN=ON`
- `libANGLE`
- `libGLESv2`
- `libEGL`
- `libGLESv1_CM`
- `libEGL_egl_loader`
- `angle_gl_enum_utils`

Current validation status:

- `desktop-mingw` builds the public static desktop stack with Null, GL, and Vulkan enabled by default.
- Dedicated MinGW probe builds now also compile `libANGLE` with `ANGLE_ENABLE_D3D11=ON` and `ANGLE_ENABLE_D3D9=ON` in separate build trees.
- GitHub Actions now configure and build the public static desktop targets through `desktop-msvc`, `desktop-linux`, and `desktop-macos`.
- The current validation surface is still static-library oriented; shared-library parity, install/export support, and runtime smoke coverage are still in progress.

Configure example:

```sh
cmake -S . -B out/cmake-desktop -G Ninja
```

Preset examples:

```sh
cmake --list-presets
cmake --preset desktop-mingw
```

The current presets are desktop-only and focus on host-native development:

- `desktop-mingw` keeps Windows MinGW on the GL, Vulkan, and Null path first.
- `desktop-msvc` keeps the Windows D3D backends enabled for a Visual Studio developer environment.
- `desktop-linux` and `desktop-macos` express the expected desktop backend defaults for those platforms.

Planned next steps:

1. Add a GN-to-CMake source inventory bridge so the CMake overlay does not hand-maintain source lists.
2. Replace the remaining placeholder interface targets, starting with `libfeature_support` and any Vulkan secondaries support needed for parity.
3. Add runtime smoke tests on Windows, Linux, and macOS so the new CI coverage checks backend bring-up rather than only host-native compilation.
4. Add shared-library parity, install/export support, and a small smoke-test/sample layer on top of the static desktop stack.
