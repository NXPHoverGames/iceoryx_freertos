# Copyright 2018-2023 Piotr Grygorczuk <grygorek@gmail.com>
# Copyright 2023 NXP

cmake_minimum_required(VERSION 3.0)
set(project freertos_sdk)
project(${project} LANGUAGES C CXX ASM)
set(version 1.0.0)

set(FREERTOS_DIR "submodules/FreeRTOS_cpp11")
set(FREERTOS_TEST_DIR ${FREERTOS_DIR}/lib_test_CA9)
set(FREERTOS_KERNEL_DIR ${FREERTOS_DIR}/FreeRTOS)
set(FREERTOS_POSIX_DIR "submodules/Lab-Project-FreeRTOS-POSIX")

if(CMAKE_CXX_COMPILER_VERSION LESS 11)
  SET(GCC_VER_DIR "v10")
else(CMAKE_CXX_COMPILER_VERSION LESS 11)
  SET(GCC_VER_DIR "v11")
endif(CMAKE_CXX_COMPILER_VERSION LESS 11)

set(FREERTOS_STDCPP_DIR "submodules/FreeRTOS_cpp11/libstdc++_gcc/${GCC_VER_DIR}")
set(IOX_DIR "submodules/iceoryx")

add_library(FreeRTOS_cpp11 STATIC 
  ${FREERTOS_KERNEL_DIR}/cpp11_gcc/freertos_time.cpp
  ${FREERTOS_KERNEL_DIR}/cpp11_gcc/gthr_key.cpp
  ${FREERTOS_KERNEL_DIR}/cpp11_gcc/thread.cpp

  ${FREERTOS_KERNEL_DIR}/Source/croutine.c
  ${FREERTOS_KERNEL_DIR}/Source/event_groups.c
  ${FREERTOS_KERNEL_DIR}/Source/list.c
  ${FREERTOS_KERNEL_DIR}/Source/queue.c
  ${FREERTOS_KERNEL_DIR}/Source/stream_buffer.c
  ${FREERTOS_KERNEL_DIR}/Source/tasks.c
  ${FREERTOS_KERNEL_DIR}/Source/timers.c

  ${FREERTOS_KERNEL_DIR}/Source/portable/MemMang/heap_4.c
  ${FREERTOS_KERNEL_DIR}/Source/portable/GCC/${CPU_ARCH}/port.c
  ${FREERTOS_KERNEL_DIR}/Source/portable/GCC/${CPU_ARCH}/portASM.S

  ${FREERTOS_STDCPP_DIR}/future.cc
  ${FREERTOS_STDCPP_DIR}/mutex.cc
  ${FREERTOS_STDCPP_DIR}/condition_variable.cc
)
add_library(${project}::FreeRTOS_cpp11 ALIAS FreeRTOS_cpp11)

target_include_directories(FreeRTOS_cpp11 PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${FREERTOS_KERNEL_DIR}/cpp11_gcc>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${FREERTOS_KERNEL_DIR}/Source/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${FREERTOS_KERNEL_DIR}/Source/portable/GCC/${CPU_ARCH}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}> # FreeRTOSConfig.h
  $<INSTALL_INTERFACE:include>
)

file(GLOB FREERTOS_KERNEL_HEADERS ${FREERTOS_KERNEL_DIR}/Source/include/*.h)
install(FILES ${FREERTOS_KERNEL_HEADERS} DESTINATION include)
file(GLOB FREERTOS_KERNEL_HEADERS_PORTABLE ${FREERTOS_KERNEL_DIR}/Source/portable/GCC/ARM_CA9/*.h)
install(FILES ${FREERTOS_KERNEL_HEADERS_PORTABLE} DESTINATION include)
file(GLOB FREERTOS_KERNEL_CPP11_HEADERS ${FREERTOS_KERNEL_DIR}/cpp11_gcc/*.h)
install(FILES ${FREERTOS_KERNEL_CPP11_HEADERS} DESTINATION include)
install(DIRECTORY ${FREERTOS_KERNEL_DIR}/cpp11_gcc/bits DESTINATION include)

install(FILES FreeRTOSConfig.h DESTINATION include)
install(TARGETS FreeRTOS_cpp11 EXPORT FreeRTOS_cpp11 DESTINATION lib)
install(EXPORT FreeRTOS_cpp11 DESTINATION lib NAMESPACE ${project}::)

add_library(FreeRTOS_POSIX STATIC
  ${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/source/FreeRTOS_POSIX_clock.c
  ${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/source/FreeRTOS_POSIX_pthread.c
  ${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/source/FreeRTOS_POSIX_pthread_cond.c
  ${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/source/FreeRTOS_POSIX_sched.c
  ${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/source/FreeRTOS_POSIX_timer.c
  ${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/source/FreeRTOS_POSIX_utils.c
  ${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/source/FreeRTOS_POSIX_mqueue.c
  ${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/source/FreeRTOS_POSIX_pthread_barrier.c
  ${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/source/FreeRTOS_POSIX_pthread_mutex.c
  ${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/source/FreeRTOS_POSIX_semaphore.c
  ${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/source/FreeRTOS_POSIX_unistd.c
)
add_library(${project}::FreeRTOS_POSIX ALIAS FreeRTOS_POSIX)

target_compile_definitions(FreeRTOS_POSIX
  PUBLIC
    configUSE_POSIX_ERRNO=1
    _SYS__PTHREADTYPES_H_
    _SYS_SCHED_H_
    _GLIBCXX_HAS_GTHREADS=1
  INTERFACE
    posixconfigENABLE_TIMER_T=0
    posixconfigENABLE_TIME_T=0
    posixconfigENABLE_TIMESPEC=0
    posixconfigENABLE_ITIMERSPEC=0
    posixconfigENABLE_CLOCK_T=0
    posixconfigENABLE_CLOCKID_T=0
    posixconfigENABLE_MODE_T=0
    posixconfigENABLE_PTHREAD_ATTR_T=1
    posixconfigENABLE_PTHREAD_COND_T=1
    posixconfigENABLE_PTHREAD_CONDATTR_T=1
    posixconfigENABLE_PTHREAD_MUTEX_T=1
    posixconfigENABLE_PTHREAD_MUTEXATTR_T=1
)

target_include_directories(FreeRTOS_POSIX PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/include/portable>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/include/portable/pc/windows> # Default, empty config header
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${FREERTOS_POSIX_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${FREERTOS_POSIX_DIR}/include/private>
    $<INSTALL_INTERFACE:include>
)

target_link_libraries(FreeRTOS_POSIX PUBLIC freertos_sdk::FreeRTOS_cpp11)

install(DIRECTORY ${FREERTOS_POSIX_DIR}/include/FreeRTOS_POSIX DESTINATION include)
install(FILES ${FREERTOS_POSIX_DIR}/include/private/iot_doubly_linked_list.h DESTINATION include)
file(GLOB FREERTOS_POSIX_HEADERS_BASIC ${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/include/*.h)
install(FILES ${FREERTOS_POSIX_HEADERS_BASIC} DESTINATION include)
file(GLOB FREERTOS_POSIX_HEADERS_BASIC_PORTABLE ${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/include/portable/*.h)
install(FILES ${FREERTOS_POSIX_HEADERS_BASIC_PORTABLE} DESTINATION include)
file(GLOB FREERTOS_POSIX_HEADERS_BASIC_PORTABLE_WIN ${FREERTOS_POSIX_DIR}/FreeRTOS-Plus-POSIX/include/portable/pc/windows/*.h)
install(FILES ${FREERTOS_POSIX_HEADERS_BASIC_PORTABLE_WIN} DESTINATION include)

install(TARGETS FreeRTOS_POSIX EXPORT FreeRTOS_POSIX DESTINATION lib)
install(EXPORT FreeRTOS_POSIX DESTINATION lib NAMESPACE ${project}::)

install(FILES ${project}-config.cmake DESTINATION lib)
