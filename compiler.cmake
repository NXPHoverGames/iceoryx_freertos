# Copyright 2018-2023 Piotr Grygorczuk <grygorek@gmail.com>
# Copyright 2023 NXP
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

cmake_minimum_required(VERSION 3.0)

include(${CMAKE_CURRENT_LIST_DIR}/submodules/FreeRTOS_cpp11/compiler.cmake)

set(FREERTOS TRUE)

# A bit of hackery to make find_package(Threads) work
set(CMAKE_THREAD_LIBS_INIT Threads::Threads)
set(THREADS_PTHREAD_ARG "0" CACHE STRING "Result from TRY_RUN" FORCE)
set(CMAKE_USE_WIN32_THREADS_INIT 0)
set(CMAKE_USE_PTHREADS_INIT 1)
set(THREADS_PREFER_PTHREAD_FLAG ON)

set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
# search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

set(CPU_ARCH "ARM_CA9")
set(CPU_FLAGS "-mcpu=cortex-a9 -mfloat-abi=hard -mfpu=auto -mtp=soft")
set(CONFIG_DEFS "-D_GLIBCXX_HAS_GTHREADS=1 -D__FREERTOS__=1")

set(CMAKE_EXE_LINKER_FLAGS "-Wl,--wrap=malloc -Wl,--wrap=free -Wl,--wrap=aligned_alloc -Wl,--wrap=_malloc_r -Wl,--wrap=_memalign_r -Wl,--gc-sections")

set(COMPILE_COMMON_FLAGS "${CONFIG_DEFS} ${CPU_FLAGS} -Wall -fno-common -fmessage-length=0 -ffunction-sections -fdata-sections")

set(CMAKE_C_FLAGS   "${COMPILE_COMMON_FLAGS} -std=c17  -nostdlib -ffreestanding -fno-builtin " CACHE INTERNAL "" FORCE)
set(CMAKE_CXX_FLAGS "${COMPILE_COMMON_FLAGS} -std=c++2a -nostdlib -ffreestanding -fno-builtin -fno-exceptions -fno-unwind-tables -fpermissive" CACHE INTERNAL "" FORCE)
set(CMAKE_ASM_FLAGS "-x assembler-with-cpp ${CPU_FLAGS}"  CACHE INTERNAL "" FORCE)
