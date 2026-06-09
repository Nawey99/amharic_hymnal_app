# Handoff Documentation

## Quick Start for New Developers

This document provides a quick reference for developers joining the project. It covers top entry points, common tasks, and essential information.

## Top Entry Points

### 1. App Entry Point

**File**: `lib/main.dart`

**What it does**:
- Initializes dependencies
- Sets up app theme and localization
- Handles app initialization errors
- Initializes sheet music discovery service

**Key Code**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppInitializer());
}
```

### 2. Main Navigation

**File**: `lib/features/hymns/presentation/pages/main_navigation_page.dart`

**What it does**:
- Bottom navigation bar with 4 tabs
- Manages page state with `IndexedStack`
- Loads initial hymn data

**Pages**:
- Tab 0: `NumberSearchPage` (Home)
- Tab 1: `IndexPage` (Index/List)
- Tab 2: `FavoritesPage` (Favorites)
- Tab 3: `SettingsPage` (Settings)

### 3. Hymn Detail Page

**File**: `lib/features/hymns/presentation/pages/hymn_detail_page.dart`

**What it does**:
- Displays hymn lyrics with zoom
- Shows Amharic and English titles
- Handles favorite toggle
- Integrates sheet music viewer

**Key Features**:
- Pinch-to-zoom (0.8x - 2.0x)
- Swipe navigation between hymns
- Share functionality

### 4. State Management

**File**: `lib/features/hymns/presentation/bloc/hymns_bloc.dart`

**What it does**:
- Manages all hymn-related state
- Handles events (Load, Search, ToggleFavorite, etc.)
- Emits states (Loading, Loaded, Error)

**Usage**:
```dart
BlocProvider<HymnsBloc>(
  create: (context) => sl<HymnsBloc>(),
  child: YourWidget(),
)
```

### 5. Dependency Injection

**File**: `lib/injection_container.dart`

**What it does**:
- Registers all dependencies
- Provides singleton instances
- Initializes services

**Usage**:
```dart
final repository = sl<SettingsRepository>();
```

## How to Add a Hymn

### Current Process

Hymns are loaded from JSON assets or SQLite database. To add a new hymn:

1. **Edit JSON File**: `assets/data/database/SDA_Hymnal.json` or `HagerignaData.json`
2. **Add Hymn Object**:
   ```json
   {
     "id": "sda-999",
     "number": 999,
     "title": "New Hymn Title",
     "lyrics": "Hymn lyrics...",
     "category": "Praise",
     "new_hymnal_title": "New Title",
     "english_title_old": "English Title"
   }
   ```
3. **Run App**: Hymn will be loaded automatically
4. **Database**: Will be synced to database on next migration

### For Database-Only Hymns

```dart
// In database migration or seed script
await db.insertHymn(HymnTable(
  number: 999,
  title: 'New Hymn',
  lyrics: 'Lyrics...',
));
```

## How to Add a Book

See `docs/lyrics-feature.md` section "How to Add a New Hymnal Book" for detailed steps.

**Quick Summary**:
1. Create JSON data file in `assets/data/database/`
2. Register in `lib/core/models/database_config.dart`
3. Update settings dropdown
4. Test loading

## How to Add a Language

See `docs/lyrics-feature.md` section "How to Add a Language" for detailed steps.

**Quick Summary**:
1. Add language config in `lib/core/models/language_config.dart`
2. Create JSON data file
3. Update `pubspec.yaml` assets
4. Register database config
5. Add localization support
6. Test

## Common Tasks

### Running the App

```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Run on specific device
flutter run -d <device-id>

# Run in release mode
flutter run --release
```

### Running Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/widget_tests/favorite_toggle_test.dart

# Integration tests
flutter test integration_test/app_test.dart

# With coverage
flutter test --coverage
```

### Code Quality

```bash
# Format code
dart format .

# Analyze code
dart analyze

# Fix auto-fixable issues
dart fix --apply
```

### Generating Code

```bash
# Generate JSON serialization
flutter pub run build_runner build --delete-conflicting-outputs

# Generate Drift database code
flutter pub run build_runner build

# Watch mode (auto-regenerate on changes)
flutter pub run build_runner watch
```

## Key Files Reference

### Core Services

- `lib/core/services/font_size_service.dart`: Font size management
- `lib/core/services/sheet_music_discovery_service.dart`: Sheet music discovery
- `lib/core/services/background_image_service.dart`: Background image toggle
- `lib/core/services/settings_service.dart`: Settings persistence
- `lib/core/services/offline_cache_service.dart`: Offline data caching
- `lib/core/services/sync_service.dart`: Background sync operations
- `lib/core/services/secure_storage_service.dart`: Secure storage for sensitive data
- `lib/core/services/bug_report_queue_service.dart`: Offline bug report queue

### Data Sources

- `lib/features/hymns/data/datasources/local_data_source.dart`: Primary data source
- `lib/core/database/json_data_source.dart`: JSON fallback
- `lib/core/database/database_helper.dart`: SQLite operations

### Widgets

- `lib/core/widgets/search_bar.dart`: Reusable search bar
- `lib/core/widgets/glass_container.dart`: Glassmorphism container
- `lib/core/widgets/settings_tiles.dart`: Settings UI components

### Pages

- `lib/features/hymns/presentation/pages/hymn_detail_page.dart`: Lyrics page
- `lib/features/hymns/presentation/pages/index_page.dart`: Hymn list
- `lib/features/hymns/presentation/pages/favorites_page.dart`: Favorites
- `lib/features/hymns/presentation/pages/settings_page.dart`: Settings

## Architecture Quick Reference

### Layer Responsibilities

- **Presentation**: UI, state management, user interactions
- **Domain**: Business logic, entities, use cases
- **Data**: Data sources, repositories, models

### Data Flow

```
UI → BLoC → UseCase → Repository → DataSource
                ↑
            Domain Layer
                ↑
         Data Layer
```

### State Management

- **BLoC**: Complex state (hymns list, search)
- **ListenableBuilder**: Simple reactive state (font size, background)
- **setState**: Local widget state only

## Debugging Tips

### 1. Check BLoC State

```dart
BlocBuilder<HymnsBloc, HymnsState>(
  builder: (context, state) {
    print('Current state: $state'); // Debug
    // ...
  },
)
```

### 2. Check Database

```dart
final db = DatabaseHelper.instance;
print('Database ready: ${db.isReady}');
```

### 3. Check Sheet Music Discovery

```dart
final service = SheetMusicDiscoveryService();
print('Hymns with sheet music: ${service.getHymnsWithSheetMusic()}');
```

### 4. Performance Profiling

```bash
# Run with performance overlay
flutter run --profile

# Check frame times in Flutter DevTools
```

## Common Issues & Solutions

### Issue: Hymns Not Loading

**Solution**:
1. Check database is initialized
2. Verify JSON file exists and is valid
3. Check database migration version
4. Review error logs

### Issue: Sheet Music Not Showing

**Solution**:
1. Verify files in `assets/sheet_music/`
2. Check `pubspec.yaml` includes `assets/sheet_music/`
3. Verify discovery service initialized
4. Check file naming convention matches

### Issue: Bottom Overflow

**Solution**:
1. Ensure `SafeArea` wrapper
2. Use `Flexible`/`Expanded` instead of fixed heights
3. Test on small screen size (360x640)
4. Check `CustomScrollView` constraints

### Issue: Favorite Toggle Not Working

**Solution**:
1. Check `GestureDetector` behavior
2. Verify no gesture conflicts
3. Check BLoC event handling
4. Review SharedPreferences access

## Testing Checklist

Before committing:

- [ ] All tests pass (`flutter test`)
- [ ] No linter errors (`dart analyze`)
- [ ] Code formatted (`dart format .`)
- [ ] Tested on small phone (360x640)
- [ ] Tested with max font scaling (2.0x)
- [ ] Tested favorite toggle
- [ ] Tested search functionality
- [ ] Tested sheet music loading
- [ ] Tested pinch-to-zoom

## Next Steps

1. Read `docs/lyrics-feature.md` for feature details
2. Read `docs/architecture.md` for architecture overview
3. Review `docs/DEVELOPER_GUIDE.md` for comprehensive guide
4. Explore codebase starting with entry points above

## Getting Help

- **Documentation**: Check `docs/` directory
- **Code Comments**: Review inline documentation
- **Tests**: See `test/` for usage examples
- **PR Summary**: See `PR_SUMMARY.md` for recent changes

## Important Notes

- **Sheet Music Path**: Uses `assets/sheet_music/` (with underscore), not `assets/sheetmusic/`
- **Database**: Uses Drift (SQLite) with JSON fallback
- **State Management**: BLoC pattern throughout
- **Architecture**: Clean Architecture with 3 layers
- **Performance**: Optimized for low-tier devices

