# Spawn Point Alignment Fix

## Problem
Player spawn points were appearing at different locations on different devices due to inconsistent window scaling and resolution handling.

## Solution Implemented

### 1. **Window Configuration Updates** ([conf.lua](conf.lua))
- Added `t.window.resizable = false` to prevent window resizing
- Added `t.window.highdpi = true` for proper high-DPI display support
- Added `t.window.usedpiscale = true` for DPI-aware scaling (LÖVE 11.3+)

### 2. **Main Game Initialization** ([main.lua](main.lua))
- Defined global constants `GAME_WIDTH = 1024` and `GAME_HEIGHT = 768`
- Added window size verification on load to ensure consistent dimensions
- Forces window to exact intended size if it doesn't match

### 3. **Debug Logging** ([src/game.lua](src/game.lua))
- Added console output when player spawns showing:
  - Exact spawn coordinates (x, y)
  - Current window dimensions
- Helps verify spawn positions are consistent across devices

## How to Test

1. **Run on your device:**
   - Note the spawn coordinates printed in console
   - Note the window dimensions (should be 1024x768)

2. **Share with testers:**
   - Ask them to check console output when spawning
   - Compare the spawn coordinates - they should be IDENTICAL
   - Window dimensions should also be 1024x768

3. **Check console output:**
   ```
   Player spawned at: x=540.00, y=510.00 (window: 1024x768)
   ```
   The coordinates should match exactly on all devices.

## Why This Works

- **Fixed Resolution**: The game now enforces a consistent 1024x768 window
- **DPI Handling**: Proper high-DPI support prevents OS-level scaling issues
- **Non-resizable**: Prevents users from accidentally changing window size
- **Consistent Coordinates**: Spawn points use absolute world coordinates that are now consistent across all devices

## What the Testers Should Do

1. Run the game
2. Open the console (already enabled in conf.lua)
3. Move through portals to different maps
4. Check that spawn coordinates match what you see on your device
5. Report any discrepancies with their window dimensions

## If Problems Persist

If spawn points still don't align after this fix, the issue might be:
1. **Different LÖVE versions** - Ensure everyone uses the same LÖVE version
2. **OS scaling** - Check if OS-level display scaling is set differently
3. **Monitor resolution** - Very unusual, but some extreme aspect ratios might cause issues

## Files Modified
- `conf.lua` - Window configuration
- `main.lua` - Window size enforcement
- `src/game.lua` - Debug logging
