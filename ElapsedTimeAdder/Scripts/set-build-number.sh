#!/bin/sh
#
# set-build-number.sh
#
# Stamps CFBundleVersion with a fresh date-based build number (yymmddHHMM)
# directly in the BUILT Info.plist, at build/archive time.
#
# Why a build-phase script instead of a scheme pre-action editing project.pbxproj:
#   The old approach was a scheme Archive pre-action that used `sed` to rewrite
#   CURRENT_PROJECT_VERSION in project.pbxproj from outside Xcode's process.
#   Xcode keeps its own in-memory project model while the project is open, and
#   doesn't reliably reload after an external edit before the build starts — so
#   the archive could embed a build number that was stale by days, even though
#   the file on disk was correct. Patching the already-built Info.plist directly
#   (after ProcessInfoPlistFile has run, forced by declaring it as an input file
#   in the build phase) has no such reload dependency.
#
set -e

PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
BUILD_NUMBER=$(date +"%y%m%d%H%M")
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" "${PLIST}"
echo "set-build-number: CFBundleVersion set to ${BUILD_NUMBER} in ${PLIST}"
