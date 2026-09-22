# Handoff Documentation

## Quick Start for New Developers

This document provides a quick reference for developers joining the project. It covers top entry points, common tasks, and essential information.

> Hymn content, audio and sheet music now come from the hymnal API
> (`amharic_hymnal_backend`); see `docs/architecture.md`
> and `docs/downloadable-media.md`. Notes below about bundled sheet music under
> `assets/sheet_music/` describe the retired approach.

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
- Bottom navigation bar with 5 tabs: Categories, Index, Number search (home), Favorites, Settings
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
- Pinch-to-zoom (0.85x - 1.8x)
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

## How Content Is Added

Hymns, books, categories, audio and sheet music are managed in the hymnal
API's admin console (`amharic_hymnal_backend`), not in this repository. The
app shows changes after its next sync. See `docs/DEVELOPER_GUIDE.md` →
"Content: Books, Languages, Audio and Sheet Music".

The bundled `assets/data/database/SDA_Hymnal.json` and `HagerignaData.json`
are only the offline copy used before an edition's first download; refresh
them from the API before a release if they have drifted.

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
# JSON model (hymn_model.g.dart)
dart run build_runner build --delete-conflicting-outputs
```

## Key Files Reference

### Core Services

- `lib/core/services/font_size_service.dart`: Font size management
- `lib/core/services/sheet_music_discovery_service.dart`: Sheet music discovery
- `lib/core/services/background_image_service.dart`: Background image toggle
- `lib/core/services/settings_service.dart`: Settings persistence
- `lib/features/hymns/data/datasources/hymn_remote_data_source.dart`: API loading and delta sync
- `lib/features/hymns/data/datasources/edition_store.dart`: Editions stored on the device
- `lib/core/services/secure_storage_service.dart`: Secure storage for sensitive data
- `lib/core/services/bug_report_queue_service.dart`: Offline bug report queue

### Data Sources

- `lib/features/hymns/data/datasources/local_data_source.dart`: Primary data source
- `lib/core/database/json_data_source.dart`: JSON fallback

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

### 2. Check Stored Content

Stored editions are JSON files in `content_cache/` under the application
support directory; downloaded media is in `media_cache/`. Deleting either
forces a fresh download.

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
- **Content**: Hymnal API, stored per edition on the device, with bundled JSON as the first-run fallback
- **State Management**: BLoC pattern throughout
- **Architecture**: Clean Architecture with 3 layers
- **Performance**: Optimized for low-tier devices
