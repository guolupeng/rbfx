
add_library(spdlog INTERFACE)
target_include_directories(spdlog INTERFACE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
target_link_libraries(spdlog INTERFACE fmt)
target_compile_definitions(spdlog INTERFACE -DSPDLOG_FMT_EXTERNAL=1)
install (TARGETS spdlog EXPORT Urho3D)
