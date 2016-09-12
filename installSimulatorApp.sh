#!/bin/bash

# Installs an app on a iOS simulator.
# Assumes the saveAppFromSimulator.sh script was used to tar up the app. 
# Assumes Xcode apps are installed in /Applications

# Usage: installSimulatorApp.sh <AppFileName> <iOSVersion> <DeviceType> <XcodeAppName>
# Where: 
#	<AppFileName> is the name of the file obtained from saveAppFromSimulator.sh (with the .tgz).
#	<iOSVersion> needs to be in the format iOS-N-M
#		e.g., iOS-9-3
#   <DeviceType> needs to be in the format iPhone-Style
#		e.g., iPhone-6
#	<XcodeAppName> needs to be in format Xcode.app
#		e.g., Xcode-7.3.1.app
# Example: ./installSimulatorApp.sh AngiesList.tgz iOS-9-3 iPhone-6 Xcode-7.3.1.app

# With Xcode 7.3.1, this where the simulated iOS devices live
SIMULATED_DEVICES=~/Library/Developer/CoreSimulator/Devices

APP_FILE_NAME="$1"
IOS_VERSION="$2"
DEVICE_TYPE="$3"
XCODE_APP="$4"

if [ -z "$APP_FILE_NAME" ]; then
    echo "You need to give the file name of the app..."
    exit 1
fi

if [ -z "$IOS_VERSION" ]; then
    echo "You need to give the iOS version..."
    exit 1
fi

if [ -z "$DEVICE_TYPE" ]; then
    echo "You need to give the device type..."
    exit 1
fi

if [ -z "$XCODE_APP" ]; then
    echo "You need to give the Xcode app name..."
    exit 1
fi

pushd $SIMULATED_DEVICES
DEVICE_ID=`/usr/libexec/PlistBuddy -c "print DefaultDevices:com.apple.CoreSimulator.SimRuntime.${IOS_VERSION}:com.apple.CoreSimulator.SimDeviceType.${DEVICE_TYPE}" *.plist`
popd
# echo $DEVICE_ID

if [ -z "$DEVICE_ID" ]; then
    echo "Could not get device Id for simulator..."
    exit 1
fi

# Get the name of the directory where we are untarring to
UNTAR_DIR=`tar -tzf $APP_FILE_NAME | head -1 | awk -F'[//]' '{print $2}'`
echo $UNTAR_DIR

# Make sure the simulator is not running-- need this when we open the simulator in case we're starting up a different simulator version. If it's open and we attempt to switch versions that doesn't happen.
osascript -e 'quit app "Simulator"'

open "/Applications/${XCODE_APP}/Contents/Developer/Applications/Simulator.app" --args -CurrentDeviceUDID $DEVICE_ID
echo "Launching Simulator..."

tar -xzf "$APP_FILE_NAME" 

# There is a race condition between launching the simulator and completion of the tar. The simulator needs to be completely launched to do the installation below.
# This next snippet of code from: https://coderwall.com/p/fprm_g/chose-ios-simulator-via-command-line--2
count=`xcrun simctl list | grep Booted | wc -l | sed -e 's/ //g'`
while [ $count -lt 1 ]
do
    sleep 1
    count=`xcrun simctl list | grep Booted | wc -l | sed -e 's/ //g'`
done

# install the app to the simulator
cd $UNTAR_DIR/*
xcrun simctl install $DEVICE_ID .