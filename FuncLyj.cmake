# ########################test###################################
# ${ARGC} 所有传入变量的数量
# ${ARGV} 所有传入的变量，本质为LIST
# ${ARGN} 传入的未命名变量
# ${ARG0}、${ARG1}、${ARG2}... 具体参数

# set(var "ABC")

# macro(Moo arg) #相当于c++中的lambda表达式和#define的结合，无返回值
# message("arg = ${arg}")
# set(arg "abc" PARENT_SCOPE) # 无效
# message("# After change the value of arg.")
# message("arg = ${arg}")
# endmacro()
# message("=== Call macro ===")
# Moo(${var})
# message("arg1 = ${var}")

# macro(Moo) #相当于c++中的lambda表达式和#define的结合，无返回值
# message("var = ${var}")
# set(var "abc")
# message("# After change the value of arg.")
# message("var = ${var}")
# endmacro()
# message("=== Call macro ===")
# Moo()
# message("arg1 = ${var}")

# set(${var} "aaa")
# function(Foo arg) #相当于c++中的函数
# message("arg = ${arg}")
# set(arg "abc" PARENT_SCOPE) # 没有通过参数传进来无效
# set(arg "abc")
# message("# After change the value of arg.")
# message("arg = ${arg}")
# endfunction()
# message("=== Call function ===")
# Foo(${var}) # 这里相当于${arg} = ${var}
# message("arg2 = ${var}")
# message("${var} = ${${var}}")

# function(Foo2 arg) #相当于c++中的函数
# message("${arg} = ${${arg}}")
# set(${arg} "abc" PARENT_SCOPE) #只修改外部
# set(${arg} "abc") # 只修改内部
# message("# After change the value of arg.")
# message("${arg} = ${${arg}}")
# endfunction()
# message("=== Call function2 ===")
# Foo2(var) # 这里相当于${arg} = var
# message("arg3 = ${var}")

# ########################test###################################

# ##########################Findpackage relative path###########################
# set(GLEW_FOUND TRUE)
# set(GLEW_DIR ${CMAKE_CURRENT_LIST_DIR})
# set(GLEW_LIBRARY_DIR ${GLEW_DIR}/lib/Release/x64)
# add_library(GLEW::GLEW SHARED IMPORTED GLOBAL)
# set_target_properties(GLEW::GLEW PROPERTIES
#     INTERFACE_INCLUDE_DIRECTORIES "${GLEW_DIR}/include"  # 头文件
#     IMPORTED_IMPLIB_RELEASE  "${GLEW_LIBRARY_DIR}/glew32.lib"       # 库文件
#     IMPORTED_LOCATION_RELEASE "${GLEW_DIR}/bin/glew32.dll"
#     # INTERFACE_LINK_LIBRARIES "pango_core;pango_opengl;pango_windowing;pango_vars"
# )
# ##########################Findpackage relative path###########################



# 开启文件夹显示
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# check conan
# [out] CONAN_STORAGE_PATH
function(CheckConan CONAN_STORAGE_PATH)
    execute_process(
        COMMAND conan config get storage
        OUTPUT_VARIABLE CONAN_PATH
        RESULT_VARIABLE CONAN_RET
    )

    if(NOT CONAN_PATH)
        message(FATAL_ERROR "NO CONAN")
    endif()

    set(${CONAN_STORAGE_PATH} ${CONAN_PATH} PARENT_SCOPE)
endfunction(CheckConan CONAN_STORAGE_PATH)

# 获取指定conan包的最新版本信息
# [in] PKG_NAME
# [out] PKG_VERSION
# [out] PKG_USER
# [out] PKG_CHANNEL
function(GetPKGInfoInConan PKG_NAME PKG_VERSION PKG_USER PKG_CHANNEL)
    execute_process(
        COMMAND conan search ${PKG_NAME}*
        OUTPUT_VARIABLE CONAN_${PKG_NAME}_PATHS
        RESULT_VARIABLE CONAN_RET
    )

    if(NOT CONAN_RET EQUAL 0)
        message(WARNING "can not found any ${PKG_NAME}")
    endif()

    string(REPLACE "\n" "---" OUTPUT_LINES "${CONAN_${PKG_NAME}_PATHS}")

    foreach(line IN LISTS OUTPUT_LINES)
        if(line MATCHES "^.*---(.*)/(.*)@(.*)/(.*)---$")
            string(STRIP ${CMAKE_MATCH_1} VALUE1)
            string(STRIP ${CMAKE_MATCH_2} VALUE2)
            string(STRIP ${CMAKE_MATCH_3} VALUE3)
            string(STRIP ${CMAKE_MATCH_4} VALUE4)
            set(${PKG_VERSION} ${VALUE2} PARENT_SCOPE)
            set(${PKG_USER} ${VALUE3} PARENT_SCOPE)
            set(${PKG_CHANNEL} ${VALUE4} PARENT_SCOPE)
        endif()
    endforeach(line IN LISTS OUTPUT_LINES)
endfunction(GetPKGInfoInConan PKG_NAME PKG_VERSION PKG_USER PKG_CHANNEL)

# 给定包信息，在conan中搜索，并在cmakecache中设置.cmake路径，输出debug：add cmake cache variable...
# [in] PKG_NAME
# [in] PKG_VERSION
# [in] PKG_USER
# [in] PKG_CHANNEL
function(FindConanPKG PKG_NAME PKG_VERSION PKG_USER PKG_CHANNEL)
    execute_process(
        COMMAND conan info ${PKG_NAME}/${PKG_VERSION}@${PKG_USER}/${PKG_CHANNEL} --paths
        OUTPUT_VARIABLE CONAN_${PKG_NAME}_PATH
        RESULT_VARIABLE CONAN_RET
    )

    if(NOT CONAN_RET EQUAL 0)
        message(WARNING "can not found any ${PKG_NAME}")
        return()
    endif()

    string(REPLACE "\n" ";" OUTPUT_LINES "${CONAN_${PKG_NAME}_PATH}")

    foreach(line IN LISTS OUTPUT_LINES)
        if(line MATCHES "([\\sa-zA-Z_]+):[ \\s]*(.*)")
            string(TOUPPER "${CMAKE_MATCH_1}" KEY)
            string(TOUPPER "${CMAKE_MATCH_2}" VALUE)

            if(KEY MATCHES "PACKAGE_FOLDER")
                file(TO_CMAKE_PATH "${VALUE}" VALUE)
                set(CONAN_${PKG_NAME}_${KEY} "${VALUE}")
            endif()
        endif()
    endforeach(line IN LISTS OUTPUT_LINES)

    file(GLOB_RECURSE CONAN_${PKG_NAME}_CMAKES "${CONAN_${PKG_NAME}_PACKAGE_FOLDER}/Find${PKG_NAME}*.cmake")

    if(NOT CONAN_${PKG_NAME}_CMAKES)
        file(GLOB_RECURSE CONAN_${PKG_NAME}_CMAKES "${CONAN_${PKG_NAME}_PACKAGE_FOLDER}/${PKG_NAME}*Config.cmake")

        if(NOT CONAN_${PKG_NAME}_CMAKES)
            message(WARNING "can not found any ${PKG_NAME}.cmake")
            return()
        endif()
    endif()

    foreach(CCC IN LISTS CONAN_${PKG_NAME}_CMAKES)
        set(regex "^.*/Find(${PKG_NAME}.?)\.cmake$")

        if("${CCC}" MATCHES "${regex}")
            set(REAL_PKG_NAME ${CMAKE_MATCH_1})
            set(CONAN_${PKG_NAME}_CMAKE ${CCC})
            continue()
        endif()

        set(regex2 "^.*/(${PKG_NAME}.?)Config\.cmake$")

        if("${CCC}" MATCHES "${regex2}")
            set(REAL_PKG_NAME ${CMAKE_MATCH_1})
            set(CONAN_${PKG_NAME}_CMAKE ${CCC})
            continue()
        endif()
    endforeach(CCC IN LISTS CONAN_${PKG_NAME}_CMAKES)

    get_filename_component(CONAN_${PKG_NAME}_PACKAGE_FOLDER "${CONAN_${PKG_NAME}_CMAKE}" DIRECTORY)
    unset(CONAN_${PKG_NAME}_PACKAGE_FOLDER CACHE)
    unset(${REAL_PKG_NAME}_DIR CACHE)
    set(CONAN_${PKG_NAME}_PACKAGE_FOLDER "${CONAN_${PKG_NAME}_PACKAGE_FOLDER}" CACHE STRING "${PKG_NAME} conan")
    set(${REAL_PKG_NAME}_DIR "${CONAN_${PKG_NAME}_PACKAGE_FOLDER}" CACHE STRING "${PKG_NAME}_DIR conan")
endfunction(FindConanPKG PKG_NAME PKG_VERSION PKG_USER PKG_CHANNEL)

# 获取目录下面所有的目录（非递归）
# [in] dir: current dir
# [out] DIRS: dir in current dir
function(Find_Items dir DIRS)
    # 清空现有的列表
    set(DIRSTMP)

    # 使用 GLOB 命令获取当前目录下的所有项
    file(GLOB ALL_ITEMS "${dir}/*")

    # 遍历所有项，筛选出目录
    foreach(ITEM ${ALL_ITEMS})
        if(IS_DIRECTORY ${ITEM})
            get_filename_component(DIR_NAME ${ITEM} NAME) # 获取目录名称

            if("${DIR_NAME}" STREQUAL "build")
                message("skip build directory!")
            elseif("${DIR_NAME}" STREQUAL "example")
                message("skip example directory!")
            elseif("${DIR_NAME}" STREQUAL "install")
                message("skip install directory!")
            elseif("${DIR_NAME}" STREQUAL "Output")
                message("skip Output directory!")
            elseif("${DIR_NAME}" STREQUAL "thirdParty")
                message("skip thirdParty directory!")
            else()
                list(APPEND DIRSTMP ${ITEM}) # 将目录添加到列表中
            endif()
        endif()
    endforeach()

    set(${DIRS} ${DIRSTMP} PARENT_SCOPE)
endfunction(Find_Items)

# 整合当前路径的.h和.cpp文件，返回列表并在工程中以文件夹显示
# [out] SRCS: list of .h and .cpp
# [in] dir: input absolute dir
# [in] FstDirName: first directories name, advice use "."
function(GroupFiles SRCS dir FstDirName)
    set(SRCSTMP ${${SRCS}})

    set(ALL_ITEMS)
    Find_Items(${dir} ALL_ITEMS)
    set(ALL_FILES)
    file(GLOB ALL_FILES "${dir}/*.h" "${dir}/*.cpp" "${dir}/*.hpp")

    if(MSVC)
        source_group(${FstDirName}/${_source_path_msvc} FILES ${ALL_FILES})
    endif()

    list(APPEND SRCSTMP ${ALL_FILES})

    # 输出所有文件夹的名称和路径
    if(ALL_ITEMS)
        foreach(DIRTMP ${ALL_ITEMS})
            get_filename_component(DIR_NAME ${DIRTMP} NAME) # 获取目录名称
            GroupFiles(SRCSTMP ${DIRTMP} ${FstDirName}/${DIR_NAME})
        endforeach()
    endif()

    set(${SRCS} ${SRCSTMP} PARENT_SCOPE)
endfunction()

# 查找当前目录下的所有子目录（递归，不包含当前目录）
# [out] DIRS
# [in] dir: current dir
function(GroupDirs DIRS dir LEVEL)
    if(${LEVEL} EQUAL 0)
        return()
    endif()

    set(DIRSTMP ${${DIRS}})

    Find_Items(${dir} ALL_ITEMS)
    list(APPEND DIRSTMP ${ALL_ITEMS})
    math(EXPR SUBLEVEL "${LEVEL} - 1" OUTPUT_FORMAT DECIMAL)

    if(${SUBLEVEL} GREATER_EQUAL 0)
        if(ALL_ITEMS)
            foreach(DIRTMP ${ALL_ITEMS})
                GroupDirs(DIRSTMP ${DIRTMP} ${SUBLEVEL})
            endforeach()
        endif()
    endif()

    set(${DIRS} ${DIRSTMP} PARENT_SCOPE)
endfunction()
