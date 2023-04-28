# Copyright 2023 NXP

cmake_minimum_required(VERSION 3.16)

project(FreeRTOS_iceoryx_example)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)

set(FREERTOS_DIR "${CMAKE_SOURCE_DIR}/../submodules/FreeRTOS_cpp11")
set(FREERTOS_TEST_DIR ${FREERTOS_DIR}/lib_test_CA9)

add_executable(iox_freertos_example
    ${FREERTOS_TEST_DIR}/startup_ARMCA9.cpp
    ${FREERTOS_TEST_DIR}/system_ARMCA9.c
    ${FREERTOS_TEST_DIR}/console.cpp
    ${FREERTOS_TEST_DIR}/ca9_global_timer.c
    ${FREERTOS_TEST_DIR}/cmsis/irq_ctrl_gic.c
    ${FREERTOS_TEST_DIR}/FreeRTOS_ca9_hooks.c
    ${FREERTOS_DIR}/sys_common/FreeRTOS_hooks.cpp
    ${FREERTOS_DIR}/sys_common/FreeRTOS_memory.cpp
    ${FREERTOS_DIR}/sys_common/sys.cpp
    hooks.c
    main.cpp
)

find_package(iceoryx_posh REQUIRED)
find_package(freertos_sdk REQUIRED COMPONENTS FreeRTOS_cpp11 FreeRTOS_POSIX)
find_package(Threads REQUIRED) # Needed by iceoryx_posh

target_link_libraries(iox_freertos_example
    PRIVATE
    iceoryx_posh::iceoryx_posh
    iceoryx_posh::iceoryx_posh_roudi
    freertos_sdk::FreeRTOS_cpp11
    freertos_sdk::FreeRTOS_POSIX
)

target_include_directories(iox_freertos_example
    PRIVATE
    ${FREERTOS_TEST_DIR}
    ${FREERTOS_TEST_DIR}/cmsis
)

set(LINKER_SCRIPT "${CMAKE_SOURCE_DIR}/linker.ld")
target_link_options(iox_freertos_example
    PRIVATE
    "-T${LINKER_SCRIPT}"
    "-Xlinker" "-Map=iox_freertos_example.map"
)
