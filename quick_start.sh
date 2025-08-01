#!/bin/bash

# Quick Start Script for Nutrition Tracker
# This will help you get to testing in the simulator quickly

echo "🍽️ Nutrition Tracker - Quick Start"
echo "=================================="
echo ""

# Check if Xcode is installed
if [ ! -d "/Applications/Xcode.app" ]; then
    echo "❌ Xcode not found! Please install Xcode first."
    echo "   Run: ./check_xcode_installation.sh"
    exit 1
fi

echo "✅ Xcode is installed"

# Check if project exists
if [ -d "./NutritionTracker/NutritionTracker.xcodeproj" ]; then
    echo "✅ Xcode project found"
    echo ""
    echo "🚀 Ready to test! Here's what to do:"
    echo ""
    echo "1. Open your project:"
    echo "   open ./NutritionTracker/NutritionTracker.xcodeproj"
    echo ""
    echo "2. In Xcode:"
    echo "   - Select 'NutritionTracker' scheme (top-left)"
    echo "   - Choose 'iPhone 15' simulator"
    echo "   - Press Cmd+R to run"
    echo ""
    echo "3. Test the app:"
    echo "   - Tap + to add food items"
    echo "   - Tap circles to mark as eaten"
    echo "   - See calorie progress update"
    echo ""
    echo "4. Test the widget:"
    echo "   - Press Cmd+Shift+H (home screen)"
    echo "   - Long press → + → Search 'Nutrition'"
    echo "   - Add widget to home screen"
    echo ""
    
    read -p "🔄 Want me to open the project now? (y/n): " open_project
    if [[ $open_project =~ ^[Yy]$ ]]; then
        echo "📂 Opening Xcode project..."
        open ./NutritionTracker/NutritionTracker.xcodeproj
        echo "✅ Project opened! Follow steps 2-4 above."
    fi
    
else
    echo "📝 No Xcode project found yet. Let's create it!"
    echo ""
    echo "Follow these steps:"
    echo ""
    echo "1. 📖 Read the guide:"
    echo "   open SIMULATOR_TESTING_GUIDE.md"
    echo ""
    echo "2. 🏗️ Create project in Xcode:"
    echo "   - Open Xcode"
    echo "   - Create new iOS App project"
    echo "   - Name: NutritionTracker"
    echo "   - Save in: $(pwd)/NutritionTracker"
    echo ""
    echo "3. 🔧 Add widget extension and configure App Groups"
    echo ""
    echo "4. 📋 Copy our code:"
    echo "   ./copy_files_to_xcode.sh"
    echo ""
    echo "5. 🚀 Test in simulator (Cmd+R)"
    echo ""
    
    read -p "🔄 Want me to open the guide now? (y/n): " open_guide
    if [[ $open_guide =~ ^[Yy]$ ]]; then
        echo "📖 Opening testing guide..."
        open SIMULATOR_TESTING_GUIDE.md
    fi
    
    read -p "🔄 Want me to open Xcode to start? (y/n): " open_xcode
    if [[ $open_xcode =~ ^[Yy]$ ]]; then
        echo "🛠️ Opening Xcode..."
        open -a Xcode
        echo "✅ Xcode opened! Create your project now."
    fi
fi

echo ""
echo "📚 Available guides:"
echo "   - SIMULATOR_TESTING_GUIDE.md (detailed testing steps)"
echo "   - NEXT_STEPS.md (project creation steps)"
echo "   - README.md (complete overview)"
echo ""
echo "🔧 Available scripts:"
echo "   - ./copy_files_to_xcode.sh (copy code to project)"
echo "   - ./check_xcode_installation.sh (verify Xcode)"
echo ""
echo "💡 Need help? Check the guides above or ask for assistance!"