#!/bin/bash -x
# http://clang.llvm.org/get_started.html
# 

BUILDDIR=/d/build/
INSTALL_DIR=$BUILDDIR/install-gcc
MIRROR_URL="http://llvm.org"
CMAKEBIN="D:\CMAKE\bin"

# check dependencies
pacman -S --needed flex bison gmp mpc mpfr wget mingw64/mingw-w64-x86_64-gcc
pacman -S --needed mingw-w64-x86_64-{binutils,crt-git,gcc,gcc-libs,gdb,headers-git,libmangle-git,libwinpthread-git,make,pkg-config,tools-git,winpthreads-git}

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
cd $BUILDDIR

if [ -e "clang.$CLANG_VER.done" ]; then
    echo "Nothing to do."
fi

PACKAGES="cfe llvm compiler-rt clang-tools-extra" #libcxx libcxxabi libunwind lld lldb openmp polly 
if [ ! -e llvm.untar.done ]; then
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
  rm -rf clang-${CLANG-VER}
  mv -v llvm-${CLANG_VER}.src clang-${CLANG_VER}
  mv -v cfe-${CLANG_VER}.src clang-${CLANG_VER}/tools/clang
  mv -v clang-tools-extra-${CLANG_VER}.src clang-${CLANG_VER}/tools/clang/tools/extra
  mv -v compiler-rt-${CLANG_VER}.src clang-${CLANG_VER}/projects/compiler-rt
  touch llvm.untar.done
fi

# cmake
rm -rf clang-build && mkdir -p clang-build 
cd clang-build
cmake ../clang-${CLANG_VER} -DCMAKE_INSTALL_PREFIX="$BUILDDIR/install" -DCMAKE_BUILD_TYPE=Release -G "Visual Studio 14 Win64"

# TODO - find out why we need this ugly patch
find . -name cmake_install.cmake | ( while read fn; do sed -i 's/$(Configuration)/Release/' $fn; done )


$COMSPEC <<ENDCMD
set TEMP=
set TMP=
call "%VS140COMNTOOLS%\..\..\VC\bin\amd64\vcvars64.bat"
REM devenv LLVM.sln /Build Release /project ALL_BUILD 
devenv LLVM.sln /Build Release /project INSTALL
ENDCMD
