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

# 开启文件夹显示
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

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
    file(GLOB ALL_FILES "${dir}/*.h" "${dir}/*.cpp")
    source_group(${FstDirName}/${_source_path_msvc} FILES ${ALL_FILES})
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
