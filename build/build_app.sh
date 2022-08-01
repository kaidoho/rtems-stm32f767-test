#!/bin/bash

THIS_SCRIPT=$(realpath "$0")
BUILD_TOP_DIR=$(dirname "${THIS_SCRIPT}")
TOP_DIR=${BUILD_TOP_DIR}/..

source ${BUILD_TOP_DIR}/config/config.sh

echo "Location of this script: ${BUILD_TOP_DIR}"
echo "RSB Source: ${RTEMS_RSB_SRC_DIR}"
echo "RTEMS Source: ${RTEMS_OS_SRC_DIR}"
echo "RTEMS Toolchain: ${RTEMS_TOOLCHAIN_INSTALL_DIR}"


if [ ! -d "${WORK_DIR}/cmake" ]; then
  mkdir -p ${WORK_DIR}/cmake
fi






pushd ${WORK_DIR}/cmake
  cmake -G"Eclipse CDT4 - Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=${CMAKE_SCRIPT_DIR}/rtems.cmake ${APP_DIR} 
  cmake --build build
popd