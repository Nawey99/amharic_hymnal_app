# Sheet Music File Organization Guide

## Overview
This guide explains how to organize, name, and save sheet music files so the app can automatically identify and display them.

---

## 📁 File Location Options

### Option 1: Assets Folder (Recommended for App Bundle)
**Location**: `assets/sheet_music/`

**Pros**:
- Files are bundled with the app
- No download needed
- Works offline immediately
- Good for core/default sheet music

**Cons**:
- Increases app size
- Cannot update without app update
- Limited to files included at build time

**Use When**: You have a standard set of sheet music that comes with the app.

### Option 2: Documents Directory (Recommended for Downloads)
**Location**: App's documents directory (managed by app)

**Pros**:
- Can download/update without app update
- Doesn't increase initial app size
- Can be managed dynamically
- Good for user-added or updated sheet music

**Cons**:
- Requires download mechanism
- Needs internet connection for initial download
- More complex file management

**Use When**: You want to support downloadable sheet music or user-uploaded files.

---

## 📝 File Naming Convention

### For Single-Page Sheet Music

**Pattern**: `{hymn_id}_{page_number}.{extension}`

**Examples**:
```
sda-1_1.jpg          → SDA Hymnal, Hymn 1, Page 1
sda-1_1.png          → SDA Hymnal, Hymn 1, Page 1 (PNG version)
hagerigna-5_1.jpg    → Hagerigna, Hymn 5, Page 1
```

### For Multi-Page Sheet Music (2+ Pages)

**Pattern**: `{hymn_id}_{page_number}.{extension}`

**Examples**:
```
sda-15_1.jpg         → SDA Hymnal, Hymn 15, Page 1
sda-15_2.jpg         → SDA Hymnal, Hymn 15, Page 2
hagerigna-42_1.png   → Hagerigna, Hymn 42, Page 1
hagerigna-42_2.png   → Hagerigna, Hymn 42, Page 2
```

### Naming Rules:
1. **Hymn ID Format**: Use the same ID format as in the database
   - SDA Hymnal: `sda-{number}` (e.g., `sda-1`, `sda-15`)
   - Hagerigna: `hagerigna-{number}` (e.g., `hagerigna-5`, `hagerigna-42`)

2. **Page Number**: Always start from `1`
   - Single page: `_1`
   - Two pages: `_1` and `_2`
   - Three pages: `_1`, `_2`, `_3` (if needed)

3. **File Extension**: Use lowercase (`.jpg`, `.png`, `.pdf`)

4. **No Spaces**: Use hyphens or underscores, never spaces

---

## 🖼️ File Format Recommendations

### JPG/JPEG (✅ Good for Photos)
**Best For**: Scanned/photographed sheet music

**Pros**:
- Smaller file size
- Good compression
- Widely supported
- Good for photos of physical sheet music

**Cons**:
- Lossy compression (may lose some quality)
- Not ideal for text-heavy content

**Recommendation**: ✅ **Use JPG for scanned/photographed sheet music**

### PNG (✅ Best for Digital Sheet Music)
**Best For**: Digitally created or high-quality scans

**Pros**:
- Lossless compression (perfect quality)
- Excellent for text and sharp lines
- Supports transparency
- Better for digital sheet music

**Cons**:
- Larger file size than JPG
- Not ideal for photos

**Recommendation**: ✅ **Use PNG for digitally created or high-quality sheet music**

### PDF (✅ Best for Multi-Page Documents)
**Best For**: Multi-page sheet music, professional documents

**Pros**:
- Single file for multiple pages
- Professional format
- Scalable (vector support)
- Standard for music publishing

**Cons**:
- Requires PDF viewer library
- Larger file size
- More complex to implement

**Recommendation**: ✅ **Use PDF for multi-page professional sheet music**

### WebP (⚠️ Optional)
**Best For**: Modern apps wanting smaller file sizes

**Pros**:
- Better compression than JPG/PNG
- Good quality
- Supported by Flutter

**Cons**:
- Less universal support
- May require conversion

**Recommendation**: ⚠️ **Optional - Use if you want smaller file sizes**

---

## 📂 Directory Structure

### Recommended Structure (Assets Folder)

```
assets/
  sheet_music/
    sda/                    # SDA Hymnal sheet music
      sda-1_1.jpg
      sda-1_2.jpg          # If hymn 1 has 2 pages
      sda-15_1.png
      sda-15_2.png
    hagerigna/             # Hagerigna sheet music
      hagerigna-5_1.jpg
      hagerigna-42_1.png
      hagerigna-42_2.png
```

### Alternative: Flat Structure

```
assets/
  sheet_music/
    sda-1_1.jpg
    sda-1_2.jpg
    sda-15_1.png
    hagerigna-5_1.jpg
    hagerigna-42_1.png
    hagerigna-42_2.png
```

**Recommendation**: Use **subdirectories** (`sda/` and `hagerigna/`) for better organization.

---

## 🔧 Implementation Steps

### Step 1: Add Files to Assets

1. **Create directory structure**:
   ```
   assets/sheet_music/sda/
   assets/sheet_music/hagerigna/
   ```

2. **Save your files** with the naming convention:
   - Example: `sda-1_1.jpg`, `sda-1_2.jpg` (if 2 pages)

3. **Update `pubspec.yaml`**:
   ```yaml
   flutter:
     assets:
       - assets/sheet_music/
       # Or specifically:
       - assets/sheet_music/sda/
       - assets/sheet_music/hagerigna/
   ```

### Step 2: Register Files in Database

Once the Sheet Music system is implemented (see `DATABASE_EXPANSION.md`), you'll register files like this:

**Example Migration Script**:
```dart
// lib/core/database/sheet_music_migration.dart

Future<void> addSheetMusicFromAssets() async {
  final db = DatabaseHelper.instance.database;
  final now = DateTime.now().millisecondsSinceEpoch;
  
  // Example: SDA Hymnal Hymn 1 with 2 pages
  await db.insertSheetMusic(
    SheetMusicCompanion.insert(
      id: 'sheet_music_sda-1_1',
      hymnId: 'sda-1',
      filePath: 'assets/sheet_music/sda/sda-1_1.jpg',
      fileType: 'image',  // or 'pdf' for PDF files
      order: 0,  // First page (primary)
      createdAt: now,
      updatedAt: now,
    ),
  );
  
  await db.insertSheetMusic(
    SheetMusicCompanion.insert(
      id: 'sheet_music_sda-1_2',
      hymnId: 'sda-1',
      filePath: 'assets/sheet_music/sda/sda-1_2.jpg',
      fileType: 'image',
      order: 1,  // Second page (secondary)
      createdAt: now,
      updatedAt: now,
    ),
  );
  
  // Example: Hagerigna Hymn 5 with 1 page
  await db.insertSheetMusic(
    SheetMusicCompanion.insert(
      id: 'sheet_music_hagerigna-5_1',
      hymnId: 'hagerigna-5',
      filePath: 'assets/sheet_music/hagerigna/hagerigna-5_1.png',
      fileType: 'image',
      order: 0,  // Only page (primary)
      createdAt: now,
      updatedAt: now,
    ),
  );
}
```

### Step 3: Automatic File Detection (Helper Function)

Create a helper function to automatically detect sheet music files:

```dart
// lib/core/utils/sheet_music_helper.dart

class SheetMusicHelper {
  /// Automatically detect sheet music files for a hymn
  /// Returns list of file paths in order (page 1, page 2, etc.)
  static List<String> detectSheetMusicFiles(String hymnId) {
    final List<String> files = [];
    
    // Check for page 1
    final page1Jpg = 'assets/sheet_music/${_getSubdirectory(hymnId)}/$hymnId_1.jpg';
    final page1Png = 'assets/sheet_music/${_getSubdirectory(hymnId)}/$hymnId_1.png';
    final page1Pdf = 'assets/sheet_music/${_getSubdirectory(hymnId)}/$hymnId_1.pdf';
    
    // Try JPG first, then PNG, then PDF
    if (_fileExists(page1Jpg)) {
      files.add(page1Jpg);
    } else if (_fileExists(page1Png)) {
      files.add(page1Png);
    } else if (_fileExists(page1Pdf)) {
      files.add(page1Pdf);
      return files; // PDF usually contains all pages
    }
    
    // Check for page 2
    final page2Jpg = 'assets/sheet_music/${_getSubdirectory(hymnId)}/$hymnId_2.jpg';
    final page2Png = 'assets/sheet_music/${_getSubdirectory(hymnId)}/$hymnId_2.png';
    
    if (_fileExists(page2Jpg)) {
      files.add(page2Jpg);
    } else if (_fileExists(page2Png)) {
      files.add(page2Png);
    }
    
    // Check for page 3 (if needed)
    final page3Jpg = 'assets/sheet_music/${_getSubdirectory(hymnId)}/$hymnId_3.jpg';
    if (_fileExists(page3Jpg)) {
      files.add(page3Jpg);
    }
    
    return files;
  }
  
  static String _getSubdirectory(String hymnId) {
    if (hymnId.startsWith('sda-')) {
      return 'sda';
    } else if (hymnId.startsWith('hagerigna-')) {
      return 'hagerigna';
    }
    return '';
  }
  
  static bool _fileExists(String path) {
    // Check if asset exists (implementation depends on your asset loading method)
    // This is a placeholder - actual implementation would check asset bundle
    return true; // Simplified
  }
  
  /// Get file type from extension
  static String getFileType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'pdf';
      case 'png':
      case 'jpg':
      case 'jpeg':
        return 'image';
      default:
        return 'image';
    }
  }
}
```

---

## 📋 Complete Example: Two-Page Sheet Music

### File Structure:
```
assets/
  sheet_music/
    sda/
      sda-15_1.jpg    # Page 1
      sda-15_2.jpg    # Page 2
```

### Database Registration:
```dart
// Register both pages for hymn sda-15
await db.insertSheetMusic(
  SheetMusicCompanion.insert(
    id: 'sheet_music_sda-15_1',
    hymnId: 'sda-15',
    filePath: 'assets/sheet_music/sda/sda-15_1.jpg',
    fileType: 'image',
    order: 0,  // Page 1
    createdAt: now,
    updatedAt: now,
  ),
);

await db.insertSheetMusic(
  SheetMusicCompanion.insert(
    id: 'sheet_music_sda-15_2',
    hymnId: 'sda-15',
    filePath: 'assets/sheet_music/sda/sda-15_2.jpg',
    fileType: 'image',
    order: 1,  // Page 2
    createdAt: now,
    updatedAt: now,
  ),
);
```

### App Display:
The app will automatically:
1. Load both pages in order (page 1, then page 2)
2. Display them sequentially
3. Allow swiping between pages
4. Show page indicators (1/2, 2/2)

---

## ✅ Best Practices

### 1. File Naming
- ✅ Use consistent naming: `{hymn_id}_{page_number}.{ext}`
- ✅ Always start page numbers from 1
- ✅ Use lowercase extensions
- ❌ Don't use spaces in filenames
- ❌ Don't skip page numbers (don't use `_1` and `_3` without `_2`)

### 2. File Format
- ✅ **JPG**: For scanned/photographed sheet music
- ✅ **PNG**: For digital/high-quality sheet music
- ✅ **PDF**: For multi-page professional documents
- ❌ Avoid: GIF, BMP, TIFF (not well supported or too large)

### 3. File Organization
- ✅ Use subdirectories (`sda/`, `hagerigna/`)
- ✅ Keep files organized by hymnal version
- ✅ Use consistent naming across all files

### 4. File Size
- ✅ Optimize images before adding (compress JPG/PNG)
- ✅ Aim for 200KB - 1MB per page
- ✅ Use appropriate resolution (150-300 DPI for sheet music)
- ❌ Avoid: Files larger than 5MB per page

### 5. Quality
- ✅ Ensure text is readable
- ✅ Use high enough resolution for zooming
- ✅ Maintain aspect ratio
- ✅ Ensure good contrast

---

## 🔍 Quick Reference

### Single-Page Sheet Music
```
File: sda-1_1.jpg
Path: assets/sheet_music/sda/sda-1_1.jpg
Order: 0
```

### Two-Page Sheet Music
```
File 1: sda-15_1.jpg → Order: 0 (Page 1)
File 2: sda-15_2.jpg → Order: 1 (Page 2)
Path: assets/sheet_music/sda/
```

### Three-Page Sheet Music (if needed)
```
File 1: hagerigna-42_1.png → Order: 0
File 2: hagerigna-42_2.png → Order: 1
File 3: hagerigna-42_3.png → Order: 2
```

---

## 🚀 Next Steps

1. **Prepare your sheet music files**:
   - Scan or create digital versions
   - Optimize file size and quality
   - Name them according to the convention

2. **Organize files**:
   - Create `assets/sheet_music/sda/` directory
   - Create `assets/sheet_music/hagerigna/` directory
   - Place files in appropriate directories

3. **Update pubspec.yaml**:
   ```yaml
   assets:
     - assets/sheet_music/
   ```

4. **Run the app**:
   - Files will be available as assets
   - Once Sheet Music system is implemented, register them in database

5. **Test**:
   - Verify files load correctly
   - Test multi-page navigation
   - Check zoom functionality

---

## ❓ FAQ

**Q: Can I mix JPG and PNG for the same hymn?**
A: Yes, but it's better to be consistent. Use the same format for all pages of the same hymn.

**Q: What if a hymn has more than 2 pages?**
A: Just continue the numbering: `_1`, `_2`, `_3`, `_4`, etc. The app will handle any number of pages.

**Q: Should I use PDF for multi-page sheet music?**
A: PDF is great for multi-page documents, but separate image files give more control. Use PDF if you have a single multi-page document, use separate images if you want more flexibility.

**Q: What resolution should I use?**
A: 150-300 DPI is ideal. For a typical sheet music page (8.5" x 11"), that's about 1275x1650 to 2550x3300 pixels.

**Q: Can I update sheet music files after the app is published?**
A: If using assets folder, you need to update the app. If using documents directory, you can download updates dynamically.

---

## 📝 Summary

1. **Location**: `assets/sheet_music/{sda|hagerigna}/`
2. **Naming**: `{hymn_id}_{page_number}.{ext}` (e.g., `sda-1_1.jpg`)
3. **Format**: JPG (scanned), PNG (digital), or PDF (multi-page)
4. **Multi-page**: Use `_1`, `_2`, etc. for page numbers
5. **Order**: Register in database with `order: 0` for page 1, `order: 1` for page 2, etc.

**Example Structure**:
```
assets/sheet_music/
  sda/
    sda-1_1.jpg      ← Single page
    sda-15_1.jpg     ← Page 1 of 2
    sda-15_2.jpg     ← Page 2 of 2
  hagerigna/
    hagerigna-5_1.png
    hagerigna-42_1.png
    hagerigna-42_2.png
```



