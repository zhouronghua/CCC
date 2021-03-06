#!/bin/bash
#######################################################################
# File Name: the_compiler_of_the cross_compiler
# Author: Ronghua Zhou
# refer to wiki for the detailed information: 
# https://www.cnblogs.com/zhouronghua/p/15236755.html
# mail: zhou.ronghua@qq.com
# Created Time: Fri Jul  30 11:17 2021
#########################################################################

export BUILD_DIR=~/CCC
export shell_base_dir=$(cd $(dirname $0); pwd)
export MIRROR_SITE=http://ftpmirror.gnu.org

export GNU_KEY=gnu-keyring.gpg
export MPFR_VERSION=mpfr-4.1.0
export GMP_VERSION=gmp-6.2.1
export MPC_VERSION=mpc-1.2.1
export BINUTILS_VERSION=binutils-2.28.1
export GCC5_VERSION=gcc-5.5.0
export GCC7_VERSION=gcc-7.5.0
export GCC9_VERSION=gcc-9.4.0
export GLIBC17_VERSION=glibc-2.17
export GLIBC23_VERSION=glibc-2.23
export GLIBC23_ONLY_VERSION=$(echo ${GLIBC23_VERSION} | cut -d "-" -f 2)

export KERNEL_MAJ_VERSION=v4.x
export KERNEL_VERSION=linux-4.15.1


export GNU_KEY_URL=${MIRROR_SITE}/${GNU_KEY}
# http://ftpmirror.gnu.org/mpfr/mpfr-4.1.0.tar.xz
export MPFR_URL=${MIRROR_SITE}/mpfr/${MPFR_VERSION}.tar.xz
# http://ftpmirror.gnu.org/gmp/gmp-6.2.1.tar.xz
export GMP_URL=${MIRROR_SITE}/gmp/${GMP_VERSION}.tar.xz
# http://ftpmirror.gnu.org/mpc/mpc-1.2.1.tar.gz
export MPC_URL=${MIRROR_SITE}/mpc/${MPC_VERSION}.tar.gz
# http://ftpmirror.gnu.org/binutils/binutils-2.28.1.tar.xz
export BINUTILS_URL=${MIRROR_SITE}/binutils/${BINUTILS_VERSION}.tar.xz

# gcc version
export GCC5_URL=${MIRROR_SITE}/gcc/${GCC5_VERSION}/${GCC5_VERSION}.tar.xz
export GCC7_URL=${MIRROR_SITE}/gcc/${GCC7_VERSION}/${GCC7_VERSION}.tar.xz
export GCC9_URL=${MIRROR_SITE}/gcc/${GCC9_VERSION}/${GCC9_VERSION}.tar.xz

# linux kernel
export KERNEL_URL=https://www.kernel.org/pub/linux/kernel/${KERNEL_MAJ_VERSION}/${KERNEL_VERSION}.tar.xz

export USE_GCC_VERSION=${GCC5_VERSION}
export USE_GCC_VERSION_URL=${GCC5_URL}
export USE_GLIBC_VERSION=${GLIBC23_VERSION}
export USE_GLIBC_ONLY_VERSION=$(echo ${USE_GLIBC_VERSION} | cut -d "-" -f 2)
export USE_GLIBC_VERSION_URL=${MIRROR_SITE}/glibc/${USE_GLIBC_VERSION}.tar.xz

export VERSIONS_NEED_TO_DOWNLOAD=(${MPFR_URL} ${GMP_URL} ${MPC_URL} ${BINUTILS_URL} ${USE_GCC_VERSION_URL}  ${USE_GLIBC_VERSION_URL} )



export COMPANY_PREFIX=xxx
export BASE_PATH=/opt/${COMPANY_PREFIX}
# for x86_64
export TAGET_ARCH=x86_64
export TAGET_ARCH_FOR_KERNEL=x86_64
# for arm64
#export TAGET_ARCH=aarch64
#export TAGET_ARCH_FOR_KERNEL=arm64
export TARGET_OS=linux
export TARGET_DIR=${COMPANY_PREFIX}_${TAGET_ARCH}_${USE_GCC_VERSION}_${USE_GLIBC_VERSION}_${TARGET_OS}
export TARGET_DIR_FOR_BUILD=${TARGET_DIR}_build
export TARGET_PATH=${BASE_PATH}/${TARGET_DIR}
export TARGET=${TAGET_ARCH}-${TARGET_OS}-gnu

export LOG_FILE=~/the_compiler_of_the_cross_compiler.log
export LOG_CMD_FILE=~/the_compiler_of_the_cross_compiler.cmd
xxx_log(){
    echo `date +"%Y-%m-%d-%H:%M:%S" ` $* | tee -a ${LOG_FILE}
}
xxx_command_log(){
    echo `date +"%Y-%m-%d-%H:%M:%S" ` "$*" | tee -a ${LOG_CMD_FILE}
    if ! "$@" >> ${LOG_FILE} 2>&1
    then
        xxx_log "###########################exec [$@] fail########################"
        exit 1
    fi
}

xxx_command_ne_log(){
    echo `date +"%Y-%m-%d-%H:%M:%S" ` "$*" | tee -a ${LOG_CMD_FILE}
    if ! "$@" >> ${LOG_FILE} 2>&1
    then
        xxx_log "###########################exec [$@] fail########################"
    fi
}
TIMESTAMP=`date +"%Y%m%d%H%M%S"`
if [ -e ${LOG_FILE} ]
then
    mv ${LOG_FILE} ${LOG_FILE}.${TIMESTAMP}.bak
fi
if [ -e ${LOG_FILE} ]
then
    mv ${LOG_CMD_FILE} ${LOG_CMD_FILE}.${TIMESTAMP}.bak
fi
xxx_log "#########################################################################"
xxx_log "make the cross compiler for gcc version ${USE_GCC_VERSION} and glibc version ${USE_GLIBC_VERSION} and kernel ${KERNEL_VERSION} and target ${TARGET} at ${shell_base_dir} begin:"
xxx_log "#########################################################################"

make_prepare(){
    # decide apt or yum to use
    if which apt >/dev/null 2>&1
    then
        xxx_command_log export PKG_INSTALL_TOOL=$(which apt)
        xxx_command_ne_log apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EB9B1D8886F44E2A
        xxx_command_ne_log apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3D5919B448457EE0
        xxx_command_ne_log apt install apt-transport-https
        xxx_command_ne_log apt -y update
        xxx_command_ne_log apt -y upgrade
    elif which yum >/dev/null  2>&1
    then
        xxx_command_log export PKG_INSTALL_TOOL=$(which yum)
        yum -y update
    else
        xxx_log "unknown os, exit"
        exit 1
    fi
    xxx_command_log ${PKG_INSTALL_TOOL} -y install libgmp-dev libmpfr-dev libmpc-dev  gcc g++ make gawk

    xxx_log "make dir ${BUILD_DIR} begin!"
    if [ !  -d ${BUILD_DIR} ]
    then
        xxx_command_log mkdir -p ${BUILD_DIR}
    fi
    xxx_log "make dir ${BUILD_DIR} success!"


    xxx_command_log cd ${BUILD_DIR}

    # import gpg fingerprint 
    if [ ! -f ${GNU_KEY} ]
    then
        wget ${GNU_KEY_URL}

        if [ -f ${GNU_KEY} ]
        then
            gpg --import ${GNU_KEY}
        fi
    fi

    # download
    for version in ${VERSIONS_NEED_TO_DOWNLOAD[*]}
    do
        xxx_log "downlowd ${version}:"
        file_name=$(echo ${version}|rev |cut -d "/" -f 1 | rev)
        if [ -f ${file_name} ]
        then
            xxx_command_log rm -f "${file_name}.sig"
            xxx_command_log wget "${version}.sig"
            if gpg --verify "${file_name}.sig" "${file_name}"
            then
                xxx_log "gpg verify ${version} success!"
                continue
            fi
        fi
        xxx_command_log rm -fr ${file_name}*
        xxx_command_log wget ${version}
        xxx_log "downlowd ${version} finished!"
    done

    if [ ! -f ${KERNEL_VERSION}.tar.xz ]
    then
        xxx_command_log wget ${KERNEL_URL}
    fi


    xxx_log "extract *.tar.xz begin!"
    for tar_file in *.tar.xz
    do
        xxx_log "extrace ${tar_file}"
        xxx_command_log tar -xf ${tar_file}
    done

    for tar_file in *.tar.gz
    do
        xxx_log "extrace ${tar_file}"
        xxx_command_log tar -xf ${tar_file}
    done

    # create soft link for mpfr, gmp, mpc
    xxx_command_log cd ${BUILD_DIR}/${USE_GCC_VERSION}
    if [ ! -e mpfr ]
    then
        xxx_command_log ln -s ../${MPFR_VERSION} mpfr
    fi
    if [ ! -e gmp ]
    then
        xxx_command_log ln -s ../${GMP_VERSION} gmp
    fi
    if [ ! -e mpc ]
    then
        xxx_command_log ln -s ../${MPC_VERSION} mpc
    fi

    # make build temp directories for gcc, glibc and binutils
    for gcc_glibc_dir in "${BUILD_DIR}/${USE_GCC_VERSION}" "${BUILD_DIR}/${USE_GLIBC_VERSION}" "${BUILD_DIR}/${BINUTILS_VERSION}";
    do
        xxx_command_log mkdir -p ${gcc_glibc_dir}/${TARGET_DIR_FOR_BUILD}
    done

    xxx_log "make target dir ${TARGET_PATH} begin:"
    xxx_command_log mkdir -p ${TARGET_PATH} 
    xxx_command_log export PATH=${TARGET_PATH}/bin:$PATH
    xxx_log "new PATH is ${PATH}"

    # make patch for glibc 2.17
    if [ ${USE_GLIBC_VERSION} == ${GLIBC17_VERSION} ]
    then
        xxx_command_ne_log sed -i "s/3.79\* | 3.\[89\]\*)/3.79\* | 3.\[89\]\* | 4.*)/" "${BUILD_DIR}/${USE_GLIBC_VERSION}/configure"
        xxx_command_ne_log sed -i "s/\+force = force-install/#\+force = force-install/g" "${BUILD_DIR}/${USE_GLIBC_VERSION}/Makeconfig"
    fi
}


make_binutils(){
    xxx_log "make binutils begin:"
    xxx_command_log cd ${BUILD_DIR}/${BINUTILS_VERSION}/${TARGET_DIR_FOR_BUILD} 

    xxx_command_log ../configure --prefix=${TARGET_PATH} --target=${TARGET} --disable-multilib 
    xxx_command_log make -j20 
    xxx_command_log make install 
    xxx_log "make binutils finished!"
}


make_kernel_headers(){
    xxx_log "kernel header files for ${KERNEL_VERSION} begin:"
    xxx_command_log cd ${BUILD_DIR}/${KERNEL_VERSION} 
    xxx_command_log make ARCH=${TAGET_ARCH_FOR_KERNEL} INSTALL_HDR_PATH=${TARGET_PATH} headers_install
    xxx_command_log make ARCH=${TAGET_ARCH_FOR_KERNEL} INSTALL_HDR_PATH=${TARGET_PATH}/${TARGET}/ headers_install
    xxx_log "kernel header files for ${KERNEL_VERSION} finished!"
}


make_gcc(){
    xxx_log "make gcc only ${USE_GCC_VERSION} begin:"
    xxx_command_log cd ${BUILD_DIR}/${USE_GCC_VERSION}/${TARGET_DIR_FOR_BUILD}

    xxx_command_log ../configure  --prefix=${TARGET_PATH} --target=${TARGET} --with-glibc-version=${USE_GLIBC_ONLY_VERSION} --enable-languages=c,c++ --disable-multilib
    xxx_command_log make -j20 all-gcc
    xxx_command_log make install-gcc
    xxx_log "make gcc only ${USE_GCC_VERSION} finished!"
}

make_glibc_headers(){
    xxx_log "make glibc ${USE_GLIBC_VERSION} headers begin:"
    xxx_command_log cd ${BUILD_DIR}/${USE_GLIBC_VERSION}/${TARGET_DIR_FOR_BUILD}

    xxx_command_log ../configure  --prefix=${TARGET_PATH} --build=${MACHTYPE} --host=${TARGET} --target=${TARGET} --disable-multilib libc_cv_forced_unwind=yes
    xxx_command_log make install-bootstrap-headers=yes install-headers
    xxx_command_log make -j20 csu/subdir_lib
    xxx_command_log install csu/crt1.o csu/crti.o csu/crtn.o ${TARGET_PATH}/lib
    # x86_64-linux-gnu-gcc
    xxx_command_log ${TAGET_ARCH}-${TARGET_OS}-gnu-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o ${TARGET_PATH}/lib/libc.so
    xxx_command_log touch ${TARGET_PATH}/include/gnu/stubs.h


    xxx_command_log ../configure  --prefix=${TARGET_PATH}/${TARGET}/ --build=${MACHTYPE} --host=${TARGET} --target=${TARGET} --disable-multilib libc_cv_forced_unwind=yes
    xxx_command_log make install-bootstrap-headers=yes install-headers
    xxx_command_log make -j20 csu/subdir_lib
    xxx_command_log install csu/crt1.o csu/crti.o csu/crtn.o ${TARGET_PATH}/${TARGET}/lib
    xxx_command_log ${TAGET_ARCH}-${TARGET_OS}-gnu-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o ${TARGET_PATH}/${TARGET}/lib/libc.so
    xxx_command_log touch ${TARGET_PATH}/${TARGET}/include/gnu/stubs.h
    xxx_log "make glibc ${USE_GLIBC_VERSION} headers finished!"
}


make_libgcc(){
    xxx_log "make libgcc ${USE_GCC_VERSION} begin:"
    xxx_command_log cd ${BUILD_DIR}/${USE_GCC_VERSION}/${TARGET_DIR_FOR_BUILD}

    xxx_command_log make -j20 all-target-libgcc
    xxx_command_log make install-target-libgcc

    xxx_log "make libgcc ${USE_GCC_VERSION} finished!"
}

make_glibc(){
    xxx_log "make glibc ${USE_GLIBC_VERSION} begin:"
    xxx_command_log cd ${BUILD_DIR}/${USE_GLIBC_VERSION}/${TARGET_DIR_FOR_BUILD}

    xxx_command_log make -j20
    xxx_command_log make install

    xxx_log "make glibc ${USE_GLIBC_VERSION} finished!"
}

make_cpp_lib(){
    xxx_log "make std c++ library ${USE_GCC_VERSION} begin:"
    xxx_command_log cd ${BUILD_DIR}/${USE_GCC_VERSION}/${TARGET_DIR_FOR_BUILD}

    xxx_command_log make -j20
    xxx_command_log make install

    xxx_log "make std c++ library ${USE_GCC_VERSION} finished!"
}

make_prepare
make_binutils
make_kernel_headers
make_gcc
make_glibc_headers
make_libgcc
make_glibc
make_cpp_lib
xxx_log "#########################################################################"

xxx_log "make the cross compiler for gcc version ${USE_GCC_VERSION} and glibc version ${USE_GLIBC_VERSION} and kernel ${KERNEL_VERSION} and target ${TARGET} finished!"

if [ -f ${shell_base_dir}/${TARGET_DIR}.patch ]
then
    xxx_command_log patch -i ${shell_base_dir}/${TARGET_DIR}.patch -p1 -d /opt/xxx/
fi
xxx_log "#########################################################################"
