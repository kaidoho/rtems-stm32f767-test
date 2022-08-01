#!/bin/bash


RTEMS_BSP_ARCH=arm
RTEMS_BSP_NAME=nucleo-f767zi


RTEMS_TOP_SRC_DIR=${TOP_DIR}/RTEMS
CMAKE_SCRIPT_DIR=${BUILD_TOP_DIR}/cmake
WORK_DIR=${BUILD_TOP_DIR}/work
TOOL_DIR=${BUILD_TOP_DIR}/tools
TOOL_DOWNLOAD_DIR=${BUILD_TOP_DIR}/downloads

ECLIPSE_INSTALL_DIR=${TOOL_DIR}/eclipse


APP_DIR=${TOP_DIR}/Application


RTEMS_RSB_GIT_REPO=git://git.rtems.org/rtems-source-builder.git
RTEMS_RSB_SRC_DIR=${RTEMS_TOP_SRC_DIR}/rsb
RTEMS_RSB_VER_COMMIT=22e32ecc272353a9047d429358aee2d61687ccc7

RTEMS_TOOLCHAIN_INSTALL_DIR=${TOOL_DIR}/rtems_toolchain

RTEMS_OS_GIT_REPO=https://github.com/kaidoho/rtems.git
RTEMS_OS_SRC_DIR=${RTEMS_TOP_SRC_DIR}/rtems
RTEMS_OS_VER_COMMIT=nucleo_stm32f767zi
RTEMS_OS_INSTALL_DIR=${WORK_DIR}/rtems




ECLIPSE_SRC_REPO=http://ftp.halifax.rwth-aachen.de/eclipse/technology/epp/downloads/release/2022-06/R
ECLIPSE_TAR_NAME=eclipse-cpp-2022-06-R-linux-gtk-x86_64.tar.gz

ECLIPSE_EMBEDDED_SRC_REPO=http://ftp.halifax.rwth-aachen.de/eclipse/embed-cdt/releases/6.2.2
ECLIPSE_EMBEDDED_TAR_NAME=org.eclipse.embedcdt.repository-6.2.2-202206121057.zip








