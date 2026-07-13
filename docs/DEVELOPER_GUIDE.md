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
│   ├── database/                   # Database layer
│   │   ├── app_database.dart      # Drift database definition
│   │   ├── database_helper.dart   # Database operations wrapper
│   │   ├── database_migration.dart # Migration logic
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
│   │   └── language_config.dart   # Language configuration
│   ├── services/                   # Shared services
│   │   ├── amharic_transliteration_service.dart
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

## Adding a New Language

### Step 1: Add Language Configuration

**File**: `lib/core/models/language_config.dart`

Add your language code and configuration:

```dart
class LanguageConfig {
  static const Map<String, LanguageInfo> languages = {
    'am': LanguageInfo(
      code: 'am',
      name: 'Amharic',
      displayName: 'አማርኛ',
    ),
    'en': LanguageInfo(  // New language example
      code: 'en',
      name: 'English',
      displayName: 'English',
    ),
  };
}
```

### Step 2: Create JSON Data File

**Location**: `assets/data/database/{language_code}_Data.json`

Create a JSON file following the existing structure:

```json
{
  "hymnals": {
    "hymnal": {
      "hymns": [
        {
          "id": "sda-1",
          "number": 1,
          "title": "Hymn Title",
          "lyrics": "Hymn lyrics...",
          ...
        }
      ]
    }
  }
}
```

### Step 3: Register in Database Helper

**File**: `lib/core/database/database_helper.dart`

Add language registration:

```dart
DatabaseRegistry.registerDatabase(
  languageCode: 'en',
  version: 'hymnal',
  config: DatabaseConfig(...),
);
```

### Step 4: Add Localization Strings

**File**: `lib/core/l10n/app_localizations.dart`

Add localization strings for your language:

```dart
class AppLocalizations {
  String get languageName {
    switch (_locale.languageCode) {
      case 'en':
        return 'English';
      case 'am':
        return 'አማርኛ';
      default:
        return 'English';
    }
  }
}
```

### Step 5: Update Settings Dropdown

**File**: `lib/features/hymns/presentation/pages/settings_page.dart`

Add dropdown item:

```dart
DropdownMenuItem(
  value: 'en',
  child: Text('English'),
),
```

### Step 6: Test Language Switching

1. Run the app
2. Go to Settings
3. Select your new language
4. Verify hymns load correctly
5. Verify UI text displays in new language

---

## Adding a New Hymnal Book

### Step 1: Create Version Config

**File**: `lib/core/models/database_config.dart`

Add version configuration:

```dart
class DatabaseConfig {
  static DatabaseConfig getHymnalConfig(String languageCode) {
    return DatabaseConfig(
      databaseName: '${languageCode}_hymnal.db',
      version: 1,
      jsonAssetPath: 'assets/data/database/${languageCode}_Hymnal.json',
    );
  }
}
```

### Step 2: Create JSON Data File

**Location**: `assets/data/database/{version}_Hymnal.json`

Structure your JSON data according to the hymnal format.

### Step 3: Update Database Schema (If Needed)

**File**: `lib/core/database/app_database.dart`

If new fields are needed, update the Drift table definition:

```dart
@DataClassName('HymnTable')
class Hymns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get number => integer()();
  TextColumn get title => text()();
  TextColumn get lyrics => text()();
  // Add new columns here
}
```

### Step 4: Create Parser

**File**: `lib/core/database/parsers/{version}_parser.dart`

Create a parser for your hymnal format:

```dart
class VersionParser {
  static List<Map<String, dynamic>> parseHymns(String jsonString) {
    final jsonData = json.decode(jsonString);
    // Parse and return list of hymn maps
  }
}
```

### Step 5: Register in Database Registry

**File**: `lib/core/database/database_helper.dart`

```dart
DatabaseRegistry.registerDatabase(
  languageCode: 'am',
  version: 'new_version',
  config: DatabaseConfig(...),
);
```

### Step 6: Update Version Dropdown

**File**: `lib/features/hymns/presentation/pages/settings_page.dart`

Add version to dropdown:

```dart
DropdownMenuItem(
  value: 'new_version',
  child: Text('New Version'),
),
```

### Step 7: Generate Database Code

Run code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## API Integration

### Step 1: Create Remote Data Source

**File**: `lib/features/hymns/data/datasources/hymn_remote_data_source.dart`

```dart
abstract class HymnRemoteDataSource {
  Future<List<HymnModel>> getHymnsFromApi();
  Future<HymnModel> getHymnByNumber(int number);
}

class HymnRemoteDataSourceImpl implements HymnRemoteDataSource {
  final Dio httpClient;
  
  HymnRemoteDataSourceImpl({required this.httpClient});
  
  @override
  Future<List<HymnModel>> getHymnsFromApi() async {
    final response = await httpClient.get('/api/hymns');
    return (response.data as List)
        .map((json) => HymnModel.fromJson(json))
        .toList();
  }
}
```

### Step 2: Create API Service

**File**: `lib/core/services/api_service.dart`

```dart
class ApiService {
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: Duration(seconds: 30),
    ));
  }
  
  Future<Response> get(String endpoint) => _dio.get(endpoint);
  Future<Response> post(String endpoint, {dynamic data}) => _dio.post(endpoint, data: data);
}
```

### Step 3: Add Sync Use Case

**File**: `lib/features/hymns/domain/usecases/sync_hymns_from_api.dart`

```dart
class SyncHymnsFromApi {
  final HymnRepository repository;
  
  SyncHymnsFromApi(this.repository);
  
  Future<Either<Failure, List<Hymn>>> call() async {
    // Fetch from API
    // Save to local database
    // Return updated hymns
  }
}
```

### Step 4: Implement Sync Strategy

**Options**:

- **Full Sync**: Replace all local data
- **Incremental Sync**: Update only changed items
- **Background Sync**: Sync periodically in background

**File**: `lib/core/services/sync_service.dart`

```dart
class SyncService {
  Timer? _syncTimer;
  
  void startPeriodicSync() {
    _syncTimer = Timer.periodic(Duration(hours: 24), (_) {
      _syncHymns();
    });
  }
  
  Future<void> _syncHymns() async {
    // Implement sync logic
  }
}
```

### Step 5: Handle Offline Caching

**Strategy**: Always prefer local cache, sync in background

```dart
Future<List<Hymn>> getHymns() async {
  // Return cached data immediately
  final cached = await localDataSource.getHymns();
  
  // Sync in background
  syncInBackground();
  
  return cached;
}
```

### Step 6: Add Retry Logic

```dart
Future<List<Hymn>> getHymnsWithRetry() async {
  int attempts = 0;
  while (attempts < 3) {
    try {
      return await remoteDataSource.getHymns();
    } catch (e) {
      attempts++;
      await Future.delayed(Duration(seconds: 2 * attempts));
    }
  }
  throw NetworkException('Failed after 3 attempts');
}
```

---

## Sheet Music Integration

### Step 1: Save Files to Assets

**Location**: `assets/sheet_music/{version}/`

**Naming Convention**:
- Single page: `{hymn_number}.jpg` or `{hymn_number}.png`
- Two pages: `{hymn_number}_2L.jpg` and `{hymn_number}_2R.jpg`

**Example**:
```
assets/sheet_music/sda/
  1.jpg              # Hymn 1, single page
  5_2L.jpg           # Hymn 5, left page
  5_2R.jpg           # Hymn 5, right page
  10.png             # Hymn 10, PNG format
```

### Step 2: Update pubspec.yaml

```yaml
flutter:
  assets:
    - assets/sheet_music/
    - assets/sheet_music/sda/
```

### Step 3: Update JSON Data

Add sheet music paths to your hymn data:

```json
{
  "id": "sda-5",
  "number": 5,
  "sheet_music": ["5_2L.jpg", "5_2R.jpg"]
}
```

### Step 4: Verify Model Mapping

**File**: `lib/features/hymns/data/models/hymn_model.dart`

Ensure `sheetMusic` field is mapped:

```dart
@JsonKey(name: 'sheet_music')
final List<String>? sheetMusic;
```

### Step 5: UI Implementation

**File**: `lib/features/hymns/presentation/widgets/sheet_music_viewer.dart`

The `SheetMusicViewer` widget handles:
- Displaying single or multiple pages
- Zoom functionality with `InteractiveViewer`
- Page navigation with `PageView`
- Labels: "2L"/"2R" for two pages, numbers for single page

**Usage**:

```dart
SheetMusicViewer(
  sheetMusicFiles: hymn.sheetMusic ?? [],
  hymnNumber: hymn.displayNumber,
)
```

### Step 6: Show Only for SDA Hymnal

**File**: `lib/features/hymns/presentation/pages/hymn_detail_page.dart`

```dart
if (!hymn.isHagerigna && hymn.sheetMusic != null && hymn.sheetMusic!.isNotEmpty)
  SheetMusicViewer(...)
```

---

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

3. **Amharic Transliteration**:
   - Uses `AmharicTransliterationService` to handle Amharic/Fidel input
   - Converts between script variants for better matching

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
- Full-text search with SQLite FTS
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
6. **Data Source**: `LocalDataSource` queries database/JSON
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

## Generating Models, DB Schema, Migrations

### Drift Code Generation

**Database Definition**: `lib/core/database/app_database.dart`

**Run Code Generation**:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:
- `app_database.g.dart`: Database implementation
- Model classes with type-safe queries

### Schema Changes

**Step 1**: Update Table Definition

```dart
class Hymns extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Add new column
  TextColumn get newField => text().nullable()();
}
```

**Step 2**: Update Database Version

```dart
@DriftDatabase(tables: [Hymns])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);
  
  @override
  int get schemaVersion => 2; // Increment version
}
```

**Step 3**: Create Migration

**File**: `lib/core/database/database_migration.dart`

```dart
Future<void> migrate(Database database, int from, int to) async {
  if (from < 2 && to >= 2) {
    await database.customStatement('ALTER TABLE hymns ADD COLUMN new_field TEXT');
  }
}
```

**Step 4**: Run Code Generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Migration Best Practices

1. Always test migrations on sample data
2. Support rollback if possible
3. Migrate data when needed (not just schema)
4. Use transactions for atomic migrations

---

## Adding Categories (Many-to-Many)

### Step 1: Create Category Table

**File**: `lib/core/database/app_database.dart`

```dart
@DataClassName('CategoryTable')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
}

@DataClassName('HymnCategoryTable')
class HymnCategories extends Table {
  IntColumn get hymnId => integer()();
  IntColumn get categoryId => integer()();
  
  @override
  Set<Column> get primaryKey => {hymnId, categoryId};
}
```

### Step 2: Update Domain Entity

**File**: `lib/features/hymns/domain/entities/category.dart`

```dart
class Category extends Equatable {
  final int id;
  final String name;
  final String displayName;
  
  const Category({
    required this.id,
    required this.name,
    required this.displayName,
  });
  
  @override
  List<Object> get props => [id, name, displayName];
}
```

### Step 3: Update Hymn Entity

**File**: `lib/features/hymns/domain/entities/hymn.dart`

```dart
class Hymn extends Equatable {
  // ... existing fields
  final List<Category> categories;
  
  const Hymn({
    // ... existing parameters
    this.categories = const [],
  });
}
```

### Step 4: Create Repository Methods

**File**: `lib/features/hymns/domain/repositories/hymn_repository.dart`

```dart
abstract class HymnRepository {
  Future<Either<Failure, List<Category>>> getCategories();
  Future<Either<Failure, List<Hymn>>> getHymnsByCategory(int categoryId);
}
```

### Step 5: Implement Repository

**File**: `lib/features/hymns/data/repositories/hymn_repository_impl.dart`

```dart
@override
Future<Either<Failure, List<Hymn>>> getHymnsByCategory(int categoryId) async {
  try {
    final hymnModels = await localDataSource.getHymnsByCategory(categoryId);
    final hymns = HymnMapper.toDomainList(hymnModels);
    return Right(hymns);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

### Step 6: UI Integration

**File**: `lib/features/hymns/presentation/pages/index_page.dart`

```dart
// Add category filter dropdown
DropdownButton<int>(
  items: categories.map((cat) => DropdownMenuItem(
    value: cat.id,
    child: Text(cat.displayName),
  )).toList(),
  onChanged: (categoryId) {
    if (categoryId != null) {
      context.read<HymnsBloc>().add(LoadHymnsByCategory(categoryId));
    }
  },
)
```

### Step 7: Add Use Case

**File**: `lib/features/hymns/domain/usecases/get_hymns_by_category.dart`

```dart
class GetHymnsByCategory {
  final HymnRepository repository;
  
  GetHymnsByCategory(this.repository);
  
  Future<Either<Failure, List<Hymn>>> call(int categoryId) async {
    return await repository.getHymnsByCategory(categoryId);
  }
}
```

---

## Adding Assets

### Audio Files

**Location**: `assets/audio/{version}/`

**Naming**: `{hymn_number}.mp3`

**pubspec.yaml**:

```yaml
flutter:
  assets:
    - assets/audio/
    - assets/audio/hymnal/
```

**Code Usage**:

```dart
AudioPlayer().play(AssetSource('audio/hymnal/${hymn.number}.mp3'));
```

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

### Sheet Music

**Location**: `assets/sheet_music/{version}/`

**Naming**:
- Single: `{number}.jpg`
- Double: `{number}_2L.jpg`, `{number}_2R.jpg`

**pubspec.yaml**:

```yaml
flutter:
  assets:
    - assets/sheet_music/
    - assets/sheet_music/sda/
```

**Code Usage**:

```dart
Image.asset('assets/sheet_music/sda/${hymn.number}_2L.jpg')
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
# Generate code for models, database, etc.
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

### Database Issues

- **Migration errors**: Check version numbers, verify migration logic
- **Database locked**: Ensure proper transaction handling
- **Missing data**: Verify JSON data structure matches models

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


