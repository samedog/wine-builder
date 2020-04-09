#!/bin/bash
## build wine with vkd3d + deps
##########################################################################################
# By Diego Cardenas "The Samedog" under GNU GENERAL PUBLIC LICENSE Version 2, June 1991
# (www.gnu.org/licenses/old-licenses/gpl-2.0.html) e-mail: the.samedog[]gmail.com.
# https://github.com/samedog/wine-builder
##########################################################################################
#
# 24-03-2020:   - First release
#               - Wine-tkg-git not needed sice GE already has the patches
#               - Addded custom patches to rollback proton behaviour 
# 25-03-2020    - Fixed dxvk multilib compiling
#               - Added gstramer, gst-plugins-base and gst-plugins-good
#               - $DIRECTORY used to ensure current location instead of relynig
#                 on "cd .." chains
#               - Colorized terminal output for errors
# 26-03-2020    - Check for compiling exit state for gnu make and meson/ninja
#               - Added gstreamer deps
# 27-03-2020    - Fixed libvpx configuring options
# 28-03-2020    - Added gstreamer subdeps
#               - Added some flags
# 01-04-2020    - Multiple fixes
# 02-04-2020    - Added threads cli argument
# 09-05-2020    - Added DESTDIR for package creation
#               - fixed some minor issues like unthreaded make and ninja 
#               - Added more info and a confirmation before doing anything
#               - Added custom patches for some new wine implementations
##########################################################################################
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
ARGS="$@"
REPOFLAG=0
NBGST=0
PTCHSTP=0
GST=1
DST=0
DEST=""
THRD=0
threads=$(grep -c processor /proc/cpuinfo)
for ARG in $ARGS
    do
        if [ $ARG == "--only-repos" ];then
            REPOFLAG=1
        fi
        if [ $ARG == "--h" ] || [ $ARG == "--help" ] || [ $ARG == "-h" ];then
            echo "
supported flags:
--only-repos            : Only pull git repos and download tar packages.
--patch-stop            : Only get to patch wine {for testing purposes}.
--no-build-gstreamer    : Don't build gstreamer, meant for proper distros
                          with package managers.
--without-gstreamer     : Disable gstreamer support entirely.
--threads=x             : Number of compiling threads.
--h --help -h           : Show this help and exit.
--dest=/path/to/dest    : DESTDIR like argument.
"
            exit 1
        fi
        if [ $ARG == "--patch-stop" ];then
            PTCHSTP=1
        fi
        if [[ $ARG == "--threads"* ]];then
			THRD=1
            threads=$(echo $ARG | cut -d'=' -f2)
        fi
        if [ $ARG == "--no-build-gstreamer" ];then
            NBGST=1
        fi
        if [ $ARG == "--without-gstreamer" ];then
            NBGST=1
            GST=0
        fi
        if [[ $ARG == "--dest"* ]];then
            DST=1
            DEST=$(echo $ARG | cut -d'=' -f2)
        fi
    done

DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DIRECTORY="$(echo $DIRECTORY | sed 's/ /\\ /g')"
dxvk_version="https://github.com/doitsujin/dxvk/releases/download/v1.6/dxvk-1.6.tar.gz"

cleanup(){
    cd "$DIRECTORY"
    if [ -d "wine_prepare" ];then
        rm -rf ./wine_prepare
    fi
    
}

process_repos() {
    
    if [ ! -d "libdv-1.0.0" ];then
        curl -L https://razaoinfo.dl.sourceforge.net/project/libdv/libdv/1.0.0/libdv-1.0.0.tar.gz -o libdv-1.0.0.tar.gz
        tar xf libdv-1.0.0.tar.gz
        rm -rf libdv-1.0.0.tar.gz
    else
        rm -rf libdv-1.0.0
        curl -L https://razaoinfo.dl.sourceforge.net/project/libdv/libdv/1.0.0/libdv-1.0.0.tar.gz -o libdv-1.0.0.tar.gz
        tar xf libdv-1.0.0.tar.gz
        rm -rf libdv-1.0.0.tar.gz
    fi
    
    if [ ! -d "libsoup-2.70.0" ];then
        curl -L http://ftp.gnome.org/pub/gnome/sources/libsoup/2.70/libsoup-2.70.0.tar.xz -o libsoup-2.70.0.tar.xz
        tar xf libsoup-2.70.0.tar.xz
        rm -rf libsoup-2.70.0.tar.xz
    else
        rm -rf libsoup-2.70.0
        curl -L http://ftp.gnome.org/pub/gnome/sources/libsoup/2.70/libsoup-2.70.0.tar.xz -o libsoup-2.70.0.tar.xz
        tar xf libsoup-2.70.0.tar.xz
        rm -rf libsoup-2.70.0.tar.xz
    fi
    
    
    if [ ! -d "Vulkan-Loader" ];then
        git clone git://github.com/KhronosGroup/Vulkan-Loader
    else
        cd ./Vulkan-Loader
        git reset --hard HEAD
        git clean -xdf
        git pull origin master
        cd ..
    fi
    
    if [ ! -d "libpsl" ];then
        git clone git://github.com/rockdaboot/libpsl
    else
        cd ./libpsl
        git reset --hard HEAD
        git clean -xdf
        git pull origin master
        cd ..
    fi
    
    if [ ! -d "libvpx" ];then
        git clone git://github.com/webmproject/libvpx.git
    else
        cd ./libvpx
        git reset --hard HEAD
        git clean -xdf
        git pull origin master
        cd ..
    fi
    
    if [ ! -d "SPIRV-Headers" ];then
        git clone git://github.com/KhronosGroup/SPIRV-Headers
    else
        cd ./SPIRV-Headers
        git reset --hard HEAD
        git clean -xdf
        git pull origin master
        cd ..
    fi
    
    if [ ! -d "SPIRV-Tools" ];then
        git clone https://github.com/KhronosGroup/SPIRV-Tools
    else
        cd ./SPIRV-Tools
        git reset --hard HEAD
        git clean -xdf
        git pull origin master
       cd ..
    fi
    
    if [ ! -d "wine-staging" ];then
        git clone https://github.com/wine-staging/wine-staging
    else
        cd ./wine-staging
        git reset --hard HEAD
        git clean -xdf
        git pull origin master
        cd ..
    fi

    if [ ! -d "Vulkan-Headers" ];then
        git clone git://github.com/KhronosGroup/Vulkan-Headers
    else
        cd ./Vulkan-Headers
        git reset --hard HEAD
		git clean -xdf
        git pull origin master
        cd ..
    fi

    if [ ! -d "vkd3d" ];then
        git clone git://github.com/HansKristian-Work/vkd3d
    else
        cd ./vkd3d
        git reset --hard HEAD
		git clean -xdf
        git pull origin master
        cd ..
    fi

    if [ ! -d "gstreamer" ];then
        git clone git://github.com/GStreamer/gstreamer
    else
        cd ./gstreamer
        git clean -fxd
        git pull --force
        git reset --hard HEAD
        cd ..
    fi
    
    if [ ! -d "gst-plugins-base" ];then
        git clone git://github.com/GStreamer/gst-plugins-base
    else
        cd ./gst-plugins-base
        git clean -fxd
        git pull --force
        git reset --hard HEAD
        cd ..
    fi
    
    if [ ! -d "gst-plugins-good" ];then
        git clone git://github.com/GStreamer/gst-plugins-good
    else
        cd ./gst-plugins-good
        git clean -fxd
        git pull --force
        git reset --hard HEAD
        cd ..
    fi

    if [ ! -d "wine" ];then
        git clone git://source.winehq.org/git/wine.git
        cd ./wine
        git clean -fxd
        git pull --force
        git reset --hard "$(../wine-staging/patches/patchinstall.sh --upstream-commit)"
        cd ..
    else
        cd ./wine
        git clean -fxd
        git pull --force
        git reset --hard "$(../wine-staging/patches/patchinstall.sh --upstream-commit)"
        cd ..
    fi
    
    
    if [ ! -d "proton-ge-custom" ];then
        mkdir ./proton-ge-custom
        cd ./proton-ge-custom
        git init
        git remote add -f origin git://github.com/GloriousEggroll/proton-ge-custom
        git config core.sparseCheckout true
        echo "patches/" > .git/info/sparse-checkout
        git pull origin proton-ge-5
        cd ..
    else
        cd ./proton-ge-custom/
        git reset --hard HEAD
		git clean -xdf
        echo "patches/" > .git/info/sparse-checkout
        git pull origin proton-ge-5
        cd ..
    fi
}

prepare(){
    cd "$DIRECTORY"
    cp -rf ./wine ./wine_prepare
    cp -rf ./custom-patches ./wine_prepare/custom-patches
    cp -rf ./libdv-1.0.0 ./wine_prepare/libdv-1.0.0
    cp -rf ./libvpx ./wine_prepare/libvpx    
    cp -rf ./libpsl ./wine_prepare/libpsl   
    cp -rf ./libsoup-2.70.0 ./wine_prepare/libsoup-2.70.0   
    cp -rf ./gstreamer ./wine_prepare/gstreamer
    cp -rf ./gst-plugins-base ./wine_prepare/gst-plugins-base
    cp -rf ./gst-plugins-good ./wine_prepare/gst-plugins-good
    cp -rf ./wine-staging ./wine_prepare/wine-staging
    cp -rf ./proton-ge-custom/patches/ ./wine_prepare/patches
    cp -rf ./vkd3d ./wine_prepare/vkd3d
    cp -rf ./SPIRV-Headers ./wine_prepare/SPIRV-Headers
    cp -rf ./SPIRV-Tools ./wine_prepare/SPIRV-Tools
    cp -rf ./Vulkan-Headers ./wine_prepare/Vulkan-Headers
    cp -rf ./Vulkan-Loader ./wine_prepare/Vulkan-Loader
}

patches() {
    cd "$DIRECTORY"/wine_prepare
    cd ./patches
    ###WE REMOVE A LOT OF UNUSED STUFF
    sed -i 's/cd \.\.//g' protonprep.sh
    sed -i 's/cd dxvk//g' protonprep.sh
    sed -i 's/cd vkd3d//g' protonprep.sh
    sed -i 's/cd wine//g' protonprep.sh
    sed -i 's/cd glib//g' protonprep.sh
    sed -i 's/git checkout lsteamclient//g' protonprep.sh
    sed -i 's/cd lsteamclient//g' protonprep.sh
    sed -i 's+patch -Np1 < \.\./patches/proton-hotfixes/steamclient-disable_SteamController007_if_no_controller.patch++g' protonprep.sh
    sed -i 's/git clean -xdf//g' protonprep.sh
    sed -i 's+patch -Np1 < \.\./patches/dxvk/valve-dxvk-avoid-spamming-log-with-requests-for-IWineD3D11Texture2D.patch++g' protonprep.sh
    sed -i 's+patch -Np1 < \.\./patches/dxvk/proton-add_new_dxvk_config_library.patch++g' protonprep.sh
    sed -i 's+\.\./wine-staging/patches/patchinstall.sh+wine-staging/patches/patchinstall.sh+g' protonprep.sh
    sed -i 's+patch -Np1 < \.\./+patch -Np1 < +g' protonprep.sh
    sed -i 's/git reset --hard HEAD//g' protonprep.sh
    sed -i 's/git clean -xdf//g' protonprep.sh
    sed -i 's+for _f in ../+for _f in ./+g' protonprep.sh
    sed -i 's+patch -Np1 < patches/glib/glib_python3_hack.patch++g' protonprep.sh
    sed -i 's/cd gst-plugins-ugly//g' protonprep.sh
    sed -i "s/echo \"add Guy's patch to fix wmv playback in gst-plugins-ugly\"//g" protonprep.sh
    sed -i "s/git revert --no-commit bae4776c571cf975be1689594f4caf93ad23e0ca//g" protonprep.sh
    sed -i "s/git revert --no-commit 5e218fe758fe6beed5c7ad73405eccf33c307e6d//g" protonprep.sh
    sed -i 's+patch -Np1 < patches/gstreamer/asfdemux-always_re-initialize_metadata_and_global_metadata.patch++g' protonprep.sh
    ## we rely on my patches for now
    printf $RED"WE ARE RELYING ON MY PErSONAL PATCHES FORM HERE ON"$NC
    sed -i 's+patches/proton/valve_proton_fullscreen_hack-staging.patch+custom-patches/valve_proton_fullscreen_hack-staging.patch+g' protonprep.sh
	sed -i 's+patches/proton/proton-winevulkan.patch+custom-patches/proton-winevulkan.patch+g' protonprep.sh
	sed -i 's+patches/proton/proton-protonify_staging.patch+custom-patches/proton-protonify_staging.patch+g' protonprep.sh
    sed -i 's+patches/proton/proton-sdl_joy.patch+custom-patches/proton-sdl_joy.patch+g' protonprep.sh
    sed -i 's+patch -Np1 < "${_f}"+if [ $_f == "./patches/wine-hotfixes/guy_mediafoundation_alpha/0029-Miscellaneous.patch" ]; then  \n patch -Np1 < custom-patches/0029-Miscellaneous.patch \n else \n patch -Np1 < "${_f}" \n fi+g' protonprep.sh
   


    ## NOT NEEDED ANYMORE
    cd ..

    ./patches/protonprep.sh
    ## revert the steamuser patch
    patch -Np1 < ./custom-patches/revert.patch
    ## revert the Never create links patch
    patch -Np1 < ./custom-patches/revert2.patch
   
	
    #####  
}

build_headers() {
    ##
    cd "$DIRECTORY"/wine_prepare
    cd ./SPIRV-Headers
    mkdir build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=/usr/lib64 .. &> "$DIRECTORY"/logs/SPIRV-Headers
    make -j"$threads" &>> "$DIRECTORY"/logs/SPIRV-Headers
    if [ $? -eq 0 ]; then
		if [ $DST -eq 1 ]; then
			make install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/SPIRV-Headers
        else
			make install &>> "$DIRECTORY"/logs/SPIRV-Headers
        fi
    else
        printf $RED"something went wrong making SPIRV-Headers\n"$NC
        exit 1
    fi
    ##
    cd ../../Vulkan-Headers
    mkdir build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=/usr/lib64 .. &> "$DIRECTORY"/logs/Vulkan-Headers
    make -j"$threads" &>> "$DIRECTORY"/logs/Vulkan-Headers
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			make install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/Vulkan-Headers
        else
			make install &>> "$DIRECTORY"/logs/Vulkan-Headers
        fi
    else
        printf $RED"something went wrong making Vulkan-Headers 64bits\n"$NC
        exit 1
    fi
}

build_sprv_tools(){
    cd "$DIRECTORY"/wine_prepare
    cd ./SPIRV-Tools
    mkdir build64
    mkdir build32
    #### 32b
    cd ./build32
    cmake -DCMAKE_TOOLCHAIN_FILE=../../32bit.toolchain \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_INSTALL_BINDIR=bin/32 \
        -DCMAKE_BUILD_TYPE=Release \
        -DSPIRV_WERROR=Off \
        -DBUILD_SHARED_LIBS=ON \
        -DSPIRV-Headers_SOURCE_DIR=$DIRECTORY/wine_prepare/SPIRV-Headers .. &> "$DIRECTORY"/logs/SPIRV-Tools
    i386 make -j"$threads" &>> "$DIRECTORY"/logs/SPIRV-Tools
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			i386 make -j"$threads" install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/SPIRV-Tools
        else
			i386 make -j"$threads" install &>> "$DIRECTORY"/logs/SPIRV-Tools
        fi
    else
        printf $RED"something went wrong making SPIRV-Tools 32bits\n"$NC
        exit 1
    fi
    
    
    #### 64b
    cd ../build64
    cmake -DCMAKE_TOOLCHAIN_FILE=../../64bit.toolchain \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib64 \
        -DCMAKE_BUILD_TYPE=Release \
        -DSPIRV_WERROR=Off \
        -DBUILD_SHARED_LIBS=ON \
        -DSPIRV-Headers_SOURCE_DIR=$DIRECTORY/wine_prepare/SPIRV-Headers .. &>> "$DIRECTORY"/logs/SPIRV-Tools
    make -j"$threads" &>> "$DIRECTORY"/logs/SPIRV-Tools
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			make -j"$threads" install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/SPIRV-Tools
        else
			make -j"$threads" install &>> "$DIRECTORY"/logs/SPIRV-Tools
        fi
    else
        printf $RED"something went wrong making SPIRV-Tools 64bits\n"$NC
        exit 1
    fi
    ##
}

build_vulkan(){
    cd "$DIRECTORY"/wine_prepare
    cd ./Vulkan-Loader
    mkdir build64
    mkdir build32

    #### 32b
    cd build32
    i386 cmake -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_CXX_FLAGS="-m32" \
        -DCMAKE_C_FLAGS="-m32" \
        -DVULKAN_HEADERS_INSTALL_DIR=/usr .. &> "$DIRECTORY"/logs/Vulkan-Loader
    make -j"$threads" &>> "$DIRECTORY"/logs/Vulkan-Loader
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			make -j"$threads" install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/Vulkan-Loader
        else
			make -j"$threads" install &>> "$DIRECTORY"/logs/Vulkan-Loader
        fi
    else
        printf $RED"something went wrong making Vulkan-Loader 32bits\n"$NC
        exit 1
    fi
    #### 64b
    cd ../build64
    cmake -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib64 \
        -DVULKAN_HEADERS_INSTALL_DIR=/usr .. &>> "$DIRECTORY"/logs/Vulkan-Loader
    make -j"$threads" &>> "$DIRECTORY"/logs/Vulkan-Loader
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			make -j"$threads" install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/Vulkan-Loader
        else
			make -j"$threads" install &>> "$DIRECTORY"/logs/Vulkan-Loader
        fi
    else
        printf $RED"something went wrong making Vulkan-Loader 63bits\n"$NC
        exit 1
    fi
}

build_vkd3d(){
    cd "$DIRECTORY"/wine_prepare
    cd ./vkd3d
    ./autogen.sh &> "$DIRECTORY"/logs/vkd3d
    mkdir build32
    mkdir build64
    
    #### 32b
    cd build32
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH=/usr/lib/pkgconfig LDFLAGS="-L/usr/lib" ../configure --prefix=/usr --libdir=/usr/lib --with-spirv-tools &>> "$DIRECTORY"/logs/vkd3d
    make -j"$threads" &>> "$DIRECTORY"/logs/vkd3d
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			make -j"$threads" install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/vkd3d
        else
			make -j"$threads" install &>> "$DIRECTORY"/logs/vkd3d
        fi
    else
        printf $RED"something went wrong making vkd3d 32bits\n"$NC
        exit 1
    fi

    #### 64b
    cd ../build64
    ../configure --prefix=/usr --libdir=/usr/lib64 --with-spirv-tools &>> "$DIRECTORY"/logs/vkd3d
    make -j"$threads" &>> "$DIRECTORY"/logs/vkd3d
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			make -j"$threads" install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/vkd3d
        else
			make -j"$threads" install &>> "$DIRECTORY"/logs/vkd3d
        fi
    else
        printf $RED"something went wrong making vkd3d 64bits\n"$NC
        exit 1
    fi
}

build_gstreamer_deps() {
    ##
    cd "$DIRECTORY"/wine_prepare
    cd ./libdv-1.0.0
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH=/usr/lib/pkgconfig LDFLAGS="-L/usr/lib" i386 ./configure --prefix=/usr \
    --disable-xv \
    --bindir=/usr/bin/32 \
    --disable-static \
    --libdir=/usr/lib &> "$DIRECTORY"/logs/libdv-1.0.0
    make -j"$threads" &>> "$DIRECTORY"/logs/libdv-1.0.0
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			make -j"$threads" install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/libdv-1.0.0
        else
			make -j"$threads" install &>> "$DIRECTORY"/logs/libdv-1.0.0
        fi
    else
        echo "something went wrong making libdv 32bits"
        exit 1
    fi
    make -j"$threads" clean &>> "$DIRECTORY"/logs/libdv-1.0.0
    
    ./configure --prefix=/usr \
    --disable-xv \
    --bindir=/usr/bin \
    --disable-static \
    --libdir=/usr/lib64 &>> "$DIRECTORY"/logs/libdv-1.0.0
    make -j"$threads" &>> "$DIRECTORY"/logs/libdv-1.0.0
    if [ $? -eq 0 ]; then 
        if [ $DST -eq 1 ]; then
			make -j"$threads" install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/libdv-1.0.0
        else
			make -j"$threads" install &>> "$DIRECTORY"/logs/libdv-1.0.0
        fi
    else
        printf $RED"something went wrong making libdv 64bits\n"$NC
        exit 1
    fi
    
    
    cd ../libvpx
    sed -i 's/cp -p/cp/' build/make/Makefile 
    mkdir libvpx-build32
    mkdir libvpx-build64
    cd    libvpx-build64
    ../configure --prefix=/usr    \
	--libdir=/usr/lib64 \
	--enable-shared  \
	--disable-static
	--disable-install-docs \
    --disable-install-srcs \
    --enable-pic \
    --enable-postproc \
    --enable-runtime-cpu-detect \
    --enable-shared \
    --enable-vp8 \
    --enable-vp9 \
    --enable-vp9-highbitdepth \
    --enable-vp9-temporal-denoising &> "$DIRECTORY"/logs/libvpx
    make -j"$threads" &>> "$DIRECTORY"/logs/libvpx
    if [ $? -eq 0 ]; then 
        if [ $DST -eq 1 ]; then
			make -j"$threads" install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/libvpx
        else
			make -j"$threads" install &>> "$DIRECTORY"/logs/libvpx
        fi
    else 
        printf $RED"something went wrong making libvpx 64bits\n"$NC
        exit 1
    fi
    
    cd ../libvpx-build32
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH=/usr/lib/pkgconfig LDFLAGS="-L/usr/lib" i386 ../configure --prefix=/usr \
    --libdir=/usr/lib\
    --target=x86-linux-gcc \
    --disable-install-bins \
    --disable-install-docs \
    --disable-install-srcs \
    --enable-pic \
    --enable-postproc \
    --enable-runtime-cpu-detect \
    --enable-shared \
    --enable-vp8 \
    --enable-vp9 \
    --enable-vp9-highbitdepth \
    --enable-vp9-temporal-denoising &>> "$DIRECTORY"/logs/libvpx
    i386 make -j"$threads" &>> "$DIRECTORY"/logs/libvpx
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			i386 make -j"$threads" install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/libvpx
        else
			i386 make -j"$threads" install &>> "$DIRECTORY"/logs/libvpx
        fi
    else
        printf $RED"something went wrong making libvpx 32bits\n"$NC
        exit 1
    fi
    make -j"$threads" clean &>> /dev/null
    
    cd ../../libpsl
    sed -i 's/env python/&3/' src/psl-make-dafsa &&
    mkdir build64
    mkdir build32
    ./autogen.sh &> "$DIRECTORY"/logs/libpsl
    cd ./build64
    
    ../configure --prefix=/usr --libdir=/usr/lib64 --disable-static &>> "$DIRECTORY"/logs/libpsl
    make -j"$threads" &>> "$DIRECTORY"/logs/libpsl
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			make -j"$threads" install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/libpsl
        else
			make -j"$threads" install &>> "$DIRECTORY"/logs/libpsl
        fi
    else
        printf $RED"something went wrong making libpsl 64bits\n"$NC
        exit 1
    fi
    
    
    cd ../build32
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH=/usr/lib/pkgconfig LDFLAGS="-L/usr/lib" i386  ../configure --prefix=/usr --bindir=/usr/bin/32 --libdir=/usr/lib --disable-static &>> "$DIRECTORY"/logs/libpsl
    i386 make -j"$threads" &>> "$DIRECTORY"/logs/libpsl
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			i386 make -j"$threads" install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/libpsl
        else
			i386 make -j"$threads" install &>> "$DIRECTORY"/logs/libpsl
        fi
    else
        printf $RED"something went wrong making libpsl 32bits\n"$NC
        exit 1
    fi
    
    cd ../../libsoup-2.70.0 
    mkdir build64
    mkdir build32
    cd    ./build64

    meson --prefix=/usr --libdir=/usr/lib64 -Dvapi=enabled -Dgssapi=disabled .. &> "$DIRECTORY"/logs/libsoup-2.70.0 &> "$DIRECTORY"/logs/libsoup-2.70.0
    ninja -j "$threads" &>> "$DIRECTORY"/logs/libsoup-2.70.0
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			DESTDIR="$DEST" ninja -j "$threads" install &>> "$DIRECTORY"/logs/libsoup-2.70.0
        else
			ninja -j "$threads" install &>> "$DIRECTORY"/logs/libsoup-2.70.0
        fi
    else
        printf $RED"something went wrong making lbsoup 64bits\n"$NC
        exit 1
    fi
    cd    ../build32

    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' meson --prefix=/usr \
    --libdir=/usr/lib \
    --bindir=/usr/bin/32 \
    -Dtls_check=false \
    -Dvapi=enabled \
    -Dgssapi=disabled .. &>> "$DIRECTORY"/logs/libsoup-2.70.0
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja -j "$threads" &>> "$DIRECTORY"/logs/libsoup-2.70.0
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' DESTDIR="$DEST" ninja -j "$threads" install &>> "$DIRECTORY"/logs/libsoup-2.70.0
        else
			CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja -j "$threads" install &>> "$DIRECTORY"/logs/libsoup-2.70.0
        fi
        
    else
        printf $RED"something went wrong making libsoup 32bits\n"$NC
        exit 1
    fi



}

build_gstreamer(){
    cd "$DIRECTORY"/wine_prepare
    cd ./gstreamer
    mkdir build32
    mkdir build64
    #### 32b
    cd    ./build32
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' meson  --prefix=/usr      \
        --libdir=/usr/lib \
        --bindir=/usr/bin/32 \
        -Dbuildtype=release \
        -Dgst_debug=false   \
        -Dgtk_doc=disabled  \
        -Dpackage-origin="git://github.com/GStreamer/gstreamer" \
        -Dpackage-name="GStreamer (Frankenpup Linux)" &> "$DIRECTORY"/logs/gstreamer
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja -j "$threads" &>> "$DIRECTORY"/logs/gstreamer
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' DESTDIR="$DEST" ninja -j "$threads" install &>> "$DIRECTORY"/logs/gstreamer
        else
			rm -rf /usr/bin32/gst-* /usr/lib/gstreamer-1.0 &>> "$DIRECTORY"/logs/gstreamer
			CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja install &>> "$DIRECTORY"/logs/gstreamer
        fi
    else
        printf $RED"something went wrong making gstreamer 32bits\n"$NC
        exit 1
    fi

    
    #### 64b
    cd ../build64 
    meson  --prefix=/usr       \
        --libdir=/usr/lib64 \
        -Dbuildtype=release \
        -Dgst_debug=false   \
        -Dgtk_doc=disabled  \
        -Dpackage-origin="http://github.com/GStreamer/gstreamer" \
        -Dpackage-name="GStreamer (Frankenpup Linux)" &>> "$DIRECTORY"/logs/gstreamer
    ninja -j "$threads" &>> "$DIRECTORY"/logs/gstreamer
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			DESTDIR="$DEST" ninja -j "$threads" install &>> "$DIRECTORY"/logs/gstreamer
        else
			rm -rf /usr/bin/gst-* /usr/{lib64,libexec}/gstreamer-1.0 &>> "$DIRECTORY"/logs/gstreamer
			ninja -j "$threads" install &>> "$DIRECTORY"/logs/gstreamer
        fi
    else
        printf $RED"something went wrong making gstreamer 64bits\n"$NC
        exit 1
    fi
    cd ../../gst-plugins-base
    
    mkdir build32
    mkdir build64
    #### 32b
    cd    ./build32
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' meson  --prefix=/usr       \
    --libdir=/usr/lib \
    --bindir=/usr/bin/32 \
    -Dbuildtype=release \
    -Dgtk_doc=disabled  \
    -Dpackage-origin="http://github.com/GStreamer/gst-plugins-base" \
    -Dpackage-name="GStreamer (Frankenpup Linux)"  &> "$DIRECTORY"/logs/gst-plugins-base
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja -j "$threads" &>> "$DIRECTORY"/logs/gst-plugins-base
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' DESTDIR="$DEST" ninja -j "$threads" install &>> "$DIRECTORY"/logs/gst-plugins-base
        else
			CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja -j "$threads" install &>> "$DIRECTORY"/logs/gst-plugins-base
        fi
    else
        printf $RED"something went wrong making gst-plugins-base 32bits\n"$NC
        exit 1
    fi
    
    #### 64b
    cd ../build64
    meson  --prefix=/usr       \
    --libdir=/usr/lib64 \
    --bindir=/usr/bin \
    -Dbuildtype=release \
    -Dgtk_doc=disabled  \
    -Dpackage-origin="http://github.com/GStreamer/gst-plugins-base" \
    -Dpackage-name="GStreamer (Frankenpup Linux)"  &>> "$DIRECTORY"/logs/gst-plugins-base
    ninja &>> "$DIRECTORY"/logs/gst-plugins-base
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			DESTDIR="$DEST" ninja -j "$threads" install &>> "$DIRECTORY"/logs/gst-plugins-base
        else
			ninja install  &>> "$DIRECTORY"/logs/gst-plugins-base
        fi
    else
        printf $RED"something went wrong making gst-plugins-base 64bits\n"$NC
        exit 1
    fi
    cd ../../gst-plugins-good
    
    mkdir build32
    mkdir build64
    #### 32b
    cd    ./build32
    p_nq=$(echo $PATH | sed 's+/opt/qt5/bin:++g')
    ldlp_nq=$(echo $LD_LIBRARY_PATH | sed 's+opt/qt5/lib:++g')
    PATH=$p_nq LD_LIBRARY_PATH=$ldlp_nq CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' meson  --prefix=/usr       \
    --libdir=/usr/lib \
    --bindir=/usr/bin/32 \
    -Dbuildtype=release \
    -Dqt5=disabled \
    -Dgtk_doc=disabled  \
    -Dpackage-origin="http://github.com/GStreamer/gst-plugins-good" \
    -Dpackage-name="GStreamer (Frankenpup Linux)"  &> "$DIRECTORY"/logs/gst-plugins-good 
    PATH=$p_nq LD_LIBRARY_PATH=$ldlp_nq CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja -j "$threads" &>> "$DIRECTORY"/logs/gst-plugins-good
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			PATH=$p_nq LD_LIBRARY_PATH=$ldlp_nq CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' DESTDIR="$DEST" ninja -j "$threads" install &>> "$DIRECTORY"/logs/gst-plugins-good
        else
			PATH=$p_nq LD_LIBRARY_PATH=$ldlp_nq CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja -j "$threads" install &>> "$DIRECTORY"/logs/gst-plugins-good
        fi
    else
        printf $RED"something went wrong making gst-plugins-good 32bits\n"$NC
        exit 1
    fi
    
    
    #### 64b
    cd ../build64
    meson  --prefix=/usr       \
    --libdir=/usr/lib64 \
    --bindir=/usr/bin \
    -Dbuildtype=release \
    -Dgtk_doc=disabled  \
    -Dpackage-origin="http://github.com/GStreamer/gst-plugins-good" \
    -Dpackage-name="GStreamer (Frankenpup Linux)" &>> "$DIRECTORY"/logs/gst-plugins-good
    ninja -j "$threads" &>> "$DIRECTORY"/logs/gst-plugins-good
    if [ $? -eq 0 ]; then
        
        if [ $DST -eq 1 ]; then
			DESTDIR="$DEST" ninja -j "$threads" install &>> "$DIRECTORY"/logs/gst-plugins-good
        else
			ninja -j "$threads" install &>> "$DIRECTORY"/logs/gst-plugins-good
        fi
    else
        printf $RED"something went wrong making gst-plugins-good 64bits\n"$NC
        exit 1
    fi
}

build_wine(){
    cd "$DIRECTORY"/wine_prepare
    mkdir build32
    mkdir build64
     #### 64b
     
	if [ $GST -eq 0 ];then
		END_ARG="--enable-win64"
	else
		END_ARG="--enable-win64 \
		--with-gstreamer" 
	fi
	
    cd ./build64
    ../configure \
        --prefix=/usr \
        --libdir=/usr/lib64 \
        --with-x \
        --with-vkd3d \
        $END_ARG &> "$DIRECTORY"/logs/wine
    make -j"$threads" &>> "$DIRECTORY"/logs/wine
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			make -j"$threads" install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/wine
        else
			make -j"$threads" install &>> "$DIRECTORY"/logs/wine
        fi
    else
        printf $RED"something went wrong making wine 64bits\n"$NC
        exit 1
    fi
    #### 32b

	if [ $GST -eq 0 ];then
		END_ARG="--with-wine64=$DIRECTORY/wine_prepare/build64"
	else
		END_ARG="--with-wine64="$DIRECTORY/wine_prepare/build64" \
		--with-gstreamer "
	fi
    cd ../build32
    PKG_CONFIG_PATH="/usr/lib/pkgconfig" ../configure \
        --prefix=/usr \
        --with-x \
        --with-vkd3d \
        --libdir=/usr/lib \
        $END_ARG &>> "$DIRECTORY"/logs/wine
    make -j"$threads" &>> "$DIRECTORY"/logs/wine
    if [ $? -eq 0 ]; then
        if [ $DST -eq 1 ]; then
			make -j"$threads" install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/wine
        else
			make -j"$threads" install &>> "$DIRECTORY"/logs/wine
        fi
    else
        printf $RED"something went wrong making wine 32bits\n"$NC
        exit 1
    fi
}

dxvk(){
    cd "$DIRECTORY"
    wget https://github.com/doitsujin/dxvk/releases/download/v1.6/dxvk-1.6.tar.gz
    tar xf dxvk-1.6.tar.gz
    dxvk-1.6/setup_dxvk.sh install
}

printf $GREEN"HELLO THERE!\n"
printf "THIS SMALL SCRIPT WILL BUILD VULKAN, WINE AND VKD3D (AND GAME RELATED PATCHES)\n"$NC
printf "\n"$NC
if [ $THRD -eq 1 ] || [ $DST -eq 1 ] || [ $REPOFLAG -eq 1 ] || [ $PTCHSTP -eq 1 ] || [ $NBGST -eq 1 ] || [ $GST -eq 0 ];then
	printf $YELLOW"Options:\n"$NC
fi
if [ $THRD -eq 1 ];then
	printf $YELLOW"Using "$threads" threads\n"$NC
fi
if [ $DST -eq 1 ];then
	printf $YELLOW"Using $DEST as target folder\n"$NC
fi
if [ $REPOFLAG -eq 1 ];then
	printf $YELLOW"Stopping at repos\n"$NC
fi
if [ $PTCHSTP -eq 1 ];then
	printf $YELLOW"Stopping at pathces\n"$NC
fi
if [ $NBGST -eq 1 ];then
	printf $YELLOW"Not building gstreamer and deps\n"$NC
fi
if [ $GST -eq 0 ];then
	printf $YELLOW"Gstreamer support disabled\n"$NC
fi

read -p 'is this ok? (Y/N)' uservar
if [ $uservar == "n" ] || [ $uservar == "N" ];then
	printf $RED"Stoppnig\n"$NC
	exit 1
elif [ $uservar == "y" ] || [ $uservar == "Y" ];then
	printf $GREEN"Continuing\n"$NC
else
	printf $YELLOW"Please answer y or n\n"$NC
	printf $RED"Stoppnig\n"$NC
	exit 1
fi

printf "\n"$NC

printf $YELLOW"cleanup\n"$NC
cleanup

printf $GREEN"cloning repos\n"$NC
process_repos
if [ $REPOFLAG -eq 1 ];then
    exit 1
fi

printf $YELLOW"preparing folders...\n"$NC
prepare

printf $YELLOW"applying patches to wine source...\n"$NC
patches
if [ $PTCHSTP -eq 1 ];then
    exit 1
fi

printf $YELLOW"building headers\n"$NC
build_headers

printf $GREEN"building SPIRV-Tools (32 and 64 bits)\n"$NC
build_sprv_tools

printf $GREEN"building and installing vulkan (32 and 64 bits)\n"$NC
build_vulkan

printf $GREEN"building and installing vkd3d (32 and 64 bits)\n"$NC
build_vkd3d

if [ $NBGST -eq 0 ] || [ $GST -eq 1 ];then
    printf $GREEN"building and installing gstreamer deps (32 and 64 bits)\n"$NC
    build_gstreamer_deps
    printf $GREEN"building and installing gstreamer (32 and 64 bits)\n"$NC
    build_gstreamer
else
    printf $RED"Skipping gstreamer (32 and 64 bits)\n"$NC
fi

printf $GREEN"building and installing wine (32 and 64 bits)\n"$NC
build_wine

if [ $DST -eq 1 ];then
	printf $RED"Using target folder skipping dxvk\n"$NC
else
	printf $GREEN"installnig dxvk\n"$NC
	dxvk
fi


printf $YELLOW"cleanup\n"$NC
cleanup
