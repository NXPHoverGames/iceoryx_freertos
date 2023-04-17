#!/bin/bash
# Copyright 2023 NXP

DIR=$(realpath .)

mkdir -p ${DIR}/install_dir
rm -rf ${DIR}/install_dir/*

mkdir -p ${DIR}/build-FreeRTOS
cd ${DIR}/build-FreeRTOS
rm -rf *

cmake \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DCMAKE_INSTALL_PREFIX=/${DIR}/install_dir \
    -DCMAKE_TOOLCHAIN_FILE=${DIR}/compiler.cmake ..
cmake --build . -- -j4
cmake --install . --prefix ${DIR}/install_dir
cd ..

mkdir -p ${DIR}/build-iceoryx
cd ${DIR}/build-iceoryx
rm -rf *

cmake \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DCMAKE_TOOLCHAIN_FILE=/${DIR}/compiler.cmake \
    -DCMAKE_PREFIX_PATH=/${DIR}/install_dir/lib \
    -DCMAKE_INSTALL_PREFIX=/${DIR}/install_dir \
    -DCMAKE_SYSROOT=${DIR}/install_dir \
    -DTOML_CONFIG=OFF \
    -C../iceoryx_options.cmake \
    ../submodules/iceoryx/iceoryx_meta
cmake --build . -- -j4
cmake --install . --prefix ${DIR}/install_dir
cd ..

mkdir -p ${DIR}/build-example
cd ${DIR}/build-example
rm -rf *

cmake \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DCMAKE_TOOLCHAIN_FILE=${DIR}/compiler.cmake \
    -DCMAKE_PREFIX_PATH=${DIR}/install_dir/lib \
    -DCMAKE_INSTALL_PREFIX=${DIR}/install_dir \
    -DCMAKE_SYSROOT=${DIR}/install_dir \
    ../example
cmake --build . -- -j4
cd ..
