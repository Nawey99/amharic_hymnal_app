# Architecture Documentation

## Overview

The Amharic Hymnal app follows Clean Architecture principles with clear separation between Data, Domain, and Presentation layers. This document provides a comprehensive overview of the architecture, data flow, and design decisions.

## 2026 Stabilization Notes

- Public content versions are `sda_new`, `sda_old`, and `hagerigna`; `hymnal` is a compatibility alias for `sda_new`.
- Hymn content comes from the hymnal API (`amharic_hymnal_backend`, `/api/v1`): the edition list from `/hymn-versions` and each edition's catalogue from `/sync` (`HymnRemoteDataSource`).
  - The first load reads the whole edition (`/sync` from the epoch) and stores it as `content_cache/<language>_<code>.json` under application support (`FileEditionStore`; not on web).
  - Each later load asks `/hymn-versions/<code>` for `contentUpdatedAt`. Unchanged: the stored copy is used. Changed: a delta `/sync` from the stored `serverTime` is applied — songs by revision, retired songs removed, `changes.audio` and `changes.categories` applied, and songs named in `changes.sheetMusicPages` re-read from `/songs/<id>` — then stored with the new `serverTime`. A rejected delta (`INVALID_SYNC_*`) falls back to a full sync.
  - Once a week (`fullRefreshInterval`) an opened edition is downloaded whole instead, which catches songs deleted outright and re-scans of pages an edition borrows; neither reaches a delta. After each update, downloaded media no stored edition refers to is deleted.
  - Requests go through `HymnalApiClient`: metadata routes send `If-None-Match` and reuse the stored body on `304`, and after `429`/`503` no request is sent until the `RateLimit`/`Retry-After` reset.
  - Once per run the app reads `/manifest` for `release.minimumAppVersion` and asks the user to update if this build is older. An edition with `capabilities.songs: false` is listed as "(በዝግጅት ላይ)".
  - Offline, or if an update fails part-way, the stored copy is served. A retired edition (`hymnVersion.isActive: false` or `HYMN_VERSION_NOT_FOUND`) is deleted. Bundled JSON is used only when nothing has been stored yet.
- Audio and sheet music download only after the user agrees, through the API's file routes (which redirect to short-lived storage URLs that are never stored). Each file is checked against the API's SHA-256 and size, then stored as `<sha256>.<ext>` under `media_cache/`, so a page or recording shared by several hymns or editions downloads once. Borrowed sheet pages (`borrowedFromVersionCode`) get a caption naming the source book, and synthesized audio (`source: synthesized`) gets a badge and its attribution.
- Bug reports go to the hymnal API's report inbox (`POST /reports?version=<edition>`, category `APP_BUG`) and appear in its admin console's Reports tab. The old in-repo servers (`backend/content`, `backend/user_app`) have been removed.
- SDA old/new songs reuse merged backend works while exposing version-specific display number, title, and lyrics.
- Each edition has its own categories (1961, 1975 and 2004 group hymns differently). Hymns carry their category from `/sync`; `EditionCategoriesService` reads `/categories` for the book order and slugs, kept on the device for offline use. `HymnCategories` number ranges are only a fallback for 2004 hymns without one.
- Anonymous analytics (`AnalyticsService`): `SONG_VIEW` when a hymn is opened and `CATEGORY_VIEW` when a category is, fire and forget. Debug builds send nothing unless built with `--dart-define=WUDASE_ANALYTICS=true`.
- Sheet music is protected by Android `FLAG_SECURE` while visible; unsupported platforms no-op gracefully.
- Bug reports queue locally (secure storage) when the API is unreachable or rate-limited, and are retried at startup; a report the API refuses outright is dropped so it cannot block the queue.

## Architecture Layers

### 1. Presentation Layer

**Location**: `lib/features/{feature}/presentation/`

**Responsibilities**:
- UI components (pages, widgets)
- State management (BLoC)
- User interactions
- Navigation

**Key Components**:
- **Pages**: `hymn_detail_page.dart`, `index_page.dart`, `favorites_page.dart`, etc.
- **BLoC**: `hymns_bloc.dart` - Manages hymn-related state
- **Widgets**: Reusable UI components

**State Management**: BLoC pattern (`flutter_bloc`)

```
User Action → Event → BLoC → UseCase → Repository → DataSource
                                                      ↓
User Sees ← State ← BLoC ← UseCase ← Repository ← DataSource
```

### 2. Domain Layer

**Location**: `lib/features/{feature}/domain/`

**Responsibilities**:
- Business logic
- Entity definitions
- Repository interfaces
- Use cases

**Key Components**:
- **Entities**: `hymn.dart` - Pure business objects
- **Repositories**: Interfaces (e.g., `hymn_repository.dart`)
- **Use Cases**: `get_hymns.dart`, `search_hymns.dart`, `get_hymn_by_number.dart`

**Rules**:
- No dependencies on Data or Presentation layers
- Pure Dart (no Flutter imports)
- Business logic only

### 3. Data Layer

**Location**: `lib/features/{feature}/data/`

**Responsibilities**:
- Data sources (local, remote)
- Repository implementations
- Data models
- Mappers (Data → Domain)

**Key Components**:
- **Data Sources**: `local_data_source.dart`, `hymn_local_data_source.dart`
- **Repositories**: `hymn_repository_impl.dart`
- **Models**: `hymn_model.dart` (with JSON serialization)
- **Mappers**: `hymn_mapper.dart`

**Data Sources**:
1. **Hymnal API** (`hymn_remote_data_source.dart`): each edition, kept on the device by `edition_store.dart` (`content_cache/<language>_<code>.json`) and updated by delta sync
2. **Bundled JSON** (`json_data_source.dart`): used only before an edition has ever been downloaded
3. **SharedPreferences**: user settings, favorites, history
4. **Media cache** (`local_media_cache_service.dart`): downloaded audio and sheet pages, stored by SHA-256
5. **Bug Report Queue**: `bug_report_queue_service.dart` - Queues bug reports for offline submission

## Dependency Flow

```
Presentation → Domain ← Data
     ↓           ↑
   BLoC      UseCase
     ↓           ↑
  Event      Repository (interface)
     ↓           ↑
  State      Repository (implementation)
                  ↑
              DataSource
```

**Key Principle**: Dependencies point inward (Presentation depends on Domain, Data depends on Domain, but Domain depends on nothing).

## Core Components

### Core Services

**Location**: `lib/core/services/`

**Key Services**:
- **SettingsService**: User preferences management
- **FontSizeService**: Reactive font size management
- **BackgroundImageService**: Background image toggle
- **HistoryService**: Hymn view history tracking
- **HymnalVersionService**: Edition list from the hymnal API
- **HymnalApiClient**: Conditional requests and rate-limit back-off for API calls
- **LocalMediaCacheService**: Verified audio and sheet-music downloads
- **SheetMusicBulkDownloadService**: Whole-edition sheet-music install
- **SongEditionsService**: The same hymn's number in other editions
- **AppUpdateService**: Minimum app version from the manifest
- **BugReportQueueService**: Offline bug report queue

### Dependency Injection

**File**: `lib/injection_container.dart`

**Technology**: `get_it`

**Setup**:
```dart
Future<void> initDependencies() async {
  await SettingsService.init();

  // Data sources
  sl.registerLazySingleton<HymnLocalDataSource>(() => LocalDataSource());
  sl.registerLazySingleton<HymnalVersionService>(HymnalVersionService.new);

  // Repositories
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl()),
  );
  
  // Use Cases
  sl.registerLazySingleton(() => GetHymns(sl()));
  
  // BLoC
  sl.registerFactory(() => HymnsBloc(/* ... */));
}
```

### Content Storage

There is no local database. Each edition's API song objects are stored as one
JSON file by `FileEditionStore` and patched by `/sync` deltas; see "2026
Stabilization Notes" above. Hymns bundled in `assets/data/database/*.json`
are parsed by `JsonDataSource` only when no stored copy exists.

### State Management

**Pattern**: BLoC (Business Logic Component)

**Flow**:
```
Event → BLoC → UseCase → Repository → DataSource
                                    ↓
State ← BLoC ← UseCase ← Repository ← DataSource
```

**Key Events**:
- `LoadHymns`: Load all hymns
- `SearchHymnsEvent`: Search hymns
- `ToggleFavorite`: Toggle favorite status
- `ChangeLanguage`: Change language
- `ChangeVersion`: Change hymnal version

**Key States**:
- `HymnsLoading`: Loading state
- `HymnsLoaded`: Success state with hymns list
- `HymnsError`: Error state

## Data Flow Examples

### Loading Hymns

```
1. User opens app
   ↓
2. MainNavigationPage.initState()
   ↓
3. HymnsBloc.add(LoadHymns(language, version, sortType))
   ↓
4. GetHymns UseCase
   ↓
5. HymnRepository.getHymns()
   ↓
6. LocalDataSource.getHymns()
   ├─ HymnRemoteDataSource.getHymns()  (stored copy, updated from the API)
   └─ on failure with no stored copy → JsonDataSource.getHymns() (bundled)
   ↓
7. HymnMapper.toDomainList()
   ↓
8. HymnsBloc.emit(HymnsLoaded(hymns))
   ↓
9. BlocBuilder rebuilds UI
```

### Searching Hymns

```
1. User types in search field
   ↓
2. Debounce (300ms)
   ↓
3. HymnsBloc.add(SearchHymnsEvent(query))
   ↓
4. SearchHymns UseCase
   ↓
5. HymnRepository.searchHymns()
   ↓
6. LocalDataSource.searchHymns()
   ├─ Search in database OR
   └─ Filter JSON data
   ↓
7. HymnMapper.toDomainList()
   ↓
8. HymnsBloc.emit(HymnsLoaded(filteredHymns))
   ↓
9. UI updates with search results
```

### Toggling Favorite

```
1. User taps favorite button
   ↓
2. GestureDetector.onTap (immediate visual feedback)
   ↓
3. HymnsBloc.add(ToggleFavorite(hymnNumber))
   ↓
4. _onToggleFavorite()
   ├─ Update SharedPreferences (per edition)
   └─ Emit HymnsLoaded (instant UI update)
   ↓
5. UI updates instantly
```

## File Structure

```
lib/
├── core/                          # Shared across features
│   ├── constants/                 # App constants
│   ├── database/                 # Database layer
│   ├── domain/                    # Domain interfaces
│   ├── error/                     # Error handling
│   ├── l10n/                      # Localization
│   ├── models/                    # Shared models
│   ├── services/                  # Shared services
│   ├── theme/                     # Theming
│   ├── utils/                     # Utilities
│   └── widgets/                   # Reusable widgets
│
├── features/                      # Feature modules
│   └── hymns/                     # Hymns feature
│       ├── data/                  # Data layer
│       │   ├── datasources/      # Data sources
│       │   ├── mappers/          # Data mappers
│       │   ├── models/            # Data models
│       │   └── repositories/     # Repository implementations
│       ├── domain/                # Domain layer
│       │   ├── entities/          # Domain entities
│       │   ├── repositories/      # Repository interfaces
│       │   └── usecases/          # Use cases
│       └── presentation/          # Presentation layer
│           ├── bloc/              # State management
│           ├── pages/              # Pages
│           └── widgets/            # Feature widgets
│
├── injection_container.dart       # Dependency injection
└── main.dart                      # App entry point
```

## Design Patterns

### 1. Repository Pattern

**Purpose**: Abstract data access

**Implementation**:
```dart
// Domain (interface)
abstract class HymnRepository {
  Future<Either<Failure, List<Hymn>>> getHymns(String language, String version);
}

// Data (implementation)
class HymnRepositoryImpl implements HymnRepository {
  final HymnLocalDataSource localDataSource;
  
  @override
  Future<Either<Failure, List<Hymn>>> getHymns(...) async {
    // Implementation
  }
}
```

### 2. Use Case Pattern

**Purpose**: Encapsulate business logic

**Implementation**:
```dart
class GetHymns implements UseCase<List<Hymn>, GetHymnsParams> {
  final HymnRepository repository;
  
  @override
  Future<Either<Failure, List<Hymn>>> call(GetHymnsParams params) async {
    return await repository.getHymns(params.languageCode, params.version);
  }
}
```

### 3. BLoC Pattern

**Purpose**: State management

**Implementation**:
```dart
class HymnsBloc extends Bloc<HymnsEvent, HymnsState> {
  final GetHymns getHymns;
  
  HymnsBloc({required this.getHymns}) : super(HymnsInitial()) {
    on<LoadHymns>(_onLoadHymns);
  }
  
  Future<void> _onLoadHymns(LoadHymns event, Emitter<HymnsState> emit) async {
    emit(HymnsLoading());
    final result = await getHymns(GetHymnsParams(...));
    // Handle result
  }
}
```

## Error Handling

### Failure Types

**File**: `lib/core/error/failures.dart`

```dart
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
}

class CacheFailure extends Failure {
  const CacheFailure() : super('Cache failure');
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('Network failure');
}
```

### Error Handling Flow

```
DataSource throws Exception
    ↓
Repository catches, converts to Failure
    ↓
UseCase returns Either<Failure, Success>
    ↓
BLoC handles Failure, emits ErrorState
    ↓
UI displays error message
```

## Testing Strategy

### Unit Tests

**Location**: `test/`

**Focus**: Business logic, use cases, repositories

**Example**:
```dart
test('GetHymns returns hymns on success', () async {
  // Arrange
  final mockRepository = MockHymnRepository();
  when(mockRepository.getHymns(any, any))
      .thenAnswer((_) async => Right([testHymn]));
  
  // Act
  final result = await GetHymns(mockRepository)(params);
  
  // Assert
  expect(result, isA<Right>());
});
```

### Widget Tests

**Location**: `test/widget_tests/`

**Focus**: UI components, user interactions

**Example**:
```dart
testWidgets('Favorite button toggles', (tester) async {
  await tester.pumpWidget(/* ... */);
  await tester.tap(find.byIcon(Icons.favorite_border));
  await tester.pump();
  expect(find.byIcon(Icons.favorite), findsOneWidget);
});
```

### Integration Tests

**Location**: `integration_test/`

**Focus**: End-to-end user flows

**Example**:
```dart
testWidgets('Complete user flow', (tester) async {
  app.main();
  await tester.pumpAndSettle();
  // Test full flow
});
```

## Performance Considerations

### 1. Lazy Loading

- Lists use `ListView.builder` with `itemExtent` when possible
- Images use `cacheWidth`/`cacheHeight` for memory efficiency
- Sheet music loads only when visible

### 2. State Management

- `buildWhen` predicates to prevent unnecessary rebuilds
- `RepaintBoundary` around expensive widgets
- `const` constructors where possible

### 3. Content loading

- A stored edition opens without waiting for the network beyond one small change check
- Unchanged editions cost one ~1 KB request; changes arrive as deltas
- Each edition is held in memory for the session after its first load

### 4. Blur Performance

- Capped blur sigma at 8.0 for GPU acceleration
- `RepaintBoundary` to isolate blur rendering
- `AnimatedContainer` for smooth transitions

## Security

### Data Storage

- **SharedPreferences**: User settings, favorites (local only)
- **Application support files**: stored editions and downloaded media (local only)
- **No Secrets**: No API keys or tokens in source code

### Network

- All remote calls use HTTPS (enforced for release builds)
- Timeouts on every request; rate-limit and `Retry-After` back-off
- Downloads verified by SHA-256; short-lived storage URLs are never stored

## Internationalization

### Current Support

- **Languages**: Amharic (am), English (en) - configurable
- **Localization**: `flutter_localizations`
- **Text Direction**: LTR (Amharic is LTR)

### Adding New Language

See `docs/lyrics-feature.md` for detailed steps.

## Theming

### Current Theme

**File**: `lib/core/theme/app_theme.dart`

- **Mode**: Dark theme (primary)
- **Colors**: Defined in `app_colors.dart`
- **Fonts**: NotoSansEthiopic for Amharic text

### Theme Structure

```dart
static ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primaryBackground,
  // ...
);
```

## Best Practices

### 1. Clean Architecture

- Keep business logic in Domain layer
- No Flutter imports in Domain layer
- Dependencies point inward

### 2. State Management

- Use BLoC for complex state
- Use `ListenableBuilder` for simple reactive state
- Avoid `setState` in complex widgets

### 3. Error Handling

- Always use `Either<Failure, Success>` pattern
- Provide meaningful error messages
- Handle offline scenarios gracefully

### 4. Performance

- Use `const` constructors
- Implement `buildWhen` predicates
- Lazy load expensive operations
- Cache frequently accessed data

### 5. Testing

- Write unit tests for business logic
- Write widget tests for UI components
- Write integration tests for critical flows

## Common Patterns

### Loading State

```dart
BlocBuilder<HymnsBloc, HymnsState>(
  builder: (context, state) {
    if (state is HymnsLoading) {
      return CircularProgressIndicator();
    }
    if (state is HymnsLoaded) {
      return HymnList(hymns: state.hymns);
    }
    if (state is HymnsError) {
      return ErrorWidget(message: state.message);
    }
    return SizedBox();
  },
)
```

### Optimistic Updates

```dart
// Update UI immediately
setState(() {
  isFavorite = !isFavorite;
});

// Persist in background
context.read<HymnsBloc>().add(ToggleFavorite(hymnNumber));
```

### Error Recovery

```dart
try {
  final result = await useCase(params);
  result.fold(
    (failure) => emit(ErrorState(failure.message)),
    (success) => emit(SuccessState(success)),
  );
} catch (e) {
  emit(ErrorState('Unexpected error: $e'));
}
```

## Migration Guide

### From Old Architecture

If migrating from a different architecture:

1. **Identify Business Logic**: Extract to Domain layer
2. **Create Use Cases**: Encapsulate business operations
3. **Implement Repositories**: Abstract data access
4. **Add BLoC**: Manage state reactively
5. **Update UI**: Use BlocBuilder/BlocListener

## Troubleshooting

### Common Issues

1. **Circular Dependencies**: Ensure Domain has no dependencies
2. **State Not Updating**: Check `buildWhen` predicates
3. **Performance Issues**: Add `RepaintBoundary`, optimize rebuilds
4. **Stale content**: Delete `content_cache/` under application support to force a full re-download

## References

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [BLoC Pattern](https://bloclibrary.dev/)
