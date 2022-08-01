#!/bin/bash


THIS_SCRIPT=$(realpath "$0")
CWD=$(dirname "${THIS_SCRIPT}")

BUILD_TOP_DIR=${CWD}/build
RTEMS_TOP_SRC_DIR=${CWD}/rtems-src

CMAKE_SCRIPT_DIR=${BUILD_TOP_DIR}/cmake_scripts
WORK_DIR=${BUILD_TOP_DIR}/work


RTEMS_RSB_GIT_REPO=git://git.rtems.org/rtems-source-builder.git
RTEMS_RSB_SRC_DIR=${RTEMS_TOP_SRC_DIR}/rsb
RTEMS_RSB_VER_COMMIT=22e32ecc272353a9047d429358aee2d61687ccc7

RTEMS_TOOLCHAIN_INSTALL_DIR=${BUILD_TOP_DIR}/rtems_toolchain

RTEMS_OS_GIT_REPO=https://github.com/kaidoho/rtems.git
RTEMS_OS_SRC_DIR=${RTEMS_TOP_SRC_DIR}/rtems
RTEMS_OS_VER_COMMIT=nucleo_stm32f767zi
RTEMS_OS_INSTALL_DIR=${WORK_DIR}/rtems_os

RTEMS_BSP_ARCH=arm
RTEMS_BSP_NAME=nucleo-f767zi

ECLIPSE_INSTALL_DIR=${BUILD_TOP_DIR}/eclipse
ECLIPSE_SRC_REPO=http://ftp.halifax.rwth-aachen.de/eclipse/technology/epp/downloads/release/2022-06/R
ECLIPSE_TAR_NAME=eclipse-cpp-2022-06-R-linux-gtk-x86_64.tar.gz

ECLIPSE_EMBEDDED_SRC_REPO=http://ftp.halifax.rwth-aachen.de/eclipse/embed-cdt/releases/6.2.2
ECLIPSE_EMBEDDED_TAR_NAME=org.eclipse.embedcdt.repository-6.2.2-202206121057.zip
TOOL_DOWNLOAD_DIR=${BUILD_TOP_DIR}/downloads

APP_DIR=${CWD}/application

echo "Location of this script: ${CWD}"
echo "RSB Source: ${RTEMS_RSB_SRC_DIR}"
echo "RTEMS Source: ${RTEMS_OS_SRC_DIR}"
echo "RTEMS Toolchain: ${RTEMS_TOOLCHAIN_INSTALL_DIR}"


if [ ! -d "${RTEMS_RSB_SRC_DIR}" ]; then 

  echo "Download RSB"	

  git clone ${RTEMS_RSB_GIT_REPO}	${RTEMS_RSB_SRC_DIR}	
  pushd ${RTEMS_RSB_SRC_DIR}
  git checkout ${RTEMS_RSB_VER_COMMIT}
  popd
fi



if [ ! -d "${RTEMS_TOOLCHAIN_INSTALL_DIR}" ]; then 

  echo "Build RTEMS toolchain for ARM"	

  pushd ${RTEMS_RSB_SRC_DIR}/rtems
  ../source-builder/sb-set-builder --prefix=${RTEMS_TOOLCHAIN_INSTALL_DIR} 6/rtems-${RTEMS_BSP_ARCH}
  popd
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


if [ ! -d "${ECLIPSE_INSTALL_DIR}" ]; then

  echo "Prepare Eclipse installation"

  if [ ! -d "${TOOL_DOWNLOAD_DIR}" ]; then
    mkdir -p ${TOOL_DOWNLOAD_DIR}
  fi 
  if [ ! -f "${TOOL_DOWNLOAD_DIR}/${ECLIPSE_TAR_NAME}" ]; then
    echo "Download Eclipse IDE for C/C++ developers"	
    wget ${ECLIPSE_SRC_REPO}/${ECLIPSE_TAR_NAME} -P ${TOOL_DOWNLOAD_DIR}
  fi 
  if [ ! -f "${TOOL_DOWNLOAD_DIR}/${ECLIPSE_EMBEDDED_TAR_NAME}" ]; then
    echo "Download Eclipse IDE for C/C++ developers"	
    wget ${ECLIPSE_EMBEDDED_SRC_REPO}/${ECLIPSE_EMBEDDED_TAR_NAME} -P ${TOOL_DOWNLOAD_DIR}
  fi 
  pushd ${BUILD_TOP_DIR}
    tar -zxvf ${TOOL_DOWNLOAD_DIR}/${ECLIPSE_TAR_NAME}
    ./eclipse/eclipse  -nosplash -application org.eclipse.equinox.p2.director -repository jar:file:${TOOL_DOWNLOAD_DIR}/${ECLIPSE_EMBEDDED_TAR_NAME}! -installIU "org.eclipse.embedcdt, org.eclipse.embedcdt.codered, org.eclipse.embedcdt.codered.feature.group, org.eclipse.embedcdt.codered.feature.jar, org.eclipse.embedcdt.codered.source, org.eclipse.embedcdt.codered.source.feature.group, org.eclipse.embedcdt.codered.source.feature.jar, org.eclipse.embedcdt.codered.ui, org.eclipse.embedcdt.codered.ui.source, org.eclipse.embedcdt.core, org.eclipse.embedcdt.core.source, org.eclipse.embedcdt.debug.core, org.eclipse.embedcdt.debug.core.source, org.eclipse.embedcdt.debug.gdbjtag, org.eclipse.embedcdt.debug.gdbjtag.core, org.eclipse.embedcdt.debug.gdbjtag.core.source, org.eclipse.embedcdt.debug.gdbjtag.feature.group, org.eclipse.embedcdt.debug.gdbjtag.feature.jar, org.eclipse.embedcdt.debug.gdbjtag.jlink, org.eclipse.embedcdt.debug.gdbjtag.jlink.core, org.eclipse.embedcdt.debug.gdbjtag.jlink.core.source, org.eclipse.embedcdt.debug.gdbjtag.jlink.feature.group, org.eclipse.embedcdt.debug.gdbjtag.jlink.feature.jar, org.eclipse.embedcdt.debug.gdbjtag.jlink.source, org.eclipse.embedcdt.debug.gdbjtag.jlink.source.feature.group, org.eclipse.embedcdt.debug.gdbjtag.jlink.source.feature.jar, org.eclipse.embedcdt.debug.gdbjtag.jlink.ui, org.eclipse.embedcdt.debug.gdbjtag.jlink.ui.source, org.eclipse.embedcdt.debug.gdbjtag.openocd, org.eclipse.embedcdt.debug.gdbjtag.openocd.core, org.eclipse.embedcdt.debug.gdbjtag.openocd.core.source, org.eclipse.embedcdt.debug.gdbjtag.openocd.feature.group, org.eclipse.embedcdt.debug.gdbjtag.openocd.feature.jar, org.eclipse.embedcdt.debug.gdbjtag.openocd.source, org.eclipse.embedcdt.debug.gdbjtag.openocd.source.feature.group, org.eclipse.embedcdt.debug.gdbjtag.openocd.source.feature.jar, org.eclipse.embedcdt.debug.gdbjtag.openocd.ui, org.eclipse.embedcdt.debug.gdbjtag.openocd.ui.source, org.eclipse.embedcdt.debug.gdbjtag.pyocd, org.eclipse.embedcdt.debug.gdbjtag.pyocd.core, org.eclipse.embedcdt.debug.gdbjtag.pyocd.core.source, org.eclipse.embedcdt.debug.gdbjtag.pyocd.feature.group, org.eclipse.embedcdt.debug.gdbjtag.pyocd.feature.jar, org.eclipse.embedcdt.debug.gdbjtag.pyocd.source, org.eclipse.embedcdt.debug.gdbjtag.pyocd.source.feature.group, org.eclipse.embedcdt.debug.gdbjtag.pyocd.source.feature.jar, org.eclipse.embedcdt.debug.gdbjtag.pyocd.ui, org.eclipse.embedcdt.debug.gdbjtag.pyocd.ui.source, org.eclipse.embedcdt.debug.gdbjtag.qemu, org.eclipse.embedcdt.debug.gdbjtag.qemu.core, org.eclipse.embedcdt.debug.gdbjtag.qemu.core.source, org.eclipse.embedcdt.debug.gdbjtag.qemu.feature.group, org.eclipse.embedcdt.debug.gdbjtag.qemu.feature.jar, org.eclipse.embedcdt.debug.gdbjtag.qemu.source, org.eclipse.embedcdt.debug.gdbjtag.qemu.source.feature.group, org.eclipse.embedcdt.debug.gdbjtag.qemu.source.feature.jar, org.eclipse.embedcdt.debug.gdbjtag.qemu.ui, org.eclipse.embedcdt.debug.gdbjtag.qemu.ui.source, org.eclipse.embedcdt.debug.gdbjtag.restart.ui, org.eclipse.embedcdt.debug.gdbjtag.restart.ui.source, org.eclipse.embedcdt.debug.gdbjtag.source, org.eclipse.embedcdt.debug.gdbjtag.source.feature.group, org.eclipse.embedcdt.debug.gdbjtag.source.feature.jar, org.eclipse.embedcdt.debug.gdbjtag.ui, org.eclipse.embedcdt.debug.gdbjtag.ui.source, org.eclipse.embedcdt.debug.packs, org.eclipse.embedcdt.debug.packs.source, org.eclipse.embedcdt.doc.user, org.eclipse.embedcdt.doc.user.feature.group, org.eclipse.embedcdt.doc.user.feature.jar, org.eclipse.embedcdt.doc.user.source.feature.group, org.eclipse.embedcdt.doc.user.source.feature.jar, org.eclipse.embedcdt.feature.group, org.eclipse.embedcdt.feature.jar, org.eclipse.embedcdt.managedbuild.cross.arm, org.eclipse.embedcdt.managedbuild.cross.arm.core, org.eclipse.embedcdt.managedbuild.cross.arm.core.source, org.eclipse.embedcdt.managedbuild.cross.arm.feature.group, org.eclipse.embedcdt.managedbuild.cross.arm.feature.jar, org.eclipse.embedcdt.managedbuild.cross.arm.source, org.eclipse.embedcdt.managedbuild.cross.arm.source.feature.group, org.eclipse.embedcdt.managedbuild.cross.arm.source.feature.jar, org.eclipse.embedcdt.managedbuild.cross.arm.ui, org.eclipse.embedcdt.managedbuild.cross.arm.ui.source, org.eclipse.embedcdt.managedbuild.cross.core, org.eclipse.embedcdt.managedbuild.cross.core.source, org.eclipse.embedcdt.managedbuild.cross.riscv, org.eclipse.embedcdt.managedbuild.cross.riscv.core, org.eclipse.embedcdt.managedbuild.cross.riscv.core.source, org.eclipse.embedcdt.managedbuild.cross.riscv.feature.group, org.eclipse.embedcdt.managedbuild.cross.riscv.feature.jar, org.eclipse.embedcdt.managedbuild.cross.riscv.source, org.eclipse.embedcdt.managedbuild.cross.riscv.source.feature.group, org.eclipse.embedcdt.managedbuild.cross.riscv.source.feature.jar, org.eclipse.embedcdt.managedbuild.cross.riscv.ui, org.eclipse.embedcdt.managedbuild.cross.riscv.ui.source, org.eclipse.embedcdt.managedbuild.cross.ui, org.eclipse.embedcdt.managedbuild.cross.ui.source, org.eclipse.embedcdt.managedbuild.packs.ui, org.eclipse.embedcdt.managedbuild.packs.ui.source, org.eclipse.embedcdt.packs, org.eclipse.embedcdt.packs.core, org.eclipse.embedcdt.packs.core.source, org.eclipse.embedcdt.packs.feature.group, org.eclipse.embedcdt.packs.feature.jar, org.eclipse.embedcdt.packs.source, org.eclipse.embedcdt.packs.source.feature.group, org.eclipse.embedcdt.packs.source.feature.jar, org.eclipse.embedcdt.packs.ui, org.eclipse.embedcdt.packs.ui.source, org.eclipse.embedcdt.templates.ad, org.eclipse.embedcdt.templates.ad.feature.group, org.eclipse.embedcdt.templates.ad.feature.jar, org.eclipse.embedcdt.templates.ad.source, org.eclipse.embedcdt.templates.ad.source.feature.group, org.eclipse.embedcdt.templates.ad.source.feature.jar, org.eclipse.embedcdt.templates.ad.ui, org.eclipse.embedcdt.templates.ad.ui.source, org.eclipse.embedcdt.templates.core, org.eclipse.embedcdt.templates.core.source, org.eclipse.embedcdt.templates.cortexm, org.eclipse.embedcdt.templates.cortexm.feature.group, org.eclipse.embedcdt.templates.cortexm.feature.jar, org.eclipse.embedcdt.templates.cortexm.source, org.eclipse.embedcdt.templates.cortexm.source.feature.group, org.eclipse.embedcdt.templates.cortexm.source.feature.jar, org.eclipse.embedcdt.templates.cortexm.ui, org.eclipse.embedcdt.templates.cortexm.ui.source, org.eclipse.embedcdt.templates.freescale, org.eclipse.embedcdt.templates.freescale.feature.group, org.eclipse.embedcdt.templates.freescale.feature.jar, org.eclipse.embedcdt.templates.freescale.pe.ui, org.eclipse.embedcdt.templates.freescale.pe.ui.source, org.eclipse.embedcdt.templates.freescale.source, org.eclipse.embedcdt.templates.freescale.source.feature.group, org.eclipse.embedcdt.templates.freescale.source.feature.jar, org.eclipse.embedcdt.templates.freescale.ui, org.eclipse.embedcdt.templates.freescale.ui.source, org.eclipse.embedcdt.templates.sifive, org.eclipse.embedcdt.templates.sifive.feature.group, org.eclipse.embedcdt.templates.sifive.feature.jar, org.eclipse.embedcdt.templates.sifive.source, org.eclipse.embedcdt.templates.sifive.source.feature.group, org.eclipse.embedcdt.templates.sifive.source.feature.jar, org.eclipse.embedcdt.templates.sifive.ui, org.eclipse.embedcdt.templates.sifive.ui.source, org.eclipse.embedcdt.templates.stm, org.eclipse.embedcdt.templates.stm.feature.group, org.eclipse.embedcdt.templates.stm.feature.jar, org.eclipse.embedcdt.templates.stm.source, org.eclipse.embedcdt.templates.stm.source.feature.group, org.eclipse.embedcdt.templates.stm.source.feature.jar, org.eclipse.embedcdt.templates.stm.ui, org.eclipse.embedcdt.templates.stm.ui.source, org.eclipse.embedcdt.ui" 
  popd

fi


if [ ! -d "${WORK_DIR}/cmake" ]; then
  mkdir -p ${WORK_DIR}/cmake
fi






pushd ${WORK_DIR}/cmake
  cmake -G"Eclipse CDT4 - Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=${CMAKE_SCRIPT_DIR}/rtems.cmake ${APP_DIR}
popd