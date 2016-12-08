#!/bin/bash -x
# http://clang.llvm.org/get_started.html
# http://llvm.org/docs/GettingStartedVS.html
# http://libcxx.llvm.org/docs/BuildingLibcxx.html
#
# On builds like this I use to have a BTRFS filesystem mounted on a file/loop with compression on the fly
# Something like
#
#     dd if=/dev/zero of=disk.img bs=1M count=4096
#     mkfs.btrfs -d single -m single --mixed disk.img
#     mkdir disk
#     sudo mount -o loop,compress=lzo disk.img disk
#     chown <your username> disk
#     

BUILDDIR="$PWD/build"
INSTALL_DIR=$BUILDDIR/install
MIRROR_URL="http://llvm.org"

if [ $# -gt 0 ]; then
    CLANG_VER="$1"
    echo "Using version $CLANG_VER"
else 
    echo "Usage: $0 <version>"
    echo "Current versions:"
    wget -qO- $MIRROR_URL/releases/download.html  | sed -n 's/.*Download LLVM \([0-9\.]*\).*/\1/p' | tr '\n' ' '
    exit 1
fi

# create build directory
mkdir -p $BUILDDIR

# build clang
cd $BUILDDIR
if [ ! -e clang.$CLANG_VER.done ]; then
    CLANG_DIR="clang-${CLANG_VER}"
    PACKAGES="cfe llvm compiler-rt clang-tools-extra libcxx libcxxabi libunwind lld lldb openmp polly"
    if [ ! -e llvm.untar.$CLANG_VER.done ]; then
      for pkg in $PACKAGES; do 
        TARFILE="${pkg}-${CLANG_VER}.src.tar.xz"
        UNTARDIR="${pkg}-$CLANG_VER"
        if [ ! -e "$TARFILE" ]; then
            wget $MIRROR_URL/releases/$CLANG_VER/$TARFILE
        fi
        rm -rf $UNTARDIR
        rm -rf $UNTARDIR.src
        tar xJf $TARFILE
      done

      # move to respective places
      rm -rf $CLANG_DIR
      mv -v llvm-${CLANG_VER}.src $CLANG_DIR
      mv -v cfe-${CLANG_VER}.src $CLANG_DIR/tools/clang
      mv -v clang-tools-extra-${CLANG_VER}.src $CLANG_DIR/tools/clang/tools/extra
      mv -v compiler-rt-${CLANG_VER}.src $CLANG_DIR/projects/compiler-rt
      mv -v libcxx-${CLANG_VER}.src $CLANG_DIR/projects/libcxx
      mv -v libcxxabi-${CLANG_VER}.src $CLANG_DIR/projects/libcxxabi
      touch llvm.untar.$CLANG_VER.done
    fi

    # cmake
    rm -rf clang-build && mkdir -p clang-build 
    cd clang-build
    cmake -DCMAKE_INSTALL_PREFIX=$BUILDDIR/install -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DLIBCXX_ENABLE_EXCEPTIONS=OFF  -DCMAKE_C_COMPILER=/usr/bin/clang $BUILDDIR/$CLANG_DIR

    make
    make check-libcxx    # damn documentation is wrong on this one
    make check-libcxxabi
    
    touch $BUILDDIR/clang.$CLANG_VER.done
fi

