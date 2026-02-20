#!/bin/bash

# Simple build script for all Swamp variants
# Builds: Windows x64, Linux x86_64, Linux ARM 32-bit, Linux ARM 64-bit
# Usage: ./build-all-simple.sh

set -e

echo "=========================================="
echo "Swamp Multi-Platform Build Script"
echo "=========================================="
echo ""

# Install all dependencies
echo "Installing build dependencies..."
sudo apt-get update
sudo apt-get install -y build-essential libtool autotools-dev automake pkg-config \
    bsdmainutils curl git python3 libssl-dev libevent-dev libboost-all-dev \
    libdb++-dev libminiupnpc-dev libzmq3-dev libqt5gui5 libqt5core5a \
    libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev \
    protobuf-compiler libqrencode-dev cmake autoconf libtool-bin \
    perl patch bison flex gperf mingw-w64 zip unzip \
    g++-mingw-w64-x86-64 gcc-mingw-w64-x86-64 \
    g++-arm-linux-gnueabihf gcc-arm-linux-gnueabihf \
    g++-aarch64-linux-gnu gcc-aarch64-linux-gnu

echo ""
echo "=========================================="
echo "Building Windows x64"
echo "=========================================="
echo ""

# Clone repository
cd ~
rm -rf swamp
git clone https://github.com/Swampthing-SwampCoin/swamp.git
cd swamp
git checkout 2.0.0.5-IPv6

# Build dependencies
cd depends
make HOST=x86_64-w64-mingw32 -j$(nproc)
cd ..

# Generate configure script
./autogen.sh

# Configure (Windows uses simple configure)
CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure --prefix=/

# Compile
make -j$(nproc)

# Strip binaries
x86_64-w64-mingw32-strip src/swampd.exe src/swamp-cli.exe src/swamp-tx.exe src/qt/swamp-qt.exe

# Package
mkdir -p ~/built
zip -j ~/built/swamp-windows-x64.zip src/swampd.exe src/swamp-cli.exe src/swamp-tx.exe src/qt/swamp-qt.exe

echo "✓ Windows x64 build complete: ~/built/swamp-windows-x64.zip"
echo ""

echo "=========================================="
echo "Building Linux x64"
echo "=========================================="
echo ""

# Clone repository
cd ~
rm -rf swamp
git clone https://github.com/Swampthing-SwampCoin/swamp.git
cd swamp
git checkout 2.0.0.5-IPv6

# Build dependencies
cd depends
make HOST=x86_64-pc-linux-gnu -j$(nproc)
cd ..

# Generate configure script
./autogen.sh

# Configure (Linux uses extended configure)
CONFIG_SITE=$PWD/depends/x86_64-pc-linux-gnu/share/config.site ./configure \
    --prefix=/ \
    --disable-shared \
    --enable-static \
    --with-pic \
    --enable-glibc-back-compat \
    --enable-reduce-exports \
    --with-gui=qt5 \
    --disable-tests \
    --disable-bench \
    LDFLAGS="-static-libstdc++"

# Compile
make -j$(nproc)

# Strip binaries
strip src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt

# Package
mkdir -p ~/built
zip -j ~/built/swamp-linux-x64.zip src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt

echo "✓ Linux x64 build complete: ~/built/swamp-linux-x64.zip"
echo ""

echo "=========================================="
echo "Building Linux ARM 32-bit"
echo "=========================================="
echo ""

# Clone repository
cd ~
rm -rf swamp
git clone https://github.com/Swampthing-SwampCoin/swamp.git
cd swamp
git checkout 2.0.0.5-IPv6

# Build dependencies
cd depends
make HOST=arm-linux-gnueabihf -j$(nproc)
cd ..

# Generate configure script
./autogen.sh

# Configure (ARM uses extended configure)
CONFIG_SITE=$PWD/depends/arm-linux-gnueabihf/share/config.site ./configure \
    --prefix=/ \
    --disable-shared \
    --enable-static \
    --with-pic \
    --enable-glibc-back-compat \
    --enable-reduce-exports \
    --with-gui=qt5 \
    --disable-tests \
    --disable-bench \
    LDFLAGS="-static-libstdc++"

# Compile
make -j$(nproc)

# Strip binaries
arm-linux-gnueabihf-strip src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt

# Package
mkdir -p ~/built
zip -j ~/built/swamp-linux-arm32.zip src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt

echo "✓ Linux ARM32 build complete: ~/built/swamp-linux-arm32.zip"
echo ""

echo "=========================================="
echo "Building Linux ARM 64-bit"
echo "=========================================="
echo ""

# Clone repository
cd ~
rm -rf swamp
git clone https://github.com/Swampthing-SwampCoin/swamp.git
cd swamp
git checkout 2.0.0.5-IPv6

# Build dependencies
cd depends
make HOST=aarch64-linux-gnu -j$(nproc)
cd ..

# Generate configure script
./autogen.sh

# Configure (ARM64 uses extended configure)
CONFIG_SITE=$PWD/depends/aarch64-linux-gnu/share/config.site ./configure \
    --prefix=/ \
    --disable-shared \
    --enable-static \
    --with-pic \
    --enable-glibc-back-compat \
    --enable-reduce-exports \
    --with-gui=qt5 \
    --disable-tests \
    --disable-bench \
    LDFLAGS="-static-libstdc++"

# Compile
make -j$(nproc)

# Strip binaries
aarch64-linux-gnu-strip src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt

# Package
mkdir -p ~/built
zip -j ~/built/swamp-linux-arm64.zip src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt

echo "✓ Linux ARM64 build complete: ~/built/swamp-linux-arm64.zip"
echo ""

echo "=========================================="
echo "All builds complete!"
echo "=========================================="
echo ""
echo "Build artifacts:"
echo "  ~/built/swamp-windows-x64.zip"
echo "  ~/built/swamp-linux-x64.zip"
echo "  ~/built/swamp-linux-arm32.zip"
echo "  ~/built/swamp-linux-arm64.zip"
echo ""

