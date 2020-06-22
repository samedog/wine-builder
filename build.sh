#!/bin/bash
## build wine with vkd3d + deps
##########################################################################################
# By Diego Cardenas "The Samedog" under GNU GENERAL PUBLIC LICENSE Version 2, June 1991
# (www.gnu.org/licenses/old-licenses/gpl-2.0.html) e-mail: the.samedog[]gmail.com.
# https://github.com/samedog/wine-builder
##########################################################################################
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
# 13-05-2020    - Updates for wine commit 4f673d5386f44d4af4459a95b3059cfb887db8c9
# 19-05-2020    - Updates for wine-staging commit 029c249e789fd8b05d8c1eeda48deb8810bbb751
#               - Now the script will work on tested commits by default
#               - Added libusb to the wine deps due to current update requiring 
#                 newer functions
#               - Now the versioning will use wine-staging commit instead wine
# 21-05-2020    - OOPSIE WOOPSIE!! uwu I made a fucky wucky!! A wittle fucko boingo! 
# 21-26-2020    - Updated for wine-staging and wine 5.9
#               - Function cleanup and make/ninja moved to wrapper funcitons
##########################################################################################
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DIRECTORY="$(echo $DIRECTORY | sed 's/ /\\ /g')"
dxvk_version="https://github.com/doitsujin/dxvk/releases/download/v1.6.1/dxvk-1.6.1.tar.gz"
ARGS="$@"
REPOFLAG=0
NBGST=0
PTCHSTP=0
GST=1
DST=0
DEST=""
THRD=0
LUSB=1
threads=$(grep -c processor /proc/cpuinfo)
LWC=$(cat ./last_working_commit | grep -m1 "wine" | cut -d':' -f2)
LWSC=$(cat ./last_working_commit | grep "wine-staging" | cut -d':' -f2)
LWPGEC=$(cat ./last_working_commit | grep "proton-ge" | cut -d':' -f2)
for ARG in $ARGS
    do
        if [ $ARG == "--only-repos" ];then
            REPOFLAG=1
        elif [ $ARG == "--no-libusb" ];then
            LUSB=0
        elif [ $ARG == "--latest" ];then
            LWC="HEAD"
            LWSC="HEAD"
            LWPGEC="HEAD"
        elif [ $ARG == "--patch-stop" ];then
            PTCHSTP=1
        elif [[ $ARG == "--threads"* ]];then
            THRD=1
            threads=$(echo $ARG | cut -d'=' -f2)
        elif [ $ARG == "--no-build-gstreamer" ];then
            NBGST=1
        elif [ $ARG == "--without-gstreamer" ];then
            NBGST=1
            GST=0
        elif [[ $ARG == "--dest"* ]];then
            DST=1
            DEST=$(echo $ARG | cut -d'=' -f2)
        elif [[ $ARG == "--last-working"* ]];then
            LWC=$(cat "$DIRECTORY"/last_working_commit)
            echo $LWC
        elif [ $ARG == "--h" ] || [ $ARG == "--help" ] || [ $ARG == "-h" ];then
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
--last-working          : Use the last working commit (manually updated) 
--latest                : Overrides the safe last_working_commit file
--no-libusb             : Skip building libusb
"
            exit 1
        fi
    done



cleanup(){
    cd "$DIRECTORY"
    if [ -d "wine_prepare" ];then
        rm -rf ./wine_prepare
        sleep 1
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
        git clean -xdf
        git reset --hard HEAD
        git pull origin master
        cd ..
    fi
    
    if [ ! -d "libusb" ];then
        git clone git://github.com/libusb/libusb.git
    else
        cd ./libusb
        git clean -xdf
        git reset --hard HEAD
        git pull origin master
        cd ..
    fi
    
    if [ ! -d "libpsl" ];then
        git clone git://github.com/rockdaboot/libpsl
    else
        cd ./libpsl
        
        git clean -xdf
        git reset --hard HEAD
        git pull origin master
        cd ..
    fi
    
    if [ ! -d "libvpx" ];then
        git clone git://github.com/webmproject/libvpx.git
    else
        cd ./libvpx
        
        git clean -xdf
        git reset --hard HEAD
        git pull origin master
        cd ..
    fi
    
    if [ ! -d "SPIRV-Headers" ];then
        git clone git://github.com/KhronosGroup/SPIRV-Headers
    else
        cd ./SPIRV-Headers
        
        git clean -xdf
        git reset --hard HEAD
        git pull origin master
        cd ..
    fi
    
    if [ ! -d "SPIRV-Tools" ];then
        git clone https://github.com/KhronosGroup/SPIRV-Tools
    else
        cd ./SPIRV-Tools
        git clean -xdf
        git reset --hard HEAD
        git pull origin master
       cd ..
    fi
    
    if [ ! -d "Vulkan-Headers" ];then
        git clone git://github.com/KhronosGroup/Vulkan-Headers
    else
        cd ./Vulkan-Headers
        git clean -xdf
        git reset --hard HEAD
        git pull origin master
        cd ..
    fi

    if [ ! -d "vkd3d" ];then
        git clone git://github.com/HansKristian-Work/vkd3d
    else
        cd ./vkd3d
        git clean -xdf
        git reset --hard HEAD
        git pull origin master
        cd ..
    fi

    if [ ! -d "gstreamer" ];then
        git clone git://github.com/GStreamer/gstreamer
    else
        cd ./gstreamer
        
        git clean -fxd
        git reset --hard HEAD
        git pull origin master
        cd ..
    fi
    
    if [ ! -d "gst-plugins-base" ];then
        git clone git://github.com/GStreamer/gst-plugins-base
    else
        cd ./gst-plugins-base
        git clean -fxd
        git reset --hard HEAD
        git pull origin master
        cd ..
    fi
    
    if [ ! -d "gst-plugins-good" ];then
        git clone git://github.com/GStreamer/gst-plugins-good
    else
        cd ./gst-plugins-good
        git clean -fxd
        git reset --hard HEAD
        git pull origin master
        
        cd ..
    fi
    
    if [ ! -d "wine-staging" ];then
        git clone https://github.com/wine-staging/wine-staging
        cd ./wine-staging
        git clean -xdf
        if [ $LWSC == "HEAD" ];then
            git reset --hard HEAD
            git pull origin master
        else
            git reset --hard $LWSC
            git pull origin $LWSC
        fi
        cd ..
        WCWS=$(./wine-staging/patches/patchinstall.sh --upstream-commit)
    else
        cd ./wine-staging
        git clean -xdf
        if [ $LWSC == "HEAD" ];then
			git clean -fxd
            git reset --hard HEAD
            git pull origin master
        else
			git clean -fxd
            git reset --hard $LWSC
            git pull origin $LWSC
        fi
        cd ..
        WCWS=$(./wine-staging/patches/patchinstall.sh --upstream-commit)
    fi

    if [ ! -d "wine" ];then
        git clone git://source.winehq.org/git/wine.git
        cd ./wine
        git clean -fxd
        git reset --hard $WCWS
        git pull origin $WCWS
        cd ..
    else
        cd ./wine
        git clean -fxd
        git reset --hard $WCWS
        git pull origin $WCWS
        cd ..
    fi
    
    if [ ! -d "proton-ge-custom" ];then
        mkdir ./proton-ge-custom
        cd ./proton-ge-custom
        git init
        git remote add -f origin git://github.com/GloriousEggroll/proton-ge-custom
        git config core.sparseCheckout true
        echo "patches/" > .git/info/sparse-checkout
        if [ $LWPGEC == "HEAD" ];then
            git reset --hard $LWPGEC
            git pull origin proton-ge-5-MF
        else
			git reset --hard $LWPGEC
			git pull origin $LWPGEC
        fi
        cd ..
    else
        cd ./proton-ge-custom/
        git clean -xdf
        echo "patches/" > .git/info/sparse-checkout
        if [ $LWPGEC == "HEAD" ];then
            git reset --hard $LWPGEC
            git pull origin proton-ge-5-MF
        else
			git reset --hard $LWPGEC
			git pull origin $LWPGEC
        fi
        cd ..
    fi
}

prepare(){
    cd "$DIRECTORY"
    cp -rf ./wine ./wine_prepare
    #mkdir ./wine_prepare
    cp -rf ./custom-patches ./wine_prepare/custom-patches
    cp -rf ./libdv-1.0.0 ./wine_prepare/libdv-1.0.0
    cp -rf ./libvpx ./wine_prepare/libvpx    
    cp -rf ./libusb ./wine_prepare/libusb    
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
    ###standard substitutions for unused patches and location or path
        sed -i 's/cd \.\./#cd \.\./g' protonprep.sh
        sed -i 's/cd dxvk/#cd dxvk/g' protonprep.sh
        sed -i 's/cd vkd3d/#cd vkd3d/g' protonprep.sh
        sed -i 's/cd glib/#cd glib/g' protonprep.sh
        sed -i 's/cd wine/#cd wine/g' protonprep.sh
        sed -i 's/git checkout lsteamclient/#git checkout lsteamclient/g' protonprep.sh
        sed -i 's/cd lsteamclient/#cd lsteamclient/g' protonprep.sh
        sed -i 's+patch -Np1 < \.\./patches/proton-hotfixes/steamclient-disable_SteamController007_if_no_controller.patch+#patch -Np1 < \.\./patches/proton-hotfixes/steamclient-disable_SteamController007_if_no_controller.patch+g' protonprep.sh
        sed -i 's/git clean -xdf/#git clean -xdf/g' protonprep.sh
        sed -i 's+patch -Np1 < \.\./patches/dxvk/valve-dxvk-avoid-spamming-log-with-requests-for-IWineD3D11Texture2D.patch+#patch -Np1 < \.\./patches/dxvk/valve-dxvk-avoid-spamming-log-with-requests-for-IWineD3D11Texture2D.patch+g' protonprep.sh
        sed -i 's+patch -Np1 < \.\./patches/dxvk/proton-add_new_dxvk_config_library.patch+#patch -Np1 < \.\./patches/dxvk/proton-add_new_dxvk_config_library.patch+g' protonprep.sh
        sed -i 's+\.\./wine-staging/patches/patchinstall.sh+wine-staging/patches/patchinstall.sh+g' protonprep.sh
        sed -i 's+patch -Np1 < \.\./+patch -Np1 < +g' protonprep.sh
        sed -i 's/git reset --hard HEAD/#git reset --hard HEAD/g' protonprep.sh
        sed -i 's/git clean -xdf/#git clean -xdf/g' protonprep.sh
        sed -i 's+for _f in ../+for _f in ./+g' protonprep.sh
        sed -i 's+patch -Np1 < patches/glib/glib_python3_hack.patch+#patch -Np1 < patches/glib/glib_python3_hack.patch+g' protonprep.sh
        sed -i 's+patch -Np1 -R < ../+patch -Np1 -R < +g' protonprep.sh
        sed -i 's/cd gst-plugins-ugly/#cd gst-plugins-ugly/g' protonprep.sh
        sed -i "s/echo \"add Guy's patch to fix wmv playback in gst-plugins-ugly\"/#echo \"add Guy's patch to fix wmv playback in gst-plugins-ugly\"/g" protonprep.sh
        sed -i 's+patch -Np1 < patches/gstreamer/+#patch -Np1 < patches/gstreamer/+g' protonprep.sh
        sed -i 's+git checkout vrclient_x64+#git checkout vrclient_x64+g' protonprep.sh
        sed -i 's+cd vrclient_x64+#cd vrclient_x64+g' protonprep.sh
        sed -i 's+patch -Np1 < patches/proton-hotfixes/vrclient-use_standard_dlopen_instead_of_the_libwine_wrappers.patch++g' protonprep.sh
        sed -i 's+echo "steamclient swap"+#echo "steamclient swap"+g' protonprep.sh
        sed -i 's+patch -Np1 < patches/dxvk/dxvk-async.patch+#patch -Np1 < patches/dxvk/dxvk-async.patch+g' protonprep.sh
        sed -i 's+patch -Np1 < patches/proton-hotfixes/steamclient-use_standard_dlopen_instead_of_the_libwine_wrappers.patch+#patch -Np1 < patches/proton-hotfixes/steamclient-use_standard_dlopen_instead_of_the_libwine_wrappers.patch+g' protonprep.sh
        sed -i "s+patch -Np1 < patches/wine-hotfixes/staging-44d1a45-localreverts.patch+cd $DIRECTORY/wine_prepare/wine-staging/ \n patch -Np1 < $DIRECTORY/wine_prepare/patches/wine-hotfixes/staging-44d1a45-localreverts.patch \n cd $DIRECTORY/wine_prepare+g" protonprep.sh  
        
    #cant revert
		#sed -i 's+git revert --no-commit fd6f50c0d3e96947846ca82ed0c9bd79fd8e5b80+#git revert --no-commit fd6f50c0d3e96947846ca82ed0c9bd79fd8e5b80+g' protonprep.sh
		sed -i 's+echo "5.10 backports"+#echo "5.10 backports"+g' protonprep.sh
		sed -i 's+patch -Np1 < patches/wine-hotfixes/ea9b507380b4415cf9edd3643d9bcea7ab934fbd.patch+#patch -Np1 < patches/wine-hotfixes/ea9b507380b4415cf9edd3643d9bcea7ab934fbd.patch+g' protonprep.sh
		sed -i 's+patch -Np1 < patches/wine-hotfixes/b4310a19e96283e114fad13f7565f912a39640de.patch+#patch -Np1 < patches/wine-hotfixes/b4310a19e96283e114fad13f7565f912a39640de.patch+g' protonprep.sh
		sed -i 's+patch -Np1 < patches/wine-hotfixes/25e9e91c3a4f6c1c134d96a5c11517178e31f111.patch+#patch -Np1 < patches/wine-hotfixes/25e9e91c3a4f6c1c134d96a5c11517178e31f111.patch+g' protonprep.sh
		sed -i 's+patch -Np1 < patches/wine-hotfixes/1ae10889647c1c84c36660749508a42e99e64a5e.patch+#patch -Np1 < patches/wine-hotfixes/1ae10889647c1c84c36660749508a42e99e64a5e.patch+g' protonprep.sh

    #unneeded lsteamclient
		sed -i 's+patch -Np1 < patches/proton/proton-steamclient_swap.patch+#patch -Np1 < patches/proton/proton-steamclient_swap.patch+g' protonprep.sh
    #unneeded game patches

    ## custom patches
		sed -i 's+patch -Np1 < patches/proton/proton-winevulkan.patch+patch -Np1 < custom-patches/proton-winevulkan.patch+g' protonprep.sh
		 
		
    cd ..


    
    ./patches/protonprep.sh
    #exit 1
    ## revert the steamuser patch
    patch -Np1 < ./custom-patches/revert.patch
    ## revert the Never create links patch
    patch -Np1 < ./custom-patches/revert2.patch

}

compile_make(){
	TARGET="$2"
	NAME="$1"
	#if [ "$TARGET" == 64 ];then

	if [ "$TARGET" == 32 ];then
		i386 make -j"$threads" &>> "$DIRECTORY"/logs/$NAME
		if [ $? -eq 0 ]; then
			if [ $DST -eq 1 ]; then
				i386 make -j"$threads" install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/$NAME
			else
				i386 make -j"$threads" install &>> "$DIRECTORY"/logs/$NAME
			fi
		else
			printf $RED"something went wrong making $NAME 32bits\n"$NC
			exit 1
		fi
	else
		make -j"$threads" &>> "$DIRECTORY"/logs/$NAME
		if [ $? -eq 0 ]; then
			if [ $DST -eq 1 ]; then
				make install DESTDIR="$DEST" &>> "$DIRECTORY"/logs/$NAME
			else
				make install &>> "$DIRECTORY"/logs/$NAME
			fi
		else
			printf $RED"something went wrong making $NAME 64bits\n"$NC
			exit 1
		fi
	fi
}

compile_ninja(){
	TARGET="$2"
	NAME="$1"
	#if [ "$TARGET" == 64 ];then

	#else
		ninja -j "$threads" &>> "$DIRECTORY"/logs/$NAME
		if [ $? -eq 0 ]; then
			if [ $DST -eq 1 ]; then
				DESTDIR="$DEST" ninja -j "$threads" install &>> "$DIRECTORY"/logs/$NAME
			else
				ninja -j "$threads" install &>> "$DIRECTORY"/logs/$NAME
			fi
		else
			printf $RED"something went wrong making $NAME 64bits\n"$NC
			exit 1
		fi
	#fi
	
}

build_headers() {
    ##
    cd "$DIRECTORY"/wine_prepare
    cd ./SPIRV-Headers
    mkdir build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=/usr/lib64 .. &> "$DIRECTORY"/logs/SPIRV-Headers
	
	compile_make SPIRV-Headers 64
	
    ##
    cd ../../Vulkan-Headers
    mkdir build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=/usr/lib64 .. &> "$DIRECTORY"/logs/Vulkan-Headers
    compile_make Vulkan-Headers 64
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
    
    compile_make SPIRV-Tools 32
    
    
    #### 64b
    cd ../build64
    cmake -DCMAKE_TOOLCHAIN_FILE=../../64bit.toolchain \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib64 \
        -DCMAKE_BUILD_TYPE=Release \
        -DSPIRV_WERROR=Off \
        -DBUILD_SHARED_LIBS=ON \
        -DSPIRV-Headers_SOURCE_DIR=$DIRECTORY/wine_prepare/SPIRV-Headers .. &>> "$DIRECTORY"/logs/SPIRV-Tools
    
    compile_make SPIRV-Tools 64
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
    
    compile_make Vulkan-Loader 32
    
    #### 64b
    cd ../build64
    cmake -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib64 \
        -DVULKAN_HEADERS_INSTALL_DIR=/usr .. &>> "$DIRECTORY"/logs/Vulkan-Loader
        
    compile_make Vulkan-Loader 64
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
    
    compile_make vkd3d 32

    #### 64b
    cd ../build64
    ../configure --prefix=/usr --libdir=/usr/lib64 --with-spirv-tools &>> "$DIRECTORY"/logs/vkd3d
   
   compile_make vkd3d 64
}

build_gstreamer_deps() {
    ##
    cd "$DIRECTORY"/wine_prepare
    cd ./libdv-1.0.0
    
    ./configure --prefix=/usr \
    --disable-xv \
    --bindir=/usr/bin \
    --disable-static \
    --libdir=/usr/lib64 &>> "$DIRECTORY"/logs/libdv-1.0.0
    
	compile_make libdv-1.0.0 64
    
    
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
    
	compile_make libvpx 64
    
    cd ../../libpsl
    sed -i 's/env python/&3/' src/psl-make-dafsa &&
    mkdir build64
    mkdir build32
    ./autogen.sh &> "$DIRECTORY"/logs/libpsl
    cd ./build64
    
    ../configure --prefix=/usr --libdir=/usr/lib64 --disable-static &>> "$DIRECTORY"/logs/libpsl
    compile_make libpsl 64
    
    cd ../../libsoup-2.70.0 
    mkdir build64

    cd    ./build64

    meson --prefix=/usr --libdir=/usr/lib64 -Dvapi=enabled -Dgssapi=disabled .. &> "$DIRECTORY"/logs/libsoup-2.70.0 &> "$DIRECTORY"/logs/libsoup-2.70.0
    ninja -j "$threads" &>> "$DIRECTORY"/logs/libsoup-2.70.0
    compile_ninja libsoup-2.70.0 64

}

build_gstreamer(){
    cd "$DIRECTORY"/wine_prepare
    cd ./gstreamer
    mkdir build64
  
    #### 64b
    cd ./build64 
    meson  --prefix=/usr       \
        --libdir=/usr/lib64 \
        -Dbuildtype=release \
        -Dgst_debug=false   \
        -Dgtk_doc=disabled  \
        -Dpackage-origin="http://github.com/GStreamer/gstreamer" \
        -Dpackage-name="GStreamer (Frankenpup Linux)" &>> "$DIRECTORY"/logs/gstreamer
    compile_ninja gstreamer 64
    
    cd ../../gst-plugins-base
    
 #### 64b
    mkdir build64
    cd ./build64
    meson  --prefix=/usr       \
    --libdir=/usr/lib64 \
    --bindir=/usr/bin \
    -Dbuildtype=release \
    -Dgtk_doc=disabled  \
    -Dpackage-origin="http://github.com/GStreamer/gst-plugins-base" \
    -Dpackage-name="GStreamer (Frankenpup Linux)"  &>> "$DIRECTORY"/logs/gst-plugins-base
    
    compile_ninja gst-plugins-base 64
    
    cd ../../gst-plugins-good
    
#### 64b
    mkdir build64
    cd ./build64
    meson  --prefix=/usr       \
		--libdir=/usr/lib64 \
		--bindir=/usr/bin \
		-Dbuildtype=release \
		-Dgtk_doc=disabled  \
		-Dpackage-origin="http://github.com/GStreamer/gst-plugins-good" \
		-Dpackage-name="GStreamer (Frankenpup Linux)" &>> "$DIRECTORY"/logs/gst-plugins-good
    compile_ninja gst-plugins-good 64
}

build_wine_deps_libusb(){
    cd "$DIRECTORY"/wine_prepare
    cd ./libusb

    #### 64b
    make distclean &>> "$DIRECTORY"/logs/libusb
    ./autogen.sh &>> "$DIRECTORY"/logs/libusb
    ./configure --prefix=/usr --libdir=/usr/lib64 &>> "$DIRECTORY"/logs/libusb
    make -j"$threads" &>> "$DIRECTORY"/logs/libusb
    compile_make libusb 64
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
    
    compile_make wine
    
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
   compile_make wine-32
}

dxvk(){
    cd "$DIRECTORY"
    wget https://github.com/doitsujin/dxvk/releases/download/v1.6.1/dxvk-1.6.1.tar.gz
    tar xf dxvk-1.6.1.tar.gz
    dxvk-1.6.1/setup_dxvk.sh install
}



printf $GREEN"HELLO THERE!\n"
printf "THIS SMALL SCRIPT WILL BUILD VULKAN, WINE AND VKD3D (AND GAME RELATED PATCHES)\n"
printf "USING WINE COMMIT $LWC\n"
printf "USING WINE-STAGING COMMIT $LWSC\n"
printf "USING PROTON-GE PATCHES COMMIT $LWPGEC"$NC
printf "\n"
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
    printf $GREEN"building and installing gstreamer deps (64 bits)\n"$NC
    build_gstreamer_deps
    printf $GREEN"building and installing gstreamer (64 bits)\n"$NC
    build_gstreamer 
else
    printf $RED"Skipping gstreamer\n"$NC
fi

if [ $LUSB -eq 0 ];then
    printf $GREEN"building and installing libusb (64 bits)\n"$NC
    build_wine_deps_libusb
else
    printf $RED"Skipping libusb\n"$NC
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
