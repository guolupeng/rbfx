#
# Copyright (c) 2008-2017 the Urho3D project.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

# Set CMake minimum version and CMake policy required by UrhoCommon module
cmake_minimum_required (VERSION 3.4.3)

# Set project name
project (Urho3D)

# Set CMake modules search path
set (CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/CMake/Modules)

# Include file that sets up all configurable properties
include(UrhoOptions)

# Include common utilitles
include(UrhoCommon)

# Enable common build options
if (NOT DEFINED CMAKE_CXX_STANDARD)
    set (CMAKE_CXX_STANDARD 14)
endif ()

# Workarounds
if (EMSCRIPTEN OR APPLE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++${CMAKE_CXX_STANDARD}")
endif ()
if (APPLE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
endif ()

set (CMAKE_EXPORT_COMPILE_COMMANDS ON)
set (CMAKE_INCLUDE_CURRENT_DIR ON)
set (CMAKE_POSITION_INDEPENDENT_CODE ON)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

if (URHO3D_SSE AND NOT MSVC)
    # Build engine and it's dependencies with SSE/SSE2 enabled.
    set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -msse -msse2")
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -msse -msse2")
endif ()

if (URHO3D_STATIC_RUNTIME)
    ucm_set_runtime(STATIC)
else ()
    ucm_set_runtime(DYNAMIC)
endif ()

add_subdirectory(Source)

include(UrhoPackaging)

# Print current build configuration
message(STATUS "Urho3D Configuration:")
if (URHO3D_STATIC_RUNTIME)
    message(STATUS "  Runtime         STATIC")
else ()
    message(STATUS "  Runtime         SHARED")
endif ()
if (BUILD_SHARED_LIBS)
    message(STATUS "  Library         SHARED")
else ()
    message(STATUS "  Library         STATIC")
endif ()
message(STATUS "  SSE             ${URHO3D_SSE}")
message(STATUS "  2D              ${URHO3D_URHO2D}")
message(STATUS "  IK              ${URHO3D_IK}")
message(STATUS "  Threading       ${URHO3D_THREADING}")
message(STATUS "  Navigation      ${URHO3D_NAVIGATION}")
message(STATUS "  Network         ${URHO3D_NETWORK}")
message(STATUS "  Physics         ${URHO3D_PHYSICS}")
message(STATUS "  Samples         ${URHO3D_SAMPLES}")
message(STATUS "  WebP            ${URHO3D_WEBP}")
message(STATUS "  CSharp          ${URHO3D_CSHARP}")
if (WIN32)
    message(STATUS "  MiniDumps       ${URHO3D_MINIDUMPS}")
endif()
message(STATUS "Developer options:")
message(STATUS "  Packaging       ${URHO3D_PACKAGING}")
message(STATUS "  SystemUI        ${URHO3D_SYSTEMUI}")
message(STATUS "  Logging         ${URHO3D_LOGGING}")
message(STATUS "  Profiling       ${URHO3D_PROFILING}")
message(STATUS "  Extras          ${URHO3D_EXTRAS}")
message(STATUS "  Tools           ${URHO3D_TOOLS}")
message(STATUS "  Docs            ${URHO3D_DOCS}")
if (TARGET Profiler)
    message(STATUS "     Profiler GUI ${URHO3D_PROFILING}")
endif ()

# clang-tidy target
find_program(CLANG_TIDY clang-tidy)
if (CLANG_TIDY)
    file (GLOB_RECURSE SOURCE_FILES
        Source/Samples/**.cpp Source/Samples/**.h Source/Samples/**.hpp Source/Samples/**.inl
        Source/Urho3D/**.cpp Source/Urho3D/**.h Source/Urho3D/**.hpp
        Source/Tools/**.cpp Source/Tools/**.h Source/Tools/**.hpp
    )
    add_custom_target(tidy
        COMMAND ${CLANG_TIDY} -p . -export-fixes=clang-tidy.yml -fix ${SOURCE_FILES}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
    set_target_properties(tidy PROPERTIES EXCLUDE_FROM_ALL 1 EXCLUDE_FROM_DEFAULT_BUILD 1)
endif()

################################################### SDK preparation ####################################################
if (MINI_URHO)
    return ()
endif ()

if (URHO3D_DOCS)
    add_subdirectory(Docs)
endif ()

# Install CMake modules and toolchains provided by and for Urho3D
install (DIRECTORY ${CMAKE_SOURCE_DIR}/CMake/ DESTINATION ${DEST_SHARE_DIR}/CMake)    # Note: the trailing slash is significant
# Install CMake build scripts
file (GLOB CMAKE_SCRIPTS ${CMAKE_SOURCE_DIR}/Script/*${SCRIPT_EXT})
install (PROGRAMS ${CMAKE_SCRIPTS} DESTINATION ${DEST_SHARE_DIR}/Scripts)
# Install data files
file (MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
if (NOT ANDROID)
    file (MAKE_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Autoload)
    foreach (RES_DIR ${RESOURCE_DIRS})
        get_filename_component (NAME ${RES_DIR} NAME)
        install (DIRECTORY ${RES_DIR} DESTINATION ${DEST_RESOURCE_DIR})
        if (NOT EXISTS ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${NAME})
            create_symlink(${RES_DIR} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${NAME})
        endif ()
    endforeach ()
    foreach (RES_DIR ${AUTOLOAD_DIRS})
        get_filename_component (NAME ${RES_DIR} NAME)
        install (DIRECTORY ${RES_DIR} DESTINATION ${DEST_RESOURCE_DIR}/Autoload)
        if (NOT EXISTS ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Autoload/${NAME})
            create_symlink(${RES_DIR} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Autoload/${NAME})
        endif ()
    endforeach ()
endif ()
