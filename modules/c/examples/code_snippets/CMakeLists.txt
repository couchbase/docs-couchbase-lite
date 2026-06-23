cmake_minimum_required(VERSION 3.11)
cmake_policy(VERSION 3.11)
cmake_policy(SET CMP0077 NEW)

# Mac/apple setup -- must appear before the first "project()" line"
set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15")
if(NOT DEFINED CMAKE_OSX_SYSROOT)
    # Tells Mac builds to use the current SDK's headers & libs, not what's in the OS.
    set(CMAKE_OSX_SYSROOT macosx)
endif()

if(DEFINED CBL_MACOS_ARCH)
    set(CMAKE_OSX_ARCHITECTURES ${CBL_MACOS_ARCH})
endif()

if(NOT DEFINED CBL_VERSION)
    set(CBL_VERSION 4.1.0)
endif()

project(code-snippets)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR}/out)

if(NOT CMAKE_PREFIX_PATH)
    set(CMAKE_PREFIX_PATH "${CMAKE_SOURCE_DIR}/libcblite-${CBL_VERSION}")
endif()
find_package(CouchbaseLite ${CBL_VERSION} REQUIRED)

add_executable(
    code-snippets
        main.cpp
        VectorSearch.h
)

# These files are a catalog of doc snippets, not a real app: main() is empty and
# every snippet function is intentionally uncalled. Silence the resulting
# "unused function" noise so genuine warnings stay visible.
if(MSVC)
    target_compile_options(code-snippets PRIVATE /wd4505)
else()
    target_compile_options(code-snippets PRIVATE -Wno-unused-function)
endif()

if(CMAKE_COMPILER_IS_GNUCC AND CBL_STATIC_CXX)
    target_compile_options(code-snippets PRIVATE -Wno-psabi)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libstdc++")
endif()

target_link_libraries(
    code-snippets PRIVATE
    cblite
)

if(MSVC)
    target_compile_options(
        code-snippets PRIVATE
        -D_WIN32_WINNT=0x0A00
        -DWIN32_LEAN_AND_MEAN
    )
endif()