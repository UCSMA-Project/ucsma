#!/bin/bash

FLAG_MENUCONFIG=false
FLAG_KERNELCONFIG=false

# Get number of available system processors (includes hyper-threading processors)
PROCESSORS=`grep -c ^processor /proc/cpuinfo`
(( THREADS = $PROCESSORS + 2 ))

usage() {
    if [ $# = 2 ]; then
        local flag=$1;
        local msg=$2;
        printf "\t$flag\t\t$msg\n";
    elif [ $# = 3 ]; then
        local flag=$1;
        local arg=$2;
        local msg=$3;
        printf "\t$flag $arg\t$msg\n";
    fi
}

print_usage() {
    echo "Usage: $0 [-c] [-k] [-t THREADS]"
    usage '-c' 'Enable advanced OpenWRT config (i.e. menuconfig).'
    usage '-k' 'Enable OpenWRT kernel config (i.e. kernel_menuconfig).'
    usage '-t' 'THREADS' 'Number of threads to use when compiling OpenWRT. Default: # of processors + 2.'
}

# Loop to get options / print usage
while getopts 'ckt:' flag; do
  case "${flag}" in
    c) FLAG_MENUCONFIG=true ;;
    k) FLAG_KERNELCONFIG=true ;;
    t) THREADS="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

# Initialize submodules
git submodule update --init --recursive

# Copy OpenWRT config diff into OpenWRT dir and prepare .config
cp OpenWRT.config OpenWRT-14.07-JS9331/.config
cd OpenWRT-14.07-JS9331
make defconfig

# Bring up menuconfig if specified
if [ "$FLAG_MENUCONFIG" = true ]; then
    make menuconfig;
fi

# Bring up kernel_menuconfig if specified
if [ "$FLAG_KERNELCONFIG" = true ]; then
    make kernel_menuconfig;
fi

# Download OpenWRT build dependencies
make download

# Build OpenWRT
make -j $THREADS v=S

# cd to repo root
cd ..

# prepare dir to build unlock kernel module
BUILD_DIR=build_dir
ATH_DRIVER_DIR=OpenWRT-14.07-JS9331/build_dir/target-mips_34kc_uClibc-0.9.33.2/linux-ar71xx_generic/linux-3.10.49/drivers/net/wireless/ath

mkdir $BUILD_DIR
cp -r $ATH_DRIVER_DIR build_dir
mkdir $BUILD_DIR/toolchain
cp OpenWRT-14.07-JS9331/bin/ar71xx/OpenWrt-Toolchain-ar71xx-for-mips_34kc-gcc-4.8-linaro_uClibc-0.9.33.2.tar.bz2 $BUILD_DIR/toolchain

# todo: unzip toolchain
# todo: store location of script in a var
# todo: copy ucsma modules code to $BUILD_DIR/ath/ath9k
# todo: compile modules
# todo: compile packetspammer
# todo: move various build products into one folder (e.g. modules, packetspammer, firmware images)
# todo: consider whether raspi stuff should be included

# make -C "/home/gg/documents/csc494/OpenWRT-14.07-JS9331/build_dir/target-mips_34kc_uClibc-0.9.33.2/linux-ar71xx_generic/linux-3.10.49/" \
#        ARCH=mips \
#        CROSS_COMPILE="/home/gg/documents/csc494/ucsma_build_dir/toolchain/OpenWrt-Toolchain-ar71xx-for-mips_34kc-gcc-4.8-linaro_uClibc-0.9.33.2/toolchain-mips_34kc_gcc-4.8-linaro_uClibc-0.9.33.2/bin//mips-openwrt-linux-" \
#        M=/home/gg/documents/csc494/ucsma_build_dir/ath/ath9k     \
#        modules

