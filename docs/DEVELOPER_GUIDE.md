# Developer Guide - Amharic Hymnal App

## Table of Contents

1. [File Structure](#file-structure)
2. [Adding a New Language](#adding-a-new-language)
3. [Adding a New Hymnal Book](#adding-a-new-hymnal-book)
4. [API Integration](#api-integration)
5. [Sheet Music Integration](#sheet-music-integration)
6. [How Lyrics Search Works](#how-lyrics-search-works)
7. [Architecture Flow](#architecture-flow)
8. [Generating Models, DB Schema, Migrations](#generating-models-db-schema-migrations)
9. [Adding Categories (Many-to-Many)](#adding-categories-many-to-many)
10. [Adding Assets](#adding-assets)

---

## File Structure

### Core Architecture

```
lib/
├── core/                           # Shared code across features
│   ├── constants/                  # App-wide constants
│   │   └── asset_paths.dart       # Asset path definitions
│   ├── data/                       # Data layer infrastructure
│   │   └── repositories/          # Repository implementations
│   │       └── settings_repository_impl.dart
│   ├── database/                   # Bundled offline content
│   │   ├── json_data_source.dart  # Reads bundled JSON
│   │   ├── parsers/               # SDA and Hagerigna JSON parsers
│   │   ├── json_data_source.dart  # JSON asset loader
│   │   └── parsers/               # Data parsers
│   │       ├── hagerigna_parser.dart
│   │       └── sda_parser.dart
│   ├── domain/                     # Domain layer interfaces
│   │   ├── repositories/          # Repository interfaces
│   │   │   └── settings_repository.dart
│   │   └── usecases/              # Use case interfaces
│   │       └── get_settings.dart
│   ├── error/                      # Error handling
│   │   ├── error_handler.dart
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── l10n/                       # Localization
│   │   └── app_localizations.dart
│   ├── models/                     # Shared models
│   │   ├── database_config.dart   # Database configuration
│   ├── services/                   # Shared services
│   │   ├── amharic_phonetic_service.dart
│   │   ├── background_image_service.dart
│   │   ├── font_size_service.dart
│   │   ├── history_service.dart
│   │   ├── screen_service.dart
│   │   └── settings_service.dart
│   ├── theme/                      # Theming
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   ├── utils/                      # Utilities
│   │   ├── amharic_utils.dart     # Amharic text utilities
│   │   └── constants.dart         # App constants
│   └── widgets/                    # Reusable widgets
│       ├── empty_state_widget.dart
│       ├── error_widget.dart
│       ├── glass_container.dart   # Glassmorphism container
│       └── settings_tiles.dart    # Settings UI components
│
├── features/                       # Feature modules
│   ├── hymns/                      # Hymns feature
│   │   ├── data/                  # Data layer
│   │   │   ├── datasources/      # Data sources
│   │   │   │   ├── hymn_local_data_source.dart
│   │   │   │   └── local_data_source.dart
│   │   │   ├── mappers/          # Data mappers
│   │   │   │   └── hymn_mapper.dart
│   │   │   ├── models/           # Data models
│   │   │   │   ├── hymn_model.dart
│   │   │   │   └── hymn_model.g.dart # Generated
│   │   │   └── repositories/     # Repository implementations
│   │   │       └── hymn_repository_impl.dart
│   │   ├── domain/               # Domain layer
│   │   │   ├── entities/         # Domain entities
│   │   │   │   └── hymn.dart
│   │   │   ├── repositories/     # Repository interfaces
│   │   │   │   └── hymn_repository.dart
│   │   │   └── usecases/         # Use cases
│   │   │       ├── get_hymn_by_number.dart
│   │   │       ├── get_hymns.dart
│   │   │       ├── get_hymns_by_category.dart
│   │   │       └── search_hymns.dart
│   │   └── presentation/         # Presentation layer
│   │       ├── bloc/             # State management
│   │       │   ├── hymns_bloc.dart
│   │       │   ├── hymns_event.dart
│   │       │   └── hymns_state.dart
│   │       ├── pages/            # Pages
│   │       │   ├── hymn_detail_page.dart
│   │       │   ├── index_page.dart
│   │       │   ├── favorites_page.dart
│   │       │   └── ...
│   │       └── widgets/          # Feature widgets
│   │           ├── alphabet_scroll_bar.dart
│   │           ├── hymn_list_item.dart
│   │           └── sheet_music_viewer.dart
│   └── settings/                  # Settings feature
│       └── presentation/
│           └── pages/
│               └── report_bug_page.dart
│
└── main.dart                       # App entry point
```

### Key Design Principles

- **Clean Architecture**: Separation of concerns into data, domain, and presentation layers
- **Dependency Rule**: Inner layers (domain) don't depend on outer layers (data/presentation)
- **Repository Pattern**: Data access abstraction through repository interfaces
- **BLoC Pattern**: State management using flutter_bloc
- **Single Responsibility**: Each class/file has one clear purpose

---

## Content: Books, Languages, Audio and Sheet Music

Hymn content is not edited in this repository. The hymnal API
(`amharic_hymnal_backend`) owns every book (edition), its songs, categories,
audio and sheet-music pages; editors change them in that backend's `/admin`
console, and the app picks the changes up through `/sync`
(see `docs/architecture.md` and `docs/backend-plan.md`).

### Adding a book (edition)

1. Create and publish the edition in the backend
   (its `docs/multiple-hymn-versions.md`).
2. Nothing is needed in the app for it to appear: `HymnalVersionService`
   lists every edition from `/hymn-versions`, and `HymnalVersions.fromApiCode`
   turns a code such as `am-sda-2019` into the local ID `sda_2019`.
3. Only if the book should work offline before its first download, bundle a
   JSON copy under `assets/data/database/`, add a parser in
   `lib/core/database/parsers/`, and register it in `DatabaseRegistry`
   (`lib/core/models/database_config.dart`).
4. Give it a fixed label and order only if needed, in `HymnalVersions`
   (`lib/core/models/hymnal_version.dart`).

### Adding a language

1. The backend must serve the language (`language=<code>`); today it serves
   only `am`.
2. Add UI strings to `lib/core/l10n/app_localizations.dart` and the locale to
   `supportedLocales` in `lib/main.dart`.
3. `HymnalVersions.apiCode` prefixes codes with the language (`am-...`); check
   the new language's codes follow the same pattern.

### Audio and sheet music

Media is never bundled. Each song from the API names its files with a
checksum; the app downloads them on request, verifies them and caches them by
checksum (`docs/downloadable-media.md`). To add or replace media, publish it in
the backend.

### Categories

Categories belong to each edition in the backend and arrive on each song
(`EditionCategoriesService` reads their order). `HymnCategories`
(`lib/core/constants/hymn_categories.dart`) is only a fallback for 2004 hymns
without one.

## How Lyrics Search Works

### Search Implementation

**File**: `lib/features/hymns/domain/usecases/search_hymns.dart`

### Search Algorithm

1. **Input Processing**:
   - Convert search query to lowercase
   - Apply Amharic transliteration for compatibility

2. **Matching Logic**:
   ```dart
   bool matches = hymn.title.toLowerCase().contains(query) ||
                  hymn.lyrics.toLowerCase().contains(query);
   ```

3. **Amharic Sound-Alike Matching**:
   - Uses `AmharicPhoneticService` so letters that sound the same (ስ/ሥ, ሀ/ሐ/ኀ, ጸ/ፀ) match
   - `ScriptDetector` tells Fidel input from Latin input

4. **Sorting**:
   - **By Name**: Groups by first letter, sorts alphabetically
   - **By Number**: Numeric sort
   - **By Category**: Groups by category

### Sort-by-Name Algorithm

**File**: `lib/core/utils/amharic_utils.dart`

1. Extract first letter using `getPrimaryLetter()`
2. Group hymns by letter family
3. Sort letters according to Amharic alphabet order
4. Within each group, sort by title

### Search Indexing (Future Enhancement)

For large datasets, consider:
- Pre-built search index
- Trie data structure for prefix matching

---

## Architecture Flow

### Data Flow Diagram

```
UI (Presentation Layer)
    ↓ (User Action)
BLoC (State Management)
    ↓ (Event)
Use Case (Domain Layer)
    ↓ (Repository Interface)
Repository Implementation (Data Layer)
    ↓ (Data Source)
Local Data Source / Remote Data Source
    ↓ (Data Model)
Domain Entity
    ↓ (Back to UI)
State Update → UI Rebuild
```

### Example: Loading Hymns

1. **User Action**: Opens Index page
2. **UI**: `IndexPage` calls `context.read<HymnsBloc>().add(LoadHymns(...))`
3. **BLoC**: `HymnsBloc` handles `LoadHymns` event
4. **Use Case**: Calls `GetHymns` use case
5. **Repository**: `HymnRepositoryImpl` implements `GetHymns`
6. **Data Source**: `LocalDataSource` asks `HymnRemoteDataSource` (stored copy + API), then bundled JSON
7. **Model**: Returns `List<HymnModel>`
8. **Mapper**: Converts to `List<Hymn>` (domain entity)
9. **Repository**: Returns `Either<Failure, List<Hymn>>`
10. **BLoC**: Emits `HymnsLoaded` state
11. **UI**: `BlocBuilder` rebuilds with new state

### State Management Pattern

**BLoC Pattern**:
- **Events**: User actions (LoadHymns, SearchHymns, ToggleFavorite)
- **States**: UI states (HymnsLoading, HymnsLoaded, HymnsError)
- **BLoC**: Business logic coordinator

**Benefits**:
- Separation of UI and business logic
- Testable business logic
- Predictable state updates

---

## Code Generation

Only the JSON model uses generated code (`hymn_model.g.dart`, from
`json_serializable`). After changing `HymnModel`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

There is no local database, so there are no schema migrations. Stored
editions are versioned by `StoredEdition.schemaVersion`; a copy with another
version is ignored and downloaded again.

## Adding Assets



### Images

**Location**: `assets/images/`

**Types**:
- Background images: `assets/images/background.jpg`
- Icons: `assets/images/icons/`
- Hymn thumbnails: `assets/images/hymns/`

**pubspec.yaml**:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/images/icons/
    - assets/images/hymns/
```

**Code Usage**:

```dart
Image.asset('assets/images/background.jpg')
```



### Font Files

**Location**: `assets/fonts/`

**pubspec.yaml**:

```yaml
flutter:
  fonts:
    - family: NotoSansEthiopic
      fonts:
        - asset: assets/fonts/NotoSansEthiopic-Regular.ttf
        - asset: assets/fonts/NotoSansEthiopic-Bold.ttf
          weight: 700
```

### Best Practices

1. **Optimize Assets**: Compress images, use appropriate formats
2. **Lazy Loading**: Load assets on-demand, not all at startup
3. **Asset Naming**: Use consistent naming conventions
4. **Asset Organization**: Group by feature/type
5. **Asset Sizing**: Provide multiple resolutions for different screen densities

---

## Additional Resources

### Testing

- **Unit Tests**: `test/features/hymns/domain/usecases/`
- **Widget Tests**: `test/features/hymns/presentation/pages/`
- **Integration Tests**: `integration_test/`

### Code Generation

```bash
# Generate code for the JSON model
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for continuous generation
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Building

```bash
# Debug build
flutter run

# Release build (Android)
flutter build apk --release

# Release build (iOS)
flutter build ios --release
```

### Debugging

- Use `debugPrint()` for logging
- Enable verbose logging with `flutter run -v`
- Use Flutter DevTools for performance profiling

---

## Troubleshooting

### Content Issues

- **Old content after an edit**: the app refetches when the edition's `contentUpdatedAt` changes; edge caches can delay that by a minute
- **Start clean**: delete `content_cache/` (and `media_cache/`) under application support

### Performance Issues

- **Slow scrolling**: Check list optimization, use RepaintBoundary
- **Memory leaks**: Ensure proper disposal of controllers/listeners
- **Large lists**: Implement pagination or lazy loading

### Build Issues

- **Code generation errors**: Run `flutter pub run build_runner clean`
- **Dependency conflicts**: Run `flutter pub get` and check `pubspec.yaml`
- **Asset errors**: Verify asset paths in `pubspec.yaml`

---

## Contributing

1. Follow clean architecture principles
2. Write tests for new features
3. Update documentation
4. Follow naming conventions
5. Format code before committing

---

**Last Updated**: 2024
**Version**: 1.0.0


