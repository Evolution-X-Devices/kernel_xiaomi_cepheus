#!/bin/bash
rm .version
# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
export CLANG_PATH=/home/mihau/mykernel/azure-clang-main/bin
export PATH=${CLANG_PATH}:${PATH}
export CROSS_COMPILE=${CLANG_PATH}/aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=${CLANG_PATH}/arm-linux-gnueabi-
DEFCONFIG="cepheus_defconfig"

# Kernel Details
VER=""

# Paths
KERNEL_DIR=`pwd`
REPACK_DIR=/home/mihau/mykernel/AnyKernel3
ZIP_MOVE=/home/mihau/mykernel

# Functions
function clean_all {
		rm -rf $REPACK_DIR/Image*
		cd $KERNEL_DIR
		echo
		make clean && make mrproper
}

function make_kernel {
		echo
		make CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip $DEFCONFIG
		make CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip -j$(grep -c ^processor /proc/cpuinfo)

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
BASE_AK_VER="POST-SOVIET-MI9-"
DATE=`date +"%Y%m%d-%H%M"`
AK_VER="$BASE_AK_VER$VER"
ZIP_NAME="$AK_VER"-"$DATE"
#export LOCALVERSION=~`echo $AK_VER`
#export LOCALVERSION=~`echo $AK_VER`
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=Mihau
export KBUILD_BUILD_HOST=Mihau

echo

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo

while read -p "Do you want to build? (y/n)" dchoice
do
case "$dchoice" in
	y|Y )
		make_kernel
		make_boot
                make_zip
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done


echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo
