#!/bin/bash

# Build script for Swamp Linux ARM 64-bit
# Usage: ./build-linux-arm64.sh

set -e

echo "=========================================="
echo "Building Swamp Linux ARM 64-bit"
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
make HOST=aarch64-linux-gnu -j$(nproc)
cd ..

# Generate configure script
echo "Generating configure script..."
./autogen.sh

# Configure
echo "Configuring..."
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
echo "Compiling..."
make -j$(nproc)

# Strip binaries
echo "Stripping binaries..."
aarch64-linux-gnu-strip src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt

# Package
echo "Packaging..."
mkdir -p ~/built
zip -j ~/built/swamp-linux-arm64.zip src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt

echo ""
echo "✓ Linux ARM64 build complete: ~/built/swamp-linux-arm64.zip"

