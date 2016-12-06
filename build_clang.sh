#!/bin/bash -x
# http://clang.llvm.org/get_started.html
# http://llvm.org/docs/GettingStartedVS.html
# 

BUILDDIR=/d/build/
INSTALL_DIR=$BUILDDIR/install-gcc
MIRROR_URL="http://llvm.org"
CMAKEBIN="D:\CMAKE\bin"
GNUWIN32="D:\Packages\GetGnuWin32\GetGnuWin32\gnuwin32"

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

# build clang
cd $BUILDDIR
if [ ! -e clang.$CLANG_VER.done ]; then
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
      CLANG_DIR="clang-${CLANG-VER}"
      rm -rf $CLANG_DIR
      mv -v llvm-${CLANG_VER}.src $CLANG_DIR
      mv -v cfe-${CLANG_VER}.src $CLANG_DIR/tools/clang
      mv -v clang-tools-extra-${CLANG_VER}.src $CLANG_DIR/tools/clang/tools/extra
      mv -v compiler-rt-${CLANG_VER}.src $CLANG_DIR/projects/compiler-rt
      mv -v libcxx-${CLANG_VER}.src libcxx-${CLANG_VER}
      mv -v libcxxabi-${CLANG_VER}.src libcxxabi-${CLANG_VER}
      touch llvm.untar.$CLANG_VER.done
    fi

    # cmake
    rm -rf clang-build && mkdir -p clang-build 
    cd clang-build
    cmake ../clang-${CLANG_VER} -DCMAKE_INSTALL_PREFIX="$BUILDDIR/install" -DCMAKE_BUILD_TYPE=Release -G "Visual Studio 14 Win64" -DLLVM_COMPILER_JOBS=3 -DLLVM_LIT_TOOLS_DIR=$GNUWIN32/bin

    # TODO - find out why we need this ugly patch
    find . -name cmake_install.cmake | ( while read fn; do sed -i 's/$(Configuration)/Release/' $fn; done )

    cmake --build . --config Release --target ALL_BUILD
    cmake --build . --config Release --target INSTALL
    
#    $COMSPEC <<ENDCMD
#    set TEMP=
#    set TMP=
#    call "%VS140COMNTOOLS%\..\..\VC\bin\amd64\vcvars64.bat"
#    devenv LLVM.sln /Build Release /project ALL_BUILD 
#    devenv LLVM.sln /Build Release /project INSTALL
#ENDCMD

    $BUIDDIR/clang-${CLANG_VER}/utils/lit/lit.py -sv --param=build_mode=Win32 --param=build_config=Release --param=clang_site_config=$BUILDDIR/clang-${CLANG_VER}/tools/clang/test/lit.site.cfg $BUILDDIR/clang-${CLANG_VER}/tools/clang/test
    touch $BUILDDIR/clang.$CLANG_VER.done
fi


cd $BUILDDIR
if [ ! -e libcxx.$CLANG_VER.done ]; then   
    rm -rf libcxx-build && mkdir libcxx-build
    cd libcxx-build
    export BINDIR=$BUILDDIR/install/bin
    cmake -DCMAKE_CXX_COMPILER=$BINDIR/clang++.exe -DCMAKE_C_COMPILER=$BINDIR/clang.exe -DCMAKE_AR=$BINDIR/llvm-ar  \
          -DLLVM_PATH=$BUILDDIR/clang-$CLANG_VER -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXX_CXX_ABI_INCLUDE_PATHS=$BUILDDIR/buildcxxabi-$CLANG_VER \
          $BUILDDIR/libcxx-$CLANG_VER 
          #-T "LLVM-vs2014" -G "Visual Studio 15 Win64"

    #export CC=$BINDIR/clang CXX=$BINDIR/clang++
    #make
    #make check-libcxx
    #touch ../libcxx.$CLANG_VER.done
fi

# Usage
# clang++ -I /d/Packages/GetGnuWin32/GetGnuWin32/gnuwin32/include/glibc/ -L /c/Program\ Files\ \(x86\)/Microsoft\ SDKs/Windows/v7.1A/Lib/ -L /c/Program\ Files\ \(x86\)/Windows\ Kits/10/Lib/10.0.14393.0/ucrt/x64/ hello.cpp -o hello

