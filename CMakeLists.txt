project (glib-c-annotator)

cmake_minimum_required (VERSION 2.6)
# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set (EXEC_NAME "glib-c-annotator")
set (RELEASE_NAME "Tool for improving the clang static analyzer functionality when analyzing c code using GLib, GObject.")
set (VERSION "0.0")
set (VERSION_INFO "Not doing much, yet")

# find pkgconfig to make sure dependencies are installed
find_package(PkgConfig)
# check for the required dependencies
pkg_check_modules(DEPS REQUIRED
    gee-0.8
    libxml-2.0
    gio-2.0
)

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

# disable c compiler warnings
add_definitions(-w)
add_definitions(-g)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# make sure we have vala
find_package(Vala REQUIRED)
# make sure we use vala
include(ValaVersion)
# make sure it's the desired version of vala
ensure_vala_version("0.26" MINIMUM)

# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    src/CMatcher.vala
    src/ConstructorMap.vala
    src/GirParser.vala
    src/Main.vala

# tell what libraries to use when compiling
PACKAGES
    gee-0.8
    libxml-2.0
    gio-2.0
)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C})
