#!/bin/bash

# Build script for Swamp Windows x64
# Usage: ./build-windows-x64.sh

set -e

echo "=========================================="
echo "Building Swamp Windows x64"
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
make HOST=x86_64-w64-mingw32 -j$(nproc)
cd ..

# Generate configure script
echo "Generating configure script..."
./autogen.sh

# Configure
echo "Configuring..."
CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure --prefix=/

# Compile
echo "Compiling..."
make -j$(nproc)

# Strip binaries
echo "Stripping binaries..."
x86_64-w64-mingw32-strip src/swampd.exe src/swamp-cli.exe src/swamp-tx.exe src/qt/swamp-qt.exe

# Package
echo "Packaging..."
mkdir -p ~/built
zip -j ~/built/swamp-windows-x64.zip src/swampd.exe src/swamp-cli.exe src/swamp-tx.exe src/qt/swamp-qt.exe

echo ""
echo "✓ Windows x64 build complete: ~/built/swamp-windows-x64.zip"

