
# Resource packaging
file (GLOB RESOURCE_DIRS ${CMAKE_SOURCE_DIR}/bin/*Data)
list (APPEND RESOURCE_DIRS ${CMAKE_SOURCE_DIR}/bin/Autoload)
if (URHO3D_PACKAGING)
    if (CMAKE_CROSSCOMPILING)
        include (ExternalProject)
        if (IOS OR TVOS)
            # When cross-compiling for iOS/tvOS the host environment has been altered by xcodebuild for the said platform, the following fix is required to reset the host environment before spawning another process to configure/generate project file for external project
            # Also workaround a known CMake/Xcode generator bug which prevents it from installing native tool binaries correctly
            set (ALTERNATE_COMMAND /usr/bin/env -i PATH=$ENV{PATH} CC=${SAVED_CC} CXX=${SAVED_CXX} CI=$ENV{CI} ${CMAKE_COMMAND} BUILD_COMMAND bash -c "sed -i '' 's/\$$\(EFFECTIVE_PLATFORM_NAME\)//g' CMakeScripts/install_postBuildPhase.make*")
        else ()
            set (ALTERNATE_COMMAND ${CMAKE_COMMAND} -E env CC=${SAVED_CC} CXX=${SAVED_CXX} CI=$ENV{CI} ${CMAKE_COMMAND})
        endif ()
        ExternalProject_Add (Urho3D-Native
            SOURCE_DIR ${Urho3D_SOURCE_DIR}
            CMAKE_COMMAND ${ALTERNATE_COMMAND}
            CMAKE_ARGS -DURHO3D_PACKAGING_TOOL=ON -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/native PackageTool
        )
        set (PACKAGE_TOOL ${CMAKE_BINARY_DIR}/native/bin/PackageTool)
    elseif (TARGET PackageTool)
        set (PACKAGE_TOOL $<TARGET_FILE:PackageTool>)
    else ()
        message(FATAL_ERROR "CMake misconfiguration")
    endif ()
    foreach (DIR ${RESOURCE_DIRS})
        get_filename_component (NAME ${DIR} NAME)
        if (ANDROID)
            set (RESOURCE_PATHNAME ${CMAKE_BINARY_DIR}/assets/${NAME}.pak)
        else ()
            set (RESOURCE_PATHNAME ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${NAME}.pak)
        endif ()
        list (APPEND PKG_COMMANDS COMMAND "${PACKAGE_TOOL}" "${DIR}" "${RESOURCE_PATHNAME}" -q -c)
    endforeach ()
    add_custom_target(pkg_resources ${PKG_COMMANDS})
    if (CMAKE_CROSSCOMPILING)
        add_dependencies(pkg_resources Urho3D-Native)
    endif ()
    if (EMSCRIPTEN)
        if (NOT EXISTS ${CMAKE_BINARY_DIR}/Source/pak-loader.js)
            file (WRITE ${CMAKE_BINARY_DIR}/Source/pak-loader.js "var Module;if(typeof Module==='undefined')Module=eval('(function(){try{return Module||{}}catch(e){return{}}})()');var s=document.createElement('script');s.src='${CMAKE_PROJECT_NAME}.js';document.body.appendChild(s);Module['preRun'].push(function(){Module['addRunDependency']('${CMAKE_PROJECT_NAME}.js.loader')});s.onload=function(){Module['removeRunDependency']('${CMAKE_PROJECT_NAME}.js.loader')};")
        endif ()
        foreach (DIR ${RESOURCE_DIRS})
            get_filename_component (NAME ${DIR} NAME)
            list (APPEND PAK_NAMES ${NAME}.pak)
        endforeach ()
        if (CMAKE_BUILD_TYPE STREQUAL Debug AND EMSCRIPTEN_EMCC_VERSION VERSION_GREATER 1.32.2)
            set (SEPARATE_METADATA --separate-metadata)
        endif ()
        set (SHARED_RESOURCE_JS ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${CMAKE_PROJECT_NAME}.js)
        add_custom_target (pkg_resources_web
            COMMAND ${EMPACKAGER} ${SHARED_RESOURCE_JS}.data --preload ${PAK_NAMES} --js-output=${SHARED_RESOURCE_JS} --use-preload-cache ${SEPARATE_METADATA}
            WORKING_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
            COMMENT "Generating shared data file"
        )
        add_dependencies(pkg_resources_web pkg_resources)
    endif ()
endif ()
