#!/bin/zsh
# Builds Whiteboard.app (menu-bar whiteboard). Run: ./build.sh && open Whiteboard.app
set -e
cd "$(dirname "$0")"
APP=Whiteboard.app
rm -rf $APP; mkdir -p $APP/Contents/MacOS $APP/Contents/Resources
swiftc -O main.swift -o $APP/Contents/MacOS/Whiteboard
cp whiteboard.html $APP/Contents/Resources/
cat > $APP/Contents/Info.plist <<P
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Whiteboard</string>
<key>CFBundleIdentifier</key><string>local.tools.whiteboard</string>
<key>CFBundleExecutable</key><string>Whiteboard</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
</dict></plist>
P
codesign --force --sign - $APP
echo built $APP
