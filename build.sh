#!/bin/sh

# This script builds Donovan for distribution.
# It first builds the app and then creates two
# ZIP files which it places on the Desktop. Those
# files can then all be uploaded to the web.

# Get the bundle version from the plist.
PLIST_FILE="mls-bar/Info.plist"
VERSION=$(date -u "+%Y%m%d%H%M")

# Set up file names and paths.
BUILD_PATH=$(mktemp -d "$TMPDIR/Donovan.XXXXXX")
ZIP_NAME="Donovan-$VERSION.zip"
ZIP_MASTER_PATH="$PWD/Releases"
ZIP_PATH1="$ZIP_MASTER_PATH/$ZIP_NAME"

# Build Donovan in a temporary build location.
xcodebuild -workspace mls-bar.xcworkspace -scheme mls-bar -configuration Release -derivedDataPath "$BUILD_PATH" build

# Go into the temporary build directory.
cd "$BUILD_PATH/Build/Products/Release"

# Compress the app.
rm -f "$ZIP_PATH1"
mkdir -p "$ZIP_MASTER_PATH"
mv mls-bar.app Donovan.app
zip -r -y "$ZIP_PATH1" Donovan.app
