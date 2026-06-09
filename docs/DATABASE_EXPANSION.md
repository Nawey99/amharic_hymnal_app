# Database Expansion Documentation

## Overview

This document provides comprehensive guidance for extending the Amharic Hymnal App database with two new systems:
1. **Category System** - Organize hymns into categories
2. **Sheet Music System** - Link sheet music files to hymns

---

## A. Category System

### Rules
- One category can contain many songs
- One song belongs to exactly one category (for now)
- Categories support multi-language names (Amharic and English)

### 1. Database Schema Changes

#### New Table: `categories`

```dart
// lib/core/database/app_database.dart

class Categories extends Table {
  TextColumn get id => text().withLength(min: 1, max: 50)();
  TextColumn get nameAmharic => text().named('name_amharic').withLength(min: 1, max: 200)();
  TextColumn get nameEnglish => text().named('name_english').withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### Update Existing Table: `hymns`

Add foreign key relationship:

```dart
// In Hymns table definition
TextColumn get categoryId => text().nullable().named('category_id').references(Categories, #id)();
```

**Note**: The existing `category` text field can remain for backward compatibility, but `categoryId` should be used for the relationship.

### 2. Migration Steps

#### Update Schema Version

```dart
// lib/core/database/app_database.dart

@DriftDatabase(tables: [Hymns, Categories])  // Add Categories to tables list
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;  // Increment from 3 to 4

  @override
  MigrationStrategy get migration {
    final schemaHelper = DatabaseSchemaHelper(this);
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await schemaHelper.initializeSchema(m);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          await schemaHelper.upgradeFromV1();
        }
        if (from <= 2) {
          await schemaHelper.upgradeFromV2();
        }
        if (from <= 3) {
          await schemaHelper.upgradeFromV3();  // New migration
        }
      },
    );
  }
}
```

#### Migration Helper Method

```dart
// lib/core/database/database_schema_helper.dart

Future<void> upgradeFromV3() async {
  // Create categories table
  await customStatement('''
    CREATE TABLE IF NOT EXISTS categories (
      id TEXT PRIMARY KEY NOT NULL,
      name_amharic TEXT NOT NULL,
      name_english TEXT NOT NULL,
      description TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');

  // Add category_id column to hymns table (nullable for backward compatibility)
  await customStatement('''
    ALTER TABLE hymns ADD COLUMN category_id TEXT
  ''');

  // Create index for faster category lookups
  await customStatement('''
    CREATE INDEX IF NOT EXISTS idx_hymns_category_id 
    ON hymns(category_id)
  ''');

  // Optional: Migrate existing category text values to new category system
  // This would require creating category records and updating hymn references
}
```

### 3. Model Class

#### Domain Entity

```dart
// lib/features/hymns/domain/entities/category.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
class Category extends Equatable {
  final String id;
  final String nameAmharic;
  final String nameEnglish;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.nameAmharic,
    required this.nameEnglish,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get display name based on current language
  String getDisplayName(String languageCode) {
    return languageCode == 'am' ? nameAmharic : nameEnglish;
  }

  @override
  List<Object?> get props => [
        id,
        nameAmharic,
        nameEnglish,
        description,
        createdAt,
        updatedAt,
      ];
}
```

#### Data Model

```dart
// lib/features/hymns/data/models/category_model.dart

import 'package:amharic_hymnal_app/features/hymns/domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.nameAmharic,
    required super.nameEnglish,
    super.description,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      nameAmharic: json['name_amharic'] as String,
      nameEnglish: json['name_english'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['created_at'] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        json['updated_at'] as int,
      ),
    );
  }

  factory CategoryModel.fromDbRow(Map<String, dynamic> row) {
    return CategoryModel(
      id: row['id'] as String,
      nameAmharic: row['name_amharic'] as String,
      nameEnglish: row['name_english'] as String,
      description: row['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at'] as int,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_amharic': nameAmharic,
      'name_english': nameEnglish,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Category toEntity() => this;
}
```

### 4. Relationship Representation

The relationship is one-to-many:
- One `Category` → Many `Hymn` records
- Each `Hymn` has a `categoryId` foreign key

### 5. Query Examples

#### Database Queries

```dart
// lib/core/database/app_database.dart

// Get all categories
Future<List<Category>> getAllCategories() {
  return (select(categories)
        ..orderBy([(c) => OrderingTerm(expression: c.nameAmharic)]))
      .get();
}

// Get category by ID
Future<Category?> getCategoryById(String categoryId) {
  return (select(categories)..where((c) => c.id.equals(categoryId)))
      .getSingleOrNull();
}

// Get hymns by category ID
Future<List<Hymn>> getHymnsByCategoryId(
  String languageCode,
  String version,
  String categoryId,
) {
  return (select(hymns)
        ..where((h) =>
            h.languageCode.equals(languageCode) &
            h.version.equals(version) &
            h.categoryId.equals(categoryId))
        ..orderBy([(h) => OrderingTerm(expression: h.number, mode: OrderingMode.asc)]))
      .get();
}

// Get category with hymn count
Future<Map<Category, int>> getCategoriesWithHymnCount(
  String languageCode,
  String version,
) async {
  final categories = await getAllCategories();
  final result = <Category, int>{};

  for (final category in categories) {
    final count = await (select(hymns)
          ..where((h) =>
              h.languageCode.equals(languageCode) &
              h.version.equals(version) &
              h.categoryId.equals(category.id)))
        .get()
        .then((hymns) => hymns.length);
    result[category] = count;
  }

  return result;
}
```

#### Repository Methods

```dart
// lib/features/hymns/data/repositories/hymns_repository_impl.dart

@override
Future<Either<Failure, List<Category>>> getAllCategories() async {
  try {
    final categories = await database.getAllCategories();
    return Right(categories.map((c) => c.toEntity()).toList());
  } catch (e) {
    return Left(ErrorHandler.handleException(e));
  }
}

@override
Future<Either<Failure, List<Hymn>>> getHymnsByCategory(
  String languageCode,
  String version,
  String categoryId,
) async {
  try {
    final hymns = await database.getHymnsByCategoryId(
      languageCode,
      version,
      categoryId,
    );
    return Right(hymns.map((h) => _mapDbRowToHymnModel(h)).toList());
  } catch (e) {
    return Left(ErrorHandler.handleException(e));
  }
}
```

### 6. UI Integration

#### Category Filter Dropdown

```dart
// lib/features/hymns/presentation/widgets/category_filter.dart

class CategoryFilter extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final Function(Category?) onCategorySelected;

  const CategoryFilter({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final settingsRepository = sl<SettingsRepository>();
    final languageCode = settingsRepository.getSelectedLanguage();

    return DropdownButton<Category?>(
      value: selectedCategory,
      items: [
        DropdownMenuItem<Category?>(
          value: null,
          child: Text('All Categories'),
        ),
        ...categories.map((category) {
          return DropdownMenuItem<Category?>(
            value: category,
            child: Text(category.getDisplayName(languageCode)),
          );
        }),
      ],
      onChanged: onCategorySelected,
    );
  }
}
```

#### Category Badge on Hymn Cards

```dart
// lib/features/hymns/presentation/widgets/hymn_list_item.dart

Widget _buildCategoryBadge(Category? category) {
  if (category == null) return const SizedBox.shrink();

  final settingsRepository = sl<SettingsRepository>();
  final languageCode = settingsRepository.getSelectedLanguage();

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.accentGreen.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: AppColors.accentGreen.withValues(alpha: 0.5),
        width: 1,
      ),
    ),
    child: Text(
      category.getDisplayName(languageCode),
      style: TextStyle(
        color: AppColors.accentGreen,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
```

### 7. Search/Sorting Integration

#### Add Category Filter to Search

```dart
// lib/features/hymns/presentation/bloc/hymns_bloc.dart

class SearchHymnsEvent extends HymnsEvent {
  final String languageCode;
  final String version;
  final String query;
  final String? categoryId;  // Add category filter

  SearchHymnsEvent(
    this.languageCode,
    this.version,
    this.query,
    this.categoryId,
  );
}

Future<void> _onSearchHymns(
  SearchHymnsEvent event,
  Emitter<HymnsState> emit,
) async {
  // ... existing search logic ...
  
  // Apply category filter if provided
  if (event.categoryId != null) {
    final categoryHymns = await getHymnsByCategory(
      event.languageCode,
      event.version,
      event.categoryId!,
    );
    // Filter search results by category
    // ...
  }
}
```

#### Sort by Category Option

```dart
// lib/features/hymns/presentation/bloc/hymns_state.dart

HymnsLoaded _sortHymns(List<Hymn> hymns, String sortType) {
  List<Hymn> sortedHymns = List.from(hymns);

  switch (sortType) {
    case 'category':
      sortedHymns.sort((a, b) {
        final aCategory = a.categoryId ?? '';
        final bCategory = b.categoryId ?? '';
        return aCategory.compareTo(bCategory);
      });
      break;
    // ... other sort types
  }

  return HymnsLoaded(
    sortedHymns,
    sortType,
    languageCode: languageCode,
    version: version,
  );
}
```

### 8. Multi-Language Support

Categories store names in both Amharic and English. The `getDisplayName()` method selects the appropriate name based on the current language setting.

---

## B. Sheet Music System

### Rules
- One song can have one or two sheet music files (PDF, image, or asset)
- Sheet music must be linked to a song via a foreign key
- If multiple versions exist, support order (primary/secondary)

### 1. Database Schema Changes

#### New Table: `sheet_music`

```dart
// lib/core/database/app_database.dart

class SheetMusic extends Table {
  TextColumn get id => text().withLength(min: 1, max: 100)();
  TextColumn get hymnId => text().named('hymn_id').withLength(min: 1, max: 100)()
      .references(Hymns, #hymnId)();
  TextColumn get filePath => text().withLength(min: 1, max: 500)();
  TextColumn get fileType => text().named('file_type').withLength(min: 1, max: 20)(); // 'pdf', 'image', 'asset'
  IntColumn get order => integer().withDefault(const Constant(0))(); // 0 = primary, 1 = secondary
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 2. Migration Steps

#### Update Schema Version

```dart
// lib/core/database/app_database.dart

@DriftDatabase(tables: [Hymns, Categories, SheetMusic])  // Add SheetMusic
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 5;  // Increment from 4 to 5

  @override
  MigrationStrategy get migration {
    // ... existing migrations ...
    if (from <= 4) {
      await schemaHelper.upgradeFromV4();  // New migration
    }
  }
}
```

#### Migration Helper Method

```dart
// lib/core/database/database_schema_helper.dart

Future<void> upgradeFromV4() async {
  // Create sheet_music table
  await customStatement('''
    CREATE TABLE IF NOT EXISTS sheet_music (
      id TEXT PRIMARY KEY NOT NULL,
      hymn_id TEXT NOT NULL,
      file_path TEXT NOT NULL,
      file_type TEXT NOT NULL,
      "order" INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (hymn_id) REFERENCES hymns(id) ON DELETE CASCADE
    )
  ''');

  // Create indexes for faster lookups
  await customStatement('''
    CREATE INDEX IF NOT EXISTS idx_sheet_music_hymn_id 
    ON sheet_music(hymn_id)
  ''');

  await customStatement('''
    CREATE INDEX IF NOT EXISTS idx_sheet_music_order 
    ON sheet_music(hymn_id, "order")
  ''');
}
```

### 3. Model Class

#### Domain Entity

```dart
// lib/features/hymns/domain/entities/sheet_music.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum SheetMusicType { pdf, image, asset }

@immutable
class SheetMusicEntity extends Equatable {
  final String id;
  final String hymnId;
  final String filePath;
  final SheetMusicType fileType;
  final int order; // 0 = primary, 1 = secondary
  final DateTime createdAt;
  final DateTime updatedAt;

  const SheetMusicEntity({
    required this.id,
    required this.hymnId,
    required this.filePath,
    required this.fileType,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPrimary => order == 0;
  bool get isSecondary => order == 1;

  @override
  List<Object?> get props => [
        id,
        hymnId,
        filePath,
        fileType,
        order,
        createdAt,
        updatedAt,
      ];
}
```

#### Data Model

```dart
// lib/features/hymns/data/models/sheet_music_model.dart

import 'package:amharic_hymnal_app/features/hymns/domain/entities/sheet_music.dart';

class SheetMusicModel extends SheetMusicEntity {
  const SheetMusicModel({
    required super.id,
    required super.hymnId,
    required super.filePath,
    required super.fileType,
    super.order,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SheetMusicModel.fromJson(Map<String, dynamic> json) {
    return SheetMusicModel(
      id: json['id'] as String,
      hymnId: json['hymn_id'] as String,
      filePath: json['file_path'] as String,
      fileType: _parseFileType(json['file_type'] as String),
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['created_at'] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        json['updated_at'] as int,
      ),
    );
  }

  factory SheetMusicModel.fromDbRow(Map<String, dynamic> row) {
    return SheetMusicModel(
      id: row['id'] as String,
      hymnId: row['hymn_id'] as String,
      filePath: row['file_path'] as String,
      fileType: _parseFileType(row['file_type'] as String),
      order: row['order'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at'] as int,
      ),
    );
  }

  static SheetMusicType _parseFileType(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return SheetMusicType.pdf;
      case 'image':
        return SheetMusicType.image;
      case 'asset':
        return SheetMusicType.asset;
      default:
        return SheetMusicType.image;
    }
  }

  String get fileTypeString {
    switch (fileType) {
      case SheetMusicType.pdf:
        return 'pdf';
      case SheetMusicType.image:
        return 'image';
      case SheetMusicType.asset:
        return 'asset';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hymn_id': hymnId,
      'file_path': filePath,
      'file_type': fileTypeString,
      'order': order,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  SheetMusicEntity toEntity() => this;
}
```

### 4. Relationship Example

The relationship is one-to-many:
- One `Hymn` → Many `SheetMusic` records
- Each `SheetMusic` has a `hymnId` foreign key

### 5. Query Examples

#### Database Queries

```dart
// lib/core/database/app_database.dart

// Get sheet music by hymn ID
Future<List<SheetMusic>> getSheetMusicByHymnId(String hymnId) {
  return (select(sheetMusic)
        ..where((sm) => sm.hymnId.equals(hymnId))
        ..orderBy([(sm) => OrderingTerm(expression: sm.order, mode: OrderingMode.asc)]))
      .get();
}

// Get primary sheet music for a hymn
Future<SheetMusic?> getPrimarySheetMusic(String hymnId) {
  return (select(sheetMusic)
        ..where((sm) => sm.hymnId.equals(hymnId) & sm.order.equals(0)))
      .getSingleOrNull();
}

// Get all hymns that have sheet music
Future<List<Hymn>> getHymnsWithSheetMusic(
  String languageCode,
  String version,
) {
  return customSelect(
    '''
    SELECT DISTINCT h.* FROM hymns h
    INNER JOIN sheet_music sm ON h.id = sm.hymn_id
    WHERE h.language_code = ? AND h.version = ?
    ORDER BY h.number ASC
    ''',
    variables: [
      Variable.withString(languageCode),
      Variable.withString(version),
    ],
    readsFrom: {hymns, sheetMusic},
  ).get().then((rows) {
    return rows.map((row) {
      final data = row.data;
      return Hymn(
        hymnId: data['id'] as String,
        // ... map other fields
      );
    }).toList();
  });
}

// Insert sheet music
Future<int> insertSheetMusic(SheetMusicCompanion sheetMusic) {
  return into(this.sheetMusic).insert(sheetMusic);
}

// Delete sheet music
Future<bool> deleteSheetMusic(String sheetMusicId) {
  return (delete(sheetMusic)..where((sm) => sm.id.equals(sheetMusicId)))
      .go()
      .then((_) => true);
}
```

#### Repository Methods

```dart
// lib/features/hymns/data/repositories/hymns_repository_impl.dart

@override
Future<Either<Failure, List<SheetMusicEntity>>> getSheetMusicByHymnId(
  String hymnId,
) async {
  try {
    final sheetMusic = await database.getSheetMusicByHymnId(hymnId);
    return Right(sheetMusic.map((sm) => sm.toEntity()).toList());
  } catch (e) {
    return Left(ErrorHandler.handleException(e));
  }
}

@override
Future<Either<Failure, SheetMusicEntity?>> getPrimarySheetMusic(
  String hymnId,
) async {
  try {
    final sheetMusic = await database.getPrimarySheetMusic(hymnId);
    return Right(sheetMusic?.toEntity());
  } catch (e) {
    return Left(ErrorHandler.handleException(e));
  }
}
```

### 6. Offline Storage

#### File Storage Strategy

```dart
// lib/core/services/sheet_music_service.dart

import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SheetMusicService {
  static Future<String> getSheetMusicDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final sheetMusicDir = Directory('${directory.path}/sheet_music');
    if (!await sheetMusicDir.exists()) {
      await sheetMusicDir.create(recursive: true);
    }
    return sheetMusicDir.path;
  }

  static Future<String> saveSheetMusicFile(
    String hymnId,
    String fileName,
    List<int> fileBytes,
  ) async {
    final dir = await getSheetMusicDirectory();
    final hymnDir = Directory('$dir/$hymnId');
    if (!await hymnDir.exists()) {
      await hymnDir.create(recursive: true);
    }
    
    final file = File('${hymnDir.path}/$fileName');
    await file.writeAsBytes(fileBytes);
    
    return file.path;
  }

  static Future<File?> getSheetMusicFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  static Future<bool> deleteSheetMusicFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
```

### 7. Adding New Sheet Music Files

#### Migration Script Example

```dart
// lib/core/database/sheet_music_migration.dart

class SheetMusicMigration {
  static Future<void> addSheetMusicFromAssets() async {
    final db = DatabaseHelper.instance.database;
    
    // Example: Add sheet music for hymn "sda-1"
    final hymnId = 'sda-1';
    final filePath = 'assets/sheet_music/sda_001.pdf';
    final order = 0; // Primary
    
    await db.insertSheetMusic(
      SheetMusicCompanion.insert(
        id: 'sheet_music_${hymnId}_primary',
        hymnId: hymnId,
        filePath: filePath,
        fileType: 'asset',
        order: order,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
```

#### Asset Management

Add sheet music files to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/sheet_music/
```

### 8. UI Integration

#### Sheet Music Viewer Widget

```dart
// lib/features/hymns/presentation/widgets/sheet_music_viewer.dart

class SheetMusicViewer extends StatelessWidget {
  final SheetMusicEntity sheetMusic;

  const SheetMusicViewer({
    super.key,
    required this.sheetMusic,
  });

  @override
  Widget build(BuildContext context) {
    switch (sheetMusic.fileType) {
      case SheetMusicType.pdf:
        return _buildPdfViewer();
      case SheetMusicType.image:
        return _buildImageViewer();
      case SheetMusicType.asset:
        return _buildAssetViewer();
    }
  }

  Widget _buildPdfViewer() {
    // Use flutter_pdfview or similar package
    return Container(
      child: Text('PDF Viewer - Implement with flutter_pdfview'),
    );
  }

  Widget _buildImageViewer() {
    return Image.file(
      File(sheetMusic.filePath),
      fit: BoxFit.contain,
    );
  }

  Widget _buildAssetViewer() {
    return Image.asset(
      sheetMusic.filePath,
      fit: BoxFit.contain,
    );
  }
}
```

#### Sheet Music Indicator on Hymn Detail Page

```dart
// lib/features/hymns/presentation/pages/hymn_detail_page.dart

Widget _buildSheetMusicSection(Hymn hymn) {
  return BlocBuilder<HymnsBloc, HymnsState>(
    builder: (context, state) {
      // Fetch sheet music for this hymn
      // Display indicator if sheet music exists
      return FutureBuilder<List<SheetMusicEntity>>(
        future: getSheetMusicByHymnId(hymn.id!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return GlassContainer(
              child: Column(
                children: [
                  Text('Sheet Music Available'),
                  ...snapshot.data!.map((sm) {
                    return ListTile(
                      leading: Icon(Icons.music_note),
                      title: Text(sm.isPrimary ? 'Primary' : 'Secondary'),
                      onTap: () => _openSheetMusicViewer(sm),
                    );
                  }),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      );
    },
  );
}
```

---

## Implementation Checklist

### Category System
- [ ] Create `Categories` table in `app_database.dart`
- [ ] Add `categoryId` foreign key to `Hymns` table
- [ ] Create migration `upgradeFromV3()`
- [ ] Create `Category` entity and `CategoryModel`
- [ ] Add repository methods for category queries
- [ ] Create UI widgets (filter dropdown, category badges)
- [ ] Integrate category filter into search
- [ ] Add "sort by category" option

### Sheet Music System
- [ ] Create `SheetMusic` table in `app_database.dart`
- [ ] Create migration `upgradeFromV4()`
- [ ] Create `SheetMusicEntity` and `SheetMusicModel`
- [ ] Implement `SheetMusicService` for file management
- [ ] Add repository methods for sheet music queries
- [ ] Create sheet music viewer widget
- [ ] Add sheet music indicator to hymn detail page
- [ ] Create migration script for adding sheet music from assets

---

## Testing Recommendations

1. **Category System**:
   - Test category creation and retrieval
   - Test hymn-category relationships
   - Test category filtering in search
   - Test multi-language category names

2. **Sheet Music System**:
   - Test file storage and retrieval
   - Test primary/secondary sheet music ordering
   - Test PDF and image viewing
   - Test offline file access

---

## Future Enhancements

1. **Category System**:
   - Support multiple categories per hymn (many-to-many)
   - Category hierarchy (parent/child categories)
   - Category icons/images

2. **Sheet Music System**:
   - Support for online sheet music URLs
   - Sheet music download/offline sync
   - Sheet music annotations
   - Print functionality



