#!/bin/bash -x
#
# https://root.cern.ch/cling-build-instructions
# arrayfire.com/building-cling-for-x86-and-arm
#

BUILDDIR="$PWD/cling-build"
INSTALL_DIR=$BUILDDIR/cling-install
MIRROR_URL="http://root.cern.cn"
COMPILER_DIR="$HOME/disk/build/install"

# create build directory
mkdir -p $BUILDDIR

# build cling
if [ ! -e $BUILDDIR/cling.checkout.done ]; then

    cd $BUILDDIR
    git clone http://root.cern.ch/git/llvm.git cling
    cd cling
    git checkout cling-patches
    cd tools
    git clone http://root.cern.ch/git/cling.git
    git clone http://root.cern.ch/git/clang.git
    cd clang
    git checkout cling-patches

    touch $BUILDDIR/cling.checkout.done
fi

if [ ! -e $BUILDDIR/cling.done ]; then    

    cd $BUILDDIR
    # cmake
    rm -rf build && mkdir -p build 
    cd build
    
    cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DCMAKE_BUILD_TYPE=Release \
	  -DCMAKE_CXX_COMPILER=$COMPILER_DIR/bin/clang++ \
	  -DCMAKE_C_COMPILER=$COMPILER_DIR/bin/clang \
	  $BUILDDIR/cling

    make -j2
    make install
    
    touch $BUILDDIR/cling.done
fi

