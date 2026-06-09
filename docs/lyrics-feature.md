# Lyrics Feature Documentation

## Overview

The lyrics feature is the core functionality of the Amharic Hymnal app, allowing users to view, search, and interact with hymn lyrics. This document provides comprehensive information about the lyrics feature implementation, including file structure, responsibilities, and how to extend it.

## File Map & Responsibilities

### Core Files

#### Presentation Layer

- **`lib/features/hymns/presentation/pages/hymn_detail_page.dart`**
  - **Responsibility**: Main lyrics display page
  - **Key Features**:
    - Displays Amharic and English titles
    - Pinch-to-zoom functionality (0.8x - 2.0x)
    - Favorite toggle
    - Share functionality
    - Sheet music integration
  - **Key Methods**:
    - `_buildTitleSection()`: Renders hymn title (Amharic + English)
    - `_buildLyricsSection()`: Renders lyrics with zoom support
    - `_handleZoomInteractionWithAnimation()`: Handles zoom with smooth animation
    - `_buildFavoriteButton()`: Favorite toggle with optimistic UI

#### Domain Layer

- **`lib/features/hymns/domain/entities/hymn.dart`**
  - **Responsibility**: Domain entity representing a hymn
  - **Key Properties**:
    - `displayTitle`: Amharic title (with fallback logic)
    - `englishTitleOld`: English title
    - `displayLyrics`: Lyrics text
    - `displayNumber`: Hymn number
    - `isFavorite`: Favorite status
  - **Key Getters**:
    - `displayTitle`: Returns best available title (newHymnalTitle > title > oldHymnalTitle)
    - `displayLyrics`: Returns best available lyrics with proper newline conversion

#### Data Layer

- **`lib/features/hymns/data/datasources/local_data_source.dart`**
  - **Responsibility**: Data source for hymns (JSON + SQLite)
  - **Key Methods**:
    - `getHymns()`: Loads hymns from database or JSON fallback
    - `_mapJsonToHymnModel()`: Maps JSON to HymnModel
    - `_mapRowToHymnModel()`: Maps database row to HymnModel
  - **Sheet Music Integration**: Auto-discovers sheet music via `SheetMusicDiscoveryService`

#### State Management

- **`lib/features/hymns/presentation/bloc/hymns_bloc.dart`**
  - **Responsibility**: BLoC for hymn state management
  - **Key Events**:
    - `LoadHymns`: Load all hymns
    - `SearchHymnsEvent`: Search hymns by query
    - `ToggleFavorite`: Toggle favorite status
    - `GetHymnByNumberEvent`: Get specific hymn by number
  - **Key States**:
    - `HymnsLoaded`: Hymns successfully loaded
    - `HymnsLoading`: Loading in progress
    - `HymnsError`: Error state

### Supporting Files

- **`lib/core/services/font_size_service.dart`**
  - Manages font size state reactively
  - Clamps values to 12.0 - 30.0 range
  - Notifies listeners on changes

- **`lib/core/theme/app_theme.dart`**
  - `getLineHeight()`: Dynamic line height based on font size
  - `getLetterSpacing()`: Dynamic letter spacing based on font size

- **`lib/core/utils/constants.dart`**
  - `minZoomScale`: 0.8
  - `maxZoomScale`: 2.0
  - `minFontSize`: 12.0
  - `maxFontSize`: 30.0

## Architecture Flow

### Loading Hymns

```
User Action
    ↓
HymnsBloc.add(LoadHymns)
    ↓
GetHymns UseCase
    ↓
HymnRepository.getHymns()
    ↓
LocalDataSource.getHymns()
    ↓
[Database Ready?]
    ├─ Yes → DatabaseHelper.getHymns()
    └─ No → JsonDataSource.getHymns()
    ↓
HymnMapper.toDomainList()
    ↓
HymnsBloc.emit(HymnsLoaded)
    ↓
UI Updates (BlocBuilder)
```

### Pinch-to-Zoom Flow

```
User Pinch Gesture
    ↓
InteractiveViewer (minScale: 0.8, maxScale: 2.0)
    ↓
onInteractionEnd
    ↓
_handleZoomInteractionWithAnimation()
    ↓
Clamp Scale (0.8 - 2.0)
    ↓
Update FontSizeService
    ↓
UI Rebuilds with New Font Size
```

### Favorite Toggle Flow

```
User Tap Favorite Button
    ↓
GestureDetector.onTap (immediate visual feedback)
    ↓
HymnsBloc.add(ToggleFavorite)
    ↓
_onToggleFavorite()
    ├─ Update SharedPreferences (optimistic)
    ├─ Emit HymnsLoaded (instant UI update)
    └─ Update Database (background, non-blocking)
    ↓
UI Updates Instantly
```

## How to Add a Language

### Step 1: Add Language Configuration

1. **Update `lib/core/models/language_config.dart`**:
   ```dart
   static const Map<String, LanguageConfig> languages = {
     'am': LanguageConfig(
       code: 'am',
       name: 'Amharic',
       // ... existing config
     ),
     'en': LanguageConfig(  // NEW
       code: 'en',
       name: 'English',
       // ... config
     ),
   };
   ```

2. **Add JSON Data File**:
   - Create `assets/data/database/EnglishData.json`
   - Follow same structure as `SDA_Hymnal.json`

3. **Update `pubspec.yaml`**:
   ```yaml
   assets:
     - assets/data/database/EnglishData.json
   ```

4. **Register Database**:
   - Update `lib/core/models/database_config.dart`
   - Add database config for new language

### Step 2: Add Localization

1. **Update `lib/core/l10n/app_localizations.dart`**:
   ```dart
   static const List<Locale> supportedLocales = [
     Locale('am'),
     Locale('en'), // NEW
   ];
   ```

2. **Generate Localization Files**:
   ```bash
   flutter gen-l10n
   ```

### Step 3: Test

```bash
flutter test
flutter run
```

## How to Add a New Hymnal Book

### Step 1: Prepare JSON Data

1. **Create JSON File**:
   - Format: `assets/data/database/{BookName}Data.json`
   - Structure: Array of hymn objects
   - Required fields: `id`, `number`, `title`, `lyrics`

2. **Example Structure**:
   ```json
   [
     {
       "id": "bookname-1",
       "number": 1,
       "title": "Hymn Title",
       "lyrics": "Hymn lyrics...",
       "category": "Praise",
       "sheet_music": ["01.jpg"]
     }
   ]
   ```

### Step 2: Register in Database Config

**File**: `lib/core/models/database_config.dart`

```dart
static DatabaseConfig? getDatabase(String languageCode, String version) {
  final configs = {
    'am-hymnal': DatabaseConfig(
      languageCode: 'am',
      version: 'hymnal',
      jsonAssetPath: 'assets/data/database/SDA_Hymnal.json',
      // ...
    ),
    'am-newbook': DatabaseConfig(  // NEW
      languageCode: 'am',
      version: 'newbook',
      jsonAssetPath: 'assets/data/database/NewBookData.json',
      // ...
    ),
  };
  return configs['$languageCode-$version'];
}
```

### Step 3: Update Settings

**File**: `lib/features/hymns/presentation/pages/settings_page.dart`

Add new version option to dropdown:
```dart
DropdownMenuItem<String>(
  value: 'newbook',
  child: Text('New Book'),
),
```

### Step 4: Run Migration (if needed)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## How Sheet Music is Discovered

### File Naming Convention

Sheet music files are located in `assets/sheet_music/` and follow these patterns:

- **Single Page**: `<songNumber>.<ext>`
  - Examples: `01.jpg`, `5.png`, `123.pdf`
  - Labeled as: `1`

- **Two Pages**: `<songNumber>L.<ext>` and `<songNumber>R.<ext>`
  - Examples: `08L.jpg`, `08R.jpg`
  - Labeled as: `2L` and `2R`

- **Special Cases**: `73,74L.jpg` (handled by discovery service)

### Discovery Process

1. **Service**: `lib/core/services/sheet_music_discovery_service.dart`
2. **Initialization**: Called in `main.dart` at app startup (non-blocking)
3. **Process**:
   ```
   Load AssetManifest.json
       ↓
   Filter assets/sheet_music/*.{jpg,png,pdf}
       ↓
   Parse filename to extract hymn number
       ↓
   Group by hymn number
       ↓
   Sort: L files before R files
       ↓
   Cache in memory
   ```

4. **Integration**: `LocalDataSource` automatically uses discovered files for SDA Hymnal

### How to Add Sheet Music Assets

1. **Place Files**:
   ```
   assets/sheet_music/
   ├── 01.jpg          (single page)
   ├── 08L.jpg         (left page)
   ├── 08R.jpg         (right page)
   └── 99.png          (single page)
   ```

2. **Update `pubspec.yaml`**:
   ```yaml
   assets:
     - assets/sheet_music/
   ```

3. **Run App**: Discovery happens automatically on startup

4. **Verify**: Check debug logs for discovery results

## How to Tune Pinch-to-Zoom Properties

### Current Defaults

**File**: `lib/core/utils/constants.dart`

```dart
static const double minZoomScale = 0.8;  // Minimum zoom
static const double maxZoomScale = 2.0;  // Maximum zoom
static const double scaleSensitivity = 1.0;  // Responsiveness multiplier
static const Duration animationDurationOnRelease = Duration(milliseconds: 200);
```

### Tuning Guidelines

1. **For More Responsive Zoom**:
   - Increase `scaleSensitivity` (e.g., 1.2)
   - Location: `lib/core/utils/constants.dart`

2. **For Slower Animation**:
   - Increase `animationDurationOnRelease` (e.g., 300ms)
   - Location: `lib/core/utils/constants.dart`

3. **For Different Zoom Range**:
   - Adjust `minZoomScale` / `maxZoomScale`
   - Location: `lib/core/utils/constants.dart`
   - Also update: `lib/features/hymns/presentation/pages/hymn_detail_page.dart` (InteractiveViewer)

### Implementation Location

**File**: `lib/features/hymns/presentation/pages/hymn_detail_page.dart`

```dart
InteractiveViewer(
  minScale: AppConstants.minZoomScale,  // 0.8
  maxScale: AppConstants.maxZoomScale,    // 2.0
  onInteractionEnd: (_) => _handleZoomInteractionWithAnimation(),
  // ...
)
```

## How to Run Device-Specific Checks

### Test Helper

**File**: `test/widget_test_helper.dart` (create if needed)

```dart
Widget createTestApp(Widget child) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(360, 640), // Small phone
        textScaler: TextScaler.linear(1.0),
      ),
      child: child,
    ),
  );
}

// Device sizes
const smallPhone = Size(360, 640);   // Low-tier
const mediumPhone = Size(414, 896);  // Mid-tier
const largePhone = Size(428, 926);  // High-tier
```

### Widget Test Example

```dart
testWidgets('No bottom overflow on small phone', (tester) async {
  await tester.binding.setSurfaceSize(smallPhone);
  await tester.pumpWidget(createTestApp(HymnDetailPage(hymn: testHymn)));
  await tester.pumpAndSettle();
  
  // Verify no overflow
  expect(tester.takeException(), isNull);
});
```

### Manual Testing

1. **Run on Emulator**:
   ```bash
   flutter run -d <device-id>
   ```

2. **Test Different Sizes**:
   - Small: 360x640
   - Medium: 414x896
   - Large: 428x926

3. **Check for Overflows**:
   - Look for "BOTTOM OVERFLOWED BY X PIXELS" in debug console
   - Test with max font scaling (2.0x)

## How to Test Favorites Toggle

### Widget Test

**File**: `test/widget_tests/favorite_toggle_test.dart`

```dart
testWidgets('Favorite toggles with single tap', (tester) async {
  // Setup
  final testHymn = Hymn(/* ... */);
  await tester.pumpWidget(/* ... */);
  
  // Find button
  final favoriteButton = find.byIcon(Icons.favorite_border);
  
  // Tap once
  await tester.tap(favoriteButton);
  await tester.pump();
  
  // Verify immediate update
  expect(find.byIcon(Icons.favorite), findsOneWidget);
});
```

### Manual Test

1. Open any hymn
2. Tap favorite button once
3. Verify icon changes immediately (no delay)
4. Navigate away and back
5. Verify favorite status persisted

## How to Test Search/Index Independence

### Test Scenario

1. **On Home Page (NumberSearchPage)**:
   - Enter search query: "5"
   - Verify search results show

2. **Navigate to Index Page**:
   - Tap Index tab
   - Verify full hymn list is shown (not filtered by "5")

3. **On Index Page**:
   - Enter search query: "test"
   - Verify Index page shows filtered results

4. **Navigate Back to Home**:
   - Verify Home page still shows its own search results

### Widget Test

```dart
testWidgets('Index page independent of Home search', (tester) async {
  // Setup Home search
  // ... search on Home page
  
  // Navigate to Index
  // ... tap Index tab
  
  // Verify Index shows full list
  expect(find.text('Full List Item'), findsWidgets);
});
```

## Code Snippets

### Adding English Title Display

**File**: `lib/features/hymns/presentation/pages/hymn_detail_page.dart`

```dart
Widget _buildTitleSection(Hymn hymn, double fontSize) {
  return GlassContainer(
    // ...
    child: Row(
      children: [
        _buildNumberBadge(hymn.displayNumber, fontSize),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleText(hymn.displayTitle, fontSize),
              _buildEnglishTitleText(hymn.englishTitleOld, fontSize),
            ],
          ),
        ),
      ],
    ),
  );
}
```

### Implementing Pinch-to-Zoom

```dart
InteractiveViewer(
  transformationController: _transformationController,
  minScale: AppConstants.minZoomScale,
  maxScale: AppConstants.maxZoomScale,
  onInteractionEnd: (_) => _handleZoomInteractionWithAnimation(),
  panEnabled: isZoomed,
  child: SelectableText(/* lyrics */),
)
```

## CLI Commands

### Run Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/widget_tests/favorite_toggle_test.dart

# Integration tests
flutter test integration_test/app_test.dart
```

### Format Code

```bash
dart format .
```

### Analyze Code

```bash
dart analyze
```

### Generate Code

```bash
# Generate JSON serialization
flutter pub run build_runner build --delete-conflicting-outputs

# Generate Drift database code
flutter pub run build_runner build
```

## Troubleshooting

### Lyrics Not Displaying

1. Check `hymn.displayLyrics` is not empty
2. Verify JSON data has `lyrics` field
3. Check database migration completed

### Pinch-to-Zoom Not Working

1. Verify `_transformationController` is initialized
2. Check `InteractiveViewer` constraints
3. Ensure `panEnabled` is true when zoomed

### Favorite Toggle Requires Multiple Taps

1. Check `GestureDetector` behavior
2. Verify no gesture conflicts
3. Ensure `HitTestBehavior.opaque` is set

### Bottom Overflow on Mobile

1. Verify `SafeArea` wrapper
2. Check `CustomScrollView` constraints
3. Test with different screen sizes

### Offline Functionality

1. App works fully offline with local data (JSON + SQLite)
2. Bug reports are queued when offline and submitted when online
3. Sync service is prepared for future API integration
4. Offline cache service manages data expiration

## PR Checklist

- [ ] All tests pass
- [ ] No linter errors
- [ ] Code formatted
- [ ] Accessibility labels added
- [ ] Font scaling tested (1.0x - 2.0x)
- [ ] Mobile layouts tested (small/medium/large)
- [ ] Pinch-to-zoom tested
- [ ] Favorite toggle tested
- [ ] Search independence verified

