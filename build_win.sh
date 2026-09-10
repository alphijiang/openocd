#!/usr/bin/bash

unset LD_LIBRARY_PATH

mkdir -p ../build
cd ../build

echo "build libusb"
if [ -d libusb ] ; then
    rm -rf libusb
fi

git clone https://github.com/libusb/libusb.git
cd libusb
./bootstrap.sh
./configure --host=x86_64-w64-mingw32 --disable-shared --enable-static
make -j`nproc`
make install DESTDIR=${HOME}/mingw-root
cd ..

echo "build libftdi"
if [ -d libftdi ] ; then
    rm -rf libftdi
fi
git clone https://github.com/mcuee/libftdi.git
cd libftdi
mkdir build && cd build
export PKG_CONFIG_ALLOW_SYSTEM_CFLAGS
export PKG_CONFIG_ALLOW_SYSTEM_LIBS
export CPPFLAGS="-I${HOME}/mingw-root/usr/local/include/libusb-1.0 -fcommon"
export LDFLAGS="-L${HOME}/mingw-root/usr/local/lib"
PKG_CONFIG_PATH=${HOME}/mingw-root/usr/local/lib/pkgconfig \
cmake .. \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_SYSTEM_NAME=Windows \
  -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
  -DCMAKE_INSTALL_PREFIX=${HOME}/mingw-root/usr/local \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DBUILD_SHARED_LIBS=OFF \
  -DFTDI_EEPROM=OFF \
  -DFTDIPP=OFF \
  -DEXAMPLES=OFF
make -j`nproc`
make install DESTDIR=${HOME}/mingw-root
cd ../../

echo "build openocd"
if [ -d openocd ] ; then
    rm -rf openocd
fi

git clone --recurse  https://github.com/alphijiang/openocd.git
export AM_LDFLAGS=--static
export PKG_CONFIG_PATH=${HOME}/mingw-root/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
export PKG_CONFIG_LIBDIR=${HOME}/mingw-root/usr/local/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${HOME}/mingw-root
export LD_LIBRARY_PATH=${HOME}/mingw-root/usr/local/lib:$LD_LIBRARY_PATH

cd openocd

./bootstrap
PKG_CONFIG_PATH=$HOME/mingw-root/usr/local/lib/pkgconfig \
./configure  --prefix=${HOME}/openocd \
             --host=x86_64-w64-mingw32 \
             --with-libusb1=${HOME}/mingw-root/usr/local \
             --with-ftdi=${HOME}/mingw-root/usr/local \
             --enable-ftdi=yes \
             --enable-jtag_vpi=yes \
             --enable-jtag-dpi=yes \
             --enable-remote-bitbang=yes \
             --enable-jlink=no \
             --enable-rlink=no \
             --enable-ace-no=no \
             --enable-usbprog=no \
             --enable-openjtag=no \
             --enable-stlink=no  \
             --enable-ftdi-oscan1=no \
             --enable-ti-icdi=no \
             --enable-ulink=no \
             --enable-usb-blaster-2=no \
             --enable-opendous=no \
             --enable-openjtag=no \
             --enable-xds110=no \
             --enable-osbdm=no \
             --enable-ft232r=no \
             --enable-vslink=no \
             --enable-aice=no  \
             --enable-usb-blaster-2=no \
             --enable-osbdm=no \
             --enable-armjtagew=no \
             --enable-cmsis-dap=no \
             --enable-usb-blaster=no  \
             --enable-vsllink=no \
             --enable-kitprog=no \
             --enable-openjtag=no \
             --enable-presto=no  \
             CPPFLAGS=" -I${HOME}/mingw-root/usr/local/include" \
             LDFLAGS="-L${HOME}/mingw-root/usr/local/lib"  \
             --disable-werror \
             ac_cv_use_mingw_ansi_stdio=no \
             --enable-internal-jimtcl

make -j`nproc`
make install
