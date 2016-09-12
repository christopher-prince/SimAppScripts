#!/bin/bash

# During a Xcode build & run on simulator, save a copy of the app so that it can be transferred to a different Mac system.

# Usage: saveAppFromSimulator <AppName> [<ResultName>]
# 	Run this when the simulator is running, after having built your app using Xcode to run on the simulator.
# Where: 
#	<AppName> is the name of the app as you see it on iOS. This app is assumed to be present on the booted simulator device.
#	<ResultFile> is the name of the file (with a .tgz appended) that will appear on your desktop. Keep white space and other special characters out of this file name. Defaults to "app"
# Example: ./saveAppFromSimulator.sh "Angie's List" AngiesList
# Example: ./saveAppFromSimulator.sh "SP Mobile" Business

APP_NAME="$1"
RESULT_NAME="$2"

if [ -z "$APP_NAME" ]; then
    echo "You need to give the name of an app on the simulator..."
    exit 1
fi

if [ -z "$RESULT_NAME" ]; then
    RESULT_NAME="app"
fi

echo "Looking for app name: ${APP_NAME} on the booted simulator device..."

# With Xcode 7.3.1, this where the simulated iOS devices live
SIMULATED_DEVICES=~/Library/Developer/CoreSimulator/Devices

# And within that directory, this subdirectory gives the apps executable Bundles (not the data for the apps):
APP_SUB_DIR="data/Containers/Bundle/Application"

# The output of the xcrun may be one line:
#    iPhone 6 (D4503861-FDEE-4E7F-8723-C47CBB21B388) (Booted)
# or may have two lines
#    iPhone 6s (243B07C0-CC02-4928-96F7-D6B3BB1737A6) (Booted)
#    Phone: iPhone 6s (243B07C0-CC02-4928-96F7-D6B3BB1737A6) (Booted)
# Seems like we can use just the first line.
BOOTED=`xcrun simctl list | grep Booted | awk 'NR==1'`

if [ -z "$BOOTED" ]; then
    echo "No simulator is booted. Cowardly giving up."
    exit 1
fi

# So, now BOOTED is something like 
# iPhone 6 (D4503861-FDEE-4E7F-8723-C47CBB21B388) (Booted)

# Get the device Id of the booted device
# http://stackoverflow.com/questions/15664862/multiple-field-separators-in-awk
DEVICE_ID=`echo -n $BOOTED | awk -F'[()]' '{print $2}'`

echo "Booted device id: ${DEVICE_ID}"

APPS_DIR="${SIMULATED_DEVICES}/${DEVICE_ID}/${APP_SUB_DIR}"
# echo $APPS_DIR
cd $APPS_DIR

# find . -iname "*.app"

OUR_APP_DIR=`find . -iname "*.app" | grep "$APP_NAME"`
echo $OUR_APP_DIR

if [ -z "$OUR_APP_DIR" ]; then
    echo "Yikes: Couldn't find your app: $APP_NAME"
    exit 1
fi

# cd "$OUR_APP_DIR"
# ls

RESULT_FILE=~/Desktop/${RESULT_NAME}.tgz
echo "Creating result file: ${RESULT_FILE}..."
tar -czf "${RESULT_FILE}" "$OUR_APP_DIR"
