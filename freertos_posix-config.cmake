# Copyright 2023 NXP

include(CMakeFindDependencyMacro)
find_dependency(FreeRTOS_cpp11)

include(${CMAKE_CURRENT_LIST_DIR}/FreeRTOS_POSIX.cmake)
