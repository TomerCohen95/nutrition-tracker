# 📱 Simple Steps to iOS Simulator

## 🚀 5 Easy Steps (10 minutes total)

### Step 1: Open Xcode & Create Project (2 minutes)
```bash
open -a Xcode
```
1. Click "Create a new Xcode project"
2. Choose **iOS** → **App** → **Next**
3. Fill in:
   - **Product Name**: `NutritionTracker`
   - **Bundle Identifier**: `com.yourname.nutritiontracker` (replace "yourname")
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Use Core Data**: ❌ UNCHECKED
4. **Next** → Save in: `/Users/tomercohen/dev/try/widget/NutritionTracker`

### Step 2: Add Widget Extension (2 minutes)
1. **File** → **New** → **Target**
2. **iOS** → **Widget Extension** → **Next**
3. **Product Name**: `NutritionWidget`
4. **Include Configuration Intent**: ❌ UNCHECKED
5. **Finish** → **Activate**

### Step 3: Configure App Groups (3 minutes)
**Main App:**
1. Select **NutritionTracker** target (left panel)
2. **Signing & Capabilities** tab
3. **+ Capability** → **App Groups**
4. **+** → Enter: `group.com.yourname.nutritiontracker`
5. ✅ Check the box

**Widget:**
1. Select **NutritionWidget** target
2. **Signing & Capabilities** tab  
3. **+ Capability** → **App Groups**
4. Select same group → ✅ Check the box

### Step 4: Copy Our Code (1 minute)
In Terminal:
```bash
cd /Users/tomercohen/dev/try/widget
./copy_files_to_xcode.sh
```
Enter your "yourname" when prompted.

### Step 5: Run in Simulator (2 minutes)
In Xcode:
1. Select **NutritionTracker** scheme (top-left)
2. Choose **iPhone 15** simulator
3. Press **Cmd+R**

## 🎉 Success!
The simulator will open with your nutrition tracker app running.

## 🧪 Test Features:
- **Add food**: Tap **+** button
- **Mark eaten**: Tap circle icons
- **View progress**: See calorie totals update
- **Test widget**: Home screen (Cmd+Shift+H) → Long press → **+** → Search "Nutrition"

**Total time: ~10 minutes!**