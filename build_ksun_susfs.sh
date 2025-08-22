#!/usr/bin/env bash

# Bash colors
green='\033[01;32m'
red='\033[01;31m'
restore='\033[0m'

# Add your clang path here
export CLANG_PATH=~/evolution/prebuilts/clang/host/linux-x86/clang-r536225/bin

# Check if clang exists
if [ ! -d ${CLANG_PATH} ]; then
    echo -e "${red}"
    echo "Clang path does not exist: ${CLANG_PATH}"
    echo "Adjust the CLANG_PATH variable in the script."
    echo -e "${restore}"
    exit 1
fi

# Check if ccache is installed
if ! command -v ccache &> /dev/null; then
    echo -e "${red}"
    echo "ccache could not be found, please install it."
    echo -e "${restore}"
    exit 1
fi

# Export environment variables
export DEFCONFIG=cepheus_defconfig
export PATH=${CLANG_PATH}:${PATH}
export O=out
export ARCH=arm64
export CC="ccache clang"
export LLVM=1
export LLVM_IAS=1
export CLANG_TRIPLE=aarch64-linux-gnu
export CROSS_COMPILE=aarch64-linux-android-
export CROSS_COMPILE_ARM32=arm-linux-androideabi-
export ZIP_NAME="EvolutionX_cepheus-ksun_susfs_$(date +%Y%m%d-%H%M)"

# Export user information so Play Integrity won't bitch about it :kek:
export KBUILD_BUILD_USER="build-user"
export KBUILD_BUILD_HOST="build-host"

# Cleanup before building
echo -e "${green}Cleaning up before building...${restore}"
echo
tmp_dir=$(`mktemp -d`)
mv .git ${tmp_dir}
rm -rf ./* .*
mv ${tmp_dir} .git
git reset --hard origin/HEAD

# Apply patches
for patch in $(ls kernel_patches/*.patch); do
    echo -e "${green}Applying patch: ${patch}...${restore}"
    echo
    git am "$patch"
done

# Initialize and update git submodules
echo -e "${green}Initializing and updating git submodules...${restore}"
echo
git submodule update --init --recursive


# Build kernel
echo -e "${green}Building kernel...${restore}"
echo
make ${DEFCONFIG}
make -j$(nproc --all) Image-dtb

# Build AnyKernel zip
if [ -f out/arch/arm64/boot/Image-dtb ]; then
    cp out/arch/arm64/boot/Image-dtb AnyKernel/
    cd AnyKernel
    zip -r9 `echo ${ZIP_NAME}`.zip *
    mv `echo ${ZIP_NAME}`.zip ~
    if [ -f ~/${ZIP_NAME}.zip ]; then
        echo
        echo -e "${green}Kernel build completed successfully! Flash zip is located in your home directory: ~/${ZIP_NAME}.zip${restore}"
    fi
else
    echo
    echo -e "${red}Kernel build failed! Please check the output for errors.${restore}"
    exit 1
fi
