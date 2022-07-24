#!/bin/bash

rm .version

# Bash Color

green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources

echo 'Enter rom path from which to build kernel'
read rompath

export CLANG_PATH=${rompath}/prebuilts/clang/host/linux-x86/trb_clang/bin
export PATH=${CLANG_PATH}:${PATH}
export CROSS_COMPILE=${CLANG_PATH}/aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=${CLANG_PATH}/arm-linux-gnueabi-


DEFCONFIG="raphael_defconfig"

# Paths

KERNEL_DIR=${rompath}/kernel/xiaomi/raphael
REPACK_DIR=${rompath}/pack
ZIP_MOVE=${rompath}/builds

mkdir -p $ZIP_MOVE/backup
mv $ZIP_MOVE/* $ZIP_MOVE/backup &> /dev/null

git clone git@github.com:SukeeratSG/anykernel.git $REPACK_DIR &> /dev/null ||  cd $REPACK_DIR ; git reset --hard HEAD~15 &> /dev/null ;git pull &> /dev/null

# Functions

function clean_all {
		
		clear
		echo 'Cleaning'
		rm -rf $REPACK_DIR/Image* $KERNEL_DIR/out
		cd $KERNEL_DIR
		make clean
		make mrproper
}

function make_kernel {

		clear 
		echo 'Making kernel'
		make CC=clang AR=llvm-ar NN=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objduml AS=llvm-as STRIP=llvm-strip $DEFCONFIG &> /dev/null
		make CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip -j$(grep -c ^processor /proc/cpuinfo) &> /dev/null

}


function make_boot {
		cp out/arch/arm64/boot/Image.gz-dtb $REPACK_DIR
	}


function make_zip {
		cd $REPACK_DIR
		zip -r9 `echo $ZIP_NAME`.zip *
		mv  `echo $ZIP_NAME`*.zip $ZIP_MOVE
		cd $KERNEL_DIR
}


DATE_START=$(date +"%s")


echo -e "${green}"
echo "-----------------"
echo "Making Kernel:"
echo "-----------------"
echo -e "${restore}"


# Vars

BASE_AK_VER="PSSG"
VER="-Performance-Non-OC"

DATE=`date +"%d.%m.%Y-%H%M"`
AK_VER="$BASE_AK_VER$VER"
ZIP_NAME="$AK_VER"-"$DATE"

export KBUILD_BUILD_USER=goindi-CI
export KBUILD_BUILD_HOST=goindi-industries
export ARCH=arm64
export SUBARCH=arm64

# Build Kernel

clean_all
make_kernel
make_boot
make_zip

echo -e "${green}"
echo "-------------------"
echo "Built Sucessfully:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."

cd $ZIP_MOVE
telegram-send --config /home/jenkins/configs/sukerat.conf --file *zip  && echo "Uploaded sucessfully" || echo "Upload Failed"
ls -a
