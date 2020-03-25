#!/bin/sh
## build wine with vkd3d + deps
##########################################################################################
# By Diego Cardenas "The Samedog" under GNU GENERAL PUBLIC LICENSE Version 2, June 1991
# (www.gnu.org/licenses/old-licenses/gpl-2.0.html) e-mail: the.samedog[]gmail.com.
# https://github.com/samedog/wine-builder
##########################################################################################
#
# 24-03-2020:   - first release
#               - wine-tkg-git not needed sice GE already has the patches
# 25-03-2020    - fixed dxvk multilib compiling
#               - added gstramer, gst-plugins-base and gst-plugins-good
#               - $DIRECTORY used to ensure current location instead of relynig
#                 on "cd .." chains
##########################################################################################



DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DIRECTORY="$(echo $DIRECTORY | sed 's/ /\\ /g')"
threads=$(grep -c processor /proc/cpuinfo)
dxvk_version="https://github.com/doitsujin/dxvk/releases/download/v1.6/dxvk-1.6.tar.gz"
process_repos() {

    if [ ! -d "Vulkan-Loader" ];then
        git clone git://github.com/KhronosGroup/Vulkan-Loader
    else
        cd ./Vulkan-Loader
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
    cd ..

    ./game-patches-testing/protonprep.sh
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
    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make -j"$threads"
    make install
    ##
    cd ../../Vulkan-Headers
    mkdir build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make -j"$threads"
    make install
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
    make install
    
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
    make install
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
        -DCMAKE_C_FLAGS="-m32" ..
    make -j"$threads"
    make install

    #### 64b
    cd ../build64
    cmake -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib64 ..
    make -j"$threads"
    make install
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
    make install

    #### 64b
    cd ../build64
    ../configure --prefix=/usr --libdir=/usr/lib64 --with-spirv-tools
    make -j"$threads"
    make install
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
        --bindir=/usr/bin32 \
        -Dbuildtype=release \
        -Dgst_debug=false   \
        -Dgtk_doc=disabled  \
        -Dpackage-origin="git://github.com/GStreamer/gstreamer" \
        -Dpackage-name="GStreamer (Frankenpup Linux)"  ..
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja
    rm -rf /usr/bin/gst-* /usr/lib/gstreamer-1.0
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja install
    
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
    rm -rf /usr/bin/gst-* /usr/{lib64,libexec}/gstreamer-1.0
    ninja install
    
    cd ../../gst-plugins-base
    
    mkdir build32
    mkdir build64
    #### 32b
    cd    ./build32
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' meson  --prefix=/usr       \
    --libdir=/usr/lib \
    --bindir=/usr/bin32 \
    -Dbuildtype=release \
    -Dgtk_doc=disabled  \
    -Dpackage-origin="http://github.com/GStreamer/gst-plugins-base" \
    -Dpackage-name="GStreamer (Frankenpup Linux)" 

    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja install
    
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
    ninja install
    
    cd ../../gst-plugins-good
    
    mkdir build32
    mkdir build64
    #### 32b
    cd    ./build32
   CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' meson  --prefix=/usr       \
    --libdir=/usr/lib \
    --bindir=/usr/bin32 \
    -Dbuildtype=release \
    -Dgtk_doc=disabled  \
    -Dpackage-origin="http://github.com/GStreamer/gst-good" \
    -Dpackage-name="GStreamer (Frankenpup Linux)" 

    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja
    CC='gcc -m32' CXX='g++ -m32' PKG_CONFIG_PATH='/usr/lib/pkgconfig' ninja install
    
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
    ninja install
}

build_wine(){
    cd "$DIRECTORY"/wine_prepare
    mkdir build32
    mkdir build64
     #### 64b
    cd ./build64
    ../configure \
        --prefix=/usr \
        --libdir=/usr/lib64 \
        --with-x \
        --with-vkd3d \
        --with-gstreamer \
        --enable-win64
    make -j"$threads"
    make -j"$threads" install
    
    #### 32b
    cd ../build32
    ../configure \
        --prefix=/usr \
        --with-x \
        --with-vkd3d \
        --libdir=/usr/lib \
        --with-gstreamer \
        --with-wine64="$DIRECTORY/wine_prepare/build64"
    make -j"$threads"
    make -j"$threads" install
      

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

echo "building and installing gstreamer (32 and 64 bits)"
build_gstreamer

echo "building and installing wine (32 and 64 bits)"
build_wine

echo "installnig dxvk"
dxvk
