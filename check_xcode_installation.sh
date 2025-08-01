#!/bin/bash

# Xcode Installation Checker Script
# Run this script to check if Xcode is installed and ready

echo "🔍 Checking Xcode Installation Status..."
echo "========================================="

# Check if Xcode.app exists
if [ -d "/Applications/Xcode.app" ]; then
    echo "✅ Xcode.app found in Applications folder"
    
    # Check Xcode version
    xcode_version=$(xcodebuild -version 2>/dev/null | head -n 1)
    if [ $? -eq 0 ]; then
        echo "✅ Xcode is ready: $xcode_version"
        
        # Check if command line tools are properly linked
        xcode_path=$(xcode-select --print-path 2>/dev/null)
        echo "📁 Developer tools path: $xcode_path"
        
        # Check for iOS Simulator
        if [ -d "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app" ]; then
            echo "✅ iOS Simulator is available"
        else
            echo "❌ iOS Simulator not found"
        fi
        
        echo ""
        echo "🎉 Xcode is ready! You can now:"
        echo "   1. Launch Xcode: open -a Xcode"
        echo "   2. Create your iOS project"
        echo "   3. Follow the SETUP_GUIDE.md instructions"
        
    else
        echo "⚠️  Xcode found but may not be fully configured"
        echo "   Try running: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    fi
    
else
    echo "⏳ Xcode is still downloading/installing..."
    echo "   Check the App Store for progress"
    echo "   This can take 30-60 minutes depending on your internet speed"
    
    # Check if it's in the process of being installed
    if pgrep -f "App Store" > /dev/null; then
        echo "   📱 App Store is running - installation may be in progress"
    fi
fi

echo ""
echo "💡 While waiting, you can:"
echo "   - Review the code files we've created"
echo "   - Read through SETUP_GUIDE.md"
echo "   - Check available disk space (Xcode needs ~15GB)"

# Check available disk space
available_space=$(df -h / | awk 'NR==2 {print $4}')
echo "   - Available disk space: $available_space"

echo ""
echo "Run this script again to check installation progress:"
echo "bash check_xcode_installation.sh"