#!/bin/bash -x
#
# Copyright 2016 VITORIAN LLC
# www.vitorian.com/x1
#
# Install MSYS2 from https://msys2.github.io/
# Install Microsoft Visual Studio 2015 DESKTOP https://go.microsoft.com/fwlink/?LinkId=691984&clcid=0x409
# Install NASM for Windows http://www.nasm.us/pub/nasm/releasebuilds/2.12.02/win64/
# Install ACTIVE PERL http://www.activestate.com/activeperl/downloads ON D:\PERL64  (for openssl)

NASM_PATH="D:\Program Files (x86)\NASM"
MSPATH="C:\Program Files (x86)\MSBuild\14.0\bin" 
ACTIVE_PERL_PATH="D:\Perl64"
BUILDDIR=/d/build 

haserr=0
if [ -z "${VS140COMNTOOLS}" ]; then
    echo "Visual Studio 2015 is not installed"
    haserr=1
fi

if [ -z "$COMSPEC" ]; then
    echo "Please set COMSPEC to your CMD.EXE executable"
    haserr=1
fi

if [ ! "$MSYSTEM" == "MINGW64" ]; then
    echo "You do not have MSYS2 installed. Please download it from https://msys2.github.io/"
    haserr=1
fi

if [ ! -e "$ACTIVE_PERL_PATH/bin/perl" ]; then
    echo "You do not seem to have Active Perl installed on $ACTIVE_PERL_PATH"
    echo "Please download it from http://www.activestate.com/activeperl/downloads and install it"
    echo "Also update the ACTIVE_PERL_PATH on top of this script to point to the directory you installed it"
    haserr=1
fi

if [ haserr == 1 ]; then
    echo "Errors detected. Bailing out."
    exit 1
fi

# MS VISUAL STUDIO PATH
$COMSPEC <<AHERE 
@echo off
call "%VS140COMNTOOLS%\..\..\VC\vcvarsall.bat" x86_amd64
echo %PATH% > Win64Path.log
set > Environment.log 
AHERE
WINPATH=`cat Win64Path.log`
export PATH=`cygpath -p "$WINPATH"`
export PATH="$ACTIVE_PERL_PATH:$PATH:$NASMPATH:$MSPATH"

echo "Current PATH=$PATH"

mkdir -p $BUILDDIR
cd $BUILDDIR

# Check if we have all the necessary tools
pacman -S --needed bash bash-completion bsdcpio bsdtar bzip2 ca-certificates catgets coreutils crypt curl dash db expat \
  file filesystem findutils flex gawk gcc-libs gdbm gettext git gmp gnupg grep gzip heimdal heimdal-libs icu inetutils  \
  info less libarchive libasprintf libassuan libbz2 libcatgets libcrypt libcurl libdb libedit libexpat libffi libgdbm   \
  libgettextpo libgpg-error libgpgme libiconv libidn libintl liblzma liblzo2 libmetalink libnettle libopenssl libp11-kit \
  libpcre libpcre16 libpcre32 libpcrecpp libpcreposix libreadline libsqlite libssh2 libtasn1 libutil-linux libxml2 lndir \
  m4 make mingw-w64-x86_64-binutils mingw-w64-x86_64-bzip2 mingw-w64-x86_64-ca-certificates mingw-w64-x86_64-c-ares      \
  mingw-w64-x86_64-cmake mingw-w64-x86_64-crt-git mingw-w64-x86_64-curl mingw-w64-x86_64-expat mingw-w64-x86_64-gcc \
  mingw-w64-x86_64-gcc-ada mingw-w64-x86_64-gcc-fortran mingw-w64-x86_64-gcc-libgfortran mingw-w64-x86_64-gcc-libs \
  mingw-w64-x86_64-gcc-objc mingw-w64-x86_64-gdb mingw-w64-x86_64-gdbm mingw-w64-x86_64-gettext mingw-w64-x86_64-gmp \
  mingw-w64-x86_64-gnutls mingw-w64-x86_64-headers-git mingw-w64-x86_64-isl mingw-w64-x86_64-jansson \
  mingw-w64-x86_64-jsoncpp mingw-w64-x86_64-libarchive mingw-w64-x86_64-libffi mingw-w64-x86_64-libiconv \
  mingw-w64-x86_64-libidn mingw-w64-x86_64-libmangle-git mingw-w64-x86_64-libmetalink mingw-w64-x86_64-libssh2 \
  mingw-w64-x86_64-libsystre mingw-w64-x86_64-libtasn1 mingw-w64-x86_64-libtre-git mingw-w64-x86_64-libuv \
  mingw-w64-x86_64-libwinpthread-git mingw-w64-x86_64-lz4 mingw-w64-x86_64-lzo2 mingw-w64-x86_64-make mingw-w64-x86_64-mpc \
  mingw-w64-x86_64-mpfr mingw-w64-x86_64-ncurses mingw-w64-x86_64-nettle mingw-w64-x86_64-nghttp2 mingw-w64-x86_64-openssl \
  mingw-w64-x86_64-p11-kit mingw-w64-x86_64-pkg-config mingw-w64-x86_64-python2 mingw-w64-x86_64-readline \
  mingw-w64-x86_64-rtmpdump-git mingw-w64-x86_64-spdylay mingw-w64-x86_64-tcl mingw-w64-x86_64-termcap mingw-w64-x86_64-tk \
  mingw-w64-x86_64-tools-git mingw-w64-x86_64-windows-default-manifest mingw-w64-x86_64-winpthreads-git mingw-w64-x86_64-xz \
  mingw-w64-x86_64-zlib mintty mpfr msys2-keyring msys2-launcher-git msys2-runtime ncurses openssh openssl p11-kit pacman \
  pacman-mirrors pactoys-git pax-git pcre perl perl-Authen-SASL perl-Convert-BinHex perl-Encode-Locale perl-Error \
  perl-File-Listing perl-HTML-Parser perl-HTML-Tagset perl-HTTP-Cookies perl-HTTP-Daemon perl-HTTP-Date perl-HTTP-Message \
  perl-HTTP-Negotiate perl-IO-Socket-SSL perl-IO-stringy perl-libwww perl-LWP-MediaTypes perl-MailTools perl-MIME-tools \
  perl-Net-HTTP perl-Net-SMTP-SSL perl-Net-SSLeay perl-TermReadKey perl-TimeDate perl-URI perl-WWW-RobotRules pkgfile \
  rebase rsync sed tar tftp-hpa time ttyrec tzcode util-linux vim wget which xz zlib

##########################################################################################################
# build openssl 
# (alternatively download the binaries *not tested*)
# http://p-nand-q.com/programming/windows/building_openssl_with_visual_studio_2013.html
##########################################################################################################
cd $BUILDDIR
if [ ! -e "openssl.done" ]; then
    if [ -d "openssl" ]; then
       cd openssl 
       git pull origin master 
    else
       rm -rf openssl 
       if [ ! -e "openssl.tgz" ]; then 
         git clone git://git.openssl.org/openssl.git
         ( cd openssl; git checkout . )
         tar czvf openssl.tgz openssl 
       else 
         tar xzvf openssl.tgz 
       fi 
       cd openssl 
    fi

    rm -rf tmp
    mkdir -p tmp
    OPENSSL_DIR_WIN=`cygpath -d $BUILDDIR/openssl`
    INSTALL_DIR_WIN=`cygpath -d $BUILDDIR/install`
    $COMSPEC <<ENDCMD
    call "%VS140COMNTOOLS%\..\..\VC\vcvarsall.bat" x86_amd64
    $COMSPEC /c "$ACTIVE_PERL_PATH/bin/perl Configure VC-WIN64A no-shared no-asm --prefix=$INSTALL_DIR_WIN"
    nmake 
    nmake install
ENDCMD
    
    # timestamp
    touch ../openssl.done
fi

##########################################################################################################
# build boost - mongocxx needs 1.61 (won't work with 1.62+ because of removal of string_ref)
##########################################################################################################
cd $BUILDDIR
if [ ! -e "$BUILDDIR/boost.done" ]; then 

    #    git clone --recursive https://github.com/boostorg/boost.git boost
    #    git checkout boost-1.61.0
    #    git submodule update

    BOOST_VERSION="1_61_0"
    BOOST_TAR_FILE="boost_${BOOST_VERSION}.tar.gz"
    BOOST_DIR="boost_${BOOST_VERSION}"
    
    # make sure the directory is empty
    rm -rf boost_$BOOST_VERSION 
    
    # Download if file not there yet
    if [ ! -e $BOOST_TAR_FILE ]; then
        wget https://sourceforge.net/projects/boost/files/boost/1.61.0/${BOOST_TAR_FILE}/download -O ${BOOST_TAR_FILE} 
    fi
    tar xzvf $BOOST_TAR_FILE 
    cd boost_$BOOST_VERSION 

    # make build binary
    if [ ! -e b2 ]; then 
        #./bootstrap.sh 
        $COMSPEC /c "bootstrap.bat" 
    fi
   
    #./b2 --toolset=msvc --variant=release --link=shared --threading=single --build-type=complete --prefix=../install address-model=64 install
    #./b2 --toolset=msvc --build-type=complete variant=release link=shared threading=single  address-model=64 architecture=x86 --with-chrono --with-date-time --prefix=../install install 
    #./b2 headers
    ./b2 -a -j4 --toolset=msvc --build-type=complete variant=release,debug link=static,shared threading=single  address-model=64  --prefix=../install install 
    #--stagedir=stage/win64 stage

    #./b2 --toolset=msvc variant=release link=shared threading=single runtime-link=shared
    # ./b2 -a -j4 --reconfigure --with-python msvc architecture=x86 address-model=64 variant=release link=shared threading=single runtime-link=shared stage

    # timestamp
    touch ../boost.done
fi

# This is a quirk with visual studio that conflicts with the TMP variable
# http://www.thepicklepages.com/drupal/pickled/error-msb6001-invalid-command-line-switch-clexe-item-has-already-been-added-key-dictionary
export TEMP=
export TMP=


##########################################################################################################
# build libbson
##########################################################################################################
cd $BUILDDIR
if [ ! -e "libbson.done" ]; then
    if [ -d "libbson" ]; then
       cd libbson
       git pull origin master 
    else
       git clone https://github.com/mongodb/libbson
       cd libbson
    fi

    # create a clean building directory
    rm -rf build-tmp
    mkdir -p build-tmp
    cd build-tmp
    cmake .. -DCMAKE_INSTALL_PREFIX="$BUILDDIR/install" -G"Visual Studio 14 Win64"
    cd .. 

    # rebuild and install 
    $COMSPEC /c "devenv.exe build-tmp\libbson.sln /Build Release /project ALL_BUILD" 
    $COMSPEC /c "devenv.exe build-tmp\libbson.sln /Build Release /project INSTALL"

    # timestamp
    touch ../libbson.done
fi

##########################################################################################################
# build mongo c library
##########################################################################################################
cd $BUILDDIR
if [ ! -e "$BUILDDIR/mongo-c-driver.done" ]; then 
    # clone mongo-c client library:
    if [ -d "mongo-c-driver" ]; then
        cd mongo-c-driver 
        git pull origin master 
    else
        git clone https://github.com/mongodb/mongo-c-driver
        cd mongo-c-driver 
    fi

    # create a clean building directory
    rm -rf build-tmp
    mkdir -p build-tmp
    cd build-tmp
    cmake .. -DCMAKE_INSTALL_PREFIX="$BUILDDIR/install" -DCMAKE_LIBRARY_PATH="${BUILDDIR}/install" -DCMAKE_INCLUDE_PATH="${BUILDDIR}/install"  -G"Visual Studio 14 Win64"

    cd .. 
    
    # rebuild and install 
    $COMSPEC /c "devenv.exe build-tmp\libmongoc.sln /Build Release /project ALL_BUILD"
    $COMSPEC /c "devenv.exe build-tmp\libmongoc.sln /Build Release /project INSTALL"

    # timestamp
    touch ../mongo-c-driver.done
fi



##########################################################################################################
# build mongo c++ library
##########################################################################################################
cd $BUILDDIR
if [ ! -e "$BUILDDIR/mongo-cxx-driver.done" ]; then 
    # clone mongo-cxx client library:
    if [ -d "mongo-cxx-driver" ]; then
        cd mongo-cxx-driver 
        git pull origin master 
    else
        git clone https://github.com/mongodb/mongo-cxx-driver
        cd mongo-cxx-driver 
    fi

    # create a clean building directory
    rm -rf build-tmp
    mkdir -p build-tmp
    cd build-tmp
    cmake .. -DCMAKE_INSTALL_PREFIX="$BUILDDIR/install" -DBOOST_ROOT="${BUILDDIR}/boost" -DLIBBSON_DIR="${BUILDDIR}/install" -DLIBMONGOC_DIR="${BUILDDIR}/install" -DCMAKE_INCLUDE_PATH="${BUILDDIR}/install"  -G"Visual Studio 14 Win64"
    cd ..

    # rebuild and install 
    $COMSPEC /c "devenv.exe build-tmp\MONGO_CXX_DRIVER.sln /Build Release /project ALL_BUILD"
    $COMSPEC /c "devenv.exe build-tmp\MONGO_CXX_DRIVER.sln /Build Release /project INSTALL"

    # timestamp



    touch ../mongo-cxx-driver.done
fi



