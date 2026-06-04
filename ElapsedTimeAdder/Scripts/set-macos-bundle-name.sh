#!/bin/sh
#
# set-macos-bundle-name.sh
#
# Sets the macOS app's CFBundleName to the spaced display name ("Elapsed Time Adder")
# in the BUILT Info.plist, so the Dock / ⌘-Tab / menu bar show the spaced name.
#
# Why a build-phase script instead of a build setting:
#   - The Dock/menu bar read CFBundleName, which equals PRODUCT_NAME.
#   - INFOPLIST_KEY_CFBundleName is ignored when GENERATE_INFOPLIST_FILE = YES.
#   - Renaming PRODUCT_NAME to "Elapsed Time Adder" DOES work for the Dock, but it also
#     renames the .app/executable/Swift module and breaks the test targets (TEST_HOST,
#     @testable import, unit-test discovery). See CLAUDE.md "App display names".
#   - So we leave PRODUCT_NAME = ElapsedTimeAdder (bundle/module/tests untouched) and
#     patch ONLY CFBundleName in the final plist, macOS-only.
#
# Runs before code signing, so the signature covers the patched plist. iOS is skipped.

set -e

if [ "${PLATFORM_NAME}" = "macosx" ]; then
    PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
    /usr/libexec/PlistBuddy -c "Set :CFBundleName 'Elapsed Time Adder'" "${PLIST}"
    echo "set-macos-bundle-name: CFBundleName set to 'Elapsed Time Adder' in ${PLIST}"
fi
