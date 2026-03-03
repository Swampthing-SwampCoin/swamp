#!/bin/bash

# Build script for Swamp Linux ARM 32-bit
# Usage: ./build-linux-arm32.sh

set -e

echo "=========================================="
echo "Building Swamp Linux ARM 32-bit"
echo "=========================================="
echo ""

# Clone repository
cd ~
rm -rf swamp
git clone https://github.com/Swampthing-SwampCoin/swamp.git
cd swamp
git checkout master

# Build dependencies
echo "Building dependencies..."
cd depends
make HOST=arm-linux-gnueabihf -j$(nproc)
cd ..

# Generate configure script
echo "Generating configure script..."
./autogen.sh

# Configure
echo "Configuring..."
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
echo "Compiling..."
make -j$(nproc)

# Strip binaries
echo "Stripping binaries..."
arm-linux-gnueabihf-strip src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt

# Package
echo "Packaging..."
mkdir -p ~/built
zip -j ~/built/swamp-linux-arm32.zip src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt

echo ""
echo "✓ Linux ARM32 build complete: ~/built/swamp-linux-arm32.zip"

