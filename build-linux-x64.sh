#!/bin/bash

# Build script for Swamp Linux x64
# Usage: ./build-linux-x64.sh

set -e

echo "=========================================="
echo "Building Swamp Linux x64"
echo "=========================================="
echo ""

# Clone repository
cd ~
rm -rf swamp
git clone https://github.com/Swampthing-SwampCoin/swamp.git
cd swamp
git checkout 2.0.0.5-IPv6

# Build dependencies
echo "Building dependencies..."
cd depends
make HOST=x86_64-pc-linux-gnu -j$(nproc)
cd ..

# Generate configure script
echo "Generating configure script..."
./autogen.sh

# Configure
echo "Configuring..."
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
echo "Compiling..."
make -j$(nproc)

# Strip binaries
echo "Stripping binaries..."
strip src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt

# Package
echo "Packaging..."
mkdir -p ~/built
zip -j ~/built/swamp-linux-x64.zip src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt

echo ""
echo "✓ Linux x64 build complete: ~/built/swamp-linux-x64.zip"

