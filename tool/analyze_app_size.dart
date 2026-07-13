// tool/analyze_app_size.dart
// Script to analyze Flutter app build size
import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  _writeLine('📊 Flutter App Size Analysis Tool\n');

  // Check if APK/AAB exists
  final apkPath = 'build/app/outputs/flutter-apk/app-release.apk';
  final aabPath = 'build/app/outputs/bundle/release/app-release.aab';

  File? buildFile;
  String buildType;

  if (File(aabPath).existsSync()) {
    buildFile = File(aabPath);
    buildType = 'AAB';
  } else if (File(apkPath).existsSync()) {
    buildFile = File(apkPath);
    buildType = 'APK';
  } else {
    _writeLine('❌ No build file found. Please build the app first:');
    _writeLine('   flutter build appbundle --release');
    _writeLine('   or');
    _writeLine('   flutter build apk --release');
    exit(1);
  }

  final sizeBytes = await buildFile.length();
  final sizeMB = sizeBytes / (1024 * 1024);

  _writeLine('📦 Build File: ${buildFile.path}');
  _writeLine('📏 Size: ${sizeMB.toStringAsFixed(2)} MB ($sizeBytes bytes)');
  _writeLine('🎯 Target: < 100 MB\n');

  if (sizeMB > 100) {
    _writeLine(
      '⚠️  WARNING: Build size exceeds 100 MB target by '
      '${(sizeMB - 100).toStringAsFixed(2)} MB',
    );
  } else {
    _writeLine('✅ Build size is within target (< 100 MB)');
  }

  // Analyze assets if APK
  if (buildType == 'APK') {
    _writeLine('\n📋 Asset Analysis:');
    await _analyzeAssets();
  }

  // Check for size analysis JSON if available
  final sizeAnalysisPath = 'build/app/outputs/size-analysis.json';
  if (File(sizeAnalysisPath).existsSync()) {
    _writeLine('\n📊 Detailed Size Analysis:');
    await _parseSizeAnalysis(sizeAnalysisPath);
  } else {
    _writeLine(
      '\n💡 Tip: Run "flutter build apk --release --analyze-size" '
      'for detailed analysis',
    );
  }
}

Future<void> _analyzeAssets() async {
  final assetsDir = Directory('assets');
  if (!assetsDir.existsSync()) {
    _writeLine('   No assets directory found');
    return;
  }

  _writeLine('   Assets directory breakdown:');

  await _analyzeDirectory(assetsDir, 'assets', 0);
}

Future<void> _analyzeDirectory(Directory dir, String path, int depth) async {
  final indent = '  ' * (depth + 1);
  final entries = dir.listSync();

  int totalSize = 0;
  int fileCount = 0;

  for (final entry in entries) {
    if (entry is File) {
      final size = await entry.length();
      totalSize += size;
      fileCount++;

      if (size > 100 * 1024) {
        // Files larger than 100KB
        final sizeKB = size / 1024;
        _writeLine(
          '$indent${entry.path.split('/').last}: '
          '${sizeKB.toStringAsFixed(2)} KB',
        );
      }
    } else if (entry is Directory) {
      final dirSize = await _getDirectorySize(entry);
      if (dirSize > 0) {
        final sizeMB = dirSize / (1024 * 1024);
        _writeLine(
          '$indent${entry.path.split('/').last}/: '
          '${sizeMB.toStringAsFixed(2)} MB',
        );
        await _analyzeDirectory(entry, entry.path, depth + 1);
      }
    }
  }

  if (depth == 0 && totalSize > 0) {
    final totalMB = totalSize / (1024 * 1024);
    _writeLine(
      '\n   Total assets: ${totalMB.toStringAsFixed(2)} MB '
      '($fileCount files)',
    );
  }
}

Future<int> _getDirectorySize(Directory dir) async {
  int totalSize = 0;
  try {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
  } catch (e) {
    // Ignore errors
  }
  return totalSize;
}

Future<void> _parseSizeAnalysis(String path) async {
  try {
    final content = await File(path).readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    if (data.containsKey('tree')) {
      final tree = data['tree'] as Map<String, dynamic>;
      _printSizeTree(tree, '');
    }
  } catch (e) {
    _writeLine('   Could not parse size analysis: $e');
  }
}

void _printSizeTree(Map<String, dynamic> node, String indent) {
  final name = node['n'] as String? ?? 'Unknown';
  final size = node['s'] as int? ?? 0;

  if (size > 100 * 1024) {
    // Only show items > 100KB
    final sizeKB = size / 1024;
    _writeLine('$indent$name: ${sizeKB.toStringAsFixed(2)} KB');
  }

  final children = node['children'] as List<dynamic>?;
  if (children != null) {
    for (final child in children) {
      if (child is Map<String, dynamic>) {
        _printSizeTree(child, '$indent  ');
      }
    }
  }
}

void _writeLine(Object? message) {
  stdout.writeln(message);
}
