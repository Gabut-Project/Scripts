#!/bin/bash
export KBUILD_BUILD_USER=Nadins
export KBUILD_BUILD_HOST=Laptop
export KJOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"

ccache=$(which ccache)

function clone_clang()
{
  CLANG_VERSION="google clang 9.0.6"
#  git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 clang
#  cd clang
#  find . | grep -v ${CLANG_VERSION} | xargs rm -rf
#  CLANG_PATH="${PWD}/${CLANG_VERSION}"
  git clone https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-5799447 clang --depth=1
  CLANG_PATH="${PWD}/clang"
  cd ..
}

function clone_custom_clang()
{
  echo "deb http://archive.ubuntu.com/ubuntu eoan main" >> /etc/apt/sources.list && apt-get update
  apt-get --no-install-recommends install libc6 libstdc++6 libgnutls30 ccache -y
  git clone https://github.com/kdrag0n/proton-clang --depth=1 -b master clang
  CLANG_VERSION="CLANG 10"
  CLANG_PATH="${PWD}/clang"
  GCC64="${CLANG_PATH}/bin/aarch64-linux-gnu-"
  GCC32="${CLANG_PATH}/bin/arm-linux-gnueabi-"
  GCC64_TYPE="aarch64-linux-gnu-"
}

function clone_gcc()
{
  GCC64_TYPE="aarch64-elf-"
  GCC32_TYPE="arm-eabi-"
  GCC_VERSION="GCC 9"
  git clone https://github.com/kdrag0n/${GCC64_TYPE}gcc --depth=1
  git clone https://github.com/kdrag0n/${GCC32_TYPE}gcc --depth=1
  GCC64="${ccache} ${PWD}/${GCC64_TYPE}gcc/bin/${GCC64_TYPE}"
  GCC32="${ccache} ${PWD}/${GCC32_TYPE}gcc/bin/${GCC32_TYPE}"
}

function install_ubuntu_gcc()
{
  apt-get install gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi -y
  GCC64_TYPE=aarch64-linux-gnu-
  GCC64=aarch64-linux-gnu-
  GCC32=arm-linux-gnueabi-
}

#输出目录 设备
function build_gcc()
{
  rm -rf ${1}/arch/arm64/boot
  make O=${1} ARCH=arm64 $merlin_defconfig
  make -j${KJOBS} O=${1} ARCH=arm64 CROSS_COMPILE="${GCC64}" CROSS_COMPILE_ARM32="${GCC32}"
  if [ $? -ne 0 ]; then
    errored "为${2}构建时出错， 终止。。。"
  fi
}
function build_clang()
{
  rm -rf ${1}/arch/arm64/boot
  make O=${1} ARCH=arm64 $merlin_defconfig
  make -j${KJOBS} O=${1} ARCH=arm64 CC="${ccache} clang" AR="llvm-ar" NM="llvm-nm" OBJCOPY="llvm-objcopy" OBJDUMP="llvm-objdump" STRIP="llvm-strip" CROSS_COMPILE="${GCC64}" CROSS_COMPILE_ARM32="${GCC32}" CLANG_TRIPLE="${GCC64_TYPE}"
  if [ $? -ne 0 ]; then
    errored "为${2}构建时出错， 终止。。。"
  fi
}

#设备名
function work_zip()
{
  git clone https://github.com/wloot/AnyKernel3
  ZIPNAME=JFla-Karamel-${TRAVIS_BUILD_NUMBER}-${1}-AOSP-${GITHEAD}.zip
  cp ${OUT_DIR}/arch/arm64/boot/Image.gz-dtb AnyKernel3
  cd AnyKernel3
  zip -r ${ZIPNAME} *
  telegram_upload ${ZIPNAME}
  rm ${ZIPNAME} Image.gz-dtb
  cd $(dirname "$PWD")
}
