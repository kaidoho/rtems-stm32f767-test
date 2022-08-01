#!/bin/bash

THIS_SCRIPT=$(realpath "$0")
BUILD_TOP_DIR=$(dirname "${THIS_SCRIPT}")
TOP_DIR=${BUILD_TOP_DIR}/..

source ${BUILD_TOP_DIR}/config/config.sh

echo "Location of this script: ${BUILD_TOP_DIR}"
echo "RSB Source: ${RTEMS_RSB_SRC_DIR}"
echo "RTEMS Source: ${RTEMS_OS_SRC_DIR}"
echo "RTEMS Toolchain: ${RTEMS_TOOLCHAIN_INSTALL_DIR}"



if [ ! -d "${RTEMS_TOOLCHAIN_INSTALL_DIR}" ]; then 
  echo "ERROR: run install_tools.sh first"	
  exit 1
fi

if [ ! -d "${RTEMS_OS_SRC_DIR}" ]; then
  echo "Download RTEMS"	
  git clone ${RTEMS_OS_GIT_REPO} ${RTEMS_OS_SRC_DIR}
  pushd ${RTEMS_OS_SRC_DIR}
  git checkout ${RTEMS_OS_VER_COMMIT}
  popd
fi

if [ -d "${RTEMS_OS_INSTALL_DIR}" ]; then 
  echo "Delete old RTEMS installation"	
  rm -rf ${RTEMS_OS_INSTALL_DIR}
fi 


echo "Build RTEMS with POSIX support"

pushd ${RTEMS_OS_SRC_DIR}
./waf bsp_defaults --rtems-bsps=${RTEMS_BSP_ARCH}/${RTEMS_BSP_NAME} > config.ini
sed -i 's/RTEMS_POSIX_API = False/RTEMS_POSIX_API = True/g' config.ini
./waf configure --prefix=${RTEMS_OS_INSTALL_DIR} --rtems-tools=${RTEMS_TOOLCHAIN_INSTALL_DIR} --rtems-bsps=${RTEMS_BSP_ARCH}/${RTEMS_BSP_NAME}
./waf install

# Write a toolchain file
cp ${CMAKE_SCRIPT_DIR}/rtems.cmake.template  ${CMAKE_SCRIPT_DIR}/rtems.cmake
ABI_FLAGS=$(sed -n "/ABI_FLAGS=/p" ${RTEMS_OS_INSTALL_DIR}/lib/pkgconfig/${RTEMS_BSP_ARCH}-rtems6-${RTEMS_BSP_NAME}.pc)
ABI_FLAGS=${ABI_FLAGS/ABI_FLAGS=/""} 

sed -i "s:REPLACED_RTEMS_TC_DIR:${RTEMS_TOOLCHAIN_INSTALL_DIR}/bin:g" ${CMAKE_SCRIPT_DIR}/rtems.cmake
sed -i "s:REPLACED_RTEMS_ARCH:${RTEMS_BSP_ARCH}:g" ${CMAKE_SCRIPT_DIR}/rtems.cmake
sed -i "s:REPLACED_RTEMS_LIB_DIR:${RTEMS_OS_INSTALL_DIR}/${RTEMS_BSP_ARCH}-rtems6/${RTEMS_BSP_NAME}/lib:g" ${CMAKE_SCRIPT_DIR}/rtems.cmake
sed -i "s:REPLACED_ABI_FLAGS:${ABI_FLAGS}:g" ${CMAKE_SCRIPT_DIR}/rtems.cmake

# Compile PreMain.c so that the compiler checks work
${RTEMS_TOOLCHAIN_INSTALL_DIR}/bin/${RTEMS_BSP_ARCH}-rtems6-gcc ${ABI_FLAGS} -isystem ${RTEMS_OS_INSTALL_DIR}/${RTEMS_BSP_ARCH}-rtems6/${RTEMS_BSP_NAME}/lib/include -o ${RTEMS_OS_INSTALL_DIR}/${RTEMS_BSP_ARCH}-rtems6/${RTEMS_BSP_NAME}/lib/PreMain.c.obj -c ${APP_DIR}/Main/PreMain.c
popd

