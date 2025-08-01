#!/bin/bash

# Script to copy nutrition tracker files to Xcode project
# Run this after you've created the Xcode project

echo "🍽️ Nutrition Tracker - File Copy Helper"
echo "======================================"

# Get the project path
PROJECT_PATH=""
if [ -d "./NutritionTracker/NutritionTracker.xcodeproj" ]; then
    PROJECT_PATH="./NutritionTracker"
    echo "✅ Found Xcode project at: $PROJECT_PATH"
elif [ -d "./NutritionTracker/NutritionTracker/NutritionTracker.xcodeproj" ]; then
    PROJECT_PATH="./NutritionTracker/NutritionTracker"
    echo "✅ Found Xcode project at: $PROJECT_PATH"
elif [ -d "../NutritionTracker/NutritionTracker.xcodeproj" ]; then
    PROJECT_PATH="../NutritionTracker"
    echo "✅ Found Xcode project at: $PROJECT_PATH"
else
    echo "❌ Xcode project not found!"
    echo "   Please make sure you've created the NutritionTracker project first"
    echo "   Expected location: ./NutritionTracker/NutritionTracker.xcodeproj"
    echo "   or ./NutritionTracker/NutritionTracker/NutritionTracker.xcodeproj"
    exit 1
fi

# Check if required source files exist
REQUIRED_FILES=("FoodItem.swift" "NutritionTrackerApp.swift" "ContentView.swift" "AddFoodView.swift" "DailyView.swift" "NutritionWidget.swift")

echo ""
echo "🔍 Checking source files..."
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "./$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file - Missing!"
        exit 1
    fi
done

echo ""
echo "📁 Ready to copy files to Xcode project"
echo ""

# Ask user for their bundle identifier suffix
read -p "🔤 What name did you use in your bundle identifier? (e.g., if you used 'com.john.nutritiontracker', enter 'john'): " USERNAME

if [ -z "$USERNAME" ]; then
    echo "❌ Username cannot be empty"
    exit 1
fi

APP_GROUP_ID="group.com.$USERNAME.nutritiontracker"
echo "📝 Will use App Group ID: $APP_GROUP_ID"

# Create backup directory
BACKUP_DIR="$PROJECT_PATH/original_files"
mkdir -p "$BACKUP_DIR"

echo ""
echo "💾 Creating backups of original files..."

# Backup original files
if [ -f "$PROJECT_PATH/NutritionTracker/ContentView.swift" ]; then
    cp "$PROJECT_PATH/NutritionTracker/ContentView.swift" "$BACKUP_DIR/"
    echo "✅ Backed up original ContentView.swift"
fi

if [ -f "$PROJECT_PATH/NutritionTracker/NutritionTrackerApp.swift" ]; then
    cp "$PROJECT_PATH/NutritionTracker/NutritionTrackerApp.swift" "$BACKUP_DIR/"
    echo "✅ Backed up original NutritionTrackerApp.swift"
fi

echo ""
echo "📋 Copying and updating files..."

# Copy and update main app files
for file in "FoodItem.swift" "AddFoodView.swift" "DailyView.swift"; do
    cp "./$file" "$PROJECT_PATH/NutritionTracker/"
    echo "✅ Copied $file"
done

# Update NutritionTrackerApp.swift with correct App Group ID
sed "s/group\.com\.yourname\.nutritiontracker/$APP_GROUP_ID/g" "./NutritionTrackerApp.swift" > "$PROJECT_PATH/NutritionTracker/NutritionTrackerApp.swift"
echo "✅ Updated NutritionTrackerApp.swift with App Group ID: $APP_GROUP_ID"

# Update ContentView.swift
cp "./ContentView.swift" "$PROJECT_PATH/NutritionTracker/"
echo "✅ Updated ContentView.swift"

# Update NutritionWidget.swift with correct App Group ID
if [ -d "$PROJECT_PATH/NutritionWidget" ]; then
    sed "s/group\.com\.yourname\.nutritiontracker/$APP_GROUP_ID/g" "./NutritionWidget.swift" > "$PROJECT_PATH/NutritionWidget/NutritionWidget.swift"
    echo "✅ Updated NutritionWidget.swift with App Group ID: $APP_GROUP_ID"
else
    echo "⚠️  NutritionWidget folder not found - make sure you added the Widget Extension target"
fi

echo ""
echo "🎉 Files copied successfully!"
echo ""
echo "📝 Next steps:"
echo "   1. Go back to Xcode"
echo "   2. You might see some red errors - that's normal"
echo "   3. Try building the project (Cmd+R)"
echo "   4. If you get errors about missing files, make sure all files are added to your targets"
echo ""
echo "🔧 If you need to add files to targets:"
echo "   1. Select the file in Xcode's project navigator"
echo "   2. In the File Inspector (right panel), check the target membership boxes"
echo "   3. Make sure NutritionTracker target is checked for main app files"
echo "   4. Make sure NutritionWidget target is checked for widget files"

echo ""
echo "✨ Your nutrition tracker app should now be ready to run!"