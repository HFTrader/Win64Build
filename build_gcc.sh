#!/bin/bash 
#############################################################################################
# IT DOES NOT WORK YET
#############################################################################################

BUILD_DIR=/d/build/
INSTALL_DIR=$BUILD_DIR/install-gcc
MIRROR_URL="http://mirrors-usa.go-parts.com"

# check dependencies
pacman -S --needed flex bison gmp mpc mpfr wget mingw64/mingw-w64-x86_64-gcc
pacman -S --needed mingw-w64-x86_64-{binutils,crt-git,gcc,gcc-libs,gdb,headers-git,libmangle-git,libwinpthread-git,make,pkg-config,tools-git,winpthreads-git}

if [ $# -gt 0 ]; then
    GCC_VER="$1"
    echo "Using version $GCC_VER"
else 
    #GCC_VER="7-20161127" 
    #GCC_VER="4.1-20080630"
    echo "Usage: $0 <version>"
    echo "Current versions:"
    wget -qO- $MIRROR_URL/gcc/snapshots | sed -n 's/.*href=\"\(.*\)\/\".*/\1/p' | tr '\n' ' '
    exit 1
fi


# create build directory
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# download GCC tarfile and unpack
GCC_TARFILE="gcc-$GCC_VER.tar.bz2"
GCC_DIR="gcc-$GCC_VER"
if [ ! -e $GCC_TARFILE ]; then
    wget $MIRROR_URL/gcc/snapshots/$GCC_VER/$GCC_TARFILE
fi
if [ -d $GCC_DIR ]; then
    rm -rf $GCC_DIR
fi
tar xjf $GCC_TARFILE

# compile GCC
cd $GCC_DIR
CC="/mingw64/bin/gcc"
CXX="/mingw64/bin/g++"
AR="/mingw64/bin/ar"
AS="/mingw64/bin/as"
RANLIB="/mingw64/bin/ranlib"
CFLAGS="-02"
CPPFLAGS="-O2" 
./configure --prefix=${INSTALL_DIR} --build=i686-w64-mingw32 --target=i686-w64-winnt --enable-languages=c,c++ --disable-multilib --disable-threads  
make

