# Windows Build Fix for flutter_secure_storage

## Problem
Windows builds fail with error:
```
fatal error C1083: Cannot open include file: 'atlstr.h': No such file or directory
```

This is because `flutter_secure_storage_windows` requires ATL headers that may not be available in all Windows build environments.

## Solution
We've excluded `flutter_secure_storage_windows` from Windows builds by:

1. **Created `windows/flutter/custom_plugins.cmake`** - A custom plugin processing file that excludes `flutter_secure_storage_windows` from the build
2. **Modified `windows/CMakeLists.txt`** - Now uses `custom_plugins.cmake` instead of `generated_plugins.cmake`
3. **Secure Storage Service** - Automatically falls back to SharedPreferences on Windows

## Implementation Details

### Files Modified:
- `windows/CMakeLists.txt` - Uses custom plugin processing
- `windows/flutter/custom_plugins.cmake` - Filters out problematic plugin
- `lib/core/services/secure_storage_service.dart` - Uses conditional imports
- `lib/core/services/secure_storage_service_stub.dart` - Windows-only stub

### How It Works:
1. `custom_plugins.cmake` defines the plugin list manually, excluding `flutter_secure_storage_windows`
2. The secure storage service uses conditional imports - on Windows it never imports `flutter_secure_storage` package
3. SharedPreferences is used as a fallback on Windows

## Important Notes

⚠️ **If you add or remove plugins**, you must update `windows/flutter/custom_plugins.cmake` to match `windows/flutter/generated_plugins.cmake` (except excluding `flutter_secure_storage_windows`).

The plugin list in `custom_plugins.cmake` should mirror `generated_plugins.cmake` but without `flutter_secure_storage_windows`.

## Alternative Solutions

If you want to enable `flutter_secure_storage` on Windows in the future:

1. Install Windows SDK components that include ATL headers
2. Or patch the plugin's CMakeLists.txt to handle missing ATL gracefully
3. Or update to a newer version of flutter_secure_storage that fixes this issue








