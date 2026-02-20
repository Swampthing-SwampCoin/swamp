#!/bin/bash

# Build script for all Swamp variants
# Builds: Windows x64, Linux x86_64, Linux ARM 32-bit, Linux ARM 64-bit
# Usage: ./build-all-variants.sh [-debug]

# Exit immediately if a command exits with a non-zero status
set -e

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for debug flag
DEBUG_MODE=false
if [[ "$1" == "-debug" ]]; then
    DEBUG_MODE=true
    echo -e "${YELLOW}Debug mode enabled - showing full build output${NC}"
    echo ""
fi

# Spinner function for long-running commands
spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    echo -n "$message "
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r$message ${spin:$i:1}"
        sleep 0.1
    done
    printf "\r$message ✓\n"
}

# Run command with or without spinner
run_command() {
    local message=$1
    shift

    if [ "$DEBUG_MODE" = true ]; then
        echo -e "${YELLOW}$message${NC}"
        "$@"
        echo -e "${GREEN}✓ Complete${NC}"
    else
        "$@" > /tmp/swamp-build.log 2>&1 &
        spinner $! "$message"
        wait $! || {
            echo -e "${RED}✗ Failed! Check /tmp/swamp-build.log for details${NC}"
            tail -50 /tmp/swamp-build.log
            exit 1
        }
    fi
}

# Configuration
CPU_PERCENT=75  # Use 75% of available cores
JOBS=$(($(nproc) * CPU_PERCENT / 100))
if [ $JOBS -lt 1 ]; then JOBS=1; fi

OUTPUT_DIR="$HOME/built"
REPO_DIR="$HOME/swamp"
BRANCH="2.0.0.5-IPv6"

# Build targets
declare -A TARGETS=(
    ["windows-x64"]="x86_64-w64-mingw32"
    ["linux-x64"]="x86_64-pc-linux-gnu"
    ["linux-arm32"]="arm-linux-gnueabihf"
    ["linux-arm64"]="aarch64-linux-gnu"
)

# Binary names for each platform
declare -A DAEMON_NAMES=(
    ["windows-x64"]="swampd.exe"
    ["linux-x64"]="swampd"
    ["linux-arm32"]="swampd"
    ["linux-arm64"]="swampd"
)

declare -A CLI_NAMES=(
    ["windows-x64"]="swamp-cli.exe"
    ["linux-x64"]="swamp-cli"
    ["linux-arm32"]="swamp-cli"
    ["linux-arm64"]="swamp-cli"
)

declare -A TX_NAMES=(
    ["windows-x64"]="swamp-tx.exe"
    ["linux-x64"]="swamp-tx"
    ["linux-arm32"]="swamp-tx"
    ["linux-arm64"]="swamp-tx"
)

declare -A QT_NAMES=(
    ["windows-x64"]="swamp-qt.exe"
    ["linux-x64"]="swamp-qt"
    ["linux-arm32"]="swamp-qt"
    ["linux-arm64"]="swamp-qt"
)

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Swamp Multi-Platform Build Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Building for: ${GREEN}Windows x64, Linux x64, Linux ARM32, Linux ARM64${NC}"
echo -e "Using ${GREEN}$JOBS${NC} parallel jobs (${CPU_PERCENT}% of $(nproc) cores)"
echo -e "${YELLOW}Note: Each platform is built separately to save disk space${NC}"
echo ""

# Step 1: Install dependencies
echo -e "${YELLOW}--- Installing build dependencies ---${NC}"
if [ "$DEBUG_MODE" = true ]; then
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
else
    run_command "Updating package lists..." sudo apt-get update -qq
    run_command "Installing build dependencies..." sudo apt-get install -y -qq \
        build-essential libtool autotools-dev automake pkg-config \
        bsdmainutils curl git python3 libssl-dev libevent-dev libboost-all-dev \
        libdb++-dev libminiupnpc-dev libzmq3-dev libqt5gui5 libqt5core5a \
        libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev \
        protobuf-compiler libqrencode-dev cmake autoconf libtool-bin \
        perl patch bison flex gperf mingw-w64 zip unzip \
        g++-mingw-w64-x86-64 gcc-mingw-w64-x86-64 \
        g++-arm-linux-gnueabihf gcc-arm-linux-gnueabihf \
        g++-aarch64-linux-gnu gcc-aarch64-linux-gnu
fi
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Step 2: Build each platform (one at a time to save disk space)
PLATFORM_COUNT=0
TOTAL_PLATFORMS=${#TARGETS[@]}

for platform in "${!TARGETS[@]}"; do
    PLATFORM_COUNT=$((PLATFORM_COUNT + 1))
    host="${TARGETS[$platform]}"

    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Building Platform $PLATFORM_COUNT/$TOTAL_PLATFORMS: $platform${NC}"
    echo -e "${BLUE}========================================${NC}"

    # Clone repository for this platform
    echo -e "${YELLOW}Step 1: Cloning repository for $platform...${NC}"
    cd ~
    if [ -d "$REPO_DIR" ]; then
        rm -rf "$REPO_DIR"
    fi
    run_command "  Cloning repository..." git clone -q https://github.com/Swampthing-SwampCoin/swamp.git
    cd "$REPO_DIR"
    run_command "  Checking out $BRANCH..." git checkout -q "$BRANCH"
    echo -e "${GREEN}✓ Repository ready${NC}"

    # Build dependencies for this platform only
    echo -e "${YELLOW}Step 2: Building dependencies for $platform ($host)...${NC}"
    cd depends
    if [ "$DEBUG_MODE" = true ]; then
        make HOST="$host" -j$JOBS
    else
        run_command "  Building dependencies (this may take 15-30 minutes)..." make HOST="$host" -j$JOBS
    fi
    cd ..
    echo -e "${GREEN}✓ Dependencies built for $platform${NC}"

    # Generate configure script
    echo -e "${YELLOW}Step 3: Generating configure script...${NC}"
    run_command "  Running autogen.sh..." ./autogen.sh
    echo -e "${GREEN}✓ Configure script generated${NC}"

    # Configure (all platforms use simple configure - config.site has all settings)
    echo -e "${YELLOW}Step 4: Configuring for $platform...${NC}"
    if [ "$DEBUG_MODE" = true ]; then
        CONFIG_SITE="$PWD/depends/$host/share/config.site" ./configure --prefix=/
    else
        run_command "  Running configure..." CONFIG_SITE="$PWD/depends/$host/share/config.site" ./configure --prefix=/
    fi
    echo -e "${GREEN}✓ Configuration complete${NC}"

    # Build
    echo -e "${YELLOW}Step 5: Compiling $platform...${NC}"
    if [ "$DEBUG_MODE" = true ]; then
        make -j$JOBS
    else
        run_command "  Compiling binaries (this may take 10-20 minutes)..." make -j$JOBS
    fi
    echo -e "${GREEN}✓ Compilation complete${NC}"

    # Strip binaries
    echo -e "${YELLOW}Step 6: Stripping binaries...${NC}"
    if [[ "$platform" == "windows-x64" ]]; then
        run_command "  Stripping Windows binaries..." x86_64-w64-mingw32-strip src/swampd.exe src/swamp-cli.exe src/swamp-tx.exe src/qt/swamp-qt.exe
    elif [[ "$platform" == "linux-arm32" ]]; then
        run_command "  Stripping ARM32 binaries..." arm-linux-gnueabihf-strip src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt
    elif [[ "$platform" == "linux-arm64" ]]; then
        run_command "  Stripping ARM64 binaries..." aarch64-linux-gnu-strip src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt
    else
        run_command "  Stripping binaries..." strip src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt
    fi
    echo -e "${GREEN}✓ Binaries stripped${NC}"

    # Package binaries
    echo -e "${YELLOW}Step 7: Packaging binaries...${NC}"
    zip_name="swamp-$platform.zip"

    if [[ "$platform" == "windows-x64" ]]; then
        run_command "  Creating ZIP archive..." zip -q -j "$zip_name" src/swampd.exe src/swamp-cli.exe src/swamp-tx.exe src/qt/swamp-qt.exe
    else
        run_command "  Creating ZIP archive..." zip -q -j "$zip_name" src/swampd src/swamp-cli src/swamp-tx src/qt/swamp-qt
    fi

    mv "$zip_name" "$OUTPUT_DIR/"
    echo -e "${GREEN}✓ Binaries packaged: $OUTPUT_DIR/$zip_name${NC}"

    # Clean up repository to save disk space (except for last platform)
    if [ $PLATFORM_COUNT -lt $TOTAL_PLATFORMS ]; then
        echo -e "${YELLOW}Step 8: Cleaning up to save disk space...${NC}"
        cd ~
        rm -rf "$REPO_DIR"
        echo -e "${GREEN}✓ Cleanup complete${NC}"
        echo -e "${BLUE}Disk space freed for next platform build${NC}"
    else
        echo -e "${YELLOW}Step 8: Keeping final build directory${NC}"
        echo -e "${BLUE}Repository remains at: $REPO_DIR${NC}"
    fi

    echo -e "${GREEN}✓✓✓ $platform build complete! ✓✓✓${NC}"
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  All builds completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Build artifacts are in: ${BLUE}$OUTPUT_DIR${NC}"
echo ""
ls -lh "$OUTPUT_DIR"/swamp-*.zip
echo ""
echo -e "${GREEN}Done!${NC}"

