# Architecture Documentation

## Overview

The Amharic Hymnal app follows Clean Architecture principles with clear separation between Data, Domain, and Presentation layers. This document provides a comprehensive overview of the architecture, data flow, and design decisions.

## 2026 Stabilization Notes

- Public content versions are `sda_new`, `sda_old`, and `hagerigna`; `hymnal` is a compatibility alias for `sda_new`.
- Flutter talks to two separate deployable backends: content on port 8787 and user/app state on port 8790.
- SDA old/new songs reuse merged backend works while exposing version-specific display number, title, and lyrics.
- SDA categories are defined once in `HymnCategories` and reused by UI and fallback mapping.
- Sheet music is protected by Android `FLAG_SECURE` while visible; unsupported platforms no-op gracefully.
- Bug reports post to the user/app backend and queue locally when the backend is unavailable.

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
1. **JSON Assets**: Fast fallback when database not ready
2. **SQLite (Drift)**: Primary data source when ready
3. **SharedPreferences**: User settings, favorites
4. **Offline Cache**: `offline_cache_service.dart` - Caches data for offline access
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
- **SheetMusicDiscoveryService**: Automatic sheet music file discovery
- **OfflineCacheService**: Offline data caching (NEW)
- **SyncService**: Background sync operations (NEW)
- **BugReportQueueService**: Offline bug report queue (NEW)

### Dependency Injection

**File**: `lib/injection_container.dart`

**Technology**: `get_it`

**Setup**:
```dart
Future<void> initDependencies() async {
  // Services
  sl.registerLazySingleton(() => SettingsService());
  sl.registerLazySingleton(() => OfflineCacheService.instance);
  sl.registerLazySingleton(() => SyncService.instance);
  sl.registerLazySingleton(() => BugReportQueueService.instance);
  
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

### Database Layer

**Technology**: Drift (SQLite)

**Files**:
- `lib/core/database/app_database.dart`: Database definition
- `lib/core/database/database_helper.dart`: Database operations
- `lib/core/database/database_migration.dart`: Migration logic

**Schema**:
```dart
@DataClassName('HymnTable')
class Hymns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get number => integer()();
  TextColumn get title => text()();
  TextColumn get lyrics => text()();
  // ...
}
```

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
   ├─ Check: Database ready?
   │  ├─ Yes → DatabaseHelper.getHymns()
   │  └─ No → JsonDataSource.getHymns()
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
   ├─ Update SharedPreferences (optimistic)
   ├─ Emit HymnsLoaded (instant UI update)
   └─ Update Database (background, non-blocking)
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

## Database Schema & Migrations

### Current Schema

**File**: `lib/core/database/app_database.dart`

```dart
@DataClassName('HymnTable')
class Hymns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get number => integer()();
  TextColumn get title => text().nullable()();
  TextColumn get lyrics => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get newHymnalTitle => text().nullable()();
  TextColumn get oldHymnalTitle => text().nullable()();
  TextColumn get englishTitleOld => text().nullable()();
  // ...
}
```

### Adding a Migration

**File**: `lib/core/database/database_migration.dart`

```dart
@DriftDatabase(tables: [Hymns], daos: [HymnDao])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2; // Increment for new migration
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          // Migration logic
          await migrator.addColumn(hymns, hymns.newColumn);
        }
      },
    );
  }
}
```

### Running Migrations

```bash
# Generate migration code
flutter pub run build_runner build --delete-conflicting-outputs

# Test migration
flutter test
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

### 3. Database

- Fast JSON fallback when database not ready
- Background database initialization
- Cached queries

### 4. Blur Performance

- Capped blur sigma at 8.0 for GPU acceleration
- `RepaintBoundary` to isolate blur rendering
- `AnimatedContainer` for smooth transitions

## Security

### Data Storage

- **SharedPreferences**: User settings, favorites (local only)
- **SQLite**: Hymn data (local only)
- **No Secrets**: No API keys or tokens in source code

### Network (Future)

- All remote calls use HTTPS
- Proper error handling and timeouts
- Secure token storage (when implemented)

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
4. **Database Errors**: Check migration version, verify schema

## References

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [BLoC Pattern](https://bloclibrary.dev/)
- [Drift Documentation](https://drift.simonbinder.eu/)
