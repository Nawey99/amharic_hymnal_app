# App Size Audit Report

## Baseline Measurement (Before Optimization)

**Date**: Initial audit
**Build Type**: Debug (current state)

### Current Size Contributors

#### Sheet Music Assets
- **Location**: `assets/sheet_music/`
- **File Count**: 398 .webp files
- **Average File Size**: ~350 KB per file
- **Total Size**: ~140 MB
- **Status**: ⚠️ **PRIMARY SIZE ISSUE** - Must be moved to remote/CDN

#### Fonts
- **File**: `assets/fonts/NotoSansEthiopic-Regular.ttf`
- **Size**: 358.29 KB
- **Status**: Needs subsetting (Amharic + Latin only) - Expected reduction: 50-70%

#### JSON Data Files
- **Files**: 
  - `assets/data/database/HagerignaData.json`: 160.58 KB
  - `assets/data/database/SDA_Hymnal.json`: 539.02 KB
  - `assets/data/database/memoryDb.js`: 2.77 KB
- **Total**: ~702 KB
- **Status**: Acceptable (metadata only)

#### Images
- **Files**: 
  - `assets/images/background.jpg`: 462.90 KB
  - `assets/images/favicon.png`: 100.41 KB
- **Total**: ~563 KB
- **Status**: background.jpg may need compression

### Build Configuration Issues

#### Android
- ❌ `minifyEnabled`: false (should be true in release)
- ❌ `shrinkResources`: false (should be true in release)
- ❌ AAB split by ABI: Not configured
- ❌ ProGuard rules: Not configured

#### iOS
- Debug symbols: Not stripped
- Unused architectures: Not removed

### Current Build Sizes

| Build Type | Size | Status |
|------------|------|--------|
| Debug APK | ~1.8 GB | ❌ Unacceptable |
| Release APK | To be measured | ⏳ Pending |
| Release AAB | To be measured | ⏳ Pending |

### Target Goals

- **Initial Install**: < 100 MB
- **Offline Cache**: User-controlled, separate from APK
- **Sheet Music**: Remote only, no bundled files
- **Audio**: Already remote ✅

## Optimization Checklist

- [ ] Remove sheet music from assets
- [ ] Implement remote sheet music loading
- [ ] Subset font (Amharic + Latin only)
- [ ] Enable Android build optimizations
- [ ] Configure ProGuard rules
- [ ] Enable AAB split by ABI
- [ ] Compress background images
- [ ] Remove unused assets
- [ ] Strip debug symbols

## Post-Optimization Measurements

_To be updated after implementation_

