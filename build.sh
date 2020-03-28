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
##########################################################################################
RED='\033[0;31m'
NC='\033[0m' # No Color
ARGS="$@"
REPOFLAG=0
NBGST=0

GST=1

for ARG in $ARGS
    do
        if [ $ARG == "--only-repos" ];then
            REPOFLAG=1
        fi
        if [ $ARG == "--h" ] || [ $ARG == "--help" ] || [ $ARG == "-h" ];then
            echo "
supported flags:
--only-repos            : Only pull git repos and download tar packages.
--no-build-gstreamer    : Don't build gstreamer, meant for proper distros
                          with package managers.
--without-gstreamer     : Disable gstreamer support entirely.
--h --help -h           : Show this help and exit.
"
            exit 1
        fi
        if [ $ARG == "--no-build-gstreamer" ];then
            NBGST=1
        fi
        if [ $ARG == "--without-gstreamer" ];then
            NBGST=1
            GST=0
        fi
    done

DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DIRECTORY="$(echo $DIRECTORY | sed 's/ /\\ /g')"
threads=threads=threads=$(grep -c processor /proc/cpuinfo)
dxvk_version="https://github.com/doitsujin/dxvk/releases/download/v1.6/dxvk-1.6.tar.gz"
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
        git clone git://github.com/doitsujin/vkd3d
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
    else
        cd ./wine
        git clean -fxd
        git pull --force
        git reset --hard HEAD
        cd ..
    fi
    
    
    if [ ! -d "proton-ge-custom" ];then
        mkdir ./proton-ge-custom
        cd ./proton-ge-custom
        git init
        git remote add -f origin git://github.com/GloriousEggroll/proton-ge-custom
        git config core.sparseCheckout true
        echo "game-patches-testing/" >> .git/info/sparse-checkout
        git pull origin proton-ge-5
        cd ..
    else
        cd ./proton-ge-custom/
        git reset --hard HEAD
    git clean -xdf
        echo "game-patches-testing/" >> .git/info/sparse-checkout
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
    cp -rf ./proton-ge-custom/game-patches-testing/ ./wine_prepare/game-patches-testing
    cp -rf ./vkd3d ./wine_prepare/vkd3d
    cp -rf ./SPIRV-Headers ./wine_prepare/SPIRV-Headers
    cp -rf ./SPIRV-Tools ./wine_prepare/SPIRV-Tools
    cp -rf ./Vulkan-Headers ./wine_prepare/Vulkan-Headers
    cp -rf ./Vulkan-Loader ./wine_prepare/Vulkan-Loader
}

patches() {
    cd "$DIRECTORY"/wine_prepare
    cd ./game-patches-testing
    ###WE REMOVE A LOT OF UNUSED {BY THS BULDER} STUFF
    sed -i 's/cd \.\.//g' protonprep.sh
    sed -i 's/cd dxvk//g' protonprep.sh
    sed -i 's/cd vkd3d//g' protonprep.sh
    sed -i 's/cd wine//g' protonprep.sh
    sed -i 's/git checkout lsteamclient//g' protonprep.sh
    sed -i 's/cd lsteamclient//g' protonprep.sh
    sed -i 's+patch -Np1 < ../game-patches-testing/proton-hotfixes/steamclient-disable_SteamController007_if_no_controller.patch++g' protonprep.sh
    sed -i 's/git clean -xdf//g' protonprep.sh
    sed -i 's+patch -Np1 < \.\./game-patches-testing/dxvk-patches/valve-dxvk-avoid-spamming-log-with-requests-for-IWineD3D11Texture2D.patch++g' protonprep.sh
    sed -i 's+patch -Np1 < \.\./game-patches-testing/dxvk-patches/proton-add_new_dxvk_config_library.patch++g' protonprep.sh
    sed -i 's+\.\./wine-staging/patches/patchinstall.sh+wine-staging/patches/patchinstall.sh+g' protonprep.sh
    sed -i 's+patch -Np1 < \.\./+patch -Np1 < +g' protonprep.sh
    sed -i 's/git reset --hard HEAD//g' protonprep.sh
    sed -i 's/git clean -xdf//g' protonprep.sh
    sed -i '39d' protonprep.sh
    
    sed -i 's*dlls/mfreadwrite/main.c | 5 +++--*dlls/mfreadwrite/reader.c | 5 +++--*g' proton-valve-patches/proton-protonify_staging.patch
    sed -i 's*diff --git a/dlls/mfreadwrite/main.c b/dlls/mfreadwrite/main.c*diff --git a/dlls/mfreadwrite/reader.c b/dlls/mfreadwrite/read.c*g' proton-valve-patches/proton-protonify_staging.patch
    sed -i 's*--- a/dlls/mfreadwrite/main.c*--- a/dlls/mfreadwrite/reader.c*g' proton-valve-patches/proton-protonify_staging.patch
    sed -i 's*+++ b/dlls/mfreadwrite/main.c*+++ b/dlls/mfreadwrite/reader.c*g' proton-valve-patches/proton-protonify_staging.patch
    cd ..

    ./game-patches-testing/protonprep.sh
    ## revert the steamuser patch
    patch -Np1 < ./custom-patches/revert.patch
    ## revert the Never create links patch
    patch -Np1 < ./custom-patches/revert2.patch
    ## winevulkan patches
    #patch -Np1 < ./custom-patches/winevulkan.patch
    ## more winevulkan pathces
    #patch -Np1 < ./custom-patches/winevulkan2.patch
    #####
}



build_headers() {
    ##
    cd "$DIRECTORY"/wine_prepare
    cd ./SPIRV-Headers
    mkdir build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make -j"$threads"
    if [ $? -eq 0 ]; then
        make install
    else
        echo "something went wrong making SPIRV-Headers"
        exit 1
    fi
    ##
    cd ../../Vulkan-Headers
    mkdir build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make -j"$threads"
    if [ $? -eq 0 ]; then
        make install
    else
        echo "something went wrong making Vulkan-Headers 64bits"
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
    --libdir=/usr/lib
    make -j"$threads"
    if [ $? -eq 0 ]; then
        make -j"$threads" install
    else
        echo "something went wrong making libdv 32bits"
        exit 1
    fi
    make -j"$threads" clean
    
    ./configure --prefix=/usr \
    --disable-xv \
    --bindir=/usr/bin \
    --disable-static \
    --libdir=/usr/lib64
    make -j"$threads"
    if [ $? -eq 0 ]; then
        make -j"$threads" install
    else
        echo "something went wrong making libdv 64bits"
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
    --enable-vp9-temporal-denoising
    make -j"$threads"
    if [ $? -eq 0 ]; then
        make install
    else
        printf $RED"something went wrong making libvpx 64bits"$NC
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
    --enable-vp9-temporal-denoising
    i386 make -j"$threads"
    if [ $? -eq 0 ]; then
        i386 make -j"$threads" install
    else
        printf $RED"something went wrong making libvpx 32bits"$NC
        exit 1
    fi
    make -j"$threads" clean
    
    cd ../../libpsl
    sed -i 's/env python/&3/' src/psl-make-dafsa &&
    mkdir build64
    mkdir build32
    ./autogen.sh
    cd ./build64
    
    ../configure --prefix=/usr --libdir=/usr/lib64 --disable-static
    make -j"$threads"
    if [ $? -eq 0 ]; then
        make install
    else
        printf $RED"something went wrong making libpsl 64bits"$NC
        exit 1
    fi
    
    
    cd ../build32
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH=/usr/lib/pkgconfig LDFLAGS="-L/usr/lib" i386  ../configure --prefix=/usr --bindir=/usr/bin/32 --libdir=/usr/lib --disable-static
    make -j"$threads"
    if [ $? -eq 0 ]; then
        make install
    else
        printf $RED"something went wrong making libpsl 32bits"$NC
        exit 1
    fi
    
    cd ../../libsoup-2.70.0 
    mkdir build64
    mkdir build32
    cd    ./build64

    meson --prefix=/usr --libdir=/usr/lib64 -Dvapi=enabled -Dgssapi=disabled ..
    ninja
    if [ $? -eq 0 ]; then
        rm -rf /usr/bin/gst-* /usr/{lib64,libexec}/gstreamer-1.0
        ninja install
    else
        printf $RED"something went wrong making lbsoup 64bits"$NC
        exit 1
    fi
    cd    ../build32

    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' meson --prefix=/usr \
    --libdir=/usr/lib \
    --bindir=/usr/bin/32 \
    -Dtls_check=false \
    -Dvapi=enabled \
    -Dgssapi=disabled ..
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja
    if [ $? -eq 0 ]; then
        CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja install
    else
        printf $RED"something went wrong making libsoup 32bits"$NC
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
        -DCMAKE_BUILD_TYPE=Release \
        -DSPIRV_WERROR=Off \
        -DBUILD_SHARED_LIBS=ON \
        -DSPIRV-Headers_SOURCE_DIR=$DIRECTORY/wine_prepare/SPIRV-Headers ..
    make -j"$threads"
    if [ $? -eq 0 ]; then
        make install
    else
        printf $RED"something went wrong making SPIRV-Tools 32bits"$NC
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
        -DSPIRV-Headers_SOURCE_DIR=$DIRECTORY/wine_prepare/SPIRV-Headers ..
    make -j"$threads"
    if [ $? -eq 0 ]; then
        make install
    else
        printf $RED"something went wrong making SPIRV-Tools 64bits"$NC
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
        -DVULKAN_HEADERS_INSTALL_DIR=/usr ..
    make -j"$threads"
    if [ $? -eq 0 ]; then
        make install
    else
        printf $RED"something went wrong making Vulkan-Loader 32bits"$NC
        exit 1
    fi
    #### 64b
    cd ../build64
    cmake -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib64 \
        -DVULKAN_HEADERS_INSTALL_DIR=/usr ..
    make -j"$threads"
    if [ $? -eq 0 ]; then
        make install
    else
        printf $RED"something went wrong making Vulkan-Loader 63bits"$NC
        exit 1
    fi
}

build_vkd3d(){
    cd "$DIRECTORY"/wine_prepare
    cd ./vkd3d
    ./autogen.sh
    mkdir build32
    mkdir build64
    
    #### 32b
    cd build32
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH=/usr/lib/pkgconfig LDFLAGS="-L/usr/lib" ../configure --prefix=/usr --libdir=/usr/lib --with-spirv-tools
    make -j"$threads"
    if [ $? -eq 0 ]; then
        make install
    else
        printf $RED"something went wrong making vkd3d 32bits"$NC
        exit 1
    fi

    #### 64b
    cd ../build64
    ../configure --prefix=/usr --libdir=/usr/lib64 --with-spirv-tools
    make -j"$threads"
    if [ $? -eq 0 ]; then
        make install
    else
        printf $RED"something went wrong making vkd3d 64bits"$NC
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
        -Dpackage-name="GStreamer (Frankenpup Linux)"
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja
    if [ $? -eq 0 ]; then
        rm -rf /usr/bin/gst-* /usr/lib/gstreamer-1.0
        CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja install
    else
        printf $RED"something went wrong making gstreamer 32bits"$NC
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
        -Dpackage-name="GStreamer (Frankenpup Linux)"
    ninja
    
    if [ $? -eq 0 ]; then
        rm -rf /usr/bin/gst-* /usr/{lib64,libexec}/gstreamer-1.0
        ninja install
    else
        printf $RED"something went wrong making gstreamer 64bits"$NC
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
    -Dpackage-name="GStreamer (Frankenpup Linux)" 

    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja
    if [ $? -eq 0 ]; then
        CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja install
    else
        printf $RED"something went wrong making gst-plugins-base 32bits"$NC
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
    -Dpackage-name="GStreamer (Frankenpup Linux)" 
    ninja
    if [ $? -eq 0 ]; then
        rm -rf /usr/bin/gst-* /usr/{lib64,libexec}/gstreamer-1.0
        ninja install
    else
        printf $RED"something went wrong making gst-plugins-base 64bits"$NC
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
    -Dpackage-name="GStreamer (Frankenpup Linux)" 
    PATH=$p_nq LD_LIBRARY_PATH=$ldlp_nq CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja
    if [ $? -eq 0 ]; then
       PATH=$p_nq LD_LIBRARY_PATH=$ldlp_nq CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja install
    else
        printf $RED"something went wrong making gst-plugins-good 32bits"$NC
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
    -Dpackage-name="GStreamer (Frankenpup Linux)" &&
    ninja
    if [ $? -eq 0 ]; then
        rm -rf /usr/bin/gst-* /usr/{lib64,libexec}/gstreamer-1.0
        ninja install
    else
        printf $RED"something went wrong making gst-plugins-good 64bits"$NC
        exit 1
    fi
}

build_wine(){
    cd "$DIRECTORY"/wine_prepare
    mkdir build32
    mkdir build64
     #### 64b
     
	 if [[ $NBGST -eq 0 || $GST -eq 1 ]];then
		END_ARG="--enable-win64 \
		--with-gstreamer" 
	else
		END_ARG="--enable-win64"
	fi
	
    cd ./build64
    ../configure \
        --prefix=/usr \
        --libdir=/usr/lib64 \
        --with-x \
        --with-vkd3d \
        $END_ARG
        

        
    make -j"$threads"
    if [ $? -eq 0 ]; then
        make -j"$threads" install
    else
        printf $RED"something went wrong making wine 64bits"$NC
        exit 1
    fi
    
    #### 32b
    
	if [[ $NBGST -eq 0 || $GST -eq 1 ]];then
		END_ARG="--with-wine64="$DIRECTORY/wine_prepare/build64" \
		--with-gstreamer "
	else
		END_ARG="--with-wine64=$DIRECTORY/wine_prepare/build64"
	fi
    cd ../build32
    PKG_CONFIG_PATH="/usr/lib/pkgconfig" ../configure \
        --prefix=/usr \
        --with-x \
        --with-vkd3d \
        --libdir=/usr/lib \
        $END_ARG

        
    make -j"$threads"
    if [ $? -eq 0 ]; then
        make -j"$threads" install
    else
        printf $RED"something went wrong making wine 32bits"$NC
        exit 1
    fi
      

}

cleanup(){
    cd "$DIRECTORY"
    if [ -d "wine_prepare" ];then
        rm -rf ./wine_prepare
    fi
    
}

dxvk(){
    cd "$DIRECTORY"
    wget https://github.com/doitsujin/dxvk/releases/download/v1.6/dxvk-1.6.tar.gz
    tar xf dxvk-1.6.tar.gz
    dxvk-1.6/setup_dxvk.sh install
}

echo "HELLO THERE!"
echo "THIS SMALL SCRIPT WILL BUILD VULKAN, WINE AND VKD3D (AND GAME RELATED PATCHES)"

echo "cleanup"
cleanup

echo "cloning repos"
process_repos
if [ $REPOFLAG -eq 1 ];then
    exit 1
fi

echo "preparing folders..."
prepare

echo "applying patchs to wine source..."
patches

echo "building headers"
build_headers

echo "building SPIRV-Tools (32 and 64 bits)"
build_sprv_tools

echo "building and installing vulkan (32 and 64 bits)"
build_vulkan

echo "building and installing vkd3d (32 and 64 bits)"
build_vkd3d

if [[ $NBGST -eq 0 || $GST -eq 1 ]];then
    echo "building and installing gstreamer deps (32 and 64 bits)"
    build_gstreamer_deps
    echo "building and installing gstreamer (32 and 64 bits)"
    build_gstreamer
else
    echo "Skipping gstreamer (32 and 64 bits)"
fi

echo "building and installing wine (32 and 64 bits)"
build_wine

echo "installnig dxvk"
dxvk
